#!/usr/bin/env bash
# Tell Gradle about the JDKs installed by mise.

set -euo pipefail

installs="$HOME/.local/share/mise/installs/java"
props="$HOME/.gradle/gradle.properties"

paths=""
for jdk in "$installs"/*; do
	[ -L "$jdk" ] && continue
	[ -x "$jdk/bin/java" ] || continue
	if [ -n "$paths" ]; then
		paths="$paths,"
	fi
	paths="$paths$jdk"
done

if [ -z "$paths" ]; then
	echo "No mise-managed JDKs found in $installs" >&2
	exit 1
fi

mkdir -p "$(dirname "$props")"

if [ -f "$props" ]; then
	grep -v -e '^org\.gradle\.java\.installations\.' \
		-e '^# Managed by .*gradle-toolchains\.sh' "$props" >"$props.tmp" || true
	mv "$props.tmp" "$props"
fi

{
	echo "# Managed by ~/.config/nvim/scripts/gradle-toolchains.sh"
	echo "org.gradle.java.installations.auto-detect=true"
	echo "org.gradle.java.installations.paths=$paths"
} >>"$props"

echo "Wrote $props"
cat "$props"
