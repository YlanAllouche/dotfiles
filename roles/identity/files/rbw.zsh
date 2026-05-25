if ! command -v rbw >/dev/null 2>&1 || [[ ! -x "$HOME/.local/bin/zbw.zsh" ]]; then
  return 0
fi

alias pas="$HOME/.local/bin/zbw.zsh password output"
alias tok="$HOME/.local/bin/zbw.zsh fields output"

eval "$(rbw gen-completions zsh)"
compdef _rbw rbw 2>/dev/null

rbw-password-completion() {
  local result
  result=$("$HOME/.local/bin/zbw.zsh" password completion 2>/dev/null)
  if [[ $? -eq 0 && -n "$result" ]]; then
    LBUFFER="${LBUFFER}${result}"
  fi
  zle redisplay
}

rbw-fields-completion() {
  local result
  result=$("$HOME/.local/bin/zbw.zsh" fields completion 2>/dev/null)
  if [[ $? -eq 0 && -n "$result" ]]; then
    LBUFFER="${LBUFFER}${result}"
  fi
  zle redisplay
}

zle -N rbw-password-completion
zle -N rbw-fields-completion

bindkey '^A' rbw-password-completion
bindkey '^B' rbw-fields-completion
