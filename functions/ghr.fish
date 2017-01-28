function ghr -d "Install form Github releases"
  function __is_cached -a _repo _tag _name
    test -f "$GHR_CACHE"; or touch "$GHR_CACHE"
    if string match -r "^$_repo\t$_tag\t$_name" < "$GHR_CACHE" >/dev/null;
      return 0
    else
      return 1
    end
  end

  function __os_pattern
    # TODO cover other patterns
    set -l _os
    if test (uname) = "Darwin"
      set _os "(darwin|osx)"
    else
      set _os "linux"
    end
    echo ".*$_os.*"
  end

  function __machine_pattern
    # TODO cover other patterns
    set -l _machine
    if test (uname -m) = "x86_64"
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

  function __resolve_real_tag -a _json_file _tag
    test "$_tag" = "latest";\
      and echo (cat "$_json_file"\
        | string match -r '".*tag_name.*"'\
        | string trim -lr\
        | string trim --chars '"tag_name": '\
        | string trim -lr --chars '"');
      or echo "$_tag"
  end

  # resolve arguments
  set -l _repo
  set -l _tag
  set -l _name
  set -l _show_help
  getopts $argv | while read -l _key _value
    switch $_key
      case "r" "repo"
        set _repo "$_value"
      case "t" "tag"
        set _tag "$_value"
      case "n" "name"
        set _name "$_value"
      case "h" "help"
        echo "Usage: ghr [-r repo] [-t tag] [-n name]"
        echo "Options:"
        echo " -h, --help             This help text"
        echo " -n, --name NAME        Save binary as NAME"
        echo " -r, --repo REPO        Github repository 'owner/repo'"
        echo " -t, --tag TAG          Download from TAG"
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
  test -z "$_tag"; and set _tag "latest"
  test -n "$GHR_TOKEN"; and set -l _api_token "-u ghr:$GHR_TOKEN"

  # check if cached when tag is specified
  test "$_tag" != "latest";
    and __is_cached "$_repo" "$_tag" "$_name";
      and return 0

  # resolve endpoint
  set -l _api_endpoint
  test "$_tag" = "latest";
    and set _api_endpoint "https://api.github.com/repos/$_repo/releases/latest";
    or set _api_endpoint "https://api.github.com/repos/$_repo/releases/tags/$_tag"
  set -l _api_json "$GHR_TEMP/$_repo/$_tag.json"
  spin -f " @ Downloading $_api_endpoint\r" "curl -sSLo $_api_json $_api_token $_api_endpoint --create-dir";
    or return 1
  set -l _artifact_endpoint (__resolve_artifact_endpoint "$_api_json")
  test -z "$_artifact_endpoint";
    and echo "Not found repository. $_repo";
    and return 1

  # resolve real tag
  set -l _real_tag (__resolve_real_tag "$_api_json" "$_tag")

  # check if cached
  __is_cached "$_repo" "$_real_tag" "$_name";
    and return 0

  # download artifact
  set -l _artifact "$GHR_TEMP/"(string split "/" $_artifact_endpoint)[-1]
  spin -f " @ Downloading $_artifact_endpoint\r" "curl -sSLo $_artifact $_api_token $_artifact_endpoint";
    or return 1

  # unarchive
  set -l _dir_name "$GHR_TEMP/"(string split -m1 "." (string split -r -m1 "/" "$_artifact")[2])[1]
  set -l _binary
  if test "$_dir_name" != "$_artifact"
    rm -rf $_dir_name
    mkdir -p $_dir_name
    switch $_artifact
      case "*.zip"
        unzip "$_artifact" -d "$_dir_name" >/dev/null
        rm -rf "$_artifact"
      case "*.tar.gz" "*.tgz"
        tar xvf "$_artifact" -C "$_dir_name" >/dev/null
        rm -rf "$_artifact"
    end
    # resolve binary
    set _binary (file $_dir_name/** | awk -F: '$2 ~ /executable/{print $1}')[1] # use first binary
  else
    # artifact which does not have extension is binary
    set _binary "$_artifact"
  end

  # enable to exec
  test -z "$_binary";
    and echo "Not found binary file in $_dir_name";
    and return 1
  mv "$_binary" "$GHR_BIN/$_name"
  chmod 755 "$GHR_BIN/$_name"

  # post process
  echo $_repo\t$_real_tag\t$_name >> $GHR_CACHE
  rm -rf "$_dir_name"
end
