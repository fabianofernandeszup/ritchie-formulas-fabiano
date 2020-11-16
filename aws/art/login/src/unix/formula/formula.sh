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
  url_sso="https://zup.awsapps.com/start" # valor fixo
  sso_role_name="ZupCodeArtifactUsers" # valor fixo
  profile="546045978864_rit_ZupCodeArtifactUsers" # valor fixo
  region="us-east-1" # valor fixo
  domain_owner="546045978864" # valor fixo

  # Config Public Server and Repository
  id_repository_zup_public="zup-public" # valor fixo
  id_server_zup_public="zup-public" # valor fixo
  username_server_zup_public="zup" # valor fixo
  password_server_zup_public="" # será carregado automaticamente

  # Config Project Server and Repository
  id_repository_project=$RIT_DOMAIN"-"$RIT_PROJECT_NAME
  id_server_project=$RIT_DOMAIN"-"$RIT_PROJECT_NAME
  username_server_project="zup" # valor fixo
  password_server_project="" # será carregado automaticamente

  # M2 Settgins
  m2_settings_file=~/.m2/settings.xml

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
#  get_caller_identity=$(aws sts get-caller-identity --profile $profile --output text)
#  if [[ "$?" != "0" && $get_caller_identity == "" ]] ; then
#    consoleSuccess "🔓" "Login on AWS SSO..."
#    aws sso login --profile $profile
#    consoleSuccess "✔" "Done"
#  else
#    consoleSuccess "🔓" "Login OK..."
#  fi

  # Configure Server e Repository ~./m2/settings.xml
  if [[ ! -f $m2_settings_file ]] ; then
    consoleError "✘️ Error:" "M2 Settings not found in $m2_settings_file"
  else
    #################################
    ########## Repository ###########
    #################################
    consoleSuccess "📎" "Configuring repositories on m2 settings..."

    addRespository "$id_repository_zup_public" "zup" "public" "$m2_settings_file"

    addRespository "$id_repository_project" "$RIT_DOMAIN" "$RIT_PROJECT_NAME" "$m2_settings_file"

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

addRespository () {
  id="$1"
  domain="$2"
  project_name="$3"
  file="$4"

  # Veriricar se já tem repo publico
  # if [[ $(xmlstarlet sel -O -t -m "//_:repository/_:id[text()='$id']" -v . $m2_settings_file) ]]; then
  if [[ -n $(xmlstarlet sel -O -t -m "//_:repository/_:id[text()='$id']" -o true "$file") ]]; then
    consoleSuccess "🔍" "Repository $id found, proceeding to config... "
  else
    consoleSuccess "🛠" "Configuring repository $id..."

    consoleSuccess "☁" "Getting url..."
    url=$(aws codeartifact get-repository-endpoint --profile $profile --domain "$domain" --domain-owner $domain_owner --region us-east-1 --repository "$project_name" --format maven --output text)
    consoleSuccess "✔" "Done"

    ## Checkt if exists repository
    if [[ -z $(xmlstarlet sel -O -t -m "//_:profiles/_:profile/_:repositories/_:repository" -o true "$file") ]]; then
      consoleSuccess "➕" "Creating First Repository $id..."
      xmlstarlet ed --inplace -O -s '/_:settings' -t elem -n 'profiles' \
                                 -s '/_:settings/profiles' -t elem -n 'profile' \
                                 -s '/_:settings/profiles/profile' -t elem -n 'repositories' \
                                 -s '/_:settings/profiles/profile/repositories' -t elem -n 'repository' \
                                 -s '/_:settings/profiles/profile/repositories/repository' -t elem -n 'id' -v "$id" \
                                 -s '/_:settings/profiles/profile/repositories/repository' -t elem -n 'url' -v "$url" "$file"
    else
      ## Adicionando elementos
      if [[ -z $(xmlstarlet sel -O -t -m "//_:profiles" -o true "$file") ]]; then
        xmlstarlet ed --inplace -O -s '/_:settings' -t elem -n 'profiles' "$file"
      fi
      if [[ -z $(xmlstarlet sel -O -t -m "//_:profiles/_:profile" -o true "$file") ]]; then
        xmlstarlet ed --inplace -O -s '/_:settings/profiles' -t elem -n 'profile' "$file"
      fi
      if [[ -z $(xmlstarlet sel -O -t -m "//_:profiles/_:profile/_:repositories" -o true "$file") ]]; then
        xmlstarlet ed --inplace -O -s '/_:settings/profiles/profile' -t elem -n 'repositories' "$file"
      fi

      consoleSuccess "➕" "Appending New Repository $id..."
      ## Append to last repository
      xmlstarlet ed --inplace -O -a '/_:settings/_:profiles/_:profile/_:repositories/_:repository[last()]' -t elem -n 'repository' \
                                      -s '//repository[last()]' -t elem -n 'id' -v "$id" \
                                      -s '//repository[last()]' -t elem -n 'url' -v "$url" "$file"
    fi
    consoleSuccess "✔" "Done."
  fi
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