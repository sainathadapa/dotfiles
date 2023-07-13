#!/bin/zsh
brew services stop skhd
skhd --verbose&
~/emacs-spacemacs-config/run_grasp.sh&
# brew services restart yabai
yabai --restart-service
brew services restart sketchybar

