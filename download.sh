GNU_MIRROR=https://ftp.snt.utwente.nl/pub/software/gnu
LLVM_MIRROR=https://github.com/llvm/llvm-project/releases/download

function fail()
{
  msg=$1
  echo $msg >&2
  exit 1
}

function patch_package()
{
  name=$1
  if [ -f patches/$name.patch ]; then
    echo "Patching $name"
    pushd $name && patch -p0 < ../patches/$name.patch && popd || fail "Failed to patch $name"
  fi
}

function download()
{
  name=$1
  file=$2
  url=$3
  if [ -z $4 ]; then
    unpacked=`basename $file .tar.gz`
  else
    unpacked=$4
  fi
  if [ -d $name ]; then
    echo "$name already exists"
    return 0
  fi
  mkdir -p .downloads
  if [ ! -f .downloads/$file ]; then
    pushd .downloads && wget --no-check-certificate $url && popd || fail "Failed to get $name"
  fi
  tar xf .downloads/$file && \
    mv $unpacked $name && \
    if [ ! -d $name ]; then 
      fail "Failed to unpack $name"
    fi
  patch_package $name
}

function llvm_download() 
{
  name=$1
  base=$2
  package=$3
  file=`basename $package.src.tar.xz`
  download $name $file $LLVM_MIRROR/$base/$file
} 

function gnu_download() 
{
  name=$1
  version=$2
  ext=$3
  canonical=$4
  unpacked=$name-$version
  file=$unpacked.$ext
  if [ "X$canonical" = "X" ]; then
    url=$GNU_MIRROR/$name/$file
  else
    url=$GNU_MIRROR/$name/$canonical/$file
  fi
  download $name $file $url $unpacked
} 


