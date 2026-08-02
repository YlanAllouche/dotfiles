#!/usr/bin/env bash
# Import corporate root CAs into every mise-managed JDK trust store.

set -euo pipefail

CERT_DIRS=("$@")
STOREPASS="${JDK_CACERTS_PASSWORD:-changeit}"

certs=()
for dir in "${CERT_DIRS[@]}"; do
	[ -d "$dir" ] || continue
	while IFS= read -r -d '' cert; do
		certs+=("$cert")
	done < <(find "$dir" \( -name '*.cer' -o -name '*.crt' -o -name '*.pem' \) -print0)
done

if [ ${#certs[@]} -eq 0 ]; then
	echo "No certificates found in: ${CERT_DIRS[*]}" >&2
	exit 1
fi

echo "Certificates: ${#certs[@]}"

installs="$HOME/.local/share/mise/installs/java"
[ -d "$installs" ] || {
	echo "No mise-managed JDKs at $installs" >&2
	exit 1
}

for jdk in "$installs"/*; do
	[ -L "$jdk" ] && continue
	cacerts="$jdk/lib/security/cacerts"
	[ -f "$cacerts" ] || continue

	keytool="$jdk/bin/keytool"
	echo "==> $(basename "$jdk")"

	for cert in "${certs[@]}"; do
		alias="$(basename "$cert")"
		alias="${alias%.*}"
		"$keytool" -delete -alias "$alias" -keystore "$cacerts" -storepass "$STOREPASS" >/dev/null 2>&1 || true
		"$keytool" -importcert -noprompt -trustcacerts -alias "$alias" \
			-file "$cert" -keystore "$cacerts" -storepass "$STOREPASS" >/dev/null
		echo "    + $alias"
	done
done

echo
echo "Done. Restart any running jdtls (:LspRestart) to pick up the new trust store."
