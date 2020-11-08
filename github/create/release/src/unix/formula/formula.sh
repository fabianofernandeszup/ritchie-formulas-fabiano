#!/bin/bash
# shellcheck disable=SC2181
# shellcheck disable=SC2086
# shellcheck disable=SC2164

removeSpaces() {
  echo "${1}" | xargs | tr " " -
}

runFormula() {
  echo "---------------------------------------------------------------------------"
  echo "🛠 Generating release $VERSION"
  tag=$(removeSpaces "$VERSION")
  API_JSON=$(printf '{"tag_name": "%s","target_commitish": "master","name": "%s","body": "Release of version %s - %s","draft": false,"prerelease": false}' $TAG $VERSION $VERSION $DESCRIPTION)
  curl --data "$API_JSON" https://api.github.com/repos/antoniofilhozup/rit-terraform-aws/releases?access_token=$TOKEN > /dev/null
  if [ $? != 0 ]; then
      echo -e "✘️ Fail generating release $VERSION";
      exit 1;
  fi
  echo "🚀 Release $VERSION successfully generated"
}
