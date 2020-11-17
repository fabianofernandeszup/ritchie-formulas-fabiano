#!/bin/bash

runFormula() {
  checkCommand aws "AWS CLI is required"
  checkCommand mvn "Maven CLI is required"
  checkCommand xmlstarlet "xmlstarlet CLI is required"

  ## Validar versão AWS CLI
  aws_version=$(aws --version)
  if [[ ! $aws_version = *"aws-cli/2."* ]]; then
    consoleError "✘ Error:" "Required AWS CLI 2.0.0 or greater"
    exit 0
  fi

  echo "------------------------------------------------------------"
  consoleSuccess "✔" "Configuring M2: $RIT_PROJECT_NAME"

  # Config Profile
  profile="546045978864_rit_ZupCodeArtifactUsers" # valor fixo
  domain_owner="546045978864" # valor fixo

  # Config Public Server and Repository
  id_repository_zup_public="zup-public" # valor fixo
  id_server_zup_public="zup-public" # valor fixo
  username_server_zup_public="zup" # valor fixo
  password_server_zup_public="" # será carregado automaticamente

  # Config Project Server and Repository
  id_repository_project="rit-$RIT_DOMAIN-$RIT_PROJECT_NAME"
  id_server_project="rit-$RIT_DOMAIN-$RIT_PROJECT_NAME"
  username_server_project="zup" # valor fixo
  password_server_project="" # será carregado automaticamente

  # M2 Settgins
  m2_settings_file=~/.m2/settings.xml

  ###########################################
  ########## Config SSO and Login ###########
  ###########################################
  rit aws art config sso

  # Configure Server e Repository ~./m2/settings.xml
  if [[ ! -f $m2_settings_file ]] ; then
    consoleError "✘️ Error:" "M2 Settings not found in $m2_settings_file"
  else
    #################################
    ############# SERVER ############
    #################################
    consoleSuccess "📎" "Configuring servers on m2 settings..."

    # Get Token
    consoleSuccess "🔁" "Getting authorization token..."
    token=$(aws codeartifact get-authorization-token --profile $profile --domain "$RIT_DOMAIN" --domain-owner $domain_owner --query authorizationToken --output text)
    consoleSuccess "✔" "Done"

    password_server_zup_public=$token
    addServer "$id_server_zup_public" "$username_server_zup_public" "$password_server_zup_public" "$m2_settings_file"

    password_server_project=$token
    addServer "$id_server_project" "$username_server_project" "$password_server_project" "$m2_settings_file"
  fi
  consoleSuccess "✔" "All Done"
  echo "------------------------------------------------------------"
  exit 0
}

addServer () {
  id="$1"
  username="$2"
  password="$3"
  file="$4"

  # Veriricar se já tem server
  if [[ -n $(xmlstarlet sel -t -m "//_:server/_:id[text()='$id']" -o true "$file") ]]; then
    consoleSuccess "🔍" "Server $id found, proceeding to re-config... "

    # Delete Server to recreate
    xmlstarlet ed --inplace -O -d "//_:server/_:id[text()='$id']/.." "$file"
  fi

  consoleSuccess "🛠" "Creating Server $id..."
  ## Se não houver servers
  if [[ -z $(xmlstarlet sel -t -m "//_:servers/_:server" -o true "$file") ]]; then
    consoleSuccess "➕" "Creating First Server $id..."

    ## Adicionando elemento servers
    if [[ -z $(xmlstarlet sel -t -m "//_:servers" -o true "$file") ]]; then
      xmlstarlet ed --inplace -O -s '/_:settings' -t elem -n 'servers' "$file"
    fi

    xmlstarlet ed --inplace -O -s '/_:settings/_:servers' -t elem -n 'server' \
                               -s '/_:settings/_:servers/server' -t elem -n 'id' -v "$id" \
                               -s '/_:settings/_:servers/server' -t elem -n 'username' -v "$username" \
                               -s '/_:settings/_:servers/server' -t elem -n 'password' -v "$password" "$file"
  else
    consoleSuccess "➕" "Appending New Server $id..."
    ## Se já houver servers
    xmlstarlet ed --inplace -O -a '/_:settings/_:servers/_:server[last()]' -t elem -n 'server' \
                               -s '//server[last()]' -t elem -n 'id' -v "$id" \
                               -s '//server[last()]' -t elem -n 'username' -v "$username" \
                               -s '//server[last()]' -t elem -n 'password' -v "$password" "$file"
  fi
  consoleSuccess "✔" "Done."
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
  icon=$1
  text=$2
  echo -e "\\e[91m$1 \\e[33;1m$2\\e[0m";
}

consoleSuccess () {
  icon=$1
  text=$2
  echo -e "\\e[0;32m$1 \\e[1;30m$2\\e[0m";
}