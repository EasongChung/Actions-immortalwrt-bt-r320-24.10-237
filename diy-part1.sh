#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# 1. 核心：通过修改 feeds.conf.default 来替换 Golang
# 移除官方 feeds 里的 golang 定义（如果有）
sed -i '/golang/d' feeds.conf.default

# 添加 sbwml 的 golang 源
# 这里的 golang 会在 update feeds 时被拉取到 feeds/golang 目录
echo 'src-git golang https://github.com/sbwml/packages_lang_golang;25.x' >> feeds.conf.default
