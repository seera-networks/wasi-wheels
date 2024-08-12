#!/bin/bash

if [ ! -e venv ]; then
  python3.12 -m venv venv
fi

. venv/bin/activate
pip install meson-python click doit pydevtool rich_click cython pythran pybind11

CURRENTDIR=$(pwd)
TEMPDIR=$(mktemp -d)
echo $TEMPDIR

cp $PYODIDE_BUILD/pyodide_build/pywasmcross.py $TEMPDIR/pywasmcross.py
cp $PYODIDE_BUILD/pyodide_build/_f2c_fixes.py $TEMPDIR/_f2c_fixes.py

ln -s $TEMPDIR/pywasmcross.py $TEMPDIR/cc
ln -s $TEMPDIR/pywasmcross.py $TEMPDIR/c++
ln -s $TEMPDIR/pywasmcross.py $TEMPDIR/ld
ln -s $TEMPDIR/pywasmcross.py $TEMPDIR/lld
ln -s $TEMPDIR/pywasmcross.py $TEMPDIR/ar
ln -s $TEMPDIR/pywasmcross.py $TEMPDIR/gcc
ln -s $TEMPDIR/pywasmcross.py $TEMPDIR/ranlib
ln -s $TEMPDIR/pywasmcross.py $TEMPDIR/strip
ln -s $TEMPDIR/pywasmcross.py $TEMPDIR/gfortran
ln -s $TEMPDIR/pywasmcross.py $TEMPDIR/cargo
ln -s $TEMPDIR/pywasmcross.py $TEMPDIR/cmake
ln -s $TEMPDIR/pywasmcross.py $TEMPDIR/meson
ln -s $TEMPDIR/pywasmcross.py $TEMPDIR/install_name_tool
ln -s $TEMPDIR/pywasmcross.py $TEMPDIR/otool

PYTHONPATH=$(python -c "import sys; print(sys.path + ['$TEMPDIR', '$SYSCONFIG'])")
echo ${PYTHONPATH}
json=$(
  cat <<< "
    {
      'pkgname': 'scipy',
      'cflags': '-I${CROSS_PREFIX}/include/python3.12 -Wno-return-type -DUNDERSCORE_G77 -fvisibility=default',
      'cxxflags': '-fexceptions -fvisibility=default',
      'ldflags': '-L${NUMPY_LIB}/core/lib/ -L${NUMPY_LIB}/random/lib/ -fexceptions',
      'target_install_dir': '${TARGET_INSTALL_DIR}',
      'builddir': '${CURRENTDIR}/build',
      'PYTHONPATH': ${PYTHONPATH},
      'orig__name__': 'pybuild.py',
      'pythoninclude': '',
      'wasi_sdk_path': '${WASI_SDK_PATH}',
      'PATH': '${PATH}',
      'exports': 'pyinit'
    }
  " | tr "'" "\"" | tee -a $TEMPDIR/pywasmcross_env.json
)

# export BUILD_ENV_SCRIPTS_DIR=$TEMPDIR
export BUILD_ENV_SCRIPTS_DIR=""
export PATH=$TEMPDIR:$PATH

export CC=$TEMPDIR/cc
export CXX=$TEMPDIR/c++
export LD=$TEMPDIR/ld
export LLD=$TEMPDIR/lld
export AR=$TEMPDIR/ar
export GCC=$TEMPDIR/gcc
export RANLIB=$TEMPDIR/ranlib
export strip=$TEMPDIR/strip
export FC=$TEMPDIR/gfortran
# export CMAKE=$TEMPDIR/cmake

export PKG_CONFIG_PATH=/root/wasi-sdk-24.0-x86_64-linux/share/wasi-sysroot/lib/pkgconfig/

# (cd src && python dev.py build --show-build-log) 
# (cd src && meson setup --cross-file /workspaces/yakiniku/mods3/wasi.meson.cross ../build .)
(cd src && ninja -C ../build) 
