function ghr -d "Install form Github releases"
  function __is_cached -a repo tag name
    test -f "$GHR_CACHE"; or touch "$GHR_CACHE"
    if string match -r "^$repo\t$tag\t$name" < "$GHR_CACHE" >/dev/null;
      return 0
    else
      return 1
    end
  end

  function __os_pattern
    # TODO cover other patterns
    set -l os
    if test (uname) = "Darwin"
      set os "(darwin|osx)"
    else
      set os "linux"
    end
    echo ".*$os.*"
  end

  function __machine_pattern
    # TODO cover other patterns
    set -l machine
    if test (uname -m) = "x86_64"
      set machine "64"
    else
      set machine "(386|32)"
    end
    echo ".*$machine.*"
  end

  function __resolve_artifact_endpoint -a json_file
    cat "$json_file"\
      | string match -r ".*browser_download_url.*"\
      | string match -r (__os_pattern)\
      | string match -r (__machine_pattern)\
      | string trim -lr\
      | string trim --chars '"browser_download_url": '\
      | string trim -lr --chars '"'
  end

  function __resolve_real_tag -a json_file tag
    test "$tag" = "latest";\
      and echo (cat "$json_file"\
        | string match -r '".*tag_name.*"'\
        | string trim -lr\
        | string trim --chars '"tag_name": '\
        | string trim -lr --chars '"');
      or echo "$tag"
  end

  # resolve arguments
  set -l repo
  set -l tag
  set -l name
  getopts $argv | while read -l key value
    switch $key
      case "_" "repo"
        set repo "$value"
      case "t" "tag"
        set tag "$value"
      case "n" "name"
        set name "$value"
      case "h" "help"
        echo "Synopsis:"
        echo "  ghr <repo> [-t tag] [-n name]"
        echo "Options:"
        echo "  -h, --help       This help text"
        echo "  -n, --name NAME  Save binary as NAME"
        echo "  -t, --tag TAG    Download from TAG"
        echo "Usage:"
        echo "  Install latest version"
        echo "    ghr peco/peco"
        echo "  Install as alias"
        echo "    ghr -n fzf junegunn/fzf-bin"
        echo "  Install from specified tag"
        echo "    ghr -t jq-1.5rc2 stedolan/jq"
        return
      case \*
        echo "'$key' is not a valid option" > /dev/stderr
        ghr -h > /dev/stderr
        return 1
    end
  end
  test -z "$repo";
    and ghr -h > /dev/stderr;
    and return 1
  test -z "$name"; and set name (string split "/" "$repo")[-1]
  test -z "$tag"; and set tag "latest"
  test -n "$GHR_TOKEN"; and set -l api_token "-H \"Authorization: token $GHR_TOKEN\""

  # check if cached when tag is specified
  test "$tag" != "latest";
    and __is_cached "$repo" "$tag" "$name";
      and return 0

  # resolve endpoint
  set -l api_endpoint
  test "$tag" = "latest";
    and set api_endpoint "https://api.github.com/repos/$repo/releases/latest";
    or set api_endpoint "https://api.github.com/repos/$repo/releases/tags/$tag"
  set -l api_json "$GHR_TEMP/$repo/$tag.json"
  spin -f " @ Downloading $api_endpoint\r" "curl -sSLo $api_json $api_token $api_endpoint --create-dir";
    or return 1
  set -l artifact_endpoint (__resolve_artifact_endpoint "$api_json")
  test -z "$artifact_endpoint";
    and echo "Not found repository. $repo";
    and return 1

  # resolve real tag
  set -l real_tag (__resolve_real_tag "$api_json" "$tag")

  # check if cached
  __is_cached "$repo" "$real_tag" "$name";
    and return 0

  # download artifact
  set -l artifact "$GHR_TEMP/"(string split "/" $artifact_endpoint)[-1]
  spin -f " @ Downloading $artifact_endpoint\r" "curl -sSLo $artifact $artifact_endpoint";
    or return 1

  # unarchive
  set -l dir_name "$GHR_TEMP/"(string split -m1 "." (string split -r -m1 "/" "$artifact")[2])[1]
  set -l binary
  if test "$dir_name" != "$artifact"
    rm -rf $dir_name
    mkdir -p $dir_name
    switch $artifact
      case "*.zip"
        unzip "$artifact" -d "$dir_name" >/dev/null
        rm -rf "$artifact"
      case "*.tar.gz" "*.tgz"
        tar xvf "$artifact" -C "$dir_name" >/dev/null
        rm -rf "$artifact"
    end
    # resolve binary
    set binary (file $dir_name/** | awk -F: '$2 ~ /executable/{print $1}')[1] # use first binary
  else
    # artifact which does not have extension is binary
    set binary "$artifact"
  end

  # enable to exec
  test -z "$binary";
    and echo "Not found binary file in $dir_name";
    and return 1
  mv "$binary" "$GHR_BIN/$name"
  chmod 755 "$GHR_BIN/$name"

  # post process
  echo $repo\t$real_tag\t$name >> $GHR_CACHE
  rm -rf "$dir_name"
end
