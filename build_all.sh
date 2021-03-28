#!/bin/bash
#set -x
MY=$(dirname $(realpath -s "${0}"))

export ARTIFACT_DIR="${MY}/artifacts"
mkdir -p "${ARTIFACT_DIR}"

DEFAULT_REPO_DIR=/mnt/web/mirror3.openshell.no/jellyfin/plugins/unstable.json
DEFAULT_REPO_URL=https://mirror3.openshell.no/jellyfin/plugins/

export JELLYFIN_REPO=${JELLYFIN_REPO:-$DEFAULT_REPO_DIR}
export JELLYFIN_REPO_URL=${JELLYFIN_REPO_URL:-$DEFAULT_REPO_URL}
#export JELLYFIN_REPO=${JELLYFIN_REPO:-$MY/test_repo}
#export JELLYFIN_REPO_URL=${JELLYFIN_REPO_URL:-http://10.79.1.0:8080}

export VERSION_SUFFIX=$(date -u +%y%m.%d%H.%M%S)

FAILED=()

for plugin in $(find . -maxdepth 1 -mindepth 1 -type d -name 'jellyfin-plugin-*' | sort); do
  name=$(basename $plugin)
  if [ "$name" = "jellyfin-plugin-meta" ]; then
    continue
  fi
  pushd $plugin > /dev/null
    echo -e "\n##### ${name} #####"

    #dotnet clean --configuration Release

    # Nuke
    #find . -type d -name obj -exec rm -r '{}' ';' 2> /dev/null
    #find . -type d -name obj -exec rm -r '{}' ';' 2> /dev/null


    #dotnet build --configuration Release --no-incremental
    #dotnet publish --no-self-contained --configuration Release --output bin
    #meta_version=$(grep -Po '^ *version: * "*\K[^"$]+' build.yaml)
    #export VERSION=$(echo $meta_version | sed 's/\.[0-9]*\.[0-9]*\.[0-9]*$/.'"$VERSION_SUFFIX"'/')

    bash $MY/build_plugin.sh || {
      FAILED+=("$name")
    }

    # && {
    #  artifacts=$(grep -Pzo '(?s)artifacts:\n\K( *-[^:]*\n)*(?=.*?:)' build.yaml | grep -aPo '"\K.*(?=")')
    #  output="${ARTIFACT_DIR}/${name}.zip"
    #  rm -f "${output}"

    #  pushd bin
    #    zip "${output}" ${artifacts} || {
    #      FAILED+=("$name")
    #    }
    #  popd > /dev/null
    #} || {
    #  FAILED+=("$name")
    #}

  popd > /dev/null
done

if [ ! ${#FAILED[@]} -eq 0 ]; then
  echo -e "\n\nThe following plugins failed to compile:" > /dev/stderr
  for plugin in "${FAILED[@]}"; do
    echo " - $plugin" > /dev/stderr
  done

  exit 1
fi
