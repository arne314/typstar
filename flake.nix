{
  description = "typstar nix flake for development and testing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, system, ... }:
        let
          pluginDeps = with pkgs.vimPlugins; [
            luasnip
            nvim-treesitter-parsers.typst
          ];
          typstarPlugin = pkgs.vimUtils.buildVimPlugin {
            name = "typstar";
            src = self;
            buildInputs = pluginDeps;
          };
          repeatStubPlugin = pkgs.vimUtils.buildVimPlugin {
            name = "repeat-stub";
            src =
              pkgs.writeTextDir "autoload/repeat.vim" # Vim
                ''
                  if exists('*repeat#set')
                    finish
                  endif
                  function! repeat#set(...) abort
                  endfunction
                '';
          };
          nvimBuild =
            extraPlugins:
            let
              config = pkgs.neovimUtils.makeNeovimConfig {
                customRC = # Lua
                  ''
                    lua << EOF
                    print("Welcome to Typstar! This is just a demo.")
                    ${builtins.readFile ./lua/tests/basic_init.lua}
                    EOF
                  '';
                plugins =
                  with pkgs.vimPlugins;
                  [
                    mini-nvim
                    repeatStubPlugin
                  ]
                  ++ pluginDeps
                  ++ extraPlugins;
              };
            in
            pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped config;
          nvimFullBuild = nvimBuild [ typstarPlugin ];
          nvimDevBuild = nvimBuild [ ];

          lintLua = pkgs.writeShellScriptBin "lint-lua" ''
            set -e
            ${pkgs.lua-language-server}/bin/lua-language-server --check .
            ${pkgs.stylua}/bin/stylua --check .
          '';
          lintPython = pkgs.writeShellScriptBin "lint-python" ''
            set -e
            ${pkgs.ruff}/bin/ruff check .
            ${pkgs.ruff}/bin/ruff format --diff --check .
          '';
        in
        {
          checks.default =
            pkgs.runCommand "typstar-plugin-tests"
              {
                buildInputs = [
                  nvimFullBuild
                  pkgs.which
                ];
                src = ./.;
              }
              ''
                export HOME=$out/home
                mkdir -p $HOME
                cd $src
                nvim --headless -c "lua MiniTest.run()"
              '';
          devShells = {
            default = pkgs.mkShell {
              packages = [
                nvimDevBuild
                pkgs.uv
                pkgs.just
              ];
              shellHook = # Bash
                ''
                  uv sync --locked
                  source .venv/bin/activate
                  export NVIM_PLUGIN_DEV=$(pwd)
                '';
            };
            lazy = pkgs.mkShell {
              packages = with pkgs; [
                just
                neovim
                tree-sitter
              ];
              shellHook = # Bash
                ''
                  just lazy --headless -c "q"
                '';
            };
          };
          packages = {
            default = typstarPlugin;
            nvim = nvimFullBuild;
            lint-lua = lintLua;
            lint-python = lintPython;
          };
        };
    };
}
