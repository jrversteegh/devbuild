#!/bin/bash

PY_VERSION=3.14
GMP_VERSION=6.3.0
MPFR_VERSION=4.2.2
MPC_VERSION=1.3.1
GCC_VERSION=15.2.0

unset LD_LIBRARY_PATH
unset LIBRARY_PATH

if [ -z $ENV_DIR ]; then
  ENV_DIR=~/Environments/dev
fi

if [ ! -z "$1" ]; then
  ENV_DIR="$1"
fi

if [ -d "$ENV_DIR" ]; then
  echo "Environment $ENV_DIR already exists. Remove if you want to create a new one"
  exit 1
fi

if [ -d .build ]; then
  echo "Build directory .build already exists. Remove if you want to build"
  exit 1
fi

. ./download.sh

run() {
  echo -n "$1... "
  shift
  log=$1
  if [ -z $log ]; then
    echo "Require log"
    exit 1
  fi
  shift
  if [ -z $1 ]; then
    echo "Require argument"
    exit 2
  fi
  $@ >> $log.log 2>$log.error || fail "Failed to run $1"
  echo " done."
}

run "Downloading GMP" downloads gnu_download gmp $GMP_VERSION tar.xz
run "Downloading MPFR" downloads gnu_download mpfr $MPFR_VERSION tar.xz 
run "Downloading MPC" downloads gnu_download mpc $MPC_VERSION tar.gz 
run "Downloading GCC" downloads gnu_download gcc $GCC_VERSION tar.gz gcc-$GCC_VERSION

if ! which pyenv >/dev/null; then
  run "Installing pyenv dependencies" pyenv sudo apt install -y liblzma-dev libbz2-dev tk-dev libssl-dev libffi-dev libsqlite3-dev libreadline-dev libncurses-dev
  run "Installing pyenv" pyenv curl https://pyenv.run | bash
fi

run "Updating pyenv" pyenv pyenv update
run "Installing Python $PY_VERSION" python pyenv install -s $PY_VERSION
run "Activating Python $PY_VERSION" python pyenv local $PY_VERSION

run "Creating virtual environment" venv python -m venv "$ENV_DIR"
echo "export PKG_CONFIG_PATH=\$VIRTUAL_ENV/lib/pkgconfig:\$PKG_CONFIG_PATH" >> "$ENV_DIR/bin/activate" 
echo "export LD_LIBRARY_PATH=\$VIRTUAL_ENV/lib:\$LD_LIBRARY_PATH" >> "$ENV_DIR/bin/activate" 
echo "export RUSTUP_HOME=\$VIRTUAL_ENV/rustup" >> "$ENV_DIR/bin/activate"
echo "export CARGO_HOME=\$VIRTUAL_ENV" >> "$ENV_DIR/bin/activate"
. "$ENV_DIR/bin/activate" || fail "Failed to activate environment"

run "Installing CMake" cmake pip install cmake
mkdir -p .build
cd .build
run "Configuring build" cmake cmake -DCMAKE_INSTALL_PREFIX="$ENV_DIR" ..
run "Building GCC" gcc cmake --build . --target gcc --parallel=8

run "Installing Rust" rust curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

deactivate

echo "Installed development environment. Activate with:"
echo ". $ENV_DIR/bin/activate"
