#!/bin/bash -e

# Clone Minetest 5.12
if [ ! -d "minetest" ]; then
  git clone --depth 1 --branch 5.12.0 https://github.com/minetest/minetest.git
fi

# Clone LuaJIT
if [ ! -d "luajit" ]; then
  git clone --depth 1 --branch v2.1 https://github.com/LuaJIT/LuaJIT.git luajit
fi

# Compile LuaJIT
cd luajit
make -j$(nproc) amalg
cd ..

# Build Minetest Server
cd minetest
mkdir -p build
cd build

# Server-only configuration with SQLite only
cmake .. -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DBUILD_SERVER=ON \
  -DBUILD_CLIENT=OFF \
  -DENABLE_CURSES=ON \
  -DBUILD_UNITTESTS=OFF \
  -DENABLE_SYSTEM_JSONCPP=OFF \
  -DENABLE_LEVELDB=OFF \
  -DLUA_INCLUDE_DIR=../../luajit/src \
  -DLUA_LIBRARY=../../luajit/src/libluajit.a

ninja

# Prepare DEB package
mkdir -p pkg/usr/bin
mkdir -p pkg/DEBIAN

# CORRECCIÓN: Copiar desde la ubicación absoluta correcta
cp ../../bin/luantiserver pkg/usr/bin/
cd pkg/usr/bin
ln -s luantiserver minetestserver
cd ../../../..

# Create control file
cat > pkg/DEBIAN/control <<EOF
Package: minetest-server
Version: 5.12.0-1
Section: games
Priority: optional
Architecture: amd64
Depends: libc6, libstdc++6, libsqlite3-0, libzstd1, libcurl4, libncurses6, libgmp10, libjsoncpp25, zlib1g
Maintainer: Minetest Team <minetest@example.com>
Description: Minetest game server with terminal support
 Minetest is an open source voxel game engine. This package provides
 the server component with terminal administration interface.
Homepage: https://www.minetest.net
EOF

# Build DEB package
dpkg-deb --build pkg
mv pkg.deb minetest-server_5.12.0_bookworm_amd64.deb

# Mover el archivo DEB a la raíz del repositorio
cp minetest-server_5.12.0_bookworm_amd64.deb ../../../
cd ../..
