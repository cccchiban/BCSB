#!/bin/bash

if [ "$(id -u)" -ne 0; then
    echo "Please run this script as root."
    exit 1
fi

install_if_missing() {
    if ! type -P "$1" >/dev/null 2>&1; then
        echo "$1 is not installed, installing..."
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update
            apt-get install -y "$1"
        elif command -v yum >/dev/null 2>&1; then
            yum install -y "$1"
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y "$1"
        elif command -v zypper >/dev/null 2>&1; then
            zypper install -y "$1"
        else
            echo "Unsupported package manager. Please install $1 manually."
            exit 1
        fi
    fi
}

install_if_missing jq
install_if_missing sudo
install_if_missing curl
install_if_missing wget

show_menu() {
    echo -e "\033[32m请选择一个操作:\033[0m"
    echo -e "\033[32m1)\033[0m 网络/性能"
    echo -e "\033[32m2)\033[0m 代理"
    echo -e "\033[32m3)\033[0m VPS测试"
    echo -e "\033[32m4)\033[0m 其他功能"
    echo -e "\033[32m5)\033[0m 安装常用环境及软件"
    echo -e "\033[32m6)\033[0m 退出"
}

network_menu() {
    echo -e "\033[32m网络选项:\033[0m"
    echo -e "\033[32m1)\033[0m 核心参数优化"
    echo -e "\033[32m2)\033[0m 安装大小包测试 nexttrace"
    echo -e "\033[32m3)\033[0m 安装 DDNS 脚本"
    echo -e "\033[32m4)\033[0m 小鸡剑皇脚本"
    echo -e "\033[32m5)\033[0m 一键开启BBR"
    echo -e "\033[32m6)\033[0m 多功能BBR安装脚本"
    echo -e "\033[32m7)\033[0m TCP窗口调优"
    echo -e "\033[32m8)\033[0m 测试访问优先级"
    echo -e "\033[32m9)\033[0m 25端口开放测试"
    echo -e "\033[32m10)\033[0m 调整ipv4/6优先访问（非直接禁用）"
    echo -e "\033[32m11)\033[0m 禁用启用ICMP"
    echo -e "\033[32m12)\033[0m WARP"
    echo -e "\033[32m13)\033[0m vnStat流量监控"
    echo -e "\033[32m14)\033[0m iftop网络通信监控"
    echo -e "\033[32m15)\033[0m 安装cloud低占用内核"
    echo -e "\033[32m16)\033[0m 删除内核优化参数"
    echo -e "\033[32m17)\033[0m 返回主菜单"
}

proxy_menu() {
    echo -e "\033[32m代理选项:\033[0m"
    echo -e "\033[32m1)\033[0m xray管理"
    echo -e "\033[32m2)\033[0m 安装mieru（改自MisakaNo）"
    echo -e "\033[32m3)\033[0m v2bx一键安装脚本"
    echo -e "\033[32m4)\033[0m v2ray-agent八合一一键脚本"
    echo -e "\033[32m5)\033[0m 安装 Xboard"
    echo -e "\033[32m6)\033[0m 安装极光转发面板"
    echo -e "\033[32m7)\033[0m 安装咸蛋转发面板"
    echo -e "\033[32m8)\033[0m hy2一键脚本"
    echo -e "\033[32m9)\033[0m DNS解锁服务器搭建"
    echo -e "\033[32m10)\033[0m X-UI弱密码全网扫描"
    echo -e "\033[32m11)\033[0m ss-plugins（支持ss2022+流量混淆）"
    echo -e "\033[32m12)\033[0m 233boy/xray一键脚本"
    echo -e "\033[32m13)\033[0m realm&Gost转发脚本"
    echo -e "\033[32m14)\033[0m 返回主菜单"
}

vps_test_menu() {
    echo -e "\033[32mVPS测试选项:\033[0m"
    echo -e "\033[32m1)\033[0m 综合测试脚本"
    echo -e "\033[32m2)\033[0m 性能测试"
    echo -e "\033[32m3)\033[0m 流媒体及 IP 质量测试"
    echo -e "\033[32m4)\033[0m 三网测速脚本"
    echo -e "\033[32m5)\033[0m 回程测试"
    echo -e "\033[32m6)\033[0m 返回主菜单"
}

kernel_optimization() {
    clear
    echo "正在编辑 /etc/sysctl.conf 文件..."
    
    sudo bash -c 'cat << EOF >> /etc/sysctl.conf
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_ecn=0
net.ipv4.tcp_frto=1
net.ipv4.tcp_mtu_probing=0
net.ipv4.tcp_rfc1337=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_fack=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_adv_win_scale=1
net.ipv4.tcp_moderate_rcvbuf=1
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_fastopen=3
net.core.rmem_max=33554432
net.core.wmem_max=33554432
net.ipv4.tcp_rmem=4096 131072 33554432
net.ipv4.tcp_wmem=4096 16384 33554432
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192
net.ipv4.ip_forward=1
net.ipv4.conf.all.route_localnet=1
net.ipv4.conf.all.forwarding=1
net.ipv4.conf.default.forwarding=1
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
vm.swappiness=10
kernel.panic=10
EOF'

    echo "应用配置..."
    sudo sysctl -p

    echo "核心优化完成。按回车键返回菜单。"
    read -r
}

install_and_test_nexttrace() {
    clear
    echo "安装 nexttrace..."
    curl -L nxtrace.org/nt | bash

    echo "配置 nexttrace..."
    export NEXTTRACE_POWPROVIDER=sakura

    while true; do
        clear
        echo "请选择测试类型:"
        echo "1) 大包测试 (1450 bytes)"
        echo "2) 小包测试 (30 bytes)"
        echo "3) 返回主菜单"
        read -p "请输入你的选择: " test_choice

        case $test_choice in
            1) 
                read -p "请输入要测试的 IP 地址: " ip
                nexttrace -T --psize 1450 $ip -p 80
                read -p "按回车键继续..."
                ;;
            2) 
                read -p "请输入要测试的 IP 地址: " ip
                nexttrace -T --psize 30 $ip -p 80
                read -p "按回车键继续..."
                ;;
            3)
                break
                ;;
            *)
                echo "无效的选择，请重试。"
                read -p "按回车键继续..."
                ;;
        esac
    done
}

install_ddns_script() {
    clear
    echo "下载并运行 DDNS 脚本..."
    curl -sS -o /root/cf-v4-ddns.sh https://raw.githubusercontent.com/aipeach/cloudflare-api-v4-ddns/master/cf-v4-ddns.sh
    chmod +x /root/cf-v4-ddns.sh
    echo "脚本下载完成并已赋予执行权限。"

    read -p "请输入你的CF的Global密钥: " CFKEY
    while [[ -z "$CFKEY" ]]; do
        echo "Global密钥不能为空，请重试。"
        read -p "请输入你的CF的Global密钥: " CFKEY
    done

    read -p "请输入你的CF账号: " CFUSER
    while [[ -z "$CFUSER" ]]; do
        echo "CF账号不能为空，请重试。"
        read -p "请输入你的CF账号: " CFUSER
    done

    read -p "请输入需要用来 DDNS 的一级域名 (例如: baidu.com): " CFZONE_NAME
    while [[ -z "$CFZONE_NAME" ]]; do
        echo "一级域名不能为空，请重试。"
        read -p "请输入需要用来 DDNS 的一级域名 (例如: baidu.com): " CFZONE_NAME
    done

    read -p "请输入 DDNS 的二级域名前缀 (例如: 123): " CFRECORD_NAME
    while [[ -z "$CFRECORD_NAME" ]]; do
        echo "二级域名前缀不能为空，请重试。"
        read -p "请输入 DDNS 的二级域名前缀 (例如: 123): " CFRECORD_NAME
    done

    sed -i "s/^CFKEY=.*/CFKEY=${CFKEY}/" /root/cf-v4-ddns.sh
    sed -i "s/^CFUSER=.*/CFUSER=${CFUSER}/" /root/cf-v4-ddns.sh
    sed -i "s/^CFZONE_NAME=.*/CFZONE_NAME=${CFZONE_NAME}/" /root/cf-v4-ddns.sh
    sed -i "s/^CFRECORD_NAME=.*/CFRECORD_NAME=${CFRECORD_NAME}/" /root/cf-v4-ddns.sh

    echo "配置文件已更新。"

    /root/cf-v4-ddns.sh

    echo "设置定时任务..."
    read -p "是否需要日志？(y/n): " log_choice

    if [ "$log_choice" = "y" ] || [ "$log_choice" = "Y" ]; then
        mkdir -p /var/log
        (crontab -l 2>/dev/null; echo "*/2 * * * * /root/cf-v4-ddns.sh >> /var/log/cf-ddns.log 2>&1") | crontab -
        echo "定时任务已设置，并将日志保存到 /var/log/cf-ddns.log。"
    else
        (crontab -l 2>/dev/null; echo "*/2 * * * * /root/cf-v4-ddns.sh >/dev/null 2>&1") | crontab -
        echo "定时任务已设置。"
    fi

    echo "运行完成。按回车键返回菜单。"
    read -r
}

chicken_king_script() {
    echo "剑皇在路上..."
    wget https://github.com/maintell/webBenchmark/releases/download/0.5/webBenchmark_linux_x64
    chmod +x webBenchmark_linux_x64

    echo "请输入线程数："
    read threads
    echo "请输入图片/文件路径："
    read file_path

    ./webBenchmark_linux_x64 -c "$threads" -s "$file_path"
    echo "开始剑皇"
    echo "按回车键返回主菜单..."
    read -r
}

enable_bbr() {
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    sysctl net.ipv4.tcp_available_congestion_control
    lsmod | grep bbr
    echo "BBR 已开启。按回车键返回菜单。"
    read -r
}

install_multifunction_bbr() {
    wget -N --no-check-certificate "https://gist.github.com/zeruns/a0ec603f20d1b86de6a774a8ba27588f/raw/4f9957ae23f5efb2bb7c57a198ae2cffebfb1c56/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
    echo "多功能BBR安装脚本运行完成。按回车键返回菜单。"
    read -r
}

tcp_window_tuning() {
    wget http://sh.nekoneko.cloud/tools.sh -O tools.sh && bash tools.sh
    echo "TCP窗口调优完成。按回车键返回菜单。"
    read -r
}

test_access_priority() {
    curl ip.sb
    echo "访问优先级测试完成。按回车键返回菜单。"
    read -r
}

port_25_test() {
    telnet smtp.aol.com 25
    echo "25端口开放测试完成。按回车键返回菜单。"
    read -r
}

adjust_ipv_priority() {
    clear
    echo "选择一个选项来调整IPv4/IPv6的优先访问:"
    echo "1) 优先使用IPv4"
    echo "2) 优先使用IPv6"
    read -p "请输入你的选择: " ipv_choice
    case $ipv_choice in
        1)
            echo "优先使用IPv4..."
            if grep -q "precedence ::ffff:0:0/96  100" /etc/gai.conf; then
                echo "已经设置为优先使用IPv4。"
            else
                echo "precedence ::ffff:0:0/96  100" | sudo tee -a /etc/gai.conf
                echo "已设置为优先使用IPv4。"
            fi
            ;;
        2)
            echo "优先使用IPv6..."
            if grep -q "precedence ::ffff:0:0/96  100" /etc/gai.conf; then
                sudo sed -i '/^precedence ::ffff:0:0\/96  100/d' /etc/gai.conf
                echo "已设置为优先使用IPv6。"
            else
                echo "已经设置为优先使用IPv6。"
            fi
            ;;
        *)
            echo "无效的选择，请重试。"
            ;;
    esac
    echo "操作完成。按回车键返回菜单。"
    read -r
}

manage_icmp() {
    echo "选择一个选项:"
    echo -e "\033[32m1)\033[0m 启用ICMP"
    echo -e "\033[32m2)\033[0m 禁用ICMP"
    echo -e "\033[32m3)\033[0m 返回上一级菜单"
    read -p "请输入你的选择: " icmp_choice
    case $icmp_choice in
        1)
            sudo sed -i '/net.ipv4.icmp_echo_ignore_all/d' /etc/sysctl.conf
            echo "net.ipv4.icmp_echo_ignore_all=0" | sudo tee -a /etc/sysctl.conf
            sudo sysctl -p
            echo "ICMP已启用"
            ;;
        2)
            sudo sed -i '/net.ipv4.icmp_echo_ignore_all/d' /etc/sysctl.conf
            echo "net.ipv4.icmp_echo_ignore_all=1" | sudo tee -a /etc/sysctl.conf
            sudo sysctl -p
            echo "ICMP已禁用"
            ;;
        3)
            echo "返回上一级菜单"
            return
            ;;
        *)
            echo "无效的选择，请重试。"
            ;;
    esac
    echo "操作完成。按回车键返回菜单。"
    read -r
}

install_warp_script() {
    clear
    echo "运行 WARP 安装脚本..."
    wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh
    echo "运行完成。按回车键返回菜单。"
    read -r
}

manage_vnstat() {
    while true; do
        clear
        echo "请选择操作:"
        echo "1) 安装并启动 vnStat"
        echo "2) 查看日流量统计"
        echo "3) 卸载 vnStat"
        echo "4) 返回主菜单"
        read -p "请输入你的选择: " choice

        case $choice in
            1)
                echo "安装 vnStat..."
                sudo apt-get update
                sudo apt-get install -y vnstat

                echo "启动 vnStat 服务..."
                sudo systemctl start vnstat
                sudo systemctl enable vnstat

                echo "vnStat 安装并启动完成。"
                read -p "按任意键继续..."
                ;;
            2)
                echo "查看日流量统计..."
                vnstat -d
                read -p "按任意键继续..."
                ;;
            3)
                echo "卸载 vnStat..."
                sudo systemctl stop vnstat
                sudo systemctl disable vnstat
                sudo apt-get purge -y vnstat
                sudo rm -rf /var/lib/vnstat
                echo "vnStat 已卸载。"
                read -p "按任意键继续..."
                ;;
            4)
                return 0
                ;;
            *)
                echo "无效的选择，请重试。"
                read -p "按任意键继续..."
                ;;
        esac
    done
}

manage_iftop() {
    while true; do
        clear
        echo "请选择操作:"
        echo "1) 安装 iftop"
        echo "2) 运行 iftop"
        echo "3) 卸载 iftop"
        echo "4) 返回主菜单"
        read -p "请输入你的选择: " choice

        case $choice in
            1)
                echo "安装 iftop..."
                sudo apt-get update
                sudo apt-get install -y iftop
                echo "iftop 安装完成。"
                read -p "按任意键继续..."
                ;;
            2)
                echo "运行 iftop..."
                read -p "请输入要监控的网络接口 (例如 eth0): " interface
                sudo iftop -i $interface
                read -p "按任意键继续..."
                ;;
            3)
                echo "卸载 iftop..."
                sudo apt-get remove -y iftop
                sudo apt-get purge -y iftop
                echo "iftop 已卸载。"
                read -p "按任意键继续..."
                ;;
            4)
                return 0
                ;;
            *)
                echo "无效的选择，请重试。"
                read -p "按任意键继续..."
                ;;
        esac
    done
}

install_and_remove_old_kernel() {
    clear

    if [ "$(uname -m)" != "x86_64" ]; then
        echo "错误：此脚本仅支持64位系统。"
        echo "请使用64位系统运行此脚本。按回车键返回菜单。"
        read -r
        return
    fi

    echo "更新包列表..."
    sudo apt-get update

    echo "查找当前内核版本..."
    current_kernel=$(uname -r)
    echo "当前内核版本：$current_kernel"

    echo "查找已安装的内核包..."
    installed_kernels=$(dpkg --list | grep linux-image | grep -v "$current_kernel" | awk '{print $2}')
    echo "已安装的内核包：$installed_kernels"

    echo "卸载旧内核..."
    for kernel in $installed_kernels; do
        sudo apt-get remove -y --purge "$kernel"
    done

    echo "安装 linux-image-cloud-amd64 内核..."
    sudo apt-get install -y linux-image-cloud-amd64

    echo "清理无用的包..."
    sudo apt-get autoremove --purge -y

    echo "更新 GRUB 配置..."
    sudo update-grub

    echo "linux-image-cloud-amd64 内核安装完成，旧内核已卸载。"

    while true; do
        read -p "是否立即重启系统以使新内核生效？（y/n）: " yn
        case $yn in
            [Yy]* ) echo "系统将在几秒钟后重启..."; sleep 3; sudo reboot; break;;
            [Nn]* ) echo "请记得稍后手动重启系统以使新内核生效。按回车键返回菜单。"; read -r; break;;
            * ) echo "请输入 y 或 n。";;
        esac
    done
}

clear_kernel_optimizations() {
    clear
    echo "正在清空内核优化参数..."

    sudo tee /etc/sysctl.conf > /dev/null <<EOF
EOF

    sudo sysctl -p

    echo "内核优化参数已清空。"
    echo "按回车键继续..."
    read -r
}


xray_management() {
    clear
    echo -e "\033[32mxray 管理\033[0m"
    echo -e "\033[32m1)\033[0m 安装 VLESS-TLS-SplitHTTP-H3"
    echo -e "\033[32m2)\033[0m 安装 xtls-rprx-vision-reality"
    echo -e "\033[32m3)\033[0m 删除 xray"
    echo -e "\033[32m4)\033[0m 开启 xray"
    echo -e "\033[32m5)\033[0m 重启 xray"
    echo -e "\033[32m6)\033[0m 查看 xray 状态"
    echo -e "\033[32m7)\033[0m 返回主菜单"
    read -p "请输入你的选择: " xray_choice
    case $xray_choice in
        1) install_vless_tls_splithttp_h3 ;;
        2) install_xtls_rprx_vision_reality ;;
        3) bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge ;;
        4) sudo systemctl start xray ;;
        5) sudo systemctl restart xray ;;
        6) sudo systemctl status xray ;;
        7) return ;;
        *) echo "无效的选择，请重试。" ;;
    esac
    echo "操作完成。按回车键返回菜单。"
    read -r
}

install_vless_tls_splithttp_h3() {
    clear
    apt update
    apt install -y curl nano socat

    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    
    echo "注释掉 /etc/systemd/system/xray.service 中的 User=nobody 行..."
    sudo sed -i 's/^User=nobody/#&/' /etc/systemd/system/xray.service

    echo "重新加载 systemd 守护进程..."
    sudo systemctl daemon-reload

    curl https://get.acme.sh | sh
    source ~/.bashrc

    read -p "请输入您的电子邮箱: " email
    ~/.acme.sh/acme.sh --register-account -m $email

    read -p "请输入您的域名: " domain
    ~/.acme.sh/acme.sh --issue --standalone -d $domain

    mkdir ~/xray_cert
    ~/.acme.sh/acme.sh --install-cert -d $domain --ecc \
        --fullchain-file ~/xray_cert/xray.crt \
        --key-file ~/xray_cert/xray.key
    chmod +r ~/xray_cert/xray.key

    sed -i 's/User=nobody/# User=nobody/' /etc/systemd/system/xray.service

    cd /usr/local/bin/
    uuid=$(./xray uuid)

    read -p "请输入path路径（留空以生成随机路径）: " path
    if [ -z "$path" ];then
        path=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 16 | head -n 1)
    fi

    read -p "是否启用CDN？ (y/n): " use_cdn
    if [[ "$use_cdn" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        alpn='["h2", "http/1.1"]'
        alpn_param='h3'
    else
        alpn='["h3"]'
        alpn_param='h2,http/1.1'
    fi

    read -p "请输入端口（如果要套CDN，最好选择443端口）: " port

    cat <<EOF > /usr/local/etc/xray/config.json
{
    "inbounds": [
        {
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls",
                    "quic"
                ]
            },
            "port": $port,
            "listen": "0.0.0.0",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$uuid"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "splithttp",
                "security": "tls",
                "splithttpSettings": {
                    "path": "/$path",
                    "host": "$domain"
                },
                "tlsSettings": {
                    "rejectUnknownSni": true,
                    "minVersion": "1.3",
                    "alpn": $alpn,
                    "certificates": [
                        {
                            "ocspStapling": 3600,
                            "certificateFile": "/root/xray_cert/xray.crt",
                            "keyFile": "/root/xray_cert/xray.key"
                        }
                    ]
                }
            }
        }
    ],
    "outbounds": [
        {
            "tag": "direct",
            "protocol": "freedom"
        }
    ]
}
EOF

    systemctl daemon-reload
    systemctl start xray
    systemctl enable xray

    share_link="vless://${uuid}@${domain}:${port}?encryption=none&security=tls&sni=${domain}&alpn=${alpn_param}&fp=chrome&type=splithttp&host=${domain}&path=/${path}#Xray"

    echo "分享链接: $share_link"
    echo "安装 VLESS-TLS-SplitHTTP-H3 完成。按回车键返回菜单。"
    read -r
}

install_xtls_rprx_vision_reality() {
    clear
    echo "安装 xray..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

    echo "注释掉 /etc/systemd/system/xray.service 中的 User=nobody 行..."
    sudo sed -i 's/^User=nobody/#&/' /etc/systemd/system/xray.service

    echo "重新加载 systemd 守护进程..."
    sudo systemctl daemon-reload

    echo "创建 /var/log/xray 目录并设置权限..."
    sudo mkdir -p /var/log/xray
    sudo chown -R $(whoami):$(whoami) /var/log/xray

    echo "生成 UUID..."
    cd /usr/local/bin/
    uuid=$(./xray uuid)

    echo "生成 x25519 密钥对..."
    keys=$(./xray x25519)
    privateKey=$(echo "$keys" | grep 'Private' | awk '{print $3}')
    publicKey=$(echo "$keys" | grep 'Public' | awk '{print $3}')

    read -rp "请输入端口号（默认10086）: " port
    port=${port:-10086}

    read -rp "请输入域名（默认as.idolmaster-official.jp）: " domain
    domain=${domain:-as.idolmaster-official.jp}

    echo "生成 shortIds..."
    shortIds=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 16 | head -n 1)

    echo "编辑 xray 配置文件..."
    sudo bash -c "cat << EOF > /usr/local/etc/xray/config.json
{
  \"log\": {
    \"loglevel\": \"warning\",
    \"access\": \"/var/log/xray/access.log\",
    \"error\": \"/var/log/xray/error.log\"
  },
  \"dns\": {
    \"servers\": [
      \"https+local://1.1.1.1/dns-query\",
      \"localhost\"
    ]
  },
  \"routing\": {
    \"domainStrategy\": \"IPIfNonMatch\",
    \"rules\": [
      {
        \"type\": \"field\",
        \"ip\": [
          \"geoip:private\" 
        ],
        \"outboundTag\": \"block\"
      },
      {
        \"type\": \"field\",
        \"ip\": [\"geoip:cn\"],
        \"outboundTag\": \"block\"
      },
      {
        \"type\": \"field\",
        \"domain\": [
          \"geosite:category-ads-all\" 
        ],
        \"outboundTag\": \"block\" 
      }
    ]
  },
  \"inbounds\": [
    {
      \"listen\": \"0.0.0.0\",
      \"port\": $port,
      \"protocol\": \"vless\",
      \"settings\": {
        \"clients\": [
          {
            \"id\": \"$uuid\",
            \"flow\": \"xtls-rprx-vision\",
            \"level\": 0,
            \"email\": \"xray@gmail.com\"
          }
        ],
        \"decryption\": \"none\"
      },
      \"streamSettings\": {
        \"network\": \"tcp\",
        \"security\": \"reality\",
        \"realitySettings\": {
          \"show\": false,
          \"dest\": \"$domain:443\",
          \"xver\": 0,
          \"serverNames\": [\"$domain\"],
          \"privateKey\": \"$privateKey\",
          \"publicKey\": \"$publicKey\",
          \"maxTimeDiff\": 7000,
          \"shortIds\": [\"\", \"$shortIds\"]
        }
      }
    }
  ],
  \"outbounds\": [
    {
      \"tag\": \"direct\",
      \"protocol\": \"freedom\"
    },
    {
      \"tag\": \"block\",
      \"protocol\": \"blackhole\"
    }
  ]
}
EOF"

    echo "重新加载 xray 服务配置..."
    sudo systemctl restart xray

    echo "检查 xray 服务状态..."
    sudo systemctl status xray

    echo "设置 xray 开机自启..."
    sudo systemctl enable xray

    ip=$(curl -4 -s ifconfig.me)
    shareLink="vless://$uuid@$ip:$port?security=reality&sni=$domain&fp=chrome&pbk=$publicKey&sid=$shortIds&type=tcp&flow=xtls-rprx-vision&encryption=none#$ip"

    echo "安装 xtls-rprx-vision-reality 完成。以下是配置信息："
    echo "UUID: $uuid"
    echo "PrivateKey: $privateKey"
    echo "PublicKey: $publicKey"
    echo "分享链接: $shareLink"
    echo "按回车键返回菜单。"
    read -r
}

install_mieru_script() {
    clear
    echo "运行Mieru安装脚本..."
    wget -N --no-check-certificate https://raw.githubusercontent.com/cccchiban/BCSB/main/mieru.sh && bash mieru.sh
    echo "运行完成。按回车键返回菜单。"
    read -r
}

install_v2bx_script() {
    clear
    echo "运行v2bx一键安装脚本..."
    wget -N https://raw.githubusercontent.com/wyx2685/V2bX-script/master/install.sh && bash install.sh
    echo "安装完成。按回车键返回菜单。"
    read -r
}

install_v2ray-agent_script() {
    clear
    echo "运行v2ray-agent八合一键脚本..."
    wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh" && chmod 700 /root/install.sh && /root/install.sh
    echo "安装完成。按回车键返回菜单。"
    read -r
}

install_Aurora_script() {
    clear
    echo "安装极光转发面板..."
    bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh)
    echo "安装完成。按回车键返回菜单。"
    read -r
}

install_xiandan_script() {
    clear
    echo "安装咸蛋转发面板..."
    bash <(wget --no-check-certificate -qO- 'https://sh.xdmb.xyz/xiandan/xd.sh')
    echo "安装完成。按回车键返回菜单。"
    read -r
}

install_xboard() {
    echo "开始安装 Xboard..."

    if dpkg -l | grep -q docker; then
        echo "Docker 已经安装，跳过安装步骤。"
    else
        echo "安装 Docker..."
        curl -sSL https://get.docker.com | bash
        systemctl enable docker
        systemctl start docker
        echo "Docker 安装完成！"
    fi

    echo "获取 Docker Compose 文件..."
    git clone -b docker-compose --depth 1 https://github.com/cedar2025/Xboard
    cd Xboard || { echo "克隆仓库失败"; exit 1; }
    echo "Docker Compose 文件获取完成！"

    echo "执行数据库安装命令..."
    docker compose run -it --rm xboard php artisan xboard:install
    echo "数据库安装命令执行完成！请记录返回的后台地址和管理员账号密码。"

    echo "启动 Xboard..."
    docker compose up -d
    echo "Xboard 启动完成！"

    IP_ADDRESS=$(hostname -I | awk '{print $1}')

    echo "你现在可以访问你的站点了。默认端口为7001。"
    echo "网站地址: http://$IP_ADDRESS:7001/"

    read -p "安装完成，按回车键返回主菜单..."
}

install_hy2_script() {
    clear
    echo "请选择安装脚本："
    echo "1. 使用自带hy2脚本 "
    echo "2. 使用masakano hy2安装脚本 "
    echo "请输入选项 (1 或 2)："
    read -r option

    case $option in
        1)
            echo "运行hy2安装脚本1..."
            curl -sS -O https://raw.githubusercontent.com/cccchiban/BCSB/main/hy2.sh && chmod +x hy2.sh && ./hy2.sh
            ;;
        2)
            echo "运行hy2安装脚本2..."
            wget -N --no-check-certificate https://raw.githubusercontent.com/Misaka-blog/hysteria-install/main/hy2/hysteria.sh && bash hysteria.sh
            ;;
        *)
            echo "无效的选项，请重新运行脚本并选择 1 或 2。"
            return
            ;;
    esac

    echo "安装完成。按回车键返回菜单。"
    read -r
}

install_dns_unlock_script() {
    echo "请选择操作："
    echo "1. 运行 DNS 解锁脚本"
    echo "2. 卸载 DNS 解锁脚本"
    read -rp "请输入选择 (1 或 2): " choice

    if [[ "$choice" == "1" ]]; then
        wget --no-check-certificate -O dnsmasq_sniproxy.sh https://raw.githubusercontent.com/myxuchangbin/dnsmasq_sniproxy_install/master/dnsmasq_sniproxy.sh
        bash dnsmasq_sniproxy.sh -f
        
        read -rp "是否限制 IP 访问？(y/n): " limit_ip
        if [[ "$limit_ip" == "y" ]]; then
            if ! command -v iptables &> /dev/null; then
                echo "iptables 未安装，正在安装..."
                apt-get update && apt-get install -y iptables
            fi
            
            iptables -A INPUT -p tcp --dport 53 -j DROP
            
            read -rp "请输入需要添加的白名单 IP（多个 IP 用空格分隔）: " -a whitelist_ips
            for ip in "${whitelist_ips[@]}"; do
                iptables -I INPUT -p tcp -s "$ip" --dport 53 -j ACCEPT
            done
            
            iptables-save > /etc/iptables/rules.v4
            echo "IP 访问限制已设置。"
        fi
        
        echo "DNS 解锁脚本安装完成。按回车键返回菜单。"
        read -r
    elif [[ "$choice" == "2" ]]; then
        wget --no-check-certificate -O dnsmasq_sniproxy.sh https://raw.githubusercontent.com/myxuchangbin/dnsmasq_sniproxy_install/master/dnsmasq_sniproxy.sh
        bash dnsmasq_sniproxy.sh -u
        
        iptables -D INPUT -p tcp --dport 53 -j DROP
        
        echo "DNS 解锁脚本卸载完成。53 端口限制已移除。按回车键返回菜单。"
        read -r
    else
        echo "无效选择，请重新运行脚本。"
    fi
}

port_scan_and_management() {
    clear
    echo "方法来自https://www.nodeseek.com/post-1084-1"
    echo "端口扫描有可能导致vps清退或收到abuse，请谨慎操作"
    echo "1) 安装端口扫描工具并进行端口扫描和弱口令尝试"
    echo "2) 卸载端口扫描工具"
    echo "3) 退出"
    read -p "请输入选项 (1-3): " operation

    case $operation in
        1)
            echo "正在安装必要的软件包..."
            sudo apt update
            sudo apt install -y nmap zmap masscan

            echo "选择扫描工具："
            echo "1) masscan"
            echo "2) zmap"
            echo "3) nmap"
            read -p "请输入选项 (1-3): " scan_tool

            read -p "请输入目标端口 (默认: 54321): " target_port
            target_port=${target_port:-54321}

            read -p "请输入扫描结果输出文件名 (默认: scan.log): " scan_output
            scan_output=${scan_output:-scan.log}

            case $scan_tool in
                1)
                    echo "使用 masscan 进行端口扫描..."
                    sudo masscan 0.0.0.0/0 -p$target_port --banners --exclude 255.255.255.255 -oJ scan.json
                    scan_file="scan.json"
                    ;;
                2)
                    echo "使用 zmap 进行端口扫描..."
                    sudo zmap --target-port=$target_port --output-file=$scan_output
                    scan_file=$scan_output
                    ;;
                3)
                    echo "使用 nmap 进行端口扫描..."
                    sudo nmap -sS 0.0.0.0/0 -p $target_port | grep -v failed > $scan_output
                    scan_file=$scan_output
                    ;;
                *)
                    echo "无效选项，退出..."
                    return
                    ;;
            esac

            echo "扫描完成，开始尝试弱口令登录..."

            week_log="week.log"
            all_log="all.log"

            > $week_log
            > $all_log

            for ip_ad in $(sed -nE 's/.*"ip": "([^"]+)".*/\1/p' $scan_file); do
                if curl --max-time 1 http://$ip_ad:$target_port; then
                    res=$(curl "http://${ip_ad}:$target_port/login" --data-raw 'username=admin&password=admin' --compressed --insecure)
                    if [[ "$res" =~ .*true.* ]]; then
                        echo $ip_ad | tee -a $week_log
                    fi
                    echo $ip_ad | tee -a $all_log
                fi
            done

            echo "弱口令尝试完成。"
            echo "可以弱口令登录的机器保存在 $week_log。"
            echo "所有被扫描的机器保存在 $all_log。"
            ;;
        2)
            echo "正在卸载端口扫描工具..."
            sudo apt remove -y nmap zmap masscan
            echo "端口扫描工具卸载完成。"
            ;;
        3)
            echo "退出..."
            exit 0
            ;;
        *)
            echo "无效选项，退出..."
            return
            ;;
    esac

    echo "按回车键返回菜单。"
    read -r
}

install_ss_plugins() {
    clear
    echo "脚本来自：https://github.com/loyess/Shell"
    wget -N --no-check-certificate -c -t3 -T60 -O ss-plugins.sh https://git.io/fjlbl
    chmod +x ss-plugins.sh
    ./ss-plugins.sh
    echo "ss-plugins 安装脚本运行完成。按回车键返回菜单。"
    read -r
}

233boy_xray() {
    clear
    bash <(wget -qO- -o- https://github.com/233boy/Xray/raw/main/install.sh)
    echo "Xray 安装脚本运行完成。按回车键返回菜单。"
    read -r
}

realm_gost_Forward() {
    clear
    echo "请选择要执行的操作："
    echo "1) Realm 转发"
    echo "2) Gost 转发"
    echo "3) 返回上级菜单"
    read -p "请输入你的选择 (1-3): " choice

    case $choice in
        1)
            clear
            echo "脚本来自：https://www.nodeseek.com/post-171363-1"
            wget -N https://raw.githubusercontent.com/qqrrooty/EZrealm/main/realm.sh && chmod +x realm.sh && ./realm.sh
            ;;
        2)
            clear
            wget --no-check-certificate -O gost.sh https://raw.githubusercontent.com/qqrrooty/EZgost/main/gost.sh && chmod +x gost.sh && ./gost.sh
            ;;
        3)
            return
            ;;
        *)
            echo "无效的选择，请重试。"
            ;;
    esac

    echo "操作完成。按回车键返回菜单。"
    read -r
}


comprehensive_test_script() {
    clear
    echo "选择一个综合测试脚本:"
    echo -e "\033[32m1)\033[0m 融合怪"
    echo -e "\033[32m2)\033[0m NodeBench"
    read -p "请输入你的选择: " test_choice
    case $test_choice in
        1)
            bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh)
            ;;
        2)
            bash <(curl -sL https://raw.githubusercontent.com/LloydAsp/NodeBench/main/NodeBench.sh)
            ;;
        *)
            echo "无效的选择，请重试。"
            ;;
    esac
    echo "脚本运行完成。按回车键返回菜单。"
    read -r
}

performance_test_script() {
    clear
    echo "选择一个性能测试脚本:"
    echo -e "\033[32m1)\033[0m GB5 完整测试脚本"
    echo -e "\033[32m2)\033[0m yabs GB6 完整测试脚本"
    echo -e "\033[32m3)\033[0m GB6 测试脚本-跳过网络磁盘测试"
    echo -e "\033[32m4)\033[0m GB5 测试脚本-跳过网络磁盘测试"
    echo -e "\033[32m5)\033[0m 秋水逸冰-bench测试脚本"
    read -p "请输入你的选择: " perf_choice
    case $perf_choice in
        1)
            bash <(wget -qO- https://raw.githubusercontent.com/i-abc/GB5/main/gb5-test.sh)
            ;;
        2)
            curl -sL yabs.sh | bash
            ;;
        3)
            curl -sL yabs.sh | bash -s -- -fi
            ;;
        4)
            curl -sL yabs.sh | bash -s -- -fi5
            ;;
        5)
            wget --no-check-certificate https://raw.githubusercontent.com/teddysun/across/master/bench.sh -O bench.sh && bash bench.sh
            ;;
        *)
            echo "无效的选择，请重试。"
            ;;
    esac
    echo "脚本运行完成。按回车键返回菜单。"
    read -r
}

media_ip_quality_test_script() {
    clear
    echo "选择一个流媒体及 IP 质量测试脚本:"
    echo -e "\033[32m1)\033[0m media测试脚本"
    echo -e "\033[32m2)\033[0m check原生检测脚本"
    echo -e "\033[32m3)\033[0m Check准确度最高"
    echo -e "\033[32m4)\033[0m IP 质量体检脚本"
    echo -e "\033[32m5)\033[0m ChatGPT 解锁检测"
    read -p "请输入你的选择: " media_choice
    case $media_choice in
        1)
            bash <(curl -L -s media.ispvps.com)
            ;;
        2)
            bash <(curl -L -s check.unlock.media)
            ;;
        3)
            bash <(curl -L -s https://github.com/1-stream/RegionRestrictionCheck/raw/main/check.sh)
            ;;
        4)
            bash <(curl -sL IP.Check.Place)
            ;;
        5)
            echo "选择 ChatGPT 解锁检测的版本:"
            echo "1) 安卓"
            echo "2) 苹果"
            read -p "请输入你的选择: " chatgpt_choice

            parse_result() {
                local result=$1
                if echo "$result" | grep -q '"cf_details"'; then
                    echo "解锁"
                elif echo "$result" | grep -q '"message":"request is not allowed"'; then
                    echo "解锁"
                elif echo "$result" | grep -q '"message":"Something went wrong"'; then
                    echo "不解锁"
                elif echo "$result" | grep -q '"message":"OpenAI’s services are not available in your country or region."'; then
                    echo "IP所在地区\国家openai不提供服务"
                else
                    echo "无法确定解锁状态"
                fi
            }

            case $chatgpt_choice in
                1)
                    result=$(curl -s android.chat.openai.com)
                    parse_result "$result"
                    ;;
                2)
                    result=$(curl -s ios.chat.openai.com)
                    parse_result "$result"
                    ;;
                *)
                    echo "无效的选择，请重试。"
                    ;;
            esac
            ;;
        *)
            echo "无效的选择，请重试。"
            ;;
    esac
    echo "脚本运行完成。按回车键返回菜单。"
    read -r
}

network_speed_test_script() {
    clear
    echo "选择一个三网测速脚本:"
    echo -e "\033[32m1)\033[0m Speedtest"
    echo -e "\033[32m2)\033[0m Taier"
    echo -e "\033[32m3)\033[0m hyperspeed"
    echo -e "\033[32m4)\033[0m 全球测速"
    read -p "请输入你的选择: " speedtest_choice
    case $speedtest_choice in
        1)
            bash <(curl -sL https://raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh)    
            ;;
        2)
            bash <(curl -sL res.yserver.ink/taier.sh)
            ;;
        3)
            bash <(curl -Lso- https://bench.im/hyperspeed)
            ;;
        4)
            curl -sL network-speed.xyz | bash
            ;;
        *)
            echo "无效的选择，请重试。"
            ;;
    esac
    echo "脚本运行完成。按回车键返回菜单。"
    read -r
}

backtrace_test_script() {
    clear
    echo "选择一个回程测试脚本:"
    echo -e "\033[32m1)\033[0m 直接显示回程"
    echo -e "\033[32m2)\033[0m backtrace重构版（推荐）"
    read -p "请输入你的选择: " backtrace_choice
    case $backtrace_choice in
        1)
            curl https://raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
            ;;
        2)  bash <(curl -sSf https://raw.githubusercontent.com/vpsxb/testrace/main/testrace.sh) backtrace
            ;;
        *)
            echo "无效的选择，请重试。"
            ;;
    esac
    echo "脚本运行完成。按回车键返回菜单。"
    read -r
}

function_script() {
    while true; do
        clear
        echo "选择一个选项:"
        echo -e "\033[32m1)\033[0m Fail2ban"
        echo -e "\033[32m2)\033[0m 添加SWAP"
        echo -e "\033[32m3)\033[0m 更改SSH端口"
        echo -e "\033[32m4)\033[0m 科技lion一键脚本工具"
        echo -e "\033[32m5)\033[0m BlueSkyXN 综合工具箱"
        echo -e "\033[32m6)\033[0m Docker备份/恢复脚本"
        echo -e "\033[32m7)\033[0m btop进程管理"
	echo -e "\033[32m8)\033[0m BetterForward tg群组机器人替身"
	echo -e "\033[32m9)\033[0m vps防滥用脚本"
        echo -e "\033[32m10)\033[0m 返回主菜单"
        read -p "请输入你的选择: " function_choice
        case $function_choice in
            1)
                wget --no-check-certificate https://raw.githubusercontent.com/FunctionClub/Fail2ban/master/fail2ban.sh && bash fail2ban.sh 2>&1 | tee fail2ban.log
                ;;
            2)
                wget https://www.moerats.com/usr/shell/swap.sh && bash swap.sh
                ;;
            3)
                read -p "请输入新的SSH端口: " new_ssh_port
                if [[ -z "$new_ssh_port" || ! "$new_ssh_port" =~ ^[0-9]+$ ]]; then
                    echo "无效的端口，请重试。"
                else
                    sudo sed -i "s/^#Port 22/Port $new_ssh_port/" /etc/ssh/sshd_config
                    sudo sed -i "s/^Port [0-9]*/Port $new_ssh_port/" /etc/ssh/sshd_config
                    sudo systemctl restart sshd

                    if command -v ufw > /dev/null; then
                        sudo ufw allow "$new_ssh_port"/tcp
                        sudo ufw reload
                        echo "UFW: 已放行端口 $new_ssh_port"
                    elif command -v firewall-cmd > /dev/null; then
                        sudo firewall-cmd --permanent --add-port="$new_ssh_port"/tcp
                        sudo firewall-cmd --reload
                        echo "firewalld: 已放行端口 $new_ssh_port"
                    elif command -v iptables > /dev/null; then
                        sudo iptables -A INPUT -p tcp --dport "$new_ssh_port" -j ACCEPT
                        sudo iptables-save > /etc/iptables/rules.v4
                        echo "iptables: 已放行端口 $new_ssh_port"
                    else
                        echo "未检测到已知的防火墙，如有必要可手动放行 $new_ssh_port 端口"
                    fi
                fi
                ;;
            4)
                curl -sS -O https://kejilion.pro/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh
                ;;
            5)
                wget -O box.sh https://raw.githubusercontent.com/BlueSkyXN/SKY-BOX/main/box.sh && chmod +x box.sh && clear && ./box.sh
                ;;
            6)
                echo -e "\033[31m注意：本脚本未经实际测试能否正常运行，请谨慎使用，如遇报错欢迎反馈\033[0m"
                echo -e "\033[32m1)\033[0m 备份Docker"
                echo -e "\033[32m2)\033[0m 恢复Docker"
                read -p "请输入你的选择: " docker_choice
                case $docker_choice in
                    1)
                        curl -sS -O https://raw.githubusercontent.com/cccchiban/BCSB/main/bf.sh  && chmod +x bf.sh && ./bf.sh
                        ;;
                    2)
                        curl -sS -O https://raw.githubusercontent.com/cccchiban/BCSB/main/hf.sh && chmod +x hf.sh && ./hf.sh
                        ;;
                    *)
                        echo "无效的选择，请重试。"
                        ;;
                esac
                ;;
            7)
                echo -e "\033[32m1)\033[0m 安装并启动btop"
                echo -e "\033[32m2)\033[0m 卸载btop"
                echo -e "\033[32m3)\033[0m 返回上一级菜单"
                read -p "请输入你的选择: " btop_choice
                case $btop_choice in
                    1)
                        sudo apt-get update
                        sudo apt install btop
                        btop
                        ;;
                    2)
                        sudo apt-get remove --purge btop
                        echo "btop已卸载。"
                        ;;
                    3)
                        ;;
                    *)
                        echo "无效的选择，请重试。"
                        ;;
                esac
                ;;
            8)
                curl -sS -O https://raw.githubusercontent.com/cccchiban/BCSB/main/BetterForward.sh && chmod +x BetterForward.sh && ./BetterForward.sh
                ;;
            9)
                curl -sS -O https://raw.githubusercontent.com/cccchiban/BCSB/main/shield.sh && chmod +x shield.sh && ./shield.sh
                ;;

            10)
                return
                ;;
            *)
                echo "无效的选择，请重试。"
                ;;
        esac
        echo "脚本运行完成。按回车键返回菜单。"
        read -r
    done
}

install_common_env_software() {
    while true; do
        clear
        echo -e "\033[32m请选择要安装的项目:\033[0m"
        echo -e "\033[32m1)\033[0m docker"
        echo -e "\033[32m2)\033[0m Python"
        echo -e "\033[32m3)\033[0m Aria2"
        echo -e "\033[32m4)\033[0m aaPanel(宝塔国际版)"
        echo -e "\033[32m5)\033[0m 宝塔"
        echo -e "\033[32m6)\033[0m 宝塔开心版"
        echo -e "\033[32m7)\033[0m 1Panel"
        echo -e "\033[32m8)\033[0m 耗子面板"
        echo -e "\033[32m9)\033[0m 哪吒监控"
	echo -e "\033[32m10)\033[0m MCSManager MC开服面板"
        echo -e "\033[32m11)\033[0m 返回主菜单"
        read -p "请输入你的选择: " install_choice
        case $install_choice in
            1)
                echo "选择 docker 安装版本:"
                echo "1) 国外专用"
                echo "2) 国内专用"
                echo "3) 自定义安装源"
                read -p "请输入你的选择: " docker_choice
                case $docker_choice in
                    1)
                        curl -sSL https://get.docker.com/ | sh
                        ;;
                    2)
                        curl -sSL https://get.daocloud.io/docker | sh
                        ;;
                    3)
                        read -p "请输入自定义Docker安装源URL: " custom_url
                        if [[ -z "$custom_url" ]]; then
                            echo "URL不能为空，请重试。"
                        else
                            curl -sSL "$custom_url" | sh
                        fi
                        ;;
                    *)
                        echo "无效的选择，请重试。"
                        ;;
                esac
                ;;
            2)
                curl -O https://raw.githubusercontent.com/lx969788249/lxspacepy/master/pyinstall.sh && chmod +x pyinstall.sh && ./pyinstall.sh
                ;;
            3)
                wget -N git.io/aria2.sh && chmod +x aria2.sh && ./aria2.sh
                ;;
            4)
                URL=https://www.aapanel.com/script/install_7.0_en.sh && if [ -f /usr/bin/curl ];then curl -ksSO "$URL" ;else wget --no-check-certificate -O install_7.0_en.sh "$URL";fi;bash install_7.0_en.sh aapanel
                ;;
            5)
                url=https://download.bt.cn/install/install_lts.sh;if [ -f /usr/bin/curl ];then curl -sSO $url;else wget -O install_lts.sh $url;fi;bash install_lts.sh ed8484bec
                ;;
            6)
                echo "请访问：https://bt.sb/bbs/forum-37-1.html 获取"
                ;;
            7)
                curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh
                ;;
            8)
                echo "请选择操作："
                echo "1) 安装耗子面板"
                echo "2) 卸载耗子面板"
                read -p "请输入你的选择: " haozi_choice
                case $haozi_choice in
                    1)
                        HAOZI_DL_URL="https://dl.cdn.haozi.net/panel"
                        curl -sSL -O ${HAOZI_DL_URL}/install_panel.sh && curl -sSL -O ${HAOZI_DL_URL}/install_panel.sh.checksum.txt && sha256sum -c install_panel.sh.checksum.txt && bash install_panel.sh || echo "Checksum 验证失败，文件可能被篡改，已终止操作"
                        ;;
                    2)
                        HAOZI_DL_URL="https://dl.cdn.haozi.net/panel"
                        curl -sSL -O ${HAOZI_DL_URL}/uninstall_panel.sh && curl -sSL -O ${HAOZI_DL_URL}/uninstall_panel.sh.checksum.txt && sha256sum -c uninstall_panel.sh.checksum.txt && bash uninstall_panel.sh || echo "Checksum 验证失败，文件可能被篡改，已终止操作"
                        ;;
                    *)
                        echo "无效的选择，请重试。"
                        ;;
                esac
                ;;
            9)
                curl -L https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh
                ;;
            10)
                echo "请选择操作："
                echo "1) 安装 MCSManager MC开服面板"
                echo "2) 手动安装 MCSManager (适用于安装失败的情况)"
                read -p "请输入你的选择: " mcsmanager_choice
                case $mcsmanager_choice in
                    1)
                        sudo su -c "wget -qO- https://script.mcsmanager.com/setup_cn.sh | bash"
                        ;;
                    2)
                        cd /opt/
                        wget https://nodejs.org/dist/v20.11.0/node-v20.11.0-linux-x64.tar.xz
                        tar -xvf node-v20.11.0-linux-x64.tar.xz
                        ln -s /opt/node-v20.11.0-linux-x64/bin/node /usr/bin/node
                        ln -s /opt/node-v20.11.0-linux-x64/bin/npm /usr/bin/npm
                        mkdir /opt/mcsmanager/
                        cd /opt/mcsmanager/
                        wget https://github.com/MCSManager/MCSManager/releases/latest/download/mcsmanager_linux_release.tar.gz
                        tar -zxf mcsmanager_linux_release.tar.gz
                        ./install.sh
                        echo -e "\033[32m请打开两个终端或screen来运行以下命令：\033[0m"
                        echo "./start-daemon.sh"
                        echo "./start-web.sh"
                        echo "访问地址：http://localhost:23333/"
                        ;;
                    *)
                        echo "无效的选择，请重试。"
                        ;;
                esac
                ;;
            11)
                break
                ;;
            *)
                echo "无效的选择，请重试。"
                ;;
        esac
        echo "脚本运行完成。按回车键返回菜单。"
        read -r
    done
}

while true; do
    clear
    show_menu
    read -p "请输入你的选择: " choice
    case $choice in
        1) 
            while true; do
                clear
                network_menu
                read -p "请输入你的选择: " net_choice
                case $net_choice in
                    1) kernel_optimization ;;
                    2) install_and_test_nexttrace ;;
                    3) install_ddns_script ;;
                    4) chicken_king_script ;;
                    5) enable_bbr ;;
                    6) install_multifunction_bbr ;;
                    7) tcp_window_tuning ;;
                    8) test_access_priority ;;
                    9) port_25_test ;;
                    10) adjust_ipv_priority ;;
                    11) manage_icmp ;;
                    12) install_warp_script ;;
                    13) manage_vnstat ;;
                    14) manage_iftop ;;
		    15) install_and_remove_old_kernel ;;
		    16) clear_kernel_optimizations ;;
                    17) break ;;
                    *) echo "无效的选择，请重试。" ;;
                esac
            done
            ;;
        2) 
            while true; do
                clear
                proxy_menu
                read -p "请输入你的选择: " proxy_choice
                case $proxy_choice in
                    1) xray_management ;;
                    2) install_mieru_script ;;
                    3) install_v2bx_script ;;
                    4) install_v2ray-agent_script ;;
                    5) install_xboard ;;
                    6) install_Aurora_script ;;
                    7) install_xiandan_script ;;
                    8) install_hy2_script ;;
                    9) install_dns_unlock_script ;;
                    10) port_scan_and_management ;;
		    11) install_ss_plugins ;;
      12) 233boy_xray ;;
      13)realm_gost_Forward ;;
                    14) break ;;
                    *) echo "无效的选择，请重试。" ;;
                esac
            done
            ;;
        3) 
            while true; do
                clear
                vps_test_menu
                read -p "请输入你的选择: " vps_choice
                case $vps_choice in
                    1) comprehensive_test_script ;;
                    2) performance_test_script ;;
                    3) media_ip_quality_test_script ;;
                    4) network_speed_test_script ;;
                    5) backtrace_test_script ;;
                    6) break ;;
                    *) echo "无效的选择，请重试。" ;;
                esac
            done
            ;;
        4) function_script ;;
        5) install_common_env_software ;;
        6) echo "退出"; exit 0 ;;
        *) echo "无效的选择，请重试。"; read -r ;;
    esac
done
