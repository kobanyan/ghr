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

function __test -a repo tag name
  echo ------
  set tests (math $tests + 1)
  test -n "$RUN_ON_TRABIS";
    and set skips (math $skips + 1);
    and return
  set -l binary $name
  test -z "$binary"; and set binary (string split "/" $repo)[-1]
  if type $binary >/dev/null 2>&1;
    __error "$binary should not be installed"
    return 1
  end
  set -l options $repo
  test -n "$tag"; and set options $options -t $tag
  test -n "$name"; and set options $options -n $name
  echo ghr $options
  ghr $options
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

__test stedolan/jq

__test motemen/ghq

echo Finished in (math (date +%s) - $start)s
echo -n "$tests tests, "
test $errors = 0;
  and set_color green;
  or set_color red;
echo -n "$errors errors, "
set_color normal
echo -n "$skips skips"
echo ""

exit $errors
