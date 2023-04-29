#!/bin/bash

#Install Oh-my-zsh (framework for managing ZSH configs. Comes w/a bunch of plugins/themes)
#Source: https://ohmyz.sh/#install
#Plugins: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins
if [ ! -d ~/.oh-my-zsh ]; then
  echo "Installing Oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else

  echo "Oh-my-zsh is already installed."
fi

#Install the Powerlevel10k zsh theme
#Source: https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
  echo "Installing powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
  sed -i '.bak' 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
  exec zsh
  p10k configure
else
  echo "powerlevel10k is already installed."
fi

echo "Configuration profile for iTerm2:"
cat << ENDCAT
  - Settings > Profiles > General:
    - Rename 'Default' to 'kabir-main'
  - Settings > Profiles > Window:
    - Transparency: 16
    - Blur: 8
    - Columns: 115
    - Rows: 30
  - Settings > Profiles > Keys > Key Mappings:
    - Double-click the '⌥<-' icon
    - Action: 'Send Escape Sequence'
    - Esc+: b
    - Double-click the '⌥->' icon
    - Action: 'Send Escape Sequence'
    - Esc+: f

ENDCAT
