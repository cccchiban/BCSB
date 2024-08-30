#!/bin/bash

export LANG=en_US.UTF-8

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"

red(){
    echo -e "${RED}${1}${PLAIN}"
}

green(){
    echo -e "${GREEN}${1}${PLAIN}"
}

yellow(){
    echo -e "${YELLOW}${1}${PLAIN}"
}

REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "fedora")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Fedora")
PACKAGE_UPDATE=("apt-get update" "apt-get update" "yum -y update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "yum -y install")
PACKAGE_REMOVE=("apt -y remove" "apt -y remove" "yum -y remove" "yum -y remove" "yum -y remove")
PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "yum -y autoremove" "yum -y autoremove")

[[ $EUID -ne 0 ]] && red "注意: 请在root用户下运行脚本" && exit 1

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
    SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
    [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
done

[[ -z $SYSTEM ]] && red "目前暂不支持你的VPS的操作系统！" && exit 1

archAffix(){
    case "$(uname -m)" in
        x86_64 | amd64 ) echo 'amd64' ;;
        armv8 | arm64 | aarch64 ) echo 'arm64' ;;
        * ) red "不支持的CPU架构!" && exit 1 ;;
    esac
}

check_ip() {
    ipv4=$(curl -s4m8 ip.p3terx.com | sed -n 1p)
    ipv6=$(curl -s6m8 ip.p3terx.com | sed -n 1p)
}

inst_mita(){
    if [[ $SYSTEM != "CentOS" ]]; then
        ${PACKAGE_UPDATE[int]}
    fi
    ${PACKAGE_INSTALL[int]} curl wget sudo

    last_version=$(curl -s https://data.jsdelivr.com/v1/package/gh/enfein/mieru | sed -n 4p | tr -d ',"' | awk '{print $1}')
    if [[ $SYSTEM == "CentOS" ]]; then
        arch=$(archAffix)
        wget -N https://github.com/enfein/mieru/releases/download/v"$last_version"/mita-"$last_version"-1."$arch".rpm
        rpm -ivh mita-$last_version-1.$arch.rpm
        rm -f mita-$last_version-1.$arch.rpm
    else
        arch=$(archAffix)
        wget -N https://github.com/enfein/mieru/releases/download/v"$last_version"/mita_"$last_version"_$arch.deb
        dpkg -i mita_"$last_version"_$arch.deb
        rm -f mita_"$last_version"_$arch.deb
    fi

    edit_conf
}

unst_mita(){
    mita stop
    ${PACKAGE_UNINSTALL[int]} mita
    green "mieru 已彻底卸载完成"
}

mita_switch(){
    yellow "请选择你需要的操作："
    echo ""
    echo -e " ${GREEN}1.${PLAIN} 启动 mieru"
    echo -e " ${GREEN}2.${PLAIN} 关闭 mieru"
    echo -e " ${GREEN}3.${PLAIN} 重启 mieru"
    echo ""
    read -rp "请输入选项 [0-3]: " switchInput
    case $switchInput in
        1 ) mita start ;;
        2 ) mita stop ;;
        3 ) mita stop && mita start ;;
        * ) exit 1 ;;
    esac
}

edit_conf(){
    mita stop

    read -p "设置 mieru 端口 [1-65535]（回车则随机分配端口）：" port
    [[ -z $port ]] && port=$(shuf -i 2000-65535 -n 1)
    until [[ -z $(ss -ntlp | awk '{print $4}' | sed 's/.*://g' | grep -w "$port") ]]; do
        if [[ -n $(ss -ntlp | awk '{print $4}' | sed 's/.*://g' | grep -w "$port") ]]; then
            red "$port 端口已经被其他程序占用，请更换端口重试！"
            read -p "设置 mieru 端口 [1-65535]（回车则随机分配端口）：" port
            [[ -z $port ]] && port=$(shuf -i 2000-65535 -n 1)
        fi
    done
    yellow "将在 mieru 代理节点使用的端口为：$port"

    read -rp "请输入 mieru 代理认证用户名 [留空随机生成]：" user_name
    [[ -z $user_name ]] && user_name=$(date +%s%N | md5sum | cut -c 1-8)
    yellow "将在 mieru 代理节点使用的用户名为：$user_name"

    read -rp "请输入 mieru 代理认证密码 [留空随机生成]：" auth_pass
    [[ -z $auth_pass ]] && auth_pass=$(date +%s%N | md5sum | cut -c 1-8)
    yellow "将在 mieru 代理节点使用的密码为：$auth_pass"

    yellow "请选择协议类型："
    echo ""
    echo -e " ${GREEN}1.${PLAIN} UDP"
    echo -e " ${GREEN}2.${PLAIN} TCP"
    echo ""
    read -rp "请输入选项 [1-2]: " protocol_choice
    case $protocol_choice in
        1 ) protocol="UDP" ;;
        2 ) protocol="TCP" ;;
        * ) protocol="UDP" ;;
    esac
    yellow "将在 mieru 代理节点使用的协议为：$protocol"

    yellow "正在检测并设置 MTU 最佳值, 请稍等..."
    check_ip
    MTUy=1500
    MTUc=10
    if [[ -n ${ipv6} && -z ${ipv4} ]]; then
        ping='ping6'
        IP1='2606:4700:4700::1001'
        IP2='2001:4860:4860::8888'
    else
        ping='ping'
        IP1='1.1.1.1'
        IP2='8.8.8.8'
    fi
    while true; do
        if ${ping} -c1 -W1 -s$((${MTUy} - 28)) -Mdo ${IP1} >/dev/null 2>&1 || ${ping} -c1 -W1 -s$((${MTUy} - 28)) -Mdo ${IP2} >/dev/null 2>&1; then
            MTUc=1
            MTUy=$((${MTUy} + ${MTUc}))
        else
            MTUy=$((${MTUy} - ${MTUc}))
            if [[ ${MTUc} = 1 ]]; then
                break
            fi
        fi
        if [[ ${MTUy} -le 1360 ]]; then
            MTUy='1360'
            break
        fi
    done
    # 将 MTU 最佳值放置至 MTU 变量中备用
    MTU=$((${MTUy} - 80))
    green "MTU 最佳值 = $MTU 已设置完成!"

    tee /etc/mita/mita_config.json <<-EOF
{
    "port": "${port}",
    "protocol": "${protocol}",
    "users": [
        {
            "username": "${user_name}",
            "password": "${auth_pass}"
        }
    ],
    "system": {
        "network": {
            "auto_mtu": ${MTU}
        }
    }
}
EOF

    mita start
    green "mieru 配置已完成!"
}

start_menu(){
    clear
    green " 1. 安装 mieru"
    green " 2. 卸载 mieru"
    green " 3. 启动/关闭/重启 mieru"
    yellow " 0. 退出"
    echo
    read -rp "请输入数字: " num
    case "$num" in
        1)
            inst_mita
            ;;
        2)
            unst_mita
            ;;
        3)
            mita_switch
            ;;
        0)
            exit 0
            ;;
        *)
            clear
            red "请输入正确的数字"
            sleep 1s
            start_menu
            ;;
    esac
}

start_menu
