#!/usr/bin/env bash

set -euo pipefail

if [ ! -z ${GITHUB_ACTIONS-} ]; then
  set -x
fi

help() {
  cat <<'EOF'
Install a binary release of ord hosted on GitHub

USAGE:
    install [options]

FLAGS:
    -h, --help      Display this message
    -f, --force     Force overwriting an existing binary

OPTIONS:
    --tag TAG       Tag (version) of the crate to install, defaults to latest release
    --to LOCATION   Where to install the binary [default: ~/bin]
    --target TARGET
EOF
}

git=casey/ord
crate=ord
url=https://github.com/casey/ord
releases=$url/releases

say() {
  echo "install: $@"
}

say_err() {
  say "$@" >&2
}

err() {
  if [ ! -z ${td-} ]; then
    rm -rf $td
  fi

  say_err "error: $@"
  exit 1
}

need() {
  if ! command -v $1 > /dev/null 2>&1; then
    err "need $1 (command not found)"
  fi
}

force=false
while test $# -gt 0; do
  case $1 in
    --force | -f)
      force=true
      ;;
    --help | -h)
      help
      exit 0
      ;;
    --tag)
      tag=$2
      shift
      ;;
    --target)
      target=$2
      shift
      ;;
    --to)
      dest=$2
      shift
      ;;
    *)
      ;;
  esac
  shift
done

# Dependencies
need curl
need sed
need jq
need install
need mkdir
need mktemp
need tar

# Optional dependencies
if [ -z ${tag-} ]; then
  need cut
  need rev
fi

if [ -z ${dest-} ]; then
  dest="$HOME/bin"
fi

if [ -z ${tag-} ]; then

  if command -v jq; then
    tag=$(curl --proto =https --tlsv1.2 -sSf https://api.github.com/repos/casey/ord/releases/latest | \
      jq . | grep 'tag_name' | sed 's/"tag_name": "/ /' | sed 's/",/ /' | sed 's/   //' | sed 's/ //')
  else
    tag=$(curl --proto =https --tlsv1.2 -sSf https://api.github.com/repos/casey/ord/releases/latest | grep tag_name | cut -d'"' -f4)
  fi
  #tag=$(curl --proto =https --tlsv1.2 -sSf https://api.github.com/repos/casey/ord/releases/latest | grep tag_name | cut -d'"' -f4)
  #tag=$(curl --proto =https --tlsv1.2 -sSf https://api.github.com/repos/casey/ord/releases/latest | grep "tag_name" | sed 's/"tag_name": "/ /'  | sed 's/",//' | sed 's/   //')
  #tag=$(curl --proto =https --tlsv1.2 -sSf https://api.github.com/repos/casey/ord/releases/latest | jq . | grep 'tag_name' | sed 's/"tag_name": "/ /' | sed 's/",/ /' | sed 's/   //' | sed 's/ //')
  echo tag=$tag
fi

if [ -z ${target-} ]; then
  uname_target=`uname -m`-`uname -s`

  case $uname_target in
    arm64-Darwin) target=aarch64-apple-darwin;;
    x86_64-Darwin) target=x86_64-apple-darwin;;
    x86_64-Linux) target=x86_64-unknown-linux-gnu;;
    *)
      err 'Could not determine target from output of `uname -m`-`uname -s`, please use `--target`:' $uname_target
    ;;
  esac
fi



echo "releases"=$releases
echo "tag"=$tag
echo "crate"=$crate
echo "target="$target

#REF: using curl and jq
#REF: curl  https://api.github.com/repos/casey/ord/releases/latest | jq .
#REF: curl  https://api.github.com/repos/casey/ord/releases/latest | jq . | grep "tag_name"
tag_name=$(curl https://api.github.com/repos/casey/ord/releases/latest | jq . | grep 'tag_name') #| sed 's/"tag_name": "//' | sed 's/",//' | sed 's/   //')
tag_name=$(sed 's/"tag_name": "//')
tag_name=$(sed 's/",//')
tag_name=$(sed 's/   //')
#EXAMPLE: "browser_download_url": "https://github.com/casey/ord/releases/download/0.4.2/ord-0.4.2-x86_64-unknown-linux-gnu.tar.gz"
#EXAMPLE: "browser_download_url": "https://github.com/casey/ord/releases/download/$tag_name/ord-$tag_name-$uname_target"

archive="$releases/download/$tag_name/$crate-$tag_name-$target.tar.gz"
echo "archive="$archive
echo "archive="$archive
echo "archive="$archive
echo "archive="$archive
echo "archive="$archive

say_err "Repository:  $url"
say_err "Crate:       $crate"
say_err "Tag:         $tag"
say_err "Target:      $target"
say_err "Destination: $dest"
say_err "Archive:     $archive"

td=$(mktemp -d || mktemp -d -t tmp)
echo "archive="$archive
curl -sSfL $archive
#curl --proto =https --tlsv1.2 -sSfL $archive
#curl --proto =https --tlsv1.2 -sSfL $archive | tar -C $td -xz

for f in $(ls $td); do
  test -x $td/$f || continue

  if [ -e "$dest/$f" ] && [ $force = false ]; then
    err "$f already exists in $dest"
  else
    mkdir -p $dest
    install -m 755 $td/$f $dest
  fi
done

rm -rf $td
