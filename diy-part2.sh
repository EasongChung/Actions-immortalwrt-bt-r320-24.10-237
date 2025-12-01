#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 2. 清理冲突包 & 官方坑包
# =========================================================
# 双重保险：移除 feeds 里的 golang (配合 diy-part1.sh 使用)
#rm -rf feeds/packages/lang/golang

# 移除 Ruby, Docker 等
rm -rf feeds/packages/lang/ruby
rm -rf feeds/packages/utils/docker
rm -rf feeds/packages/utils/dockerd
rm -rf feeds/packages/utils/containerd
rm -rf feeds/packages/utils/runc
rm -rf feeds/packages/utils/tini

# =========================================================
# 3. 克隆/替换第三方插件
# =========================================================

# Theme Argon
rm -rf feeds/luci/themes/luci-theme-argon
git clone https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

# Passwall & Dependencies
# 先移除冲突的包
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}

# 克隆 Passwall 依赖和主程序
git clone https://github.com/xiaorouji/openwrt-passwall-packages package/passwall-packages
rm -rf feeds/luci/applications/luci-app-passwall
git clone https://github.com/xiaorouji/openwrt-passwall package/passwall-luci

# Tailscale
sed -i '/\/etc\/init\.d\/tailscale/d;/\/etc\/config\/tailscale/d;' feeds/packages/net/tailscale/Makefile
git clone https://github.com/asvow/luci-app-tailscale package/luci-app-tailscale

# iStore
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}
git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
git_sparse_clone main https://github.com/linkease/istore luci

# EasyTier
git clone -b optional-easytier-web --single-branch https://github.com/icyray/luci-app-easytier package/luci-app-easytier
sed -i 's/util.pcdata/xml.pcdata/g' package/luci-app-easytier/luci-app-easytier/luasrc/model/cbi/easytier.lua

# =========================================================
# 4. 系统配置调整 (.config, Makefile, DTS 等)
# =========================================================

# 修改版本号
sed -i 's|IMG_PREFIX:=|IMG_PREFIX:=$(shell TZ="Asia/Shanghai" date +"%Y%m%d")-24.10-6.6-|' include/image.mk

# 复制 DTS 和配置文件
cp -f "$GITHUB_WORKSPACE/dts/filogic.mk" "target/linux/mediatek/image/filogic.mk"
cp -f "$GITHUB_WORKSPACE/dts/mt7981b-ph-hy3000-emmc.dts" "target/linux/mediatek/dts/mt7981b-ph-hy3000-emmc.dts"
cp -f "$GITHUB_WORKSPACE/dts/mt7981b-bt-r320-emmc.dts" "target/linux/mediatek/dts/mt7981b-bt-r320-emmc.dts"
cp -f "$GITHUB_WORKSPACE/dts/mt7981b-sl-3000-emmc.dts" "target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts"
cp -f "$GITHUB_WORKSPACE/dts/02_network" "target/linux/mediatek/filogic/base-files/etc/board.d/02_network"
cp -f "$GITHUB_WORKSPACE/dts/01_leds" "target/linux/mediatek/filogic/base-files/etc/board.d/01_leds"
cp -f "$GITHUB_WORKSPACE/dts/platform.sh" "target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh"
cp -f "$GITHUB_WORKSPACE/dts/mediatek_filogic" "package/boot/uboot-envtools/files/mediatek_filogic"
cp -f "$GITHUB_WORKSPACE/dts/npc/rc.local" "package/base-files/files/etc/rc.local"
chmod +x package/base-files/files/etc/rc.local
cp -f "$GITHUB_WORKSPACE/dts/npc/npc.conf" "package/base-files/files/etc/npc.conf"
chmod +x package/base-files/files/etc/npc.conf

echo "PH-HY3000和BT-R320 dts文件替换成功"

# =========================================================
# 5. 最终配置修正 (Sed 命令)
# =========================================================

# 强制禁用 Ruby 和 Docker (双重保险)
sed -i 's/CONFIG_PACKAGE_ruby=y/# CONFIG_PACKAGE_ruby is not set/' .config
sed -i 's/CONFIG_PACKAGE_docker=y/# CONFIG_PACKAGE_docker is not set/' .config
sed -i 's/CONFIG_PACKAGE_dockerd=y/# CONFIG_PACKAGE_dockerd is not set/' .config
sed -i 's/CONFIG_PACKAGE_luci-app-dockerman=y/# CONFIG_PACKAGE_luci-app-dockerman is not set/' .config

# 启用 Docker 内核支持 (为 opkg 安装做准备)
echo "CONFIG_PACKAGE_kmod-docker-internal=y" >> .config
echo "CONFIG_PACKAGE_kmod-veth=y" >> .config
echo "CONFIG_PACKAGE_kmod-ipt-nat=y" >> .config
echo "CONFIG_PACKAGE_kmod-bridge=y" >> .config
echo "CONFIG_PACKAGE_kmod-netfilter=y" >> .config


# 1. 强力修复 libxcrypt 编译错误 (核心修改)
# =========================================================
# 找到 libxcrypt 的 Makefile（通常在 feeds/packages/libs/libxcrypt）
LIBXCRYPT_MAKEFILE=$(find feeds/packages/libs/libxcrypt -name Makefile)

if [ -f "$LIBXCRYPT_MAKEFILE" ]; then
    echo "Found libxcrypt Makefile at: $LIBXCRYPT_MAKEFILE"
    
    # 1. 删除所有包含 -Werror 的行，防止警告变错误
    sed -i 's/-Werror//g' "$LIBXCRYPT_MAKEFILE"
    
    # 2. 显式添加忽略 format-nonliteral 错误的参数
    # 如果文件里有 TARGET_CFLAGS，就在它后面追加
    sed -i '/TARGET_CFLAGS/ s/$/ -Wno-format-nonliteral/' "$LIBXCRYPT_MAKEFILE"
    
    # 3. 如果上面没生效，再暴力注入到 Configure 参数里
    sed -i '/CONFIGURE_ARGS +=/a \	CFLAGS="$(TARGET_CFLAGS) -Wno-format-nonliteral" \\' "$LIBXCRYPT_MAKEFILE"
    
    echo "✅ 已应用 libxcrypt 修复补丁"
else
    echo "⚠️ 未找到 libxcrypt Makefile，尝试全盘搜索..."
    find . -name Makefile | xargs grep -l "libxcrypt"
fi

# 解决 quickstart 插件编译提示不支持压缩
if [ -f "package/feeds/nas_luci/luci-app-quickstart/Makefile" ]; then
    # 修正路径，从nas_luci源中查找该插件
    sed -i 's/DEPENDS:=+luci-base/DEPENDS:=+luci-base\n    NO_MINIFY=1/' "package/feeds/nas_luci/luci-app-quickstart/Makefile"
    echo "✅ 成功修改 quickstart 插件配置"
else
    echo "ℹ️ 未找到 quickstart 插件的 Makefile，跳过修改"
fi
