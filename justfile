# dev shell with nix built nvim but sourcing the plugin upon start
dev:
    nix develop

# run nix built nvim including the plugin
run:
    nix run .#nvim -- test.typ

# run all tests in a flake check
check:
    nix flake check

# run all tests or specify a file; expected to be run in the dev shell
test *file:
    @if [ "{{file}}" = "" ]; then \
        nvim --headless -c "lua MiniTest.run()"; \
    else \
        nvim --headless -c "lua MiniTest.run_file('{{file}}')"; \
    fi

