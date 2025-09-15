# Typstar
Neovim plugin for efficient (mathematical) note taking in Typst

## Features
- Powerful autosnippets using [LuaSnip](https://github.com/L3MON4D3/LuaSnip/) and [Tree-sitter](https://tree-sitter.github.io/) (inspired by [fastex.nvim](https://github.com/lentilus/fastex.nvim))
- Easy insertion of drawings using [Obsidian Excalidraw](https://github.com/zsviczian/obsidian-excalidraw-plugin) or [Rnote](https://github.com/flxzt/rnote)
- Export of [Anki](https://apps.ankiweb.net/) flashcards \[No Neovim required\]

## Usage

### Snippets
Use `:TypstarToggleSnippets` to toggle all snippets at any time.
To efficiently navigate insert nodes and avoid overlapping ones,
use `:TypstarSmartJump` and `:TypstarSmartJumpBack`.
Available snippets can mostly be intuitively derived from [here](././lua/typstar/snippets), they include:

Universal snippets:
- Alphanumeric characters: `:<char>` &#8594; `$<char>$ ` in markup (e.g. `:X` &#8594; `$X$ `, `:5` &#8594; `$5$ `)
- Greek letters: `;<latin>` &#8594; `<greek>` in math and `$<greek>$ ` in markup (e.g. `;a` &#8594; `alpha`/`$alpha$ `)
- Common indices (numbers and letters `i-n`): `<letter><index> ` &#8594; `<letter>_<index> ` in math and `$<letter>$ <index> ` &#8594; `$<letter>_<index>$ ` in markup (e.g `A314 ` &#8594; `A_314 `, `$alpha$ n ` &#8594; `$alpha_n$ `)

You can find a complete map of latin to greek letters including reasons for the less intuitive ones [here](./lua/typstar/snippets/letters.lua).
Note that some greek letters have multiple latin ones mapped to them.

Markup snippets:
- Begin inline math with `ll` and multiline math with `dm`
- [Markup shorthands](./lua/typstar/snippets/markup.lua) (e.g. `HIG` &#8594; `#highlight[<cursor>]`, `IMP` &#8594; `$==>$ `)
- [ctheorems shorthands](./lua/typstar/snippets/markup.lua) (e.g. `tem` &#8594; empty theorem, `exa` &#8594; empty example)
- [Flashcards](#anki): `fla` and `flA`
- All above snippets support visual mode via the [selection key](#installation)

Math snippets:
- [Many shorthands](./lua/typstar/snippets/math.lua) for mathematical expressions
- Series of numbered letters: `<letter> ot<optional last index> ` &#8594; `<letter>_1, <letter>_2, ... ` (e.g. `a ot ` &#8594; `a_1, a_2, ... `, `a ot4 ` &#8594; `a_1, a_2, a_3, a_4 `, `alpha otk ` &#8594; `alpha_1, alpha_2, ..., alpha_k `, `oti ` &#8594; `1, 2, ..., i `)
- Wrapping of any mathematical expression (see [operations](./lua/typstar/snippets/visual.lua), works nested, multiline and in visual mode via the [selection key](#installation)): `<expression><operation>` &#8594; `<operation>(<expression>)` (e.g. `(a^2+b^2)rt` &#8594; `sqrt(a^2+b^2)`, `lambdatd` &#8594; `tilde(lambda)`, `(1+1)sQ` &#8594; `[1+1]`, `(1+1)sq` &#8594; `[(1+1)]`)
- Simple functions: `fo<value> ` &#8594; `f(<value>) ` (e.g. `fox ` &#8594; `f(x) `, `ao5 ` &#8594; `a(5) `)
- Matrices: `<size>ma` and `<size>lma` (e.g. `23ma` &#8594; 2x3 matrix)

Note that you can [customize](#custom-snippets) (enable, disable and modify) every snippet.

### Excalidraw/Rnote
- Use `:TypstarInsertExcalidraw`/`:TypstarInsertRnote` to
  create a new drawing using the [configured](#configuration) template,
  insert a figure displaying it and open it in Obsidian/Rnote.
- To open an inserted drawing in Obsidian/Rnote,
  simply run `:TypstarOpenDrawing` (or `:TypstarOpenExcalidraw`/`:TypstarOpenRnote` if you are using the same file extension for both)
  while your cursor is on a line referencing the drawing.

### Anki
Use the `flA` snippet to create a new flashcard
```typst
#flashcard(0, "My first flashcard")[
  Typst is awesome $a^2+b^2=c^2$
]
```
or the `fla` snippet to add a more complex front
```typst
#flashcard(0)[I love Typst $pi$][
  This is the back of my second flashcard
]
```

To render the flashcard in your document as well add some code like this
```typst
#let flashcard(id, front, back) = {
  strong(front)
  [\ ]
  back
}
```

- Add a comment like `// ANKI: MY::DECK` to your document to set a deck used for all flashcards after this comment (You can use multiple decks per file)
- Add a file named `.anki` containing a deck name to define a default deck on a directory base
- Add a file named `.anki.typ` to define a preamble on a directory base. You can find the default preamble [here](./src/anki/typst_compiler.py).
- Tip: Despite the use of SVGs you can still search your flashcards in Anki as the typst source is added into an invisible html paragraph

#### Neovim
- Use `:TypstarAnkiScan` to scan the current nvim working directory and compile all flashcards in its context, unchanged files will be ignored
- Use `:TypstarAnkiForce` to force compilation of all flashcards in the current working directory even if the files haven't changed since the last scan (e.g. on preamble change)
- Use `:TypstarAnkiForceCurrent` to force compilation of all flashcards in the file currently edited
- Use `:TypstarAnkiReimport` to also add flashcards that have already been asigned an id but are not currently
present in Anki
- Use `:TypstarAnkiForceReimport` and `:TypstarAnkiForceCurrentReimport` to combine features accordingly

#### Standalone
- Run `typstar-anki --help` to show the available options


## Installation
Install the plugin in Neovim (see [Nix instructions](#in-a-nix-flake-optional)) and run the plugin setup.
```lua
require('typstar').setup({ -- depending on your neovim plugin system
   -- your typstar config goes here
})
```

<details>
<summary>Example lazy.nvim config</summary>

```lua
{
    "arne314/typstar",
    dependencies = {
        "L3MON4D3/LuaSnip",
    },
    ft = { "typst" },
    keys = {
        {
            "<M-t>",
            "<Cmd>TypstarToggleSnippets<CR>",
            mode = { "n", "i" },
        },
        {
            "<M-j>",
            "<Cmd>TypstarSmartJump<CR>",
            mode = { "s", "i" },
        },
        {
            "<M-k>",
            "<Cmd>TypstarSmartJumpBack<CR>",
            mode = { "s", "i" },
        },
    },
    config = function()
        local typstar = require("typstar")
        typstar.setup({
            -- your typstar configuration
            add_undo_breakpoints = true,
        })
    end,
},
{
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
    config = function()
        local luasnip = require("luasnip")
        luasnip.config.setup({
            enable_autosnippets = true,
            store_selection_keys = "<Tab>",
        })
    end,
},
{
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    config = function()
        local configs = require("nvim-treesitter.configs")
        configs.setup({
            ensure_installed = { "typst" },
        })
    end,
},
```
</details>

### Snippets
1. Install [LuaSnip](https://github.com/L3MON4D3/LuaSnip/), set `enable_autosnippets = true` and set a visual mode selection key (e.g. `store_selection_keys = '<Tab>'`) in the configuration
2. Install [jsregexp](https://github.com/kmarius/jsregexp) as described [here](https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md#transformations) (You will see a warning on startup if jsregexp isn't installed properly)
3. Install [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) and run `:TSInstall typst`
4. Make sure you haven't remapped `<C-g>`. Otherwise set `add_undo_breakpoints = false` in the [config](#configuration)
5. Optional: Setup [ctheorems](https://typst.app/universe/package/ctheorems/) with names like [here](./lua/typstar/snippets/markup.lua)

### Excalidraw
1. Install [Obsidian](https://obsidian.md/) and create a vault in your typst note taking directory
2. Install the [obsidian-excalidraw-plugin](https://github.com/zsviczian/obsidian-excalidraw-plugin) and enable `Auto-export SVG` (in plugin settings at `Embedding Excalidraw into your Notes and Exporting > Export Settings > Auto-export Settings`)
3. Have the `xdg-open` command working or set a different command at `uriOpenCommand` in the [config](#configuration)
4. If you encounter issues with the file creation of drawings, try cloning the repo into `~/typstar` or setting the `typstarRoot` config accordingly; feel free to open an issue

### Rnote
1. Install [Rnote](https://github.com/flxzt/rnote?tab=readme-ov-file#installation); I recommend not using flatpak as that might cause issues with file permissions.
2. Make sure `rnote-cli` is available in your `PATH` or set a different command at `exportCommand` in the [config](#configuration)
3. Have the `xdg-open` command working with Rnote files or set a different command at `uriOpenCommand` in the [config](#configuration)
4. See comment 4 above at Excalidraw

### Anki
0. Typst version `0.12.0` or higher is required
1. Install [Anki](https://apps.ankiweb.net/#download)
2. Install [Anki-Connect](https://ankiweb.net/shared/info/2055492159) and make sure `http://localhost` is added to `webCorsOriginList` in the Add-on config (should be added by default)
3. Install the typstar python package (I recommend using [pipx](https://github.com/pypa/pipx) via `pipx install git+https://github.com/arne314/typstar`, you will need to have python build tools and clang installed) \[Note: this may take a while\]
4. Make sure the `typstar-anki` command is available in your `PATH` or modify the `typstarAnkiCmd` option in the [config](#configuration)

### In a Nix Flake (optional)
You can add typstar to your `nix-flake` like so
```nix
# `flake.nix`
inputs = {
  # ... other inputs
  typstar = {
    url = "github:arne314/typstar";
    flake = false;
  };
}
```
Now you can use `typstar` in any package-set
```nix
with pkgs; [
  # ... other packges
  (pkgs.vimUtils.buildVimPlugin {
     name = "typstar";
     src = inputs.typstar; 
     buildInputs = [
        vimPlugins.luasnip 
        vimPlugins.nvim-treesitter-parsers.typst
     ];
  })
]
```

## Configuration
Configuration options can be intuitively derived from the table [here](./lua/typstar/config.lua).

### Excalidraw/Rnote templates
The `templatePath` option expects a table that maps file patterns to template locations.
To for example have a specific template for lectures, you could configure it like this
```Lua
templatePath = {
    { 'lectures/.*%.excalidraw%.md$', '~/Templates/lecture_excalidraw.excalidraw.md' }, -- path contains "lectures"
    { '%.excalidraw%.md$', '~/Templates/default_excalidraw.excalidraw.md' }, -- fallback
},
```

### Custom snippets
The [config](#configuration) allows you to
- disable all snippets via `snippets.enable = false`
- only include specific modules from the snippets folder via e.g. `snippets.modules = { 'letters' }`
- exclude specific triggers via e.g. `snippets.exclude = { 'dx', 'ddx' }`
- disable different behaviors of snippets from the `visual` module
    - visual selection via e.g. `snippets.visual_disable = { 'br' }`
    - normal snippets (`abs` &#8594; `abs(1+1)`) via e.g. `snippets.visual_disable_normal = { 'abs' }`
    - postfix snippets (`xabs` &#8594; `abs(x)`) via e.g. `snippets.visual_disable_postfix = { 'abs' }`

For further customization you can make use of the provided wrappers from within your [LuaSnip](https://github.com/L3MON4D3/LuaSnip/) config.
Let's say you prefer the short `=>` arrow over the long `==>` one and would like to change the `ip` trigger to `imp`.
Your `typstar` config could look like
```lua
require('typstar').setup({
    snippets = {
        exclude = { 'ip' },
    },
})
```
while your LuaSnip `typst.lua` could look like this (`<` and `>` require escaping as `<>` [introduces a new node](https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md#fmt))
```lua
local tp = require('typstar.autosnippets')
local snip = tp.snip
local math = tp.in_math
local markup = tp.in_markup

return {
    -- add a new snippet (the old one is excluded via the config)
    snip('imp', '=>> ', {}, math),

    -- override existing triggers by setting a high priority
    snip('ib', '<<= ', {}, math, 2000),
    snip('iff', '<<=>> ', {}, math, 2000),

    -- setup markup snippets accordingly
    snip('IMP', '$=>>$ ', {}, markup, 2000),
    snip('IFF', '$<<=>>$ ', {}, markup, 2000),
}
```

