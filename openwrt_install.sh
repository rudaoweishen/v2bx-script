#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

# check os
if [[ ! -f /etc/openwrt_release ]]; then
    echo -e "${red}未检测到 OpenWrt 系统，请联系脚本作者！${plain}\n" && exit 1
fi

# check architecture
arch=$(uname -m)
if [[ $arch == "aarch64" ]]; then
    arch="arm64-v8a"
elif [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="64"
else
    echo -e "${red}不支持的架构: ${arch}${plain}"
    exit 1
fi

install_base() {
    opkg update >/dev/null 2>&1
    opkg install wget curl unzip tar socat ca-certificates >/dev/null 2>&1
}

install_V2bX() {
    if [[ -e /usr/local/V2bX/ ]]; then
        rm -rf /usr/local/V2bX/
    fi

    mkdir /usr/local/V2bX/ -p
    cd /usr/local/V2bX/

    last_version=$(curl -Ls "https://api.github.com/repos/wyx2685/V2bX/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ ! -n "$last_version" ]]; then
        echo -e "${red}检测 V2bX 版本失败，可能是超出 Github API 限制，请稍后再试${plain}"
        exit 1
    fi
    echo -e "检测到 V2bX 最新版本：${last_version}，开始安装"
    
    wget --no-check-certificate -N --progress=bar -O /usr/local/V2bX/V2bX-linux.zip https://github.com/wyx2685/V2bX/releases/download/${last_version}/V2bX-linux-${arch}.zip
    if [[ $? -ne 0 ]]; then
        echo -e "${red}下载 V2bX 失败，请确保你的服务器能够下载 Github 的文件${plain}"
        exit 1
    fi

    unzip V2bX-linux.zip
    rm V2bX-linux.zip -f
    chmod +x V2bX
    mkdir /etc/V2bX/ -p
    cp geoip.dat /etc/V2bX/
    cp geosite.dat /etc/V2bX/

    cp /usr/local/V2bX/V2bX /etc/init.d/V2bX
    chmod +x /etc/init.d/V2bX
    echo -e "${green}V2bX ${last_version}${plain} 安装完成，您可以使用 service V2bX start 启动服务"

    if [[ ! -f /etc/V2bX/config.json ]]; then
        cp config.json /etc/V2bX/
        echo -e ""
        echo -e "全新安装，请先参看教程：https://v2bx.v-50.me/，配置必要的内容"
    else
        service V2bX start
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}V2bX 启动成功${plain}"
        else
            echo -e "${red}V2bX 启动失败，请检查日志${plain}"
        fi
    fi

    cp dns.json /etc/V2bX/
    cp route.json /etc/V2bX/
    cp custom_outbound.json /etc/V2bX/
    cp custom_inbound.json /etc/V2bX/
    curl -o /usr/bin/V2bX -Ls https://raw.githubusercontent.com/wyx2685/V2bX-script/master/V2bX.sh
    chmod +x /usr/bin/V2bX
    ln -s /usr/bin/V2bX /usr/bin/v2bx
}

echo -e "${green}开始安装 V2bX${plain}"
install_base
install_V2bX