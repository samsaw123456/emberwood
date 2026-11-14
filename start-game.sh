#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -P "$(dirname "$0")" && pwd)

if [ -n "${GODOT_BIN:-}" ]; then
	godot_bin=$GODOT_BIN
elif command -v godot4 >/dev/null 2>&1; then
	godot_bin=godot4
elif command -v godot >/dev/null 2>&1; then
	godot_bin=godot
elif [ -x "$HOME/.local/share/phippy-tools/Godot_v4.5.1-stable_linux.x86_64" ]; then
	godot_bin=$HOME/.local/share/phippy-tools/Godot_v4.5.1-stable_linux.x86_64
else
	printf '%s\n' 'Godot 4 is needed to play Emberwood.' >&2
	printf '%s\n' 'Install Godot 4.5.1, open project.godot, and press Play.' >&2
	printf '%s\n' 'For this launcher, put godot4 on PATH or set GODOT_BIN to its executable.' >&2
	exit 127
fi

if ! command -v "$godot_bin" >/dev/null 2>&1; then
	printf 'Cannot run Godot: %s\n' "$godot_bin" >&2
	printf '%s\n' 'Set GODOT_BIN to a Godot 4 executable, without extra arguments.' >&2
	exit 127
fi

exec "$godot_bin" --path "$project_dir" "$@"
