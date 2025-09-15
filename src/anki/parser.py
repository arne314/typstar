import json
import re
from glob import glob
from pathlib import Path
from typing import List, Tuple

import appdirs
import tree_sitter
from tree_sitter_typst import language as get_typst_language

from .config_parser import RecursiveConfigParser
from .file_handler import FileHandler
from .flashcard import Flashcard

ts_flashcard_query = """
(call 
  item: [
    (call 
      item: (call 
        item: (ident) @fncall
        (group 
          (number) @id))
      (content) @front)
    (call
      item: (ident) @fncall
      (group
        (number) @id
        (string) @front))
    ]
    (#eq? @fncall "flashcard")
  ((content) @back
) @flashcard)
"""

ts_deck_query = """
((comment) @deck)
"""
deck_regex = re.compile(r"\W+ANKI:\s*([\S ]*)")


class FlashcardParser:
    typst_language: tree_sitter.Language
    typst_parser: tree_sitter.Parser
    flashcard_query_cursor: tree_sitter.Query
    deck_query_cursor: tree_sitter.Query

    file_handlers: List[tuple[FileHandler, List[Flashcard]]]
    file_hashes: dict[str, str]
    file_hashes_store_path: Path = Path(appdirs.user_state_dir("typstar") + "/file_hashes.json")

    def __init__(self):
        self.typst_language = tree_sitter.Language(get_typst_language())
        self.typst_parser = tree_sitter.Parser(self.typst_language)
        self.flashcard_query_cursor = tree_sitter.QueryCursor(
            self.typst_language.query(ts_flashcard_query)
        )
        self.deck_query_cursor = tree_sitter.QueryCursor(self.typst_language.query(ts_deck_query))
        self.file_handlers = []
        self._load_file_hashes()

    def _parse_file(
        self, file: FileHandler, preamble: str | None, default_deck: str | None
    ) -> List[Flashcard]:
        cards = []
        tree = self.typst_parser.parse(file.get_bytes(), encoding="utf8")
        card_captures = self.flashcard_query_cursor.captures(tree.root_node)
        if not card_captures:
            return cards
        deck_captures = self.deck_query_cursor.captures(tree.root_node)

        def row_compare(node):
            return node.start_point.row

        card_captures["id"].sort(key=row_compare)
        card_captures["front"].sort(key=row_compare)
        card_captures["back"].sort(key=row_compare)

        deck_refs: List[Tuple[int, str | None]] = []
        deck_refs_idx = -1
        current_deck = default_deck
        if deck_captures:
            deck_captures["deck"].sort(key=row_compare)
            for comment in deck_captures["deck"]:
                if match := deck_regex.match(file.get_node_content(comment)):
                    deck_refs.append(
                        (
                            comment.start_point.row,
                            None if match[1].isspace() else match[1],
                        )
                    )

        for note_id, front, back in zip(
            card_captures["id"], card_captures["front"], card_captures["back"]
        ):
            while (
                deck_refs_idx < len(deck_refs) - 1
                and back.end_point.row >= deck_refs[deck_refs_idx + 1][0]
            ):
                deck_refs_idx += 1
                current_deck = deck_refs[deck_refs_idx][1]

            card = Flashcard(
                file.get_node_content(front, True),
                file.get_node_content(back, True),
                current_deck,
                int(file.get_node_content(note_id)),
                preamble,
                file,
            )
            card.set_ts_nodes(front, back, note_id)
            cards.append(card)
        return cards

    def parse_directory(self, root_dir: Path, force_scan: Path | None = None):
        flashcards = []
        single_file = None
        is_force_scan = force_scan is not None
        if is_force_scan:
            if force_scan.is_file():
                single_file = force_scan
                scan_dir = force_scan.parent
            else:
                scan_dir = force_scan
        else:
            scan_dir = root_dir

        print(
            f"Parsing flashcards in {scan_dir if single_file is None else single_file} ...",
            flush=True,
        )
        configs = RecursiveConfigParser(
            root_dir, {".anki", ".anki.typ"}, recursive=single_file is None
        )

        for file in glob(f"{scan_dir}/**/**.typ", recursive=True):
            file = Path(file)
            if single_file is not None and file != single_file:
                continue

            fh = FileHandler(file)
            file_changed = self._hash_changed(fh)
            if is_force_scan or file_changed:
                cards = self._parse_file(
                    fh, configs.get_config(file, ".anki.typ"), configs.get_config(file, ".anki")
                )
                self.file_handlers.append((fh, cards))
                flashcards.extend(cards)
        return flashcards

    def _hash_changed(self, file: FileHandler) -> bool:
        file_hash = file.get_file_hash()
        cached = self.file_hashes.get(str(file.file_path))
        self.file_hashes[str(file.file_path)] = file_hash
        return file_hash != cached

    def _load_file_hashes(self):
        self.file_hashes_store_path.parent.mkdir(parents=True, exist_ok=True)
        self.file_hashes_store_path.touch()
        content = self.file_hashes_store_path.read_text()
        if content:
            self.file_hashes = json.loads(content)
        else:
            self.file_hashes = {}

    def save_file_hashes(self):
        self.file_hashes_store_path.write_text(json.dumps(self.file_hashes))

    def clear_file_hashes(self):
        self.file_hashes = {}
        self.save_file_hashes()

    def update_ids_in_source(self):
        print("Updating ids in source...", flush=True)
        for fh, cards in self.file_handlers:
            file_updated = False
            for c in cards:
                if c.id_updated:
                    fh.update_node_content(c.note_id_node, c.note_id)
                    file_updated = True
            if file_updated:
                fh.write()
                self.file_hashes[str(fh.file_path)] = fh.get_file_hash()
