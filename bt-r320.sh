#!/bin/bash

# git clone -b openwrt-24.10-6.6 --single-branch --filter=blob:none https://github.com/padavanonly/immortalwrt-mt798x-24.10 immortalwrt-mt798x-24.10
# cd immortalwrt-mt798x-24.10

# git config --local https.proxy socks5://host.docker.internal:1080

# ./scripts/feeds update -a
# ./scripts/feeds install -a

# 复制 DTS 和配置文件
cp -f "$GITHUB_WORKSPACE/dts/filogic.mk" "target/linux/mediatek/image/filogic.mk"
cp -f "$GITHUB_WORKSPACE/dts/mt7981b-ph-hy3000-emmc.dts" "target/linux/mediatek/dts/mt7981b-ph-hy3000-emmc.dts"
cp -f "$GITHUB_WORKSPACE/dts/mt7981b-bt-r320-emmc.dts" "target/linux/mediatek/dts/mt7981b-bt-r320-emmc.dts"
cp -f "$GITHUB_WORKSPACE/dts/mt7981b-sl-3000-emmc.dts" "target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts"
cp -f "$GITHUB_WORKSPACE/dts/02_network" "target/linux/mediatek/filogic/base-files/etc/board.d/02_network"
cp -f "$GITHUB_WORKSPACE/dts/01_leds" "target/linux/mediatek/filogic/base-files/etc/board.d/01_leds"
cp -f "$GITHUB_WORKSPACE/dts/platform.sh" "target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh"
cp -f "$GITHUB_WORKSPACE/dts/mediatek_filogic" "package/boot/uboot-envtools/files/mediatek_filogic"
echo "PH-HY3000和BT-R320 dts文件替换成功"

# theme
rm -rf feeds/luci/themes/luci-theme-argon
git clone https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

# passwall
# rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
# git clone https://github.com/xiaorouji/openwrt-passwall-packages package/passwall-packages

# rm -rf feeds/luci/applications/luci-app-passwall
# git clone https://github.com/xiaorouji/openwrt-passwall package/passwall-luci
# git clone https://github.com/xiaorouji/openwrt-passwall2 package/passwall2-luci

# ssr-plus
# rm -rf package/helloworld
# git clone --depth=1 https://github.com/fw876/helloworld.git package/helloworldd
# git -C package/helloworld pull

# mosdns
# rm -rf feeds/packages/lang/golang
# git clone https://github.com/sbwml/packages_lang_golang -b 25.x feeds/packages/lang/golang
# rm -rf feeds/packages/net/mosdns
# git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns

# tailscale
# sed -i '/\/etc\/init\.d\/tailscale/d;/\/etc\/config\/tailscale/d;' feeds/packages/net/tailscale/Makefile
# git clone https://github.com/asvow/luci-app-tailscale package/luci-app-tailscale

# easytier
git clone -b optional-easytier-web --single-branch https://github.com/icyray/luci-app-easytier package/luci-app-easytier
sed -i 's/util.pcdata/xml.pcdata/g' package/luci-app-easytier/luci-app-easytier/luasrc/model/cbi/easytier.lua

# defconfig
# cp -f ../.config .config
# cp -f defconfig/mt7981-ax3000.config .config
sed -i 's|IMG_PREFIX:=|IMG_PREFIX:=$(shell TZ="Asia/Shanghai" date +"%Y%m%d")-24.10-6.6-|' include/image.mk
# make menuconfig

# compile and build
make download -j8
make -j$(nproc)
