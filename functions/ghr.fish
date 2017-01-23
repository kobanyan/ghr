function ghr
  function __is_cached -a _repo _version _name
    test -f "$GHR_CACHE"; or touch "$GHR_CACHE"
    if string match -r "^$_repo\t$_version\t$_name" < "$GHR_CACHE" >/dev/null;
      return 0
    else
      return 1
    end
  end

  function __os_pattern
    # TODO cover other patterns
    set -l _os
    if test (uname) = "Darwin"
      set _os "darwin"
    else
      set _os "linux"
    end
    echo ".*$_os.*"
  end

  function __machine_pattern
    # TODO cover other patterns
    set -l _machine
    if test (uname) = "x86_64"
      set _machine "64"
    else
      set _machine "386"
    end
    echo ".*$_machine.*"
  end

  function __resolve_artifact_endpoint -a _json_file
    cat "$_json_file"\
      | string match -r ".*browser_download_url.*"\
      | string match -r (__os_pattern)\
      | string match -r (__machine_pattern)\
      | string trim -lr\
      | string trim --chars '"browser_download_url": '\
      | string trim -lr --chars '"'
  end

  function __resolve_real_version -a _json_file _version
    test "$_version" = "latest";\
      and echo (cat "$_json_file"\
        | string match -r '".*tag_name.*"'\
        | string trim -lr\
        | string trim --chars '"tag_name": '\
        | string trim -lr --chars '"');
      or echo "$_version"
  end

  # resolve arguments
  set -l _repo
  set -l _version
  set -l _name
  set -l _show_help
  getopts $argv | while read -l _key _value
    switch $_key
      case "r" "repo"
        set _repo "$_value"
      case "v" "version"
        set _version "$_value"
      case "n" "name"
        set _name "$_value"
      case "h" "help"
        echo "Usage: ghr [-r repo] [-v version] [-n name]"
        echo "Options:"
        echo " -h, --help             This help text"
        echo " -n, --name NAME        Save binary as NAME"
        echo " -r, --repo REPO        Github repository like 'user/repo'"
        echo " -v, --version VERSION  Use 'latest' if empty."
        return
      case \*
        echo "'$_key' is not a valid option" > /dev/stderr
        ghr -h > /dev/stderr
        return 1
    end
  end
  test -z "$_repo";
    and echo "'-r, --repo' is required option" > /dev/stderr;
    and ghr -h > /dev/stderr;
    and return 1
  test -z "$_name"; and set _name (string split "/" "$_repo")[-1]
  test -z "$_version"; and set _version "latest"

  # check if cached when version is specified
  test "$_version" != "latest";
    and __is_cached "$_repo" "$_version" "$_name";
      and return 0

  # resolve endpoint
  set -l _api_endpoint "https://api.github.com/repos/$_repo/releases/$_version"
  set -l _api_json "$GHR_TEMP/$_repo/$_version.json"
  spin -f " @ Downloading $_api_endpoint\r" "curl -sSLo $_api_json $_api_endpoint --create-dir";
    or return 1
  set -l _artifact_endpoint (__resolve_artifact_endpoint "$_api_json")
  test -z "$_artifact_endpoint";
    and echo "Not found repository. $_repo";
    and return 1

  # resolve real version
  set -l _real_version (__resolve_real_version "$_api_json" "$_version")

  # check if cached
  __is_cached "$_repo" "$_real_version" "$_name";
    and return 0

  # download artifact
  set -l _artifact "$GHR_TEMP/"(string split "/" $_artifact_endpoint)[-1]
  spin -f " @ Downloading $_artifact_endpoint\r" "curl -sSLo $_artifact $_artifact_endpoint";
    or return 1

  # unarchive
  set -l _dir_name (string split -r -m1 . "$_artifact")[1]
  if not string match -r "^$GHR_TEMP" "$_dir_name" >/dev/null 2>&1;
    echo "Illegal dir_name. $_dir_name"
    return 1
  end
  rm -rf $_dir_name
  mkdir -p $_dir_name
  switch $_artifact
    case "*.zip"
      unzip "$_artifact" -d "$_dir_name" >/dev/null
      rm -rf "$_artifact"
    case "*.tar.gz" "*.tgz"
      tar xvf "$_artifact" -C "$_dir_name" >/dev/null
      rm -rf "$_artifact"
    # TODO cover other extensions
    case "*"
      echo "Unknown archive type. $_artifact"
      return 1
  end

  # resolve binary
  set -l _binary (file $_dir_name/** | awk -F: '$2 ~ /executable/{print $1}')[1] # use first binary
  test -z "$_binary";
    and echo "Not found binary file in $_dir_name";
    and return 1

  # enable to exec
  mv "$_binary" "$GHR_BIN/$_name"
  chmod 755 "$GHR_BIN/$_name"

  # post process
  echo $_repo\t$_real_version\t$_name >> $GHR_CACHE
  rm -rf "$_dir_name"
end
