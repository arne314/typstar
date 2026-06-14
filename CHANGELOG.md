# Changelog

## 1.6.0 - 2026-06-14
PR #28

### Changed
- theorem snippet triggers have less conflicts (`thm`, `prf`, `prp`, `lmm`, `crl`, `axm`, `dfn`, `exm`, `rmr`)
- theorem snippets have been moved into a separate module (enabled by default)
- math triggers allow numbers in front of them (e.g. `3x1 ` for `3x_1 `)
- `br` snippet uses `dash` instead of `macron`
- matrix triggers are now `<dim>ma ` and `<dim>ma.`

### Fixed
- Anki string fronts will be compiled in Typst strings for full unicode compatibility
- matrix snippet edge cases (e.g. with dimension 1)
- letter prime snippet conflict edge cases

## 1.5.1 - 2026-03-27

### Changed
- Python package can now be installed from PyPI without any build tools

### Fixed
- Anki export on Windows

## 1.5.0 - 2026-03-24
PR #26

### Changed
- BREAKING: inline math trigger `ll` -> `kk`
- reduced trigger conflicts in visual snippets
  (diaer, arrow, floor, ceil now trigger with `dir`, `arw`, `flr` and `cel`)

### Added
- snippet test engine
- weekly integration tests with latest (nixpkgs) nvim
- prime snippets
- numbered series snippets starting from 0
- simple plugin update notification
- config: override any luasnip snippet option
- config: luasnip callbacks helper
- docs: better dev workflow documentation

### Fixed
- node jumping issues
- a few snippet engine issues
- Anki package installation issues
- special characters in Anki paths

## 1.4.2 - 2025-11-04
PR #22

### Changed
- Typst 0.14 compatibility

### Added
- basic "physics" snippets
- additional superscript snippets

### Removed
- ak/sk plus minus snippets

## 1.4.1 - 2025-09-15
PR #20

### Changed
- a few snippets

### Added
- a few snippets

### Fixed
- breaking change in the tree sitter python bindings
- a few snippets

## 1.4.0 - 2025-08-04
PR #19

### Changed
- a few snippets
- documentation improvements

### Added
- Rnote integration: quickly insert and open Rnote drawings with automatic (svg) export

## 1.3.4 - 2025-07-12
PR #18

### Added
- easy insert node traversal via `TypstarSmartJump` and `TypstarSmartJumpBack`
- ability to precisely configure visual snippets

### Fixed
- a few snippet issues

## 1.3.3 - 2025-06-11
PR #16

### Changed
- smarter `dm` expansion and indentation

### Added
- ability to insert undo breakpoints on snippet expansion

### Fixed
- a few snippet issues

## 1.3.2 - 2025-05-07
PR #14

### Changed
- snippet wordtrig syntax
- a few snippets

### Added
- nvim 0.11 support
- ability to blacklist certain triggers per snippet

### Fixed
- a few snippet issues
- html escaping in Anki

## 1.3.1 - 2025-02-10
PR #12

### Changed
- snippets now support Typst 0.13

### Fixed
- Anki issues

## 1.3.0 - 2025-02-07
PR #11

### Added
- Anki flashcard reimport
- installation and customization documentation
- a few snippets

### Changed
- a few snippets

### Fixed
- snippet matching issues

## 1.2.0 - 2025-01-10
PR #8

### Changed
- a few math snippets

### Added
- Anki default deck per directory
- warning on missing jsregexp
- markup wrapping snippets

## 1.1.1 - 2025-01-03
PR #4

### Fixed
- optimized tree sitter dependencies
- unicode in flashcards

## 1.1.0 - 2025-01-01
PR #3

### Added
- Anki flashcard export

## 1.0.0 - 2024-12-14
PR #2

### Changed
- big performance improvements

### Added
- snippets for common indices
- smart tree sitter snippets

