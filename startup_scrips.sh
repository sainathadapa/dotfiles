#!/bin/zsh
brew services stop skhd
brew services restart yabai
skhd --verbose&
./emacs-spacemacs-config/run_grasp.sh&
sudo yabai --load-sa

