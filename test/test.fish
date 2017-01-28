set -g tests 0
set -g errors 0
set -g skips 0
set -g start (date +%s)

function __error -a message
  set_color red
  echo -n $message
  set_color normal
  echo ""
  set errors (math $errors + 1)
end

function __test -a repo tag name skip_at_running_on_travis
  set tests (math $tests + 1)
  # skip at running on travis
  test -n "$RUN_ON_TRABIS" -a -n "$skip_at_running_on_travis";
    and set skips (math $skips + 1);
    and echo "Skip installing from $repo; tag: $tag; name: $name"
    and return
  # resolve binary name
  set -l binary $name
  test -z "$binary"; and set binary (string split "/" $repo)[-1]
  # check if not installed
  if type $binary >/dev/null 2>&1;
    __error "$binary should not be installed"
    return 1
  end
  # install
  set -l options $repo
  test -n "$tag"; and set options $options -t $tag
  test -n "$name"; and set options $options -n $name
  echo ghr $options
  ghr $options
  # check if installed
  if type $binary >/dev/null 2>&1;
    if test -n "$tag";
      if not string match -r ".*$tag.*" (eval $binary --version);
        __error "$binary - $tag should be installed"
        return 1
      end
    end
  else
    __error "$binary should be installed"
    return 1
  end
end

echo Started

__test peco/peco

__test junegunn/fzf-bin 0.16.0

__test junegunn/fzf-bin "" fzf

__test stedolan/jq "" "" true

__test motemen/ghq

echo Finished in (math (date +%s) - $start)s
echo -n "$tests tests, "
test $errors = 0;
  and set_color green;
  or set_color red;
echo -n "$errors errors, "
set_color yellow
echo -n "$skips skips"
set_color normal
echo ""

exit $errors
