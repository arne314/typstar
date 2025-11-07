import asyncio
import os
from pathlib import Path

import typer
from typing_extensions import Annotated

from anki.anki_api import AnkiConnectApi
from anki.parser import FlashcardParser
from anki.typst_compiler import TypstCompiler

cli = typer.Typer(name="typstar-anki")


async def export_flashcards(
    root_dir, force_scan, clear_cache, reimport, typst_cmd, anki_url, anki_key
):
    parser = FlashcardParser()
    compiler = TypstCompiler(root_dir, typst_cmd)
    api = AnkiConnectApi(anki_url, anki_key)

    # parse flashcards
    if clear_cache:
        parser.clear_file_hashes()
    flashcards = parser.parse_directory(root_dir, force_scan)

    # async typst compilation
    await compiler.compile_flashcards(flashcards)

    try:
        # async anki push
        await api.push_flashcards(flashcards, reimport)
    finally:
        # write id updates to files
        parser.update_ids_in_source()
    parser.save_file_hashes()
    print("Done", flush=True)


@cli.command()
def cmd(
    root_dir: Annotated[
        Path,
        typer.Option(
            help="Directory scanned for flashcards and passed over to typst compile command"
        ),
    ] = Path(os.getcwd()),
    force_scan: Annotated[
        Path | None,
        typer.Option(
            help="File/directory to scan for flashcards while ignoring stored "
            "file hashes (e.g. on preamble change)"
        ),
    ] = None,
    clear_cache: Annotated[
        bool,
        typer.Option(
            help="Clear all stored file hashes (more aggressive than force-scan "
            "as it clears hashes regardless of their path)"
        ),
    ] = False,
    reimport: Annotated[
        bool,
        typer.Option(
            help="Instead of throwing an error, also add flashcards that have already been assigned an id "
            "but are not present in Anki. The assigned id will be updated in the source code."
        ),
    ] = False,
    typst_cmd: Annotated[
        str, typer.Option(help="Typst command used for flashcard compilation")
    ] = "typst",
    anki_url: Annotated[str, typer.Option(help="Url for Anki-Connect")] = "http://127.0.0.1:8765",
    anki_key: Annotated[str | None, typer.Option(help="Api key for Anki-Connect")] = None,
):
    asyncio.run(
        export_flashcards(
            root_dir, force_scan, clear_cache, reimport, typst_cmd, anki_url, anki_key
        )
    )


def main():
    typer.run(cmd)


if __name__ == "__main__":
    main()
