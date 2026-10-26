# dev shell with nix built nvim but sourcing the plugin upon start
dev:
    nix develop

# dev shell with plain nvim for lazy testing
dev-lazy:
    nix develop .#lazy

# lint lua and/or python
lint *lang:
    @if [ -z "{{lang}}" ]; then \
        nix run .#lint-lua; \
        nix run .#lint-python; \
    else \
        nix run .#lint-{{lang}}; \
    fi

# run nix built nvim including the plugin
run:
    nix run .#nvim -- test.typ

# run all tests in a flake check
check:
    nix flake check

# run all tests or specify a file; expected to be run in the dev shell
test *file:
    @if [ -z "{{file}}" ]; then \
        nvim --headless -c "lua MiniTest.run()"; \
    else \
        nvim --headless -c "lua MiniTest.run_file('{{file}}')"; \
    fi

# run tests in lazy
test-lazy *file:
    @if [ -z "{{file}}" ]; then \
        ./res/lazy/lazy.sh --headless -c "lua MiniTest.run()"; \
    else \
        ./res/lazy/lazy.sh --headless -c "lua MiniTest.run_file('{{file}}')"; \
    fi

# run typstar in an isolated lazy installation (no nix required)
lazy *args:
    @if [ -z "{{args}}" ]; then \
        ./res/lazy/lazy.sh test.typ; \
    else \
        ./res/lazy/lazy.sh {{args}}; \
    fi

# lint within lazy shell
lazy-lint:
    lua-language-server --check . --configpath "$LUARC"
    stylua --check .
