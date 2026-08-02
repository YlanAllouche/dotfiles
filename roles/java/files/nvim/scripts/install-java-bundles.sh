#!/usr/bin/env bash
# Install the jdtls bundles (java-debug-adapter + java-test) used by
# nvim-jdtls.
#
# mason downloads these packages from https://open-vsx.org, which is blocked on
# some networks. The same extensions are published on the VS Code Marketplace,
# so this script fetches them from there and unpacks the jars directly.

set -euo pipefail

DEST="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/java-bundles"

EXTENSIONS=(
	"vscjava vscode-java-debug 0.59.2026072407"
	"vscjava vscode-java-test 0.46.2026072702"
)

marketplace_url() {
	printf 'https://marketplace.visualstudio.com/_apis/public/gallery/publishers/%s/vsextensions/%s/%s/vspackage' "$1" "$2" "$3"
}

mkdir -p "$DEST"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

for entry in "${EXTENSIONS[@]}"; do
	read -r publisher extension version <<<"$entry"
	target="$DEST/$extension"
	echo "==> $extension $version"

	curl -fsSL -H 'Accept-Encoding: gzip' \
		-o "$tmp/$extension.gz" \
		"$(marketplace_url "$publisher" "$extension" "$version")"

	gunzip -c "$tmp/$extension.gz" >"$tmp/$extension.vsix"

	rm -rf "$target"
	mkdir -p "$target"
	unzip -qq "$tmp/$extension.vsix" -d "$target"

	count="$(find "$target/extension/server" -name '*.jar' 2>/dev/null | wc -l | tr -d ' ')"
	echo "    -> $target ($count jars)"
done

echo
echo "Done. nvim-jdtls picks these up automatically from $DEST"

workspaces="${XDG_CACHE_HOME:-$HOME/.cache}/nvim/jdtls"
if [ -d "$workspaces" ]; then
	find "$workspaces" -mindepth 2 -maxdepth 2 -type d -name config -exec rm -rf {} + 2>/dev/null || true
	echo "Invalidated OSGi bundle caches under $workspaces"
fi
