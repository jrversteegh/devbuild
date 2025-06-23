#!/bin/bash

GMP_VERSION=6.3.0
MPFR_VERSION=4.2.2
MPC_VERSION=1.3.1
GCC_VERSION=15.1.0
LLVM_VERSION=20.1.7


if [ -z $ENV_DIR ]; then
  ENV_DIR=~/Environments/dev
fi

if [ -d "$ENV_DIR" ]; then
  echo "Environment $ENV_DIR already exists. Remove if you want to create a new one"
  exit 1
fi

. ./download.sh


gnu_download gmp $GMP_VERSION tar.xz
gnu_download mpfr $MPFR_VERSION tar.xz 
gnu_download mpc $MPC_VERSION tar.gz 
gnu_download gcc $GCC_VERSION tar.gz gcc-$GCC_VERSION

llvm_download llvm llvmorg-$LLVM_VERSION llvm-$LLVM_VERSION
llvm_download llvm/tools/clang llvmorg-$LLVM_VERSION clang-$LLVM_VERSION
llvm_download llvm/projects/libcxx llvmorg-$LLVM_VERSION libcxx-$LLVM_VERSION
llvm_download llvm/projects/libcxxabi llvmorg-$LLVM_VERSION libcxxabi-$LLVM_VERSION
llvm_download llvm/projects/openmp llvmorg-$LLVM_VERSION openmp-$LLVM_VERSION

python -m venv "$ENV_DIR" || fail "Failed to setup environment"
echo "export PKG_CONFIG_PATH=\$VIRTUAL_ENV/lib/pkgconfig:\$PKG_CONFIG_PATH" >> "$ENV_DIR/bin/activate" 
echo "export LD_LIBRARY_PATH=\$VIRTUAL_ENV/lib:\$LD_LIBRARY_PATH" >> "$ENV_DIR/bin/activate" 
. "$ENV_DIR/bin/activate" || fail "Failed to activate environment"

pip install cmake
mkdir -p .build
cd .build
cmake -DCMAKE_INSTALL_PREFIX="$ENV_DIR" ..
make -j 8

deactivate
