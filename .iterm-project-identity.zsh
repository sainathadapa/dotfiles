typeset -ga ITERM_PROJECT_IDENTITY_COLORS=(
  198f74
  4778c7
  a05caf
  d07b3d
  c44f6f
  1785a5
  718c32
  b45f24
)

iterm_project_identity_name() {
  emulate -L zsh

  local directory=${1:-$PWD}
  [[ ${directory:A} == ${HOME:A} ]] && return 0

  local root
  root=$(command git -C "$directory" rev-parse --show-toplevel 2>/dev/null) || root=$directory
  print -r -- "${root:t}"
}

iterm_project_identity_color() {
  emulate -L zsh

  local project=$1
  local checksum byte_count
  read -r checksum byte_count <<< "$(print -rn -- "$project" | cksum)"

  local index=$(( checksum % ${#ITERM_PROJECT_IDENTITY_COLORS} + 1 ))
  print -r -- "$ITERM_PROJECT_IDENTITY_COLORS[$index]"
}

iterm_project_identity_update() {
  emulate -L zsh

  [[ ${TERM_PROGRAM-} == "iTerm.app" ]] || return 0

  typeset -g ZSH_THEME_TERM_TITLE_IDLE='%n@%m'
  typeset -g ZSH_THEME_TERM_TAB_TITLE_IDLE='%n@%m'

  local project color suffix
  project=$(iterm_project_identity_name "$PWD")
  if [[ -n $project ]]; then
    color=$(iterm_project_identity_color "$project")
    suffix=" · $project"
  else
    color=default
    suffix=""
  fi

  local key="$project|$color"
  [[ ${ITERM_PROJECT_IDENTITY_LAST_KEY-} == $key ]] && return 0
  typeset -g ITERM_PROJECT_IDENTITY_LAST_KEY=$key

  (( $+functions[iterm2_set_user_var] )) && iterm2_set_user_var project "$project"
  (( $+functions[iterm2_set_user_var] )) && iterm2_set_user_var projectSuffix "$suffix"

  if (( $+functions[it2setcolor] || $+commands[it2setcolor] )); then
    it2setcolor tab "$color"
  fi
}

if [[ -o interactive && ${TERM_PROGRAM-} == "iTerm.app" ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook -d precmd iterm_project_identity_update 2>/dev/null
  add-zsh-hook precmd iterm_project_identity_update
  iterm_project_identity_update
fi
