#!/bin/bash
#========================================================================================================================
# https://github.com/ophub/amlogic-s9xxx-openwrt
# Description: Automatically Build OpenWrt
# Function: Diy script (After Update feeds, Modify the default IP, hostname, theme, add/remove software packages, etc.)
# Source code repository: https://github.com/immortalwrt/immortalwrt / Branch: master
#========================================================================================================================

# ------------------------------- Main source started -------------------------------
#
# Add the default password for the 'root' user（Change the empty password to 'password'）
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow

# Set etc/openwrt_release
sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION='R$(date +%Y.%m.%d)'|g" package/base-files/files/etc/openwrt_release
echo "DISTRIB_SOURCECODE='immortalwrt'" >>package/base-files/files/etc/openwrt_release

# Modify default IP（FROM 192.168.1.1 CHANGE TO 192.168.31.4）
# sed -i 's/192.168.1.1/192.168.31.4/g' package/base-files/files/bin/config_generate
#
# ------------------------------- Main source ends -------------------------------

# ------------------------------- Other started -------------------------------
#
# Add luci-app-amlogic
svn co https://github.com/ophub/luci-app-amlogic/trunk/luci-app-amlogic package/luci-app-amlogic

# Apply patch
# git apply ../config/patches/{0001*,0002*}.patch --directory=feeds/luci
#
# hostname
sed -i "s/ImmortalWrt/TRW/g" package/base-files/files/bin/config_generate

# ssid
sed -i "s/ImmortalWrt/TRW/g" package/kernel/mac80211/files/lib/wifi/mac80211.sh
# php7 max_size
sed -i -e "s/upload_max_filesize = 2M/upload_max_filesize = 1024M/g" -e "s/post_max_size = 8M/post_max_size = 1024M/g" feeds/packages/lang/php7/files/php.ini

# clash-core
mkdir -p files/etc/openclash/core
CLASH_DEV_URL=$(curl -fsSL https://api.github.com/repos/vernesong/OpenClash/contents/core-lateset/dev | grep download_url | grep clash-linux-arm64 | awk -F '"' '{print $4}')
CLASH_TUN_URL=$(curl -fsSL https://api.github.com/repos/vernesong/OpenClash/contents/core-lateset/premium | grep download_url | grep clash-linux-arm64 | awk -F '"' '{print $4}')
CLASH_META_URL=$(curl -fsSL https://api.github.com/repos/vernesong/OpenClash/contents/core-lateset/meta | grep download_url | grep clash-linux-arm64 | awk -F '"' '{print $4}')
GEOIP_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
GEOSITE_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
wget -qO- $CLASH_DEV_URL | tar xOvz > files/etc/openclash/core/clash
wget -qO- $CLASH_TUN_URL | gunzip -c > files/etc/openclash/core/clash_tun
wget -qO- $CLASH_META_URL | tar xOvz > files/etc/openclash/core/clash_meta
wget -qO- $GEOIP_URL > files/etc/openclash/GeoIP.dat
wget -qO- $GEOSITE_URL > files/etc/openclash/GeoSite.dat
chmod +x files/etc/openclash/core/clash*
# speedtest
mkdir -p files/bin
wget -qO- https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-aarch64.tgz | tar xOvz > files/bin/speedtest
chmod +x files/bin/speedtest
# Set etc/openwrt_release
sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION='R$(date +%Y.%m.%d)'|g" package/base-files/files/etc/openwrt_release
echo "DISTRIB_SOURCECODE='openwrt'" >>package/base-files/files/etc/openwrt_release
sed -i 's/ImmortalWrt/OpenWrt/g' include/version.mk
sed -i 's/ImmortalWrt/OpenWrt/g' config/Config-images.in
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/image-config.in
# timezone
sed -i -e "s/CST-8/WIB-7/g" -e "s/Shanghai/Jakarta/g" package/emortal/default-settings/files/99-default-settings-chinese
sed -i 's/UTC/WIB-7/g' package/base-files/files/bin/config_generate

# fix default theme
sed -i "s/+luci-theme-bootstrap //" feeds/luci/collections/luci/Makefile

# interface
sed -i "9 i\uci set network.wan1=interface\nuci set network.wan1.proto='dhcp'\nuci set network.wan1.device='eth1'\nuci set network.wan2=interface\nuci set network.wan2.proto='dhcp'\nuci set network.wan2.device='wwan0'\nuci set network.wan3=interface\nuci set network.wan3.proto='dhcp'\nuci set network.wan3.device='usb0'\nuci commit network\n" package/emortal/default-settings/files/99-default-settings
sed -i "20 i\uci add_list firewall.@zone[1].network='wan1'\nuci add_list firewall.@zone[1].network='wan2'\nuci add_list firewall.@zone[1].network='wan3'\nuci commit firewall\n" package/emortal/default-settings/files/99-default-settings
# oh-my-zsh
mkdir -p files/root
pushd files/root
git clone https://github.com/robbyrussell/oh-my-zsh ./.oh-my-zsh
git clone https://github.com/zsh-users/zsh-autosuggestions ./.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ./.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions ./.oh-my-zsh/custom/plugins/zsh-completions
cp $GITHUB_WORKSPACE/include/common-files/patches/zsh/.zshrc .
cp $GITHUB_WORKSPACE/include/common-files/patches/zsh/example.zsh ./.oh-my-zsh/custom/example.zsh
popd
# ------------------------------- Other ends -------------------------------

