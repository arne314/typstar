import html

import tree_sitter

from .file_handler import FileHandler


class Flashcard:
    note_id: int
    front: str
    back: str
    deck: str
    id_updated: bool

    preamble: str | None
    file_handler: FileHandler

    note_id_node: tree_sitter.Node
    front_node: tree_sitter.Node
    back_node: tree_sitter.Node

    svg_front: bytes
    svg_back: bytes

    def __init__(
        self,
        front: str,
        back: str,
        deck: str | None,
        note_id: int,
        preamble: str | None,
        file_handler: FileHandler,
    ):
        if deck is None:
            deck = "Default"
        if not note_id:
            note_id = 0
        self.front = front
        self.back = back
        self.deck = deck
        self.note_id = note_id
        self.preamble = preamble
        self.file_handler = file_handler
        self.id_updated = False

    def __str__(self):
        return f"Flashcard(id={self.note_id}, front={self.front})"

    def as_typst(self, front: bool) -> str:
        if self.front_node.type == "string":
            return f'#flashcard({self.note_id}, "{self.front if front else ""}")[{self.back if not front else ""}]'
        return f"#flashcard({self.note_id})[{self.front if front else ''}][{self.back if not front else ''}]"

    def as_html(self, front: bool) -> str:
        safe_front = html.escape(self.front)
        safe_back = html.escape(self.back)
        prefix = f"<p hidden>{safe_front}: {safe_back}{' ' * 10}</p>"  # indexable via anki search
        image = f'<img src="{self.svg_filename(front)}" />'
        return prefix + image

    def as_anki_model(self, tmp: bool = False) -> dict:
        model = {
            "modelName": "Basic",
            "fields": {
                "Front": f"tmp typst: {self.front}" if tmp else self.as_html(True),
                "Back": f"tmp typst: {self.back}" if tmp else self.as_html(False),
            },
            "tags": ["typst"],
        }
        if not self.is_new():
            model["id"] = self.note_id
        return model

    def svg_filename(self, front: bool) -> str:
        return f"typst_{self.note_id}_{'front' if front else 'back'}.svg"

    def is_new(self) -> bool:
        return self.note_id == 0 or self.note_id is None

    def set_ts_nodes(
        self, front: tree_sitter.Node, back: tree_sitter.Node, note_id: tree_sitter.Node
    ):
        self.front_node = front
        self.back_node = back
        self.note_id_node = note_id

    def update_id(self, value: int):
        if self.note_id != value:
            self.note_id = value
            self.id_updated = True

    def set_svgs(self, front, back):
        self.svg_front = front
        self.svg_back = back
