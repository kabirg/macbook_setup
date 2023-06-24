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
alias scratch='cd ~/Documents/code/scratch'

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
# First commit to a new branch.
# alias gpos='git push --set-upstream origin $(git branch --show-current)'
alias gpos='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'
alias gacp='function _gacp() { git add . && git commit -m "${1:-bugfix}" && git push origin; }; _gacp'

# K8s
alias k='kubectl'
alias kx='kubectx'
alias eksls='aws eks list-clusters |jq'
alias eksadd='aws eks update-kubeconfig --region us-west-2 --name'

# AWS
alias awsid='aws sts get-caller-identity | jq'
alias av='aws-vault'
alias avl='av ls'
alias ave='unset AWS_VAULT;aws-vault exec'
alias clearaws='aws-vault clear; for var in $(env | grep "^AWS_" | awk -F= "{print \$1}"); do unset $var; done'
alias gac='gimme-aws-creds --profile'

# Docker
alias stopall='docker stop $(docker ps -aq)'
alias rmall='docker rm $(docker ps -aq)'
alias dsk='stopall && rmall'

# Networking
alias kgia='kubectl get ingress --all-namespaces | awk "NR==1 {printf \"%-40s %-40s\n\", \$1, \$2}; NR>1 {printf \"%-40s %-40s\n\", \$1, \$2}"'
alias nginxlbs='kubectl get svc --all-namespaces -o "custom-columns=NAME:.metadata.name,LOADBALANCER:.status.loadBalancer.ingress[0].hostname" | grep "<NGINX_INGRESS_POD_NAME>"'
alias digs='dig +noall +answer'
alias curls='curl -o /dev/null -s -w "%{http_code}\n"'


# Java
alias javals='/usr/libexec/java_home -V'


# For any issue running older Terraform versions:
# TFENV_ARCH=amd64 tfenv install <version>

##############################
###### Functions ######
##############################

# Get logs for any given pod
function klf() {
  # Prompt for namespace
  echo "Namespace:"
  read namespace

  # Prompt for pod name
  echo "Pod name:"
  read pod_name

  # Generate the full command
  command="kubectl logs -f -n ${namespace} ${pod_name}"

  # Echo the command
  echo "Running command: ${command}"

  # Run the command
  eval ${command}
}

# Get the LB and hostnames associated with any given ingress
function kinglb() {
  # Prompt for namespace
  echo "Namespace:"
  read namespace

  # Prompt for ingress name
  echo "Ingress name:"
  read ingress_name

  # Generate the LB command
  command="kubectl get ingress ${ingress_name} -n ${namespace} -o jsonpath='{.status.loadBalancer.ingress[*].hostname}'"

  # Generate the Hostname command
  command1="kubectl get ingress ${ingress_name} -n ${namespace}  -o jsonpath='{.spec.rules[*].host}'"

  # Echo the command
  echo "${command}"
  echo "${command1}"
  echo ''
  echo ''
  # Run the command and echo it
  echo 'RESULTS:::'
  echo $(eval ${command})
  echo $(eval ${command1})
}

# Get cert info for any given LB URL
function lbcert() {
    local lb_url=$1
    if [[ -z $lb_url ]]; then
        echo "Please provide a load balancer URL as argument"
        return 1
    fi

    # Extract domain from URL
    local domain=$(echo $lb_url | cut -d'/' -f1)

    # Get all types of load balancers
    local lbs_app_net=$(aws elbv2 describe-load-balancers)
    local lbs_classic=$(aws elb describe-load-balancers)

    # Combine the results
    local lbs_combined=$(echo "$lbs_app_net" "$lbs_classic" | jq -s '.[0].LoadBalancers + .[1].LoadBalancerDescriptions')

    # Get the ARN or Name of the load balancer with the matching DNS name
    local lb_arn_or_name=$(echo "$lbs_combined" | jq -r --arg domain "$domain" 'map(select(.DNSName == $domain)) | .[0] | .LoadBalancerArn // .LoadBalancerName')

    if [[ -z $lb_arn_or_name ]]; then
        echo "No load balancer found with this URL"
        return 1
    fi

    # Define variables to store listeners and cert_arn
    local listeners=""
    local cert_arn=""

    # Check if the ARN or Name is an ARN (contains "arn:") or a Name
    if [[ $lb_arn_or_name == arn:aws:* ]]; then
        # If it's an ARN, then it's an Application or Network Load Balancer
        listeners=$(aws elbv2 describe-listeners --load-balancer-arn "$lb_arn_or_name")
        cert_arn=$(echo "$listeners" | jq -r '.Listeners[0].Certificates[0].CertificateArn')
    else
        # If it's not an ARN, then it's a Classic Load Balancer
        local lb_name=$(echo $lb_arn_or_name | cut -d'-' -f1)
        listeners=$(aws elb describe-load-balancers --load-balancer-name "$lb_name")
        cert_arn=$(echo "$listeners" | jq -r '.LoadBalancerDescriptions[0].ListenerDescriptions[0].Listener.SSLCertificateId')
    fi

    if [[ -z $cert_arn ]]; then
        echo "No certificate found for this load balancer"
        return 1
    fi

    # Describe the certificate
    local cert=$(aws acm describe-certificate --certificate-arn "$cert_arn")

    # Get the domain name from the certificate
    local domain_name=$(echo "$cert" | jq -r '.Certificate.DomainName')
    local san=$(echo "$cert" | jq -r '.Certificate.SubjectAlternativeNames[]')

    echo "LB ARN or Name: $lb_arn_or_name"
    echo "Certificate ARN: $cert_arn"
    echo "Domain Name: $domain_name \n"
    echo "Subject Alternative Names:"
    echo "$san"
}

# Get cert info for any given cert identifier
function certinfo() {
    local cert_arn=$1
    if [[ -z $cert_arn ]]; then
        echo "Please provide a certificate ARN as argument"
        return 1
    fi

    local cert_info=$(aws acm describe-certificate --certificate-arn "$cert_arn")

    local domain_name=$(echo "$cert_info" | jq -r '.Certificate.DomainName')
    local san=$(echo "$cert_info" | jq -r '.Certificate.SubjectAlternativeNames[]')
    local in_use_by=$(echo "$cert_info" | jq -r '.Certificate.InUseBy[]')

    echo "Domain Name: $domain_name \n"
    echo "Subject Alternative Names:"
    echo "$san"
    echo "\n"
    echo "In Use By:"
    echo "$in_use_by"
}

# Run through a list of analysis tools
function netcheck() {
  # Get all the ingresses
  echo "\nGetting all Ingresses...\nkgia"
  kgia

  # Get the configured ingress LB and hostname
  echo "\nGetting Ingress LB and hostname below. Enter Namespace and Ingress-name you want to investigate...\nkinglb"
  kinglb

  # Resolve both of them
  echo "\nTo resolve, run 'digs', 'digsp' and 'curls' next.."
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
  echo 'gpos'
  echo 'gacp -- git add/commit/push - accepts custom-message'


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
  echo 'javals -- list installed java versions'
  echo 'jdk <version #> -- switches Java versions'

  echo ''
  echo '---- NETWORKING COMMANDS ----'
  echo 'klf - get logs for any given pod'
  echo 'kgia - gell all ingresses'
  echo 'kinglb - get the LB and hostnames associated with any given ingress'
  echo 'nginxlbs - LBs of private/public NGINX conrollers'
  echo 'lbcert - get cert info for any given LB URL'
  echo 'certinfo - get cert info for any given cert identifier'
  echo 'netcheck - run through a list of analysis tools'
  echo 'digs - run dig but only get the answer section'
  echo 'curls - run curl but only get the response code'
  echo ''
}
