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
        "x86_64-darwin"
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
          devShells.default = pkgs.mkShell {
            packages = [
              nvimDevBuild
              pkgs.uv
              pkgs.just
            ];
            shellHook = # Bash
              ''
                uv sync --locked
                export NVIM_PLUGIN_DEV=$(pwd)
              '';
          };
          packages = {
            default = typstarPlugin;
            nvim = nvimFullBuild;
          };
        };
    };
}
