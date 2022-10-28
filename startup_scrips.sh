#!/bin/zsh
brew services stop skhd
skhd --verbose&
~/emacs-spacemacs-config/run_grasp.sh&
brew services restart yabai
# sudo yabai --load-sa

