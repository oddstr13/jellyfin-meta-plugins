#!/bin/bash
MY=$(dirname $(realpath -s "${0}"))

ABORT=0
function abort() {
    ABORT=1
}

for plugin in $(find . -maxdepth 1 -mindepth 1 -type d -name 'jellyfin-plugin-*' | sort); do
    if [ $ABORT -gt 0 ]; then
        break
    fi
    name=$(basename $plugin)
    if [ "$name" = "jellyfin-plugin-meta" ]; then
        continue
    fi

    pushd $plugin > /dev/null
        meta_version=$(grep -Po '^ *version: * "*\K[^"$]+' build.yaml)
        git_tag=$(git tag --ignore-case --sort=-version:refname --list 'v*' | head -n 1)
        git_tag_num=$(echo $git_tag | tail -c +2)
        meta_major=$(echo $meta_version | awk -F. '{ print $1 }')
        commits=$(git rev-list ${git_tag:-$(git log --pretty=%h --reverse | head -n1)}..HEAD --count)

        if [ "$commits" -gt 0 ] || [ "${meta_major:-1}" -gt "${git_tag_num:-0}" ]; then
            echo '----------'
            echo "Name: $name"
            echo "Meta: $meta_version"
            echo "Tag:  $git_tag"
            echo "Commits since last tag: $commits"

            if [ "${meta_major:-1}" -gt "${git_tag_num:-0}" ]; then
                echo Tag is behind
            else
                echo Tag equals meta
            fi

            echo '----------'
            git status --porcelain

            read -p "Tag new release? Y/[N]: " -r
            if [[ "${REPLY:-n}" =~ ^[Yy]$ ]]; then
                read -p "New version [$meta_major]: " new_version
                new_version=${new_version:-$meta_major}
                git tag -a -m "Version ${new_version}" v$new_version

                read -p "Push tag v$new_version? [Y]/N: " -r
                if [[ "${REPLY:-y}" =~ ^[Yy]$ ]]; then
                    git push upstream v$new_version
                fi
            fi

            read -p "Enter subshell? Y/[N]: " -r
            if [[ "${REPLY:-n}" =~ ^[Yy]$ ]]; then
                echo 'Entering subshell. `exit` to continue, `exit 1` stop script'
                export PS1="\e[1;35m\$(realpath -s --relative-base=$MY .)\e[0;37m$\e[m "
                if ! bash --noprofile --norc; then
                    echo "Aborting!"
                    break
                fi
            fi
        fi
    popd > /dev/null
done
