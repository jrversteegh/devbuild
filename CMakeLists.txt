cmake_minimum_required(VERSION 3.28)

project(cppbuild)

# Create external projects for contributions
include(ExternalProject)

set(PRE_FLAGS --prefix=${CMAKE_INSTALL_PREFIX})
set(CMAKE_FLAGS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++)
file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/llvm/configure" "cd ${CMAKE_CURRENT_SOURCE_DIR}/llvm && cmake -S llvm -G \"Unix Makefiles\" -B ${CMAKE_BINARY_DIR}/llvm -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS=\"clang;clang-tools-extra;lldb;lld\" -DLLVM_ENABLE_RUNTIMES=\"libcxx;libcxxabi;libunwind\" -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}\n")

# First build gcc 
ExternalProject_Add(
  gmp
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/gmp
  BUILD_IN_SOURCE 1
  CONFIGURE_COMMAND ./configure ${PRE_FLAGS}
)

ExternalProject_Add(
  mpfr
  DEPENDS gmp
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/mpfr
  BUILD_IN_SOURCE 1
  CONFIGURE_COMMAND ./configure ${PRE_FLAGS} --with-gmp=${CMAKE_INSTALL_PREFIX}
)

ExternalProject_Add(
  mpc
  DEPENDS mpfr
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/mpc
  BUILD_IN_SOURCE 1
  CONFIGURE_COMMAND ./configure ${PRE_FLAGS} --with-gmp=${CMAKE_INSTALL_PREFIX} --with-mpfr=${CMAKE_INSTALL_PREFIX}
)

ExternalProject_Add(
  gcc
  DEPENDS mpc
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/gcc
  CONFIGURE_COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/gcc/configure ${PRE_FLAGS} --disable-multilib --enable-ld
--enable-gold --enable-lto --with-gmp=${CMAKE_INSTALL_PREFIX} --with-mpfr=${CMAKE_INSTALL_PREFIX} --with-mpc=${CMAKE_INSTALL_PREFIX}

)

ExternalProject_Add_Step(
  gcc
  after_install
  DEPENDEES install
  COMMAND cd ${CMAKE_INSTALL_PREFIX}/bin && ln -sf gcc cc
)

ExternalProject_Add(
  llvm 
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/llvm
  CONFIGURE_COMMAND sh ${CMAKE_CURRENT_SOURCE_DIR}/llvm/configure
  BUILD_COMMAND $(MAKE) -C ${CMAKE_BINARY_DIR}/llvm
  INSTALL_COMMAND $(MAKE) -C ${CMAKE_BINARY_DIR}/llvm install
)
