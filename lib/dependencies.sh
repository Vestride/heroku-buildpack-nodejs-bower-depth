run_if_present() {
  local script_name=${1:-}
  local has_script=$(read_json "$BUILD_DIR/package.json" ".scripts[\"$script_name\"]")
  if [ -n "$has_script" ]; then
    echo "Running $script_name"
    npm run "$script_name" --if-present
  fi
}

install_node_modules() {
  local build_dir=${1:-}

  if [ -e $build_dir/package.json ]; then
    cd $build_dir

    echo "Pruning any extraneous modules"
    npm prune --unsafe-perm --userconfig $build_dir/.npmrc 2>&1
    if [ -e $build_dir/npm-shrinkwrap.json ]; then
      echo "Installing node modules (package.json + shrinkwrap)"
    else
      echo "Installing node modules (package.json)"
    fi
    npm install --unsafe-perm --userconfig $build_dir/.npmrc 2>&1
  else
    echo "Skipping (no package.json)"
  fi
}

rebuild_node_modules() {
  local build_dir=${1:-}

  if [ -e $build_dir/package.json ]; then
    cd $build_dir
    echo "Rebuilding any native modules"
    npm rebuild 2>&1
    if [ -e $build_dir/npm-shrinkwrap.json ]; then
      echo "Installing any new modules (package.json + shrinkwrap)"
    else
      echo "Installing any new modules (package.json)"
    fi
    npm install --unsafe-perm --userconfig $build_dir/.npmrc 2>&1
  else
    echo "Skipping (no package.json)"
  fi
}

install_bower_components() {
  local build_dir=${1:-}
  local bower_glob=${2:-}
  local custom_bower_dir=${3:-}

  # Check and run bower
  if [ -e $build_dir/bower.json ]; then
    # Install bower locally
    info "Found bower.json, installing bower."
    npm install bower 2>&1
    bower_dir=$build_dir/node_modules/.bin
    info "Bower installed. Running bower install."
    $bower_dir/bower install --force-latest && $bower_dir/bower update --force-latest 2>&1

    # Deep Bower install.
    if [ $bower_glob != "" ]; then
      header "Installing bower components for bower components which match '$bower_glob'"

      for file in $( ls bower_components/$bower_glob/bower.json ); do
        (cd `dirname $file` && $bower_dir/bower install 2>&1)
      done
    fi

    # Custom bower folder for extra installs.
    if [ $custom_bower_dir != "" ]; then
      if [ -d $build_dir/$custom_bower_dir ]; then
        header "Custom bower directory set, running bower install within '$custom_bower_dir'"
        (cd "$custom_bower_dir" && $bower_dir/bower install 2>&1)
      else
        header "'$build_dir/$custom_bower_dir' directory does not exist"
      fi
    fi

  else
    info "No bower.json found"
  fi
}
