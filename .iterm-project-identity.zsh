typeset -ga ITERM_PROJECT_IDENTITY_COLORS=(
  a8dccb
  afcff0
  c5b7e8
  e7b4c4
  f0b5a8
  ebcb89
  bcd99a
  96d1d0
  b7c5e4
  d0b6dc
  e8c39e
  afcdb4
  9fc5e8
  d5b0c9
  c8d6a5
  a9c6c9
)

iterm_project_identity_name() {
  emulate -L zsh

  local directory=${1:-$PWD}
  [[ ${directory:A} == ${HOME:A} ]] && return 0

  local root
  root=$(command git -C "$directory" rev-parse --show-toplevel 2>/dev/null) || root=$directory
  print -r -- "${root:t}"
}

iterm_project_identity_directory_key() {
  emulate -L zsh

  local directory=${1:-$PWD}
  local canonical=${directory:A}
  local home=${HOME:A}

  if [[ $canonical == $home ]]; then
    print -r -- "~"
  elif [[ $canonical == ${home}/* ]]; then
    print -r -- "~/${canonical#${home}/}"
  else
    print -r -- "$canonical"
  fi
}

iterm_project_identity_color() {
  emulate -L zsh

  local identity=$1
  local checksum byte_count
  read -r checksum byte_count <<< "$(print -rn -- "$identity" | cksum)"

  local index=$(( checksum % ${#ITERM_PROJECT_IDENTITY_COLORS} + 1 ))
  print -r -- "$ITERM_PROJECT_IDENTITY_COLORS[$index]"
}

iterm_project_identity_set_chrome_color() {
  emulate -L zsh

  local color=$1
  if [[ $color == default ]]; then
    print -rn -- $'\e]6;1;bg;*;default\a'
    return 0
  fi

  local red=$(( 16#${color[1,2]} ))
  local green=$(( 16#${color[3,4]} ))
  local blue=$(( 16#${color[5,6]} ))

  print -rn -- \
    $'\e]6;1;bg;red;brightness;'"$red"$'\a\e]6;1;bg;green;brightness;'"$green"$'\a\e]6;1;bg;blue;brightness;'"$blue"$'\a'
}

iterm_project_identity_set_badge_format() {
  emulate -L zsh

  local format=$1
  local encoded
  encoded=$(print -rn -- "$format" | base64)
  print -rn -- $'\e]1337;SetBadgeFormat='"$encoded"$'\a'
}

iterm_project_identity_update() {
  emulate -L zsh

  [[ ${TERM_PROGRAM-} == "iTerm.app" ]] || return 0

  typeset -g ZSH_THEME_TERM_TITLE_IDLE='%n@%m'
  typeset -g ZSH_THEME_TERM_TAB_TITLE_IDLE='%n@%m'

  local project directory_key color suffix badge_value badge_format
  project=$(iterm_project_identity_name "$PWD")
  directory_key=$(iterm_project_identity_directory_key "$PWD")

  badge_value=""
  badge_format=""
  if [[ $directory_key == "~" ]]; then
    color=default
  else
    color=$(iterm_project_identity_color "$directory_key")
    badge_value=$directory_key
    badge_format='\(user.directoryBadge)'
  fi

  if [[ -n $project ]]; then
    suffix=" · $project"
  else
    suffix=""
  fi

  local -i has_user_var=$+functions[iterm2_set_user_var]
  local key="$project|$directory_key|$color|$has_user_var"
  [[ ${ITERM_PROJECT_IDENTITY_LAST_KEY-} == $key ]] && return 0
  typeset -g ITERM_PROJECT_IDENTITY_LAST_KEY=$key

  if (( has_user_var )); then
    iterm2_set_user_var project "$project"
    iterm2_set_user_var projectSuffix "$suffix"
    iterm2_set_user_var directoryBadge "$badge_value"
  else
    badge_format=""
  fi

  if (( $+functions[it2setcolor] || $+commands[it2setcolor] )); then
    it2setcolor tab "$color"
  fi

  iterm_project_identity_set_chrome_color "$color"
  iterm_project_identity_set_badge_format "$badge_format"
}

if [[ -o interactive && ${TERM_PROGRAM-} == "iTerm.app" ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook -d precmd iterm_project_identity_update 2>/dev/null
  add-zsh-hook precmd iterm_project_identity_update
  iterm_project_identity_update
fi
