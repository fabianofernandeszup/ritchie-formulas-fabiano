#!/bin/bash

runFormula() {
  checkCommand aws "AWS CLI is required"

  ## Validar versão AWS CLI
  aws_version=$(aws --version)
  if [[ ! $aws_version = *"aws-cli/2."* ]]; then
    consoleError "✘ Error:" "Required AWS CLI 2.0.0 or greater"
    exit 0
  fi

  echo "------------------------------------------------------------"
  consoleSuccess "✔" "Configuring SSO"

  # Config Profile
  url_sso="https://zup.awsapps.com/start" # valor fixo
  sso_role_name="ZupCodeArtifactUsers" # valor fixo
  profile="546045978864_rit_ZupCodeArtifactUsers" # valor fixo
  region="us-east-1" # valor fixo
  domain_owner="546045978864" # valor fixo

  # Configure AWS SSO
  # shellcheck disable=SC2143
  if [[ -n $(grep "$profile" ~/.aws/config) ]]; then
    consoleSuccess "✔" "Profile $profile found, proceeding to login..."
  else
    consoleError "🚧" "Profile $profile not found"
    if [[ ! -f ~/.aws/config ]] ; then
      consoleSuccess "🚥" "Creating config aws..."
      echo "" > ~/.aws/config
    else
        echo "" >> ~/.aws/config
    fi

    consoleSuccess "🛠" "Configuring sso profile..."
    # shellcheck disable=SC2129
    echo "[profile $profile]" >> ~/.aws/config
    echo "sso_start_url = $url_sso" >> ~/.aws/config
    echo "sso_region = $region" >> ~/.aws/config
    echo "sso_account_id = $domain_owner" >> ~/.aws/config
    echo "sso_role_name = $sso_role_name" >> ~/.aws/config
    echo "region = $region" >> ~/.aws/config
    echo "output = json" >> ~/.aws/config
    consoleSuccess "✔" "Done"
  fi

  ####################################
  ########## Login AWS SSO ###########
  ####################################
  get_caller_identity=$(aws sts get-caller-identity --profile $profile --output text)
  if [[ "$?" != "0" && $get_caller_identity == "" ]] ; then
    consoleSuccess "🔓" "Login on AWS SSO..."
    aws sso login --profile $profile
    consoleSuccess "✔" "Done"
  else
    consoleSuccess "🔓" "Login OK..."
  fi
  echo "------------------------------------------------------------"
}

checkCommand () {
    if ! command -v "$1" >/dev/null; then
      if [[ "$2" == "" ]] ; then
        echo -e "✘️ \\e[91mError: \\e[33;1m$1 \\e[0mis required";
      else
        echo -e "✘️ \\e[91mError: \\e[33;1m$2\\e[0m";
      fi
      echo
      exit 0;
    fi
}

consoleError () {
  echo -e "\\e[91m$1 \\e[33;1m$2\\e[0m";
}

consoleSuccess () {
  echo -e "\\e[0;32m$1 \\e[1;30m$2\\e[0m";
}