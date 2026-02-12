set dotenv-load := true

_default:
    @just --choose

asphalt:
    asphalt sync

blink:
    pesde run blink Blink/main.blink --watch

watch:
	watchexec \
	  -w src \
	  -w wally.toml \
	  -w default.project.json \
	  -- just sourcemap

sourcemap: wally
    argon sourcemap default.project.json --output sourcemap.json
    wally-package-types --sourcemap sourcemap.json Packages/

run:
    argon serve

wally:
    wally install

pesde:
    pesde install


todo:
    taskwarrior-tui --taskdata .task

git:
    gitui

develop:
    @sh -c ' \
        h=$(nix hash path ./flake.nix); \
        old="$FLAKE_HASH"; \
        if [ "$old" != "$h" ]; then \
            echo "Entering flake shell..."; \
            FLAKE_HASH="$h" exec nix develop; \
        else \
            echo "Inside flake shell, skipping nix develop..."; \
        fi \
    '
