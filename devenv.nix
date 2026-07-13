{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  packages = [
    pkgs.git
    pkgs.steelix
    pkgs.steel
    pkgs.steel-language-server
    pkgs.taplo
  ];

  scripts.smoketest.exec = "taplo check config.toml languages.toml";

  scripts.test-drive.exec = ''
    PROFILE_DIR="$PWD/.devenv/test-profile"
    mkdir -p "$PROFILE_DIR/helix" "$PROFILE_DIR/data" "$PROFILE_DIR/cache"

    # Symlink config files to local sandbox config path
    ln -sfn "$PWD/config.toml" "$PROFILE_DIR/helix/config.toml"
    ln -sfn "$PWD/languages.toml" "$PROFILE_DIR/helix/languages.toml"
    ln -sfn "$PWD/init.scm" "$PROFILE_DIR/helix/init.scm"

    echo "Starting test-drive of Helix (Steelix) in isolated sandbox..."
    echo "Caches, plugins, and state will be saved to: $PROFILE_DIR"

    XDG_CONFIG_HOME="$PROFILE_DIR" \
    XDG_DATA_HOME="$PROFILE_DIR/data" \
    XDG_CACHE_HOME="$PROFILE_DIR/cache" \
    helix "$@"
  '';

  git-hooks.hooks = {
    taplo.enable = true;
  };
}
