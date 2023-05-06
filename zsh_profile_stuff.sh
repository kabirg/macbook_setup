##############################
###### Quick Commands ######
##############################
# System
alias refreshz="source ~/.zshrc"
alias ll='ls -l'
alias la='ls -la'

# Directories
alias code='cd ~/Documents/code'
alias creds='cd ~/Documents/creds'

# Terraform
alias tf="terraform"
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa="terraform apply"

# Git
alias gs="git status"
alias gc='git checkout'
alias gb='git branch'
alias gcb='git checkout -b'
alias gpo='git pull origin'

# K8s
alias k='kubectl'
alias kx='kubectx'
alias kt='kubectl get po -A'
alias eksls='aws eks list-clusters |jq'
alias eksadd='aws eks update-kubeconfig --region us-west-2 --name'

# AWS
alias awsid='aws sts get-caller-identity | jq'
alias av='aws-vault'
alias avl='av ls'
alias ave='unset AWS_VAULT;aws-vault exec'
alias clearaws='aws-vault clear; for var in $(env | grep "^AWS_" | awk -F= "{print \$1}"); do unset $var; done'
alias gacs='gimme-aws-creds --profile sandbox'

# Docker
alias stopall='docker container stop $(docker container ls -q)'
alias rmall='docker container rm $(docker container ls -aq)'

# Java
alias javals='/usr/libexec/java_home -V'

# For any issue running older Terraform versions:
# TFENV_ARCH=amd64 tfenv install <version>

##############################
###### Functions ######
##############################

function cmds() {
  echo ''
  echo '---- SYSTEM COMMANDS ----'
  echo 'refreshz'
  echo 'll'
  echo 'la'
  echo 'code'
  echo 'creds'

  echo ''
  echo '---- GIT COMMANDS ----'
  echo 'gs'
  echo 'gc'
  echo 'gb'
  echo 'gcb'
  echo 'gpo'

  echo ''
  echo '---- AWS COMMANDS ----'
  echo 'awsid'
  echo 'awsids'
  echo 'av'
  echo 'avl'
  echo 'ave'
  echo 'clearaws -- unset VAULT stuff and clear all AWS envvars'
  echo 'gac'
  echo 'gacs'
  echo 'avsg'

  echo ''
  echo '---- K8s COMMANDS ----'
  echo 'k'
  echo 'kx'
  echo 'kt -- kubectl get po -A....just to do a quick test'
  echo 'eksls'
  echo 'eksadd'

  echo ''
  echo '---- TERRAFORM COMMANDS ----'
  echo 'tf'
  echo 'tfi'
  echo 'tfp'
  echo 'tfa'

  echo ''
  echo '---- DOCKER COMMANDS ----'
  echo 'stopall'
  echo 'rmall'

  echo ''
  echo '---- LINTING COMMANDS ----'
  echo 'yamllint'

  echo ''
  echo '---- JAVA COMMANDS ----'
  echo 'jdk <version #> -- switches Java versions'
  echo 'javals -- list installed java versions'
}

function avsg() {
  AWS_USER="Kabir.Gupta@test.com"
  PS3="Choose an account: "
  declare -A options
  options=( "aws_abc" "aws_xyz" )
select account in "${options[@]}";
  do
    echo -e "\nyou picked $account ($REPLY)"
    case $account in
      aws_xyz)
        ID=x
      ;;
      aws_abc)
        ID=x
      ;;
      *)
        echo "invalid account"
        exit 1
      ;;
    esac
    aws-vault clear $AWS_USER
    OUT=$(aws-vault exec "$AWS_USER" -- aws sts assume-role --role-arn arn:aws:iam::"$ID":role/admin --role-session-name BroImAnAdmin)
    eAWS_ACCESS_KEY_ID=$(echo "$OUT" | jq -r .Credentials.AccessKeyId)
    eAWS_SECRET_ACCESS_KEY=$(echo "$OUT" | jq -r .Credentials.SecretAccessKey)
    eAWS_SESSION_TOKEN=$(echo "$OUT" | jq -r .Credentials.SessionToken)

    echo "export AWS_ACCESS_KEY_ID=$eAWS_ACCESS_KEY_ID"
    echo "export AWS_SECRET_ACCESS_KEY=$eAWS_SECRET_ACCESS_KEY"
    echo "export AWS_SESSION_TOKEN=$eAWS_SESSION_TOKEN"
    break
  done
}

function gac() {
  unset AWS_PROFILE
  PROFILE_ARG="$1"
  # ROLE_OPTION="${3:-0}" # Default role option is 0

  case "$PROFILE_ARG" in
    s) PROFILE="sandbox";;
    d) PROFILE="dev";;
    *)
      echo "Invalid argument. Please provide s (sandbox), d (development), or p (production)."
      return 1
  esac

  export AWS_PROFILE="${PROFILE}"
  (echo "0"; echo "0") | gimme-aws-creds --profile "${PROFILE}"
}

function awsids() {
  echo "AWS Account Name          AWS Account ID"
  echo "-----------------------------------------"
  echo "dev                        xxx"
  echo "prod                       xxx"
  echo "sandbox                    xxx"
}

# Check for location of all installed JDK's
function jdk() {
  version=$1
  export JAVA_HOME=$(/usr/libexec/java_home -v"$version")
  java -version
}
