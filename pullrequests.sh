

for plugin in $(find . -maxdepth 1 -mindepth 1 -type d -name 'jellyfin-plugin-*'); do
  pushd $plugin > /dev/null
    data=$(hub pr list --format='%pC%>(8)%i%Creset %t% l%n%Cblue%         U%Creset%n' --color=always)

    if [ ! -z "$data" ]; then
      basename $plugin
      echo "${data}"
      echo
    fi

  popd > /dev/null
done

