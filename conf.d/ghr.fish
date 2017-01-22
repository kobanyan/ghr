if test -z "$GHR_ROOT"
  set -x GHR_ROOT "$HOME/.ghr"
end
set -x GHR_TEMP "$GHR_ROOT/temp"
set -x GHR_BIN "$GHR_ROOT/bin"
set -x GHR_CACHE "$GHR_ROOT/cache"
mkdir -p $GHR_TEMP $GHR_BIN
set -x PATH $GHR_BIN $PATH
