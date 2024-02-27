# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export TERM="xterm-256color"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# zsh --------------------------------------------------------------------------------

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  macos
  git
  docker
  zsh-history-substring-search
  zsh-autosuggestions
  zsh-syntax-highlighting
  fast-syntax-highlighting
)

# ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)
# export ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)

# --------------------
# from https://github.com/larkery/zsh-histdb/pull/134/files
# This query will find the most frequently issued command that is issued in
# the current directory or any subdirectory.
# You can get other behaviours by changing the query.
_zsh_autosuggest_strategy_histdb_top_here() {
    local query="
SELECT
    commands.argv
FROM
    history
LEFT JOIN
    commands
ON
    history.command_id = commands.id
LEFT JOIN
    places
ON
    history.place_id = places.id
WHERE
    places.dir
LIKE
    '$(sql_escape $PWD)%'
AND
    commands.argv
LIKE
    '$(sql_escape $1)%'
GROUP BY
    commands.argv
ORDER BY
    COUNT(commands.argv) DESC
LIMIT 1"
    suggestion=$(_histdb_query "$query")
}

# This will find the most frequently issued command issued exactly in this directory,
# or if there are no matches it will find the most frequently issued command in any directory.
# You could use other fields like the hostname to restrict to suggestions on this host, etc.
_zsh_autosuggest_strategy_histdb_top() {
    local query="
SELECT
    commands.argv
FROM
    history
LEFT JOIN
    commands
ON
    history.command_id = commands.rowid
LEFT JOIN
    places
ON
    history.place_id = places.rowid
WHERE
    commands.argv
LIKE
    '$(sql_escape $1)%'
GROUP BY
    commands.argv,
    places.dir
ORDER BY
    places.dir != '$(sql_escape $PWD)',
    COUNT(commands.argv) DESC
LIMIT 1"
    suggestion=$(_histdb_query "$query")
}

# This query will find the most recently issued command that is issued in
# the current directory or any subdirectory preferring commands in the current session.
_zsh_autosuggest_strategy_histdb_top_here_and_now() {
    local query="
SELECT
    commands.argv
FROM
    history
LEFT JOIN
    commands
ON
    history.command_id = commands.id
LEFT JOIN
    places
ON
    history.place_id = places.id
WHERE
    places.dir
LIKE
    '$(sql_escape $PWD)%'
AND
    commands.argv
LIKE
    '$(sql_escape $1)%'
AND
    history.exit_status = 0
GROUP BY
    commands.argv,
    history.session,
    history.start_time
ORDER BY
    history.session = '$(sql_escape $HISTDB_SESSION)' DESC,
    history.start_time DESC
LIMIT 1"
    suggestion=$(_histdb_query "$query")
}

_zsh_autosuggest_strategy_histdb_top_here_and_now_2() {
    local query="
SELECT commands.argv
FROM history
LEFT JOIN commands ON history.command_id = commands.id
LEFT JOIN places ON history.place_id = places.id
WHERE
  places.dir LIKE '$(sql_escape $PWD)%' AND
  commands.argv LIKE '$(sql_escape $1)%'
  AND (
    -- keep commands with bad exit statuses from current session
    (history.session = '$(sql_escape $HISTDB_SESSION)') OR
    -- otherwise only keep successful commands
    history.exit_status = 0
  )
GROUP BY
    commands.argv,
    history.session,
    history.start_time
ORDER BY
    history.session = '$(sql_escape $HISTDB_SESSION)' DESC,
    history.start_time DESC
LIMIT 1"
    suggestion=$(_histdb_query "$query")
}
# --------------------

ZSH_AUTOSUGGEST_STRATEGY=histdb_top_here_and_now_2

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# zsh --------------------------------------------------------------------------------

# pyenv configuration
# if command -v pyenv 1>/dev/null 2>&1; then
#   eval "$(pyenv init -)"
# fi
# if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi
eval "$(pyenv init - --no-rehash)"
eval "$(pyenv virtualenv-init -)"
export PYENV_VIRTUALENV_DISABLE_PROMPT=1

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# https://github.com/larkery/zsh-histdb#installation
HISTDB_TABULATE_CMD=(sed -e $'s/\x1f/\t/g')
source $HOME/.oh-my-zsh/custom/plugins/zsh-histdb/sqlite-history.zsh
autoload -Uz add-zsh-hook

# https://iterm2.com/documentation-shell-integration.html
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh" || true

