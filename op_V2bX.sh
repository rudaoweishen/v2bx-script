#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 必须使用root用户运行此脚本！\n" && exit 1

# check os
if [[ -f /etc/openwrt_release ]]; then
    release="openwrt"
else
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n" && exit 1
fi

# 检查系统是否有 IPv6 地址
check_ipv6_support() {
    if ip -6 addr | grep -q "inet6"; then
        echo "1"  # 支持 IPv6
    else
        echo "0"  # 不支持 IPv6
    fi
}

confirm() {
    read -rp "$1 [y/n]: " temp
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/rudaoweishen/V2bX-script/master/openwrt_install.sh)
    if [[ $? == 0 ]]; then
        start
    fi
}

update() {
    echo -n "输入指定版本(默认最新版): " 
    read version
    bash <(curl -Ls https://raw.githubusercontent.com/rudaoweishen/V2bX-script/master/openwrt_install.sh) $version
    if [[ $? == 0 ]]; then
        echo -e "${green}更新完成${plain}"
        exit
    fi
}

uninstall() {
    confirm "确定要卸载 V2bX 吗?" "n"
    if [[ $? != 0 ]]; then
        return 0
    fi
    /etc/init.d/v2bx stop
    rm -rf /etc/V2bX
    echo -e "${green}卸载成功${plain}"
}

start() {
    /etc/init.d/v2bx start
    echo -e "${green}V2bX 启动成功${plain}"
}

stop() {
    /etc/init.d/v2bx stop
    echo -e "${green}V2bX 停止成功${plain}"
}

restart() {
    /etc/init.d/v2bx restart
    echo -e "${green}V2bX 重启成功${plain}"
}

status() {
    /etc/init.d/v2bx status
}

show_log() {
    journalctl -u v2bx.service -e --no-pager -f
}

config() {
    echo "V2bX配置文件路径: /etc/V2bX/config.json"
    vi /etc/V2bX/config.json
    echo -e "${green}配置修改完毕，正在重启 V2bX...${plain}"
    restart
}

show_menu() {
    echo -e "
  ${green}V2bX 后端管理脚本，${plain}${red}适用于 OpenWRT${plain}
--- https://github.com/rudaoweishen/V2bX ---
  ${green}0.${plain} 修改配置
  ${green}1.${plain} 安装 V2bX
  ${green}2.${plain} 更新 V2bX
  ${green}3.${plain} 卸载 V2bX
  ${green}4.${plain} 启动 V2bX
  ${green}5.${plain} 停止 V2bX
  ${green}6.${plain} 重启 V2bX
  ${green}7.${plain} 查看 V2bX 状态
  ${green}8.${plain} 查看 V2B X 日志
  ${green}9.${plain} 退出脚本
 "
    read -rp "请输入选择 [0-9]: " num

    case "${num}" in
        0) config ;;
        1) install ;;
        2) update ;;
        3) uninstall ;;
        4) start ;;
        5) stop ;;
        6) restart ;;
        7) status ;;
        8) show_log ;;
        9) exit ;;
        *) echo -e "${red}请输入正确的数字 [0-9]${plain}" ;;
    esac
}

# 启动菜单
show_menu