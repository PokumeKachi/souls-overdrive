set dotenv-load := true

_default:
    @just --choose

asphalt:
    asphalt sync

run:
    rojo serve

wally:
    wally install

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
