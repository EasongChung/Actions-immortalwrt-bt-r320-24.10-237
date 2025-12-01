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


# =========================================================
# 1. 优先修复 Golang 环境 (解决 Xray, Docker 等编译失败的关键)
# =========================================================
# rm -rf feeds/packages/lang/golang
#git clone https://github.com/sbwml/packages_lang_golang -b 25.x feeds/packages/lang/golang
#git clone https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# 注意：25.x 分支可能对某些旧源码不兼容，建议用 22.x 或 master，或者根据你之前的成功经验保持 25.x
# 如果你之前用 25.x 成功了，就保留 25.x

# =========================================================
# 2. 清理可能有问题的官方包 (Ruby, Docker 等)
# =========================================================
# 移除 Ruby 以防止编码报错 (Invalid byte sequence)
rm -rf feeds/packages/lang/ruby

# 移除 Docker 源码 (防止编译失败，建议后续通过 opkg 安装)
rm -rf feeds/packages/utils/docker
rm -rf feeds/packages/utils/dockerd

#添加编译日期标识
date_version=$(date +"%Y年%m月%d日")
#sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")
#sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ by vx:Mr___zjz-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")
#添加编译日期
COMPILE_DATE=$(date +"%Y年%m月%d日")







# 修改版本为编译日期，数字类型。
date_version=$(date +"%Y年%m月%d日")
echo $date_version > version

# 为iStoreOS固件版本加上编译作者
author="微信:Mr___zjz"
sed -i "s/DISTRIB_DESCRIPTION.*/DISTRIB_DESCRIPTION='%D %V ${date_version} by ${author}'/g" package/base-files/files/etc/openwrt_release
sed -i "s/OPENWRT_RELEASE.*/OPENWRT_RELEASE=\"%D %V ${date_version} by ${author}\"/g" package/base-files/files/usr/lib/os-release

sed -i "s/%D/ openwrt/g" package/base-files/files/usr/lib/os-release
sed -i "s/%D/ openwrt/g" package/base-files/files/etc/openwrt_release

sed -i "s/%V/ 24.10.4 /g" package/base-files/files/usr/lib/os-release
sed -i "s/%V/ 24.10.4    编译日期： ${COMPILE_DATE}  by 微信:Mr___zjz//g" package/base-files/files/etc/openwrt_release

sed -i "s/%C/   编译日期： ${COMPILE_DATE}  by 微信:Mr___zjz/g" package/base-files/files/usr/lib/os-release  
sed -i "s/%C/   编译日期： ${COMPILE_DATE}  by 微信:Mr___zjz/g" package/base-files/files/etc/openwrt_release

sed -i "s/%R/   编译日期： ${COMPILE_DATE}  by 微信:Mr___zjz/g" package/base-files/files/usr/lib/os-release  
sed -i "s/%R/   编译日期： ${COMPILE_DATE}  by 微信:Mr___zjz/g" package/base-files/files/etc/openwrt_release

# Add the default password for the 'root' user（Change the empty password to 'password'）
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow

WIFI_FILE="./package/mtk/applications/mtwifi-cfg/files/mtwifi.sh"
#修改WIFI名称
sed -i "s/ImmortalWrt/Openwrt/g" $WIFI_FILE
#修改WIFI加密
sed -i "s/encryption=.*/encryption='psk2+ccmp'/g" $WIFI_FILE
#修改WIFI密码
sed -i "/set wireless.default_\${dev}.encryption='psk2+ccmp'/a \\\t\t\t\t\t\set wireless.default_\${dev}.key='password'" $WIFI_FILE


orig_version=$(cat "package/emortal/default-settings/files/99-default-settings-chinese" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
#VERSION=$(grep "^PRETTY_NAME="package/base-files/files/etc/os-release | cut -d'=' -f2 | tr -d '"')
VERSION=$(grep "PRETTY_NAME=" package/base-files/files/usr/lib/os-release | cut -d'=' -f2)
#sed -i "s/openwrt 24.10.3 /R${date_version} by vx:Mr___zjz  /g" package/emortal/default-settings/files/99-default-settings-chinese

#sed -i '/^exit 0$/i sed -i "s,OPENWRT_RELEASE=.*, ${VERSION} 编译日期：${date_version}  by 微信:Mr___zjz  ,g" package/base-files/files/usr/lib/os-release' package/emortal/default-settings/files/99-default-settings-chinese
sed -i '/^exit 0$/i sed -i "s,OPENWRT_RELEASE=.*,'"${VERSION}"' 编译日期：'"${date_version}"'  by 微信:Mr___zjz  ,g" package/base-files/files/usr/lib/os-release' \package/emortal/default-settings/files/99-default-settings-chinese
CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
#sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='HY3000'/g" $CFG_FILE
#添加第三方软件源
sed -i "s/option check_signature/# option check_signature/g" package/system/opkg/Makefile
echo src/gz openwrt_kiddin9 https://dl.openwrt.ai/latest/packages/aarch64_cortex-a53/kiddin9 >> ./package/system/opkg/files/customfeeds.conf

# 最大连接数修改为65535
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=65535' package/base-files/files/etc/sysctl.conf
