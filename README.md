# openwrt-rom
自动打包openwrt image, 仅含 x86, x64, K2(a), K2P(a). 4种型号.
 
# 状态
https://github.com/tick-guo/openwrt-rom

![workflow](https://github.com/tick-guo/openwrt-rom/actions/workflows/openwrt21.02.yml/badge.svg)
![GitHub all releases](https://img.shields.io/github/downloads/tick-guo/openwrt-rom/total?label=下载量)
![GitHub repo size](https://img.shields.io/github/repo-size/tick-guo/openwrt-rom?label=库大小)

![](https://img.shields.io/github/last-commit/tick-guo/openwrt-rom?label=最近提交)
![GitHub Release Date](https://img.shields.io/github/release-date/tick-guo/openwrt-rom?label=最新发布)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/tick-guo/openwrt-rom?label=最新版本)](https://github.com/tick-guo/openwrt-rom/releases)

# 特点
 1. 集成中文
 2. 很少的自定义包
 3. 每日构建,追新
 4. 有21.02稳定版(更新少,官方只提交重要补丁)和最新开发版(官方修改更新多)两个版本
 5. 安装后,可以浏览器上直接在线更新官方源的包

# 来源说明
```
预编译包路径来自版本库文件的配置
/include/version.mk
https://git.openwrt.org/?p=openwrt/openwrt.git;a=blob;f=include/version.mk;h=ca6a15bdbff27d94941a1cdd92a894332f0384bd;hb=2853b6d652b7edfe9e8d034503705f6d74d52a52
在22.03 分支上,在持续更新,如果有22.03.x的小版本会包含到这个分支  https://downloads.openwrt.org/releases/22.03-SNAPSHOT
在tag上的则固定版本不会再提交 https://downloads.openwrt.org/releases/22.03.0
master分支则比22.03分支还新, 在持续更新 https://downloads.openwrt.org/snapshots
```
 
