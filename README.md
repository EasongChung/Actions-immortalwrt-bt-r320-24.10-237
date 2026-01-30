# ImmortalWrt 24.10 for Globitel BT-R320-EMMC

[![LICENSE](https://img.shields.io/github/license/mashape/apistatus.svg?style=flat-square&label=LICENSE)](https://github.com/P3TERX/Actions-OpenWrt/blob/master/LICENSE)

## 项目简介

本项目是基于以下两个核心项目构建的定制固件编译环境：
1. [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt) - GitHub Actions 在线编译框架
2. [padavanonly/immortalwrt-mt798x-6.6](https://github.com/padavanonly/immortalwrt-mt798x-6.6) - ImmortalWrt 24.10（Linux内核6.6）固件源码

- 基于中国移动RAX3000M路由器（eMMC存储版本）固件工作流修改为Globitel BT-R320-EMMC路由器，自用编译工作流，可自定义插件和优化功能。

## U-boot

- 本编译固件推荐使用 lgs2007m 大佬的U-boot，https://github.com/lgs2007m/Actions-OpenWrt/releases/tag/Router-Flashing-Files

## 注意事项

- 如果遇到编译错误，建议先检查配置文件是否正确，或者尝试清理编译缓存
  - 1.在工作流里手动删除编译缓存
  - 2.在build-openwrt.yml工作流文件代码里的环境变量env的CACHE_VERSION缓存版本号进行递增以控制缓存不被命中。

## 准备工作

### 1. 必要条件

- GitHub账号
- 基本的Git操作知识
- 了解OpenWrt固件编译的基本概念

### 2. 配置GitHub

#### 获取REPO_TOKEN

1. 登录GitHub账号，点击右上角头像，选择`Settings`
2. 在左侧菜单选择`Developer settings` -> `Personal access tokens` -> `Tokens (classic)`
3. 点击`Generate new token`按钮
4. 填写`Note`（如"ImmortalWrt Build Token"）
5. 选择权限：
   - `repo` - 全选
   - `workflow`
6. 点击`Generate token`按钮
7. **复制并保存生成的Token**（离开页面后将无法再次查看）

#### Fork仓库

1. 访问[本仓库](https://github.com/EasongChung/Actions-immortalwrt-bt-r320-24.10-237)
2. 点击右上角的`Fork`按钮，将仓库复制到您的GitHub账号


## 使用教程

### GitHub Actions 自动编译

#### 修改配置文件

1. 修改`.config`文件（固件编译配置）：
   - 可以直接编辑现有`.config`文件
   - 或者上传您自己生成的配置文件

2. 修改自定义脚本：
   - `diy-part1.sh`：更新feeds之前的自定义操作（添加软件源等）
   - `diy-part2.sh`：更新feeds之后的自定义操作（修改默认设置、主题等）

#### 开始编译

1. 进入仓库的`Actions`页面
2. 选择`Build OpenWrt` workflow
3. 点击`Run workflow`按钮，选择好配置
   - `编译方式`：选择编译环境
      - `Host`：在本地环境编译
      - `Docker`：在Docker容器中编译，已集成依赖和固件源码
   - LAN IP：设置路由器LAN口IP地址
   - 默认主题：选择默认的Web管理界面主题
   - 主机名：设置路由器的主机名
   - WIFI名称：设置路由器的WIFI名称，可分别设置2.4G和5G的WIFI名称
   - 5G高功率25db：是否启用WIFI5G高功率25db
   - SSH：是否通过SSH连接到Actions
   - 缓存加速编译：是否启用缓存加速编译
   - 清理编译：是否在编译前清理旧的编译文件
4. 点击`Run workflow`开始编译过程
5. 编译过程通常需要1-3小时，取决于配置的复杂度，启用缓存加速编译在首次编译成功后，下次编译对编译速度会有很大的提升。

#### 下载固件

1. 编译完成后，在Actions页面找到已完成的Workflow运行
2. 点击进入详情页面
3. 在页面底部的`Artifacts`部分下载编译好的固件

## 自定义配置说明

### 配置文件说明

- `.config`：包含固件编译的所有配置选项，决定了编译哪些软件包和功能
- `diy-part1.sh`：添加第三方feed源和包的脚本
  ```bash
  # 示例：添加istore和nas相关源
  add_feed "istore" "https://github.com/linkease/istore.git;main"
  add_feed "nas_luci" "https://github.com/linkease/nas-packages-luci.git;main"
  ```
- `diy-part2.sh`：更新golang包
  ```bash
  # 示例：更新golang包
  rm -rf feeds/packages/lang/golang
  mkdir -p feeds/packages/lang/golang
  git clone https://github.com/sbwml/packages_lang_golang -b 24.x feeds/packages/lang/golang
  ```

### 自定义.config文件

如果您想完全自定义固件配置，可以：

1. 基于现有`.config`文件修改
2. 使用`make menuconfig`交互式配置（本地环境）
3. 从[padavanonly/immortalwrt-mt798x-6.6](https://github.com/padavanonly/immortalwrt-mt798x-6.6)获取默认配置


### 刷写固件
- 1. 通过U-boot刷机，首次刷机推荐使用U-boot方式进行
- 2. 通过Web界面刷机，更新固件推荐方式
   - 1. 登录路由器Web管理界面（默认：`http://192.168.1.1`）
   - 2. 进入`系统` -> `备份/升级`
   - 3. 选择编译好的固件文件，点击`刷写固件`按钮
   - 4. 等待刷机完成并自动重启
>提示1：*刷机前请备份好路由器数据，刷机过程中请不要断开电源，刷机完成后请重新登录路由器Web管理界面。*
---
>提示2：*如果刷好固件使用有任何问题，备份好路由器数据后请尝试恢复出厂设置或者通过U-boot方式刷机，有可能是因为原先路由器数据产生冲突导致路由器异常！*

## 项目结构

```
├── .github/workflows/   # GitHub Actions工作流配置
│   ├── build-image.yml  # 构建镜像工作流
│   ├── build-openwrt.yml # 构建OpenWrt固件工作流
│   └── update-checker.yml # 更新检查工作流
├── Dockerfile           # Docker镜像配置
├── .config              # OpenWrt编译配置文件
├── build-openwrt.sh     # 主要构建脚本
├── diy-part1.sh         # 自定义脚本（更新feeds前）
├── diy-part2.sh         # 自定义脚本（更新feeds后）
└── README.md            # 项目说明文档
```
## 引用项目

- [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt) - GitHub Actions在线编译模板
- [padavanonly/immortalwrt-mt798x-6.6](https://github.com/padavanonly/immortalwrt-mt798x-6.6) - ImmortalWrt固件源码
- [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) - 开源路由器固件项目
- [Microsoft Azure](https://azure.microsoft.com) - 提供GitHub Actions运行环境
- [GitHub Actions](https://github.com/features/actions) - 自动化工作流平台

## 许可证

[MIT](https://github.com/P3TERX/Actions-OpenWrt/blob/main/LICENSE) © [项目维护者]
