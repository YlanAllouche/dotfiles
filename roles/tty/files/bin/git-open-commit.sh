#!/usr/bin/env sh

set -eu

usage() {
  printf '%s\n' "Usage: $0 <commit-sha>" >&2
  exit 1
}

normalize_remote() {
  remote_url=$1

  case "$remote_url" in
    git@*:* )
      host=${remote_url#git@}
      host=${host%%:*}
      repo_path=${remote_url#*:}
      ;;
    ssh://git@*/* )
      trimmed=${remote_url#ssh://git@}
      host=${trimmed%%/*}
      repo_path=${trimmed#*/}
      ;;
    https://*/* | http://*/* )
      trimmed=${remote_url#*://}
      host=${trimmed%%/*}
      repo_path=${trimmed#*/}
      ;;
    * )
      return 1
      ;;
  esac

  repo_path=${repo_path%.git}

  case "$host" in
    *gitlab* )
      printf 'https://%s/%s/-/commit' "$host" "$repo_path"
      ;;
    * )
      printf 'https://%s/%s/commit' "$host" "$repo_path"
      ;;
  esac
}

open_url() {
  url=$1

  if [ "${DOTFILES_OPEN_PRINT_ONLY:-}" = "1" ]; then
    printf '%s\n' "$url"
    return 0
  fi

  if [ -n "${BROWSER:-}" ]; then
    "$BROWSER" "$url" >/dev/null 2>&1 &
    return 0
  fi

  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 &
    return 0
  fi

  if command -v open >/dev/null 2>&1; then
    open "$url" >/dev/null 2>&1 &
    return 0
  fi

  printf '%s\n' "$url"
}

[ "$#" -eq 1 ] || usage

commit_sha=$1
remote_url=$(git remote get-url origin 2>/dev/null || true)

[ -n "$remote_url" ] || {
  printf '%s\n' "git-open-commit.sh: could not determine remote.origin.url" >&2
  exit 1
}

base_url=$(normalize_remote "$remote_url") || {
  printf '%s\n' "git-open-commit.sh: unsupported remote URL format: $remote_url" >&2
  exit 1
}

open_url "$base_url/$commit_sha"
