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
  # Check and run bower
  if [ -f $build_dir/bower.json ]; then
    # Install bower locally
    header "Found bower.json, installing bower."
    npm install bower 2>&1
    bower_dir=$build_dir/node_modules/.bin
    info "Bower installed. Running bower install."
    $bower_dir/bower install --force-latest && $bower_dir/bower update --force-latest 2>&1

    # Deep Bower install.
    if [ "$BOWER_GLOB" != "" ]; then
      header "Installing bower components for bower components which match '$BOWER_GLOB'"

      for file in $( ls bower_components/$BOWER_GLOB/bower.json ); do
        (cd `dirname $file` && $bower_dir/bower install 2>&1)
      done
    fi

    # Custom bower folder for extra installs.
    if [ "$CUSTOM_BOWER_DIR" != "" ]; then
      if [ -d $build_dir/$CUSTOM_BOWER_DIR ]; then
        header "Custom bower directory set, running bower install within '$CUSTOM_BOWER_DIR'"
        (cd "$CUSTOM_BOWER_DIR" && $bower_dir/bower install 2>&1)
      else
        header "'$build_dir/$CUSTOM_BOWER_DIR' directory does not exist"
      fi
    fi

  else
    header "No bower.json found"
  fi
}
