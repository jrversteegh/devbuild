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
  unp1=`basename $file .tar.gz`
  unp2=`basename $file .tar.bz2`
  unp3=`basename $file .tar.xz`
  unp4=`basename $file .tgz`
  # patch level 1 (qt)
  unpp=`basename $file "-1.tar.gz"`
  unps=`basename $file "-src.tar.gz"`
  if [ -d $name ]; then
    return 0
  fi
  mkdir -p .downloads
  if [ ! -f .downloads/$file ]; then
    pushd .downloads && wget --no-check-certificate $url && popd || fail "Failed to get $name"
  fi
  tar xf .downloads/$file && \
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
  file=$name-$version.$ext
  if [ "X$canonical" = "X" ]; then
    url=$GNU_MIRROR/$name/$file
  else
    url=$GNU_MIRROR/$name/$canonical/$file
  fi
  download $name $file $url
} 


