#!/bin/bash

########################################################################
########################  FUNCTIONS  ###################################
########################################################################
function confirm_complete() {
  while true; do
    read -p "Did you complete this (y/n): " yn
    case $yn in
      [Yy]* )
        echo "Proceeding..."
        return 0;;
      [Nn]* )
        echo "Please complete the step first, then enter 'y' to proceed."
        ;;
      * )
        echo "Please answer y or n.";;
    esac
  done
}

function tool_install() {
  if ! command -v "$1" $> /dev/null; then
    echo "........................................."
    echo "$1 is not installed. Installing..."
    echo "........................................."
    echo ""

    if [[ "$1" == brew ]]; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      read -p "Have you run the additional Brew commands from the output? (y/n)" answer
      case "${answer}" in
        [Yy]* )
          echo "Proceeding..."
          ;;
        [Nn]* )
          echo "Exiting script now. Please do so and come back!"
          exit 1
          ;;
        * )
          echo "Please anser 'y' or 'n'."
      esac
    fi

    if [[ "$1" == docker ]]; then
      echo "Installing Rosetta dependency first..."
      softwareupdate --install-rosetta
      echo "Navigate here to download Docker Desktop DMG: https://docs.docker.com/desktop/install/mac-install/"
      confirm_complete
    fi

    if [[ "$1" == tfenv ]]; then
      brew install tfenv
    fi

    if [[ "$1" == jq ]]; then
      brew install jq
    fi

    if [[ "$1" == yamllint ]]; then
      brew install yamllint
    fi

    if [[ "$1" == aws ]]; then
      curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
      sudo installer -pkg AWSCLIV2.pkg -target /
    fi

    if [[ "$1" == helm ]]; then
      brew install helm
    fi

    if [[ "$1" == kubectl ]]; then
      brew install kubectl
    fi

    if [[ "$1" == kubectx ]]; then
      brew install kubectx
    fi

    if [[ "$1" == k9s ]]; then
      brew install derailed/k9s/k9s
    fi

    if [[ "$1" == ansible ]]; then
      python3 -m pip install --user ansible
      echo 'export PATH="$PATH:$(python3 -m site --user-base)/bin"'
      confirm_complete
    fi

    if [[ "$1" == "python3" || "$1" == "pip3" ]]; then
      continue
    fi

    if [[ "$1" == java11 ]]; then
      brew install java11
      sudo ln -sfn /opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
    fi

    if [[ "$1" == java8 ]]; then
      brew install adoptopenjdk/openjdk/adoptopenjdk8
    fi

    return 1
  else
    echo "........................................."
    echo "$1 is already installed..."

    if [[ "$1" == brew ]]; then
      validation $1 "-v"
    fi

    if [[ "$1" == docker ]]; then
      validation $1 "-v"
    fi

    if [[ "$1" == tfenv ]]; then
      validation $1 "-v"
    fi

    if [[ "$1" == jq ]]; then
      validation $1 "--version"
    fi

    if [[ "$1" == yamllint ]]; then
      validation $1 "--version"
    fi

    if [[ "$1" == aws ]]; then
      validation $1 "--version"
    fi

    if [[ "$1" == helm ]]; then
      validation $1 "version"
    fi

    if [[ "$1" == kubectl ]]; then
      version=$(kubectl version --output=yaml | grep -i gitVersion)
      echo "$version"
    fi

    if [[ "$1" == k9s ]]; then
      validation $1 "version"
    fi

    if [[ "$1" == ansible ]]; then
      validation $1 "--version"
    fi

    if [[ "$1" == python3 ]]; then
      validation $1 "--version"
    fi

    if [[ "$1" == pip3 ]]; then
      validation $1 "--version"
    fi

    if [[ "$1" == java11 ]]; then
      java -version
    fi
  fi
}

function validation() {
  if command -v $1 &> /dev/null; then
    version=$("$1" $2 2>&1)
    echo "$version"
    echo "........................................."
    echo ""
  else
    echo "$1 - NO"
    echo "........................................."
    echo ""
  fi
}

########################################################################

echo "..............................................."
echo "System Details:"
if [[ $(uname -m) == "x86_64" ]]; then
  echo "This mac is based on Intel/x86 hardware (or potentiall AMD based on x86 architecture)"
elif [[ $(uname -m) == "arm64" ]]; then
  echo "This mac is based on Apple Silicon/ARM hardware"
else
  echo "This mac has an unknown chip architecture"
fi
echo "..............................................."
echo ""
echo "Python3/pip3 are not bundled with MacOS. To set them up..."
echo " - First install the CLI developer tools (which contain the Python interpreter): 'xcode-select --install'"
echo " - MacOS provides shims (symlinks) for Python3/pip3 in '/usr/bin'. These will redirect commands to the Python interpreter. So you dont need to install them manually."
confirm_complete

#Source: https://brew.sh/
tool_install brew

#Source: https://docs.docker.com/desktop/install/mac-install/
tool_install docker

#Source: https://formulae.brew.sh/formula/tfenv
tool_install tfenv

#Source: https://formulae.brew.sh/formula/jq
tool_install jq

tool_install yamllint

#Source: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
tool_install aws

#Source: https://helm.sh/docs/intro/install/#from-homebrew-macos
tool_install helm

#Source: https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/
tool_install kubectl

#Source: https://github.com/ahmetb/kubectx#homebrew-macos-and-linux
tool_install kubectx

#Source: https://k9scli.io/topics/install/
tool_install k9s

#Source: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
tool_install ansible

tool_install python3

tool_install pip3

tool_install java11


echo "................................"
echo "Tool installation complete...."
echo "................................"

echo "Download the following Desktop tools:"
echo "- iterm2: https://iterm2.com/"
echo "- Pulsar: https://pulsar-edit.dev/"
echo "- Postman: https://www.postman.com/downloads/"
confirm_complete

echo "................................"
echo "More tools you can download..."
echo "- AWS authentication tool (i.e aws-vault, gimme-aws-creds, etc...)"
echo "- Packer (https://formulae.brew.sh/formula/packer)"
echo "- Lens (https://k8slens.dev/desktop.html)"

echo "................................"
echo "Setup your SSH key..."
#Source: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
echo " - ssh-keygen -t ed25519 -C 'your_email@example.com'"
echo " - eval '\$(ssh-agent -s)'"
echo " - touch ~/.ssh/config"
cat << 'ENDCAT'
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519"
ENDCAT
echo " - ssh-add --apple-use-keychain ~/.ssh/id_ed25519"
echo " - Add the key to your GitHub account"
echo "NOTE: use double-quotes"
