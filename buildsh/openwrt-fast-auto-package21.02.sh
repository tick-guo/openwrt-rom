#!/bin/bash

alias ll='ls -l --color=auto'

sudo mkdir -m 777 -p /opt/openwrt/image
if [ ! -d /opt/openwrt ];then
  echo 目录创建失败:/opt/openwrt
  exit 1
fi

echo > /opt/openwrt/image/readme.txt
echo 开始编译时间 >> /opt/openwrt/image/readme.txt
TZ='Asia/Shanghai'  date  '+%Y-%m-%d %H:%M:%S' >> /opt/openwrt/image/readme.txt
		
function create_custom()
{
#版本号,用日期
#VERSION=$(TZ='Asia/Shanghai' date +%Y%m%d.%H%M)
valtime=$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M')
MYINFO="'编译日期 $valtime by tick-guo(https://github.com/tick-guo/openwrt-rom),恩山论坛(https://www.right.com.cn/forum/home.php?mod=space&uid=715099&do=thread&view=me&from=space)'"
echo $MYINFO
#自定义lan ip, 设置中国时区
mkdir -p files/etc/uci-defaults
pushd files/etc/uci-defaults

cat << EOF > 01_tick_custom
#!/bin/sh
uci -q set system.@system[0].notes=${MYINFO}
uci -q commit 
EOF
chmod 755 01_tick_custom

cat << "EOF" > 16_tick_custom
if [ "$(uci -q get system.@tick[0].init)" = "true" ];then
  echo upgrade
  exit 0
else
  echo clean install
fi

uci -q batch << EOI
set network.lan.ipaddr='192.168.5.1'
commit network
set system.@system[0].zonename='Asia/Shanghai'
set system.@system[0].timezone='CST-8'
commit system

#屏蔽掉,用默认值
#lan ipv6 relay
	#del dhcp.lan.ra_slaac
	#set dhcp.lan.ra='relay'
	#del dhcp.lan.ra_flags
	#add_list dhcp.lan.ra_flags='none'
	#set dhcp.lan.dhcpv6='relay'
	#set dhcp.lan.ndp='relay'
#wan ipv6 relay master
	#set dhcp.wan.master='1'
	#set dhcp.wan.ra='relay'
	#add_list dhcp.wan.ra_flags='none'
	#set dhcp.wan.dhcpv6='relay'
	#set dhcp.wan.ndp='relay'
	#commit dhcp

add system tick
commit 
set system.@tick[0].init='true'
commit
EOI
echo end of tick_custom
exit 0
EOF
chmod 755 16_tick_custom

popd

}

#官方默认包
val_office="\
 cgi-io \
 libiwinfo-lua \
 liblua \
 liblucihttp \
 liblucihttp-lua \
 libubus-lua \
 lua \
 luci \
 luci-app-firewall \
 luci-app-opkg \
 luci-base \
 luci-lib-base \
 luci-lib-ip \
 luci-lib-jsonc \
 luci-lib-nixio \
 luci-mod-admin-full \
 luci-mod-network \
 luci-mod-status \
 luci-mod-system \
 luci-proto-ipv6 \
 luci-proto-ppp \
 luci-ssl \
 luci-theme-bootstrap \
 px5g-wolfssl \
 rpcd \
 rpcd-mod-file \
 rpcd-mod-iwinfo \
 rpcd-mod-luci \
 rpcd-mod-rrdns \
 uhttpd \
 uhttpd-mod-ubus \
 "
 
#公用
#自定义附加包,用中文语言文件,自动引入原包
#ddns依赖wget-ssl,curl,drill
#luci-i18n-ttyd-zh-cn https有问题
#luci-i18n-base-en  这个包没有,去掉
val_more="$val_office  \
 \

luci-i18n-base-zh-cn \
luci-i18n-ddns-zh-cn wget-ssl curl drill \
luci-i18n-firewall-zh-cn \
luci-i18n-opkg-zh-cn \
luci-i18n-statistics-zh-cn \
luci-i18n-upnp-zh-cn \
luci-i18n-wifischedule-zh-cn \
luci-i18n-wol-zh-cn \
luci-i18n-uhttpd-zh-cn \
"

function build64(){
cd /opt/openwrt

mkdir x64
cd x64
pwd

ls *.xz
if [ $? != 0 ];then
  wget https://downloads.openwrt.org/releases/22.03-SNAPSHOT/targets/x86/64/openwrt-imagebuilder-22.03-SNAPSHOT-x86-64.Linux-x86_64.tar.xz > /dev/null

  tar -xf openwrt-imagebuilder-22.03-SNAPSHOT-x86-64.Linux-x86_64.tar.xz
fi

cd openwrt-imagebuilder-22.03-SNAPSHOT-x86-64.Linux-x86_64

#差异包
val_base="\
 libiwinfo \
 libiwinfo-data \
 "

make info | grep "Current Revision"

create_custom

make image PROFILE=generic FILES="files" PACKAGES="$val_base $val_more"
cd bin/targets/x86/64
ll
mv -f *squashfs-combined.img.gz /opt/openwrt/image/

}


#64用于现代PC硬件（大约在2007年以后的产品），它是为具有64位功能的计算机而构建的，并支持现代CPU功能。除非有充分的理由，否则请选择此选项。
#Generic  仅适用于32位硬件（旧硬件或某些Atom处理器），应为i586 Linux体系结构，将在Pentium 4及更高版本上运行。仅当您的硬件无法运行64位版本时才使用此功能。
#Legacy用于奔腾4之前的非常旧的PC硬件，在Linux体系结构支持中称为i386。它会错过许多现代硬件上想要/需要的功能，例如多核支持以及对超过1GB RAM的支持，但实际上会在较旧的硬件上运行，而其他版本则不会。
#Geode是为Geode SoC定制的自定义旧版目标，Geode SoC仍在许多（老化的）网络设备中使用，例如PCEngines的较旧Alix板
#Combined-squashfs.img.gz该磁盘映像使用传统的OpenWrt布局，一个squashfs只读根文件系统和一个读写分区，在其中存储您安装的设置和软件包。由于此映像的组装方式，您只有230 兆MB的空间来存储其他程序包和配置，而Extroot不起作用。
#Combined-ext4.img.gz此磁盘映像使用单个读写ext4分区，没有只读squashfs根文件系统，因此可以扩大分区。故障安全模式或出厂重置等功能将不可用，因为它们需要只读的squashfs分区才能起作用。
function build32(){
cd /opt/openwrt

mkdir x32
cd x32
pwd

ls *.xz
if [ $? != 0 ];then
 
  wget https://downloads.openwrt.org/releases/22.03-SNAPSHOT/targets/x86/generic/openwrt-imagebuilder-22.03-SNAPSHOT-x86-generic.Linux-x86_64.tar.xz > /dev/null

  tar -xf openwrt-imagebuilder-22.03-SNAPSHOT-x86-generic.Linux-x86_64.tar.xz
fi

cd openwrt-imagebuilder-22.03-SNAPSHOT-x86-generic.Linux-x86_64

##差异包
val_base="\
 libiwinfo \
 libiwinfo-data \
 "

make info 

create_custom

make image PROFILE=generic FILES="files" PACKAGES="$val_base $val_more"
cd bin/targets/x86/generic
ll
mv -f *squashfs-combined.img.gz /opt/openwrt/image/

}

function buildk2(){
cd /opt/openwrt

mkdir k2
cd k2
pwd

ls *.xz
if [ $? != 0 ];then

  wget https://downloads.openwrt.org/releases/22.03-SNAPSHOT/targets/ramips/mt7620/openwrt-imagebuilder-22.03-SNAPSHOT-ramips-mt7620.Linux-x86_64.tar.xz > /dev/null

  tar -xf openwrt-imagebuilder-22.03-SNAPSHOT-ramips-mt7620.Linux-x86_64.tar.xz
fi

cd openwrt-imagebuilder-22.03-SNAPSHOT-ramips-mt7620.Linux-x86_64

##差异包
val_base="\
 "

make info 

create_custom

make image PROFILE=phicomm_psg1218a FILES="files" PACKAGES="$val_base $val_more"
cd bin/targets/ramips/mt7620
ll
mv -f *squashfs-sysupgrade.bin /opt/openwrt/image/

}

function buildk2p(){
cd /opt/openwrt

mkdir k2p
cd k2p
pwd

ls *.xz
if [ $? != 0 ];then

  wget https://downloads.openwrt.org/releases/22.03-SNAPSHOT/targets/ramips/mt7621/openwrt-imagebuilder-22.03-SNAPSHOT-ramips-mt7621.Linux-x86_64.tar.xz > /dev/null

  tar -xf openwrt-imagebuilder-22.03-SNAPSHOT-ramips-mt7621.Linux-x86_64.tar.xz
fi

cd openwrt-imagebuilder-22.03-SNAPSHOT-ramips-mt7621.Linux-x86_64

##差异包
val_base="\
 "

make info 

create_custom

make image PROFILE=phicomm_k2p FILES="files" PACKAGES="$val_base $val_more"
cd bin/targets/ramips/mt7621
ll
mv -f *squashfs-sysupgrade.bin /opt/openwrt/image/

}

#============================================================dev
function build64dev(){
cd /opt/openwrt

mkdir x64dev
cd x64dev
pwd

ls *.xz
if [ $? != 0 ];then
  
  wget  https://downloads.openwrt.org/snapshots/targets/x86/64/openwrt-imagebuilder-x86-64.Linux-x86_64.tar.xz

  tar -xf openwrt-imagebuilder-x86-64.Linux-x86_64.tar.xz
fi

cd openwrt-imagebuilder-x86-64.Linux-x86_64 

#差异包
val_base="\
 libiwinfo \
 libiwinfo-data \
 "

make info | grep "Current Revision"

create_custom

make image PROFILE=generic FILES="files" PACKAGES="$val_base $val_more"
cd bin/targets/x86/64
ll
mv -f *squashfs-combined.img.gz /opt/openwrt/image/

}

function build32dev(){
cd /opt/openwrt

mkdir x32dev
cd x32dev
pwd

ls *.xz
if [ $? != 0 ];then
  wget https://downloads.openwrt.org/snapshots/targets/x86/generic/openwrt-imagebuilder-x86-generic.Linux-x86_64.tar.xz > /dev/null

  tar -xf openwrt-imagebuilder-x86-generic.Linux-x86_64.tar.xz
fi

cd openwrt-imagebuilder-x86-generic.Linux-x86_64

##差异包
val_base="\
 libiwinfo \
 libiwinfo-data \
 "

make info 

create_custom

make image PROFILE=generic FILES="files" PACKAGES="$val_base $val_more"
cd bin/targets/x86/generic
#openwrt-21.02-snapshot-r16302-9b258f220f-x86-generic-generic-squashfs-combined.img.gz
#openwrt-x86-generic-generic-squashfs-combined.img.gz
ll
mv -f *squashfs-combined.img.gz /opt/openwrt/image/

}

function buildk2dev(){
cd /opt/openwrt

mkdir k2dev
cd k2dev
pwd

ls *.xz
if [ $? != 0 ];then
 
  wget https://downloads.openwrt.org/snapshots/targets/ramips/mt7620/openwrt-imagebuilder-ramips-mt7620.Linux-x86_64.tar.xz > /dev/null

  tar -xf openwrt-imagebuilder-ramips-mt7620.Linux-x86_64.tar.xz
fi

cd openwrt-imagebuilder-ramips-mt7620.Linux-x86_64

##差异包
val_base="\
 "

make info 

create_custom

make image PROFILE=phicomm_k2-v22.4 FILES="files" PACKAGES="$val_base $val_more"
cd bin/targets/ramips/mt7620
#openwrt-ramips-mt7620-phicomm_k2-v22.4-squashfs-sysupgrade.bin
ll
mv -f *squashfs-sysupgrade.bin /opt/openwrt/image/

}

function buildk2pdev(){
cd /opt/openwrt

mkdir k2pdev
cd k2pdev
pwd

ls *.xz
if [ $? != 0 ];then

  wget https://downloads.openwrt.org/snapshots/targets/ramips/mt7621/openwrt-imagebuilder-ramips-mt7621.Linux-x86_64.tar.xz > /dev/null

  tar -xf openwrt-imagebuilder-ramips-mt7621.Linux-x86_64.tar.xz
fi

cd openwrt-imagebuilder-ramips-mt7621.Linux-x86_64

##差异包
val_base="\
 "

make info 

create_custom

make image PROFILE=phicomm_k2p FILES="files" PACKAGES="$val_base $val_more"
cd bin/targets/ramips/mt7621
#openwrt-ramips-mt7621-phicomm_k2p-squashfs-sysupgrade.bin
ll
mv -f *squashfs-sysupgrade.bin /opt/openwrt/image/

}


function getinfo(){
cd /opt/openwrt/image/

echo 完成编译时间 >> readme.txt
TZ='Asia/Shanghai'  date  '+%Y-%m-%d %H:%M:%S' >> readme.txt

echo >> readme.txt
echo md5校验值 >> readme.txt
md5sum *.bin >> readme.txt
md5sum *.gz >> readme.txt

cat << "EOF" >> readme.txt

# 附件会生成8个升级包

1. 名字中有21.02的是**稳定版**,偶尔会有更新
2. 没有21.02的是**最新开发版**,每天都会有不少更新
3. 安装后可以从路由器内从软件包内更新,不用每次刷整包


EOF

}

#最新开发版,在master上
buildk2pdev
buildk2dev
build32dev
build64dev
#22.03.X 稳定版
buildk2p
buildk2
build32
build64

getinfo

echo ========== all end ==========
