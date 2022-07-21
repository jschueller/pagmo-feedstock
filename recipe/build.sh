#!/usr/bin/env bash

mkdir build
cd build

if [[ "$target_platform" == osx-* ]]; then
    # Workaround for compile issue on older OSX SDKs.
    export CXXFLAGS="$CXXFLAGS -fno-aligned-allocation"
else
    LDFLAGS="-lrt ${LDFLAGS}"
fi

# NOTE: ipopt and nlopt not yet fully available on non-x86.
if [[ "$target_platform" == linux-aarch64 ||  "$target_platform" == linux-ppc64le || "$target_platform" == osx-arm64* ]]; then
    export ENABLE_IPOPT=no
else
    export ENABLE_IPOPT=yes
fi

if [[ "$target_platform" == osx-arm64* ]]; then
    export ENABLE_NLOPT=no
else
    export ENABLE_NLOPT=yes
fi

if test "$target_platform" != "linux-ppc64le"
then
  CMAKE_ARGS="${CMAKE_ARGS} -DPAGMO_ENABLE_IPO=ON"
fi

cmake ${CMAKE_ARGS} \
    -DBoost_NO_BOOST_CMAKE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DPAGMO_WITH_EIGEN3=yes \
    -DPAGMO_WITH_NLOPT=$ENABLE_NLOPT \
    -DPAGMO_WITH_IPOPT=$ENABLE_IPOPT \
    -DPAGMO_BUILD_TESTS=yes \
    -DPAGMO_BUILD_TUTORIALS=yes \
    ..

make install -j${CPU_COUNT}

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
    ctest -j${CPU_COUNT} --output-on-failure --timeout 1000 -E fork_island
fi
