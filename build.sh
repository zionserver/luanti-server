#!/bin/bash -e

# Compilar LuaJIT
pushd luajit
make amalg -j$(nproc)
popd

# Compilar Luanti en modo servidor con soporte terminal
pushd luanti
mkdir -p build
cd build

# Configuración para servidor con terminal
cmake .. -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DBUILD_SERVER=ON \
    -DBUILD_CLIENT=OFF \
    -DENABLE_CURSES=ON \
    -DBUILD_UNITTESTS=OFF \
    -DENABLE_SYSTEM_JSONCPP=OFF \
    -DLUA_INCLUDE_DIR=../../luajit/src/ \
    -DLUA_LIBRARY=../../luajit/src/libluajit.a \
    -DZSTD_INCLUDE_DIR=/usr/include \          # Ruta explícita para Zstd
    -DZSTD_LIBRARY=/usr/lib/x86_64-linux-gnu/libzstd.so

ninja

# Generar binario de depuración
objcopy --only-keep-debug ../bin/minetestserver luanti-server.debug

# Preparar para empaquetado .deb
mkdir -p pkg-debian/DEBIAN
mkdir -p pkg-debian/usr/bin
mkdir -p pkg-debian/usr/lib
mkdir -p pkg-debian/usr/share/luanti-server

# Instalar en directorio temporal
DESTDIR=$(pwd)/pkg-debian ninja install

# Mover el binario renombrado
mv pkg-debian/usr/bin/minetestserver pkg-debian/usr/bin/luanti-server

# Copiar bibliotecas requeridas
cp /usr/lib/x86_64-linux-gnu/libzstd.so.1 pkg-debian/usr/lib/
cp /usr/lib/x86_64-linux-gnu/libleveldb.so.1d pkg-debian/usr/lib/
cp /usr/lib/x86_64-linux-gnu/libsnappy.so.1 pkg-debian/usr/lib/
cp /usr/lib/x86_64-linux-gnu/libjsoncpp.so.24 pkg-debian/usr/lib/
cp /usr/lib/x86_64-linux-gnu/libncursesw.so.6 pkg-debian/usr/lib/
cp /usr/lib/x86_64-linux-gnu/libtinfo.so.6 pkg-debian/usr/lib/

# Crear archivo de control para el paquete .deb
cat > pkg-debian/DEBIAN/control <<EOF
Package: luanti-server
Version: 5.12.0
Section: games
Priority: optional
Architecture: amd64
Depends: libncurses6, libsqlite3-0, zlib1g, libgmp10, libcurl4, libc6, libstdc++6, libzstd1, libleveldb1d, libjsoncpp24
Maintainer: Tu Nombre <tu@email.com>
Description: Servidor Luanti con soporte de terminal
 Minetest modificado para servidor con interfaz terminal
EOF

# Crear script post-instalación
cat > pkg-debian/DEBIAN/postinst <<EOF
#!/bin/sh
set -e
chmod +x /usr/bin/luanti-server
ldconfig  # Actualizar caché de bibliotecas
EOF
chmod +x pkg-debian/DEBIAN/postinst

# Construir el paquete .deb
dpkg-deb --build pkg-debian
mv pkg-debian.deb luanti-server_5.12.0_amd64.deb

popd
