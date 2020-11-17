#!/bin/bash

runFormula() {
  checkCommand aws "AWS CLI is required"
  checkCommand mvn "Maven CLI is required"
  checkCommand xmlstarlet "xmlstarlet CLI is required"

  # Config Profile
  profile="546045978864_rit_ZupCodeArtifactUsers" # valor fixo

  ###########################################
  ########## Config SSO and Login ###########
  ###########################################
  rit aws art config sso

#  cd $CURRENT_PWD
  cd ~/www/app
  # Config Project Server and Repository
  id_repository_project="rit-$RIT_DOMAIN-$RIT_PROJECT_NAME"
  if [[ ! -f pom.xml ]] ; then
    echo -e "✘️ \\e[91mError: \\e[0mpom.xml not found. This folder is not a Maven project."
    exit 0
  else
    echo "------------------------------------------------------------"
    consoleSuccess  "✔" "Configuring project:$RIT_PROJECT_NAME"

    addRespositoryDistribution "$id_repository_project" "$RIT_DOMAIN" "$RIT_PROJECT_NAME" "$profile" "pom.xml"

    consoleSuccess "✔" "Done";
    echo "------------------------------------------------------------"
  fi
  exit 0
}

addRespositoryDistribution () {
  id="$1"
  domain="$2"
  project_name="$3"
  profile="$4"
  file="$5"

  # Delete distributionManagement
#  xmlstarlet ed --inplace -O -d "//_:distributionManagement" "$file"

  # Veriricar se já tem repo
  if [[ -n $(xmlstarlet sel -O -t -m "//_:repository/_:id[text()='$id']" -o true "$file") ]]; then
    consoleSuccess "🔍" "Repository $id found, proceeding to config... "
  else
    consoleSuccess "🛠" "Configuring repository $id..."

    consoleSuccess "☁" "Getting url..."
#    url=$(aws codeartifact get-repository-endpoint --profile $profile --domain "$domain" --domain-owner $domain_owner --region us-east-1 --repository "$project_name" --format maven --output text)
    url="URL"
    consoleSuccess "✔" "Done"

    ## Checkt if exists repository
    if [[ -z $(xmlstarlet sel -O -t -m "//_:distributionManagement/_:repository" -o true "$file") ]]; then
      consoleSuccess "➕" "Creating First Repository $id..."
      xmlstarlet ed --inplace -O -s '/_:project' -t elem -n 'distributionManagement' \
                                 -s '/_:project/distributionManagement' -t elem -n 'repository' \
                                 -s '/_:project/distributionManagement/repository' -t elem -n 'id' -v "$id" \
                                 -s '/_:project/distributionManagement/repository' -t elem -n 'name' -v "$id" \
                                 -s '/_:project/distributionManagement/repository' -t elem -n 'url' -v "$url" "$file"
    else
      ## Adicionando elementos
      if [[ -z $(xmlstarlet sel -O -t -m "//_:distributionManagement" -o true "$file") ]]; then
        xmlstarlet ed --inplace -O -s '/_:project' -t elem -n 'distributionManagement' "$file"
      fi

      consoleSuccess "➕" "Appending New Repository $id..."
      ## Append to last repository
      xmlstarlet ed --inplace -O -a '/_:project/_:distributionManagement/_:repository[last()]' -t elem -n 'repository' \
                                 -s '//repository[last()]' -t elem -n 'id' -v "$id" \
                                 -s '//repository[last()]' -t elem -n 'name' -v "$id" \
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