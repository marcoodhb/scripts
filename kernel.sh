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

OLD_PATH="$PATH"
export PATH="$CLANG_BIN_DIR:$PATH"

PROJECT_ROOT=$(pwd)
KERNEL_SOURCE_DIR="$PROJECT_ROOT/kernel/xiaomi/earth"
KERNEL_OUTPUT_DIR="$KERNEL_SOURCE_DIR/out"


echo "...Generando .config..."
make -C "$KERNEL_SOURCE_DIR" O="$KERNEL_OUTPUT_DIR" \
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
make -C "$KERNEL_SOURCE_DIR" O="$KERNEL_OUTPUT_DIR" \
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

export PATH="$OLD_PATH"

CUSTOM_KERNEL_ARTIFACTS_DIR="$PROJECT_ROOT/build_cache"
mkdir -p "$CUSTOM_KERNEL_ARTIFACTS_DIR"
KERNEL_IMAGE_PATH="$KERNEL_OUTPUT_DIR/arch/arm64/boot/Image.gz"

if [ ! -f "$KERNEL_IMAGE_PATH" ]; then
    echo "ERROR: La compilación del kernel falló. No se encontró Image.gz."
    exit 1
fi

cp "$KERNEL_IMAGE_PATH" "$CUSTOM_KERNEL_ARTIFACTS_DIR/Image.gz"

echo "--- Kernel completado y guardado en $CUSTOM_KERNEL_ARTIFACTS_DIR ---"
