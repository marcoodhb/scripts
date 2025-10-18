#!/bin/bash
set -e


TOOLCHAIN_ARCHIVE_PATH="my-toolchain/21.0.0.tar.gz"
TOOLCHAIN_EXTRACT_DIR="my-toolchain/extracted"
mkdir -p "$TOOLCHAIN_EXTRACT_DIR"
tar -xzf "$TOOLCHAIN_ARCHIVE_PATH" -C "$TOOLCHAIN_EXTRACT_DIR"

echo "...Actualizando submódulos del kernel..."
cd kernel/xiaomi/earth
git submodule update --init --recursive
cd ../../..

CLANG_BIN_DIR="$(pwd)/$TOOLCHAIN_EXTRACT_DIR/bin"

if [ ! -d "$CLANG_BIN_DIR" ]; then
    echo "ERROR: El directorio del toolchain '$CLANG_BIN_DIR' no existe"
    exit 1
fi
echo "Toolchain encontrado en: $CLANG_BIN_DIR"

export PATH="$CLANG_BIN_DIR:$PATH"

echo "...Generando .config..."
make -C kernel/xiaomi/earth O=kernel/xiaomi/earth/out \
    ARCH=arm64 \
    SUBARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
    CC="$CLANG_BIN_DIR/clang" \
    LLVM=1 \
    LLVM_IAS=1 \
    LD="$CLANG_BIN_DIR/ld.lld" \
    AR="$CLANG_BIN_DIR/llvm-ar" \
    NM="$CLANG_BIN_DIR/llvm-nm" \
    STRIP="$CLANG_BIN_DIR/llvm-strip" \
    OBJCOPY="$CLANG_BIN_DIR/llvm-objcopy" \
    OBJDUMP="$CLANG_BIN_DIR/llvm-objdump" \
    OBJSIZE="$CLANG_BIN_DIR/llvm-size" \
    READELF="$CLANG_BIN_DIR/llvm-readelf" \
    HOSTCC="$CLANG_BIN_DIR/clang" \
    HOSTCXX="$CLANG_BIN_DIR/clang++" \
    HOSTAR="$CLANG_BIN_DIR/llvm-ar" \
    HOSTLD="$CLANG_BIN_DIR/ld.lld" \
    -j$(nproc --all) \
    earth_defconfig

echo "---Build---"
make -C kernel/xiaomi/earth O=kernel/xiaomi/earth/out \
    ARCH=arm64 \
    SUBARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
    CC="$CLANG_BIN_DIR/clang" \
    LLVM=1 \
    LLVM_IAS=1 \
    LD="$CLANG_BIN_DIR/ld.lld" \
    AR="$CLANG_BIN_DIR/llvm-ar" \
    NM="$CLANG_BIN_DIR/llvm-nm" \
    STRIP="$CLANG_BIN_DIR/llvm-strip" \
    OBJCOPY="$CLANG_BIN_DIR/llvm-objcopy" \
    OBJDUMP="$CLANG_BIN_DIR/llvm-objdump" \
    OBJSIZE="$CLANG_BIN_DIR/llvm-size" \
    READELF="$CLANG_BIN_DIR/llvm-readelf" \
    HOSTCC="$CLANG_BIN_DIR/clang" \
    HOSTCXX="$CLANG_BIN_DIR/clang++" \
    HOSTAR="$CLANG_BIN_DIR/llvm-ar" \
    HOSTLD="$CLANG_BIN_DIR/ld.lld" \
    -j$(nproc --all)

KERNEL_IMAGE_PATH=$(realpath "kernel/xiaomi/earth/out/arch/arm64/boot/Image.gz")

if [ ! -f "$KERNEL_IMAGE_PATH" ]; then
    echo "ERROR: No se encontró el archivo Image.gz"
    exit 1
fi

echo "export TARGET_PREBUILT_KERNEL=$KERNEL_IMAGE_PATH" > kernel_env.sh

echo "--- Kernel completado ---"
