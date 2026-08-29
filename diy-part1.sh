#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Apply the LYT T68M daughterboard DTS patch (SATA2 + SDIO WiFi AIC8800)

set -e

echo ">>> diy-part1: pwd=$(pwd)"
echo ">>> diy-part1: GITHUB_WORKSPACE=$GITHUB_WORKSPACE"
echo ">>> diy-part1: workspace files:"
ls -la "$GITHUB_WORKSPACE/custom" || true

PATCH="$GITHUB_WORKSPACE/custom/0001-rockchip-t68m-enable-sata2-sdio-wifi.patch"
DTS=target/linux/rockchip/dts/rk3568/rk3568-t68m.dts

if [ ! -f "$PATCH" ]; then
    echo "!!! diy-part1: patch file missing: $PATCH"
    exit 1
fi

if [ ! -f "$DTS" ]; then
    echo "!!! diy-part1: target dts not found at $DTS (in $(pwd))"
    exit 1
fi

echo ">>> diy-part1: applying DTS patch ($PATCH) => $DTS"
if command -v git >/dev/null 2>&1 && [ -d .git ]; then
    echo ">>> diy-part1: trying git apply"
    if git apply --check --verbose "$PATCH" 2>&1; then
        git apply "$PATCH"
        echo ">>> diy-part1: git apply OK"
    else
        echo "!!! diy-part1: git apply --check failed, falling back to patch -p1"
        patch -p1 --batch --fuzz=0 -i "$PATCH"
        echo ">>> diy-part1: patch -p1 OK (fallback)"
    fi
else
    echo ">>> diy-part1: git not available, using patch -p1"
    patch -p1 --batch --fuzz=0 -i "$PATCH"
    echo ">>> diy-part1: patch -p1 OK"
fi

echo ">>> diy-part1: verifying DTS markers"
for marker in '&sata2 {' 'sdio_pwrseq: sdio-pwrseq {' '&sdmmc2 {' 'wifi_enable_h: wifi-enable-h {'; do
    if grep -qF "$marker" "$DTS"; then
        echo "    marker OK: $marker"
    else
        echo "!!! diy-part1: marker NOT FOUND: $marker"
        exit 1
    fi
done

echo ">>> diy-part1: DTS patch applied and verified OK"