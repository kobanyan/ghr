set -g tests 0
set -g errors 0
set -g start (date +%s)

function __error -a message
  set_color red
  echo -n $message
  set_color normal
  echo ""
  set errors (math $errors + 1)
end

function __installed -a binary version
  set tests (math $tests + 1)
  if type $binary >/dev/null 2>&1;
    if test -n "$version";
       string match -r ".*$version.*" (eval $binary --version);
          or __error "Not installed $binary - $version"
    end
  else
    __error "Not installed $binary."
  end
end

ghr -r junegunn/fzf-bin -n fzf
__installed fzf

ghr -r junegunn/fzf-bin -v 0.16.2
__installed fzf-bin 0.16.2

ghr -r peco/peco
__installed peco

ghr -r stedolan/jq
__installed jq

ghr -r motemen/ghq
__installed ghq

echo Finished in (math (date +%s) - $start)s
echo -n "$tests tests, "
test $errors = 0;
  and set_color green;
  or set_color red;
echo -n "$errors errors"
set_color normal
echo ""

exit $errors
