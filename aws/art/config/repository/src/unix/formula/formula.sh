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
  consoleSuccess "✔" "Configuring M2 Repository: $RIT_PROJECT_NAME"

  # Config Profile
  profile="546045978864_rit_ZupCodeArtifactUsers" # valor fixo
  domain_owner="546045978864" # valor fixo

  # Config Public Server and Repository
  id_repository_zup_public="zup-public" # valor fixo

  # Config Project Server and Repository
  id_repository_project="rit-$RIT_DOMAIN-$RIT_PROJECT_NAME"

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
    ########## Repository ###########
    #################################
    consoleSuccess "📎" "Configuring repositories"

    addRespository "$id_repository_zup_public" "zup" "public" $profile "$m2_settings_file"

    addRespository "$id_repository_project" "$RIT_DOMAIN" "$RIT_PROJECT_NAME" $profile "$m2_settings_file"
  fi
  consoleSuccess "✔" "All Done"
  echo "------------------------------------------------------------"
  exit 0
}

addRespository () {
  id="$1"
  domain="$2"
  project_name="$3"
  profile="$4"
  file="$5"

  # Veriricar se já tem repo publico
  if [[ -n $(xmlstarlet sel -O -t -m "//_:repository/_:id[text()='$id']" -o true "$file") ]]; then
    consoleSuccess "🔍" "Repository $id found, proceeding to config... "
  else
    consoleSuccess "🛠" "Configuring repository $id..."

    consoleSuccess "☁" "Getting url..."
    url=$(aws codeartifact get-repository-endpoint --profile "$profile" --domain "$domain" --domain-owner "$domain_owner" --region us-east-1 --repository "$project_name" --format maven --output text)
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