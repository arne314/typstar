import asyncio
import glob
import os
from typing_extensions import Annotated

import typer

from anki.anki_api import AnkiConnectApi
from anki.file_handler import FileHandler
from anki.parser import FlashcardParser
from anki.typst_compiler import TypstCompiler

cli = typer.Typer(name="typstar-anki")


async def export_flashcards(root_dir, typst_cmd, anki_url, anki_key):
    parser = FlashcardParser()
    compiler = TypstCompiler(root_dir, typst_cmd)
    api = AnkiConnectApi(anki_url, anki_key)

    # parse flashcards
    flashcards = parser.parse_directory(root_dir)

    # async typst compilation
    await compiler.compile_flashcards(flashcards)

    try:
        # async anki push per deck
        await api.push_flashcards(flashcards)
    finally:
        # write id updates to files
        parser.update_ids_in_source()
    print("Done")


@cli.command()
def cmd(root_dir: Annotated[
    str, typer.Option(help="Directory scanned for flashcards and passed over to typst compile command")] = os.getcwd(),
        typst_cmd: Annotated[str, typer.Option(help="Typst command used for flashcard compilation")] = "typst",
        anki_url: Annotated[str, typer.Option(help="Url for Anki-Connect")] = "http://127.0.0.1:8765",
        anki_key: Annotated[str, typer.Option(help="Api key for Anki-Connect")] = None,
        ):
    asyncio.run(export_flashcards(root_dir, typst_cmd, anki_url, anki_key))


def main():
    typer.run(cmd)


if __name__ == "__main__":
    main()
