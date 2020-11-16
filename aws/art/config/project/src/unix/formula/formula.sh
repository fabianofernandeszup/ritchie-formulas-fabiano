#!/bin/bash

runFormula() {
  checkCommand aws "AWS CLI is required"
  checkCommand mvn "Maven CLI is required"
  checkCommand xmlstarlet "xmlstarlet CLI is required"

  cd $CURRENT_PWD
  if [ -f pom.xml ] ; then
    echo -e "✘️ \\e[91mError: \\e[0mpom.xml not found. This folder is not a Maven project.";
    exit 0;
  fi
  echo "------------------------------------------------------------"
  echo -e "\\e[0;32m✔ \\e[1;30mConfiguring project:\\e[0m $RIT_PROJECT_NAME";
  echo -e "\\e[0;32m✔ \\e[1;30mDone \\e[0m";
  echo "------------------------------------------------------------"
  exit 0
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
