#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
# echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
#echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

# =========================================================
# 1. 优先修复 Golang 环境 (解决 Xray, Docker 等编译失败的关键)
# =========================================================
rm -rf feeds/packages/lang/golang
#git clone https://github.com/sbwml/packages_lang_golang -b 25.x feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

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


