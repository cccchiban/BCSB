#!/bin/bash

if [ "$(id -u)" -ne 0; then
    echo "请以root用户运行此脚本"
    exit 1
fi

install_if_missing() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "$1 未安装，正在安装..."
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
            echo "不支持的包管理器，请手动安装 $1"
            exit 1
        fi
    }
}

install_if_missing curl
install_if_missing wget

show_menu() {
    echo -e "\033[32m请选择一个操作:\033[0m"
    echo -e "\033[32m1)\033[0m 网络"
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
    echo -e "\033[32m13)\033[0m 返回主菜单"
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
    echo -e "\033[32m9)\033[0m 返回主菜单"
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
net.ipv4.tcp_window_scaling = 1
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.ipv4.tcp_rmem = 4096 131072 33554432
net.ipv4.tcp_wmem = 4096 16384 33554432
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_adv_win_scale = -2
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 1
kernel.panic = -1
vm.swappiness = 0
net.ipv4.tcp_fastopen = 3
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
                ;;
            2) 
                read -p "请输入要测试的 IP 地址: " ip
                nexttrace -T --psize 30 $ip -p 80
                ;;
            3)
                break
                ;;
            *)
                echo "无效的选择，请重试。"
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
    echo "运行hy2安装脚本..."
    curl -sS -O https://raw.githubusercontent.com/cccchiban/BCSB/main/hy2.sh && chmod +x hy2.sh && ./hy2.sh
    echo "安装完成。按回车键返回菜单。"
    read -r
}

comprehensive_test_script() {
    clear
    echo "选择一个综合测试脚本:"
    echo -e "\033[32m1)\033[0m 融合怪"
    echo -e "\033[32m2)\033[0m NodeBench"
    echo -e "\033[32m3)\033[0m yabs"
    echo -e "\033[32m4)\033[0m 使用 gb5 测试 yabs"
    read -p "请输入你的选择: " test_choice
    case $test_choice in
        1)
            bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh)
            ;;
        2)
            bash <(curl -sL https://raw.githubusercontent.com/LloydAsp/NodeBench/main/NodeBench.sh)
            ;;
        3)
            curl -sL yabs.sh | bash
            ;;
        4)
            curl -sL yabs.sh | bash -5
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
    echo -e "\033[32m1)\033[0m GB5 专测脚本"
    read -p "请输入你的选择: " perf_choice
    case $perf_choice in
        1)
            bash <(curl -sL bash.icu/gb5)
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
            bash <(curl -sL bash.icu/speedtest)
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
    echo -e "\033[32m1)\033[0m 直接显示回程（小白用这个）"
    echo -e "\033[32m2)\033[0m 回程详细测试（推荐）"
    read -p "请输入你的选择: " backtrace_choice
    case $backtrace_choice in
        1)
            curl https://raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
            ;;
        2)
            wget https://ghproxy.com/https://raw.githubusercontent.com/vpsxb/testrace/main/testrace.sh -O testrace.sh && bash testrace.sh
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
        echo -e "\033[32m7)\033[0m 返回主菜单"
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
        echo -e "\033[32m10)\033[0m 返回主菜单"
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
                    13) break ;;
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
                    9) break ;;
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
