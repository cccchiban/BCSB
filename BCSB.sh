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
    echo -e "\033[32m1)\033[0m 核心优化"
    echo -e "\033[32m2)\033[0m 安装大小包测试 nexttrace"
    echo -e "\033[32m3)\033[0m xray管理"
    echo -e "\033[32m4)\033[0m 安装mieru"
    echo -e "\033[32m5)\033[0m 安装/启动 btop"
    echo -e "\033[32m6)\033[0m 科技lion 综合功能脚本"
    echo -e "\033[32m7)\033[0m SKY-BOX 综合功能脚本"
    echo -e "\033[32m8)\033[0m v2bx一键安装脚本"
    echo -e "\033[32m9)\033[0m 安装 DDNS 脚本"
    echo -e "\033[32m10)\033[0m 安装 Xboard"
    echo -e "\033[32m11)\033[0m 小鸡剑皇脚本"
    echo -e "\033[32m12)\033[0m DD 重装脚本"
    echo -e "\033[32m13)\033[0m 综合测试脚本"
    echo -e "\033[32m14)\033[0m 性能测试"
    echo -e "\033[32m15)\033[0m 流媒体及 IP 质量测试"
    echo -e "\033[32m16)\033[0m 三网测速脚本"
    echo -e "\033[32m17)\033[0m 回程测试"
    echo -e "\033[32m18)\033[0m 其他功能"
    echo -e "\033[32m19)\033[0m 安装常用环境及软件"
    echo -e "\033[32m20)\033[0m 退出"
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

    # 启动Xray
    systemctl daemon-reload
    systemctl start xray
    systemctl enable xray

    # 生成分享链接
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

install_or_start_btop() {
    clear
    if ! command -v btop &> /dev/null; then
        echo "btop 未安装，正在安装..."
        sudo apt update
        sudo apt install -y build-essential cmake libncurses5-dev libncursesw5-dev git
        git clone https://github.com/aristocratos/btop.git
        cd btop
        make
        sudo make install
    else
        echo "btop 已安装，跳过安装步骤。"
    fi

    echo "启动 btop..."
    btop
}

install_techlion_script() {
    clear
    echo "运行科技lion 综合功能脚本..."
    curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh
    echo "运行完成。按回车键返回菜单。"
    read -r
}

install_skybox_script() {
    clear
    echo "运行SKY-BOX 综合功能脚本..."
    wget -O box.sh https://raw.githubusercontent.com/BlueSkyXN/SKY-BOX/main/box.sh && chmod +x box.sh && clear && ./box.sh
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

chicken_king_script() {
    echo "剑皇在路上"
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

install_ddns_script() {
    clear
    echo "下载并运行 DDNS 脚本..."
    curl -sS -o /root/cf-v4-ddns.sh https://raw.githubusercontent.com/aipeach/cloudflare-api-v4-ddns/master/cf-v4-ddns.sh
    chmod +x /root/cf-v4-ddns.sh
    echo "脚本下载完成并已赋予执行权限。"

    read -p "请输入你的CF的Global密钥: " CFKEY
    read -p "请输入你的CF账号: " CFUSER
    read -p "请输入需要用来 DDNS 的一级域名 (例如: baidu.com): " CFZONE_NAME
    read -p "请输入 DDNS 的二级域名前缀 (例如: 123): " CFRECORD_NAME

    sed -i "s/^CFKEY=.*/CFKEY=${CFKEY}/" /root/cf-v4-ddns.sh
    sed -i "s/^CFUSER=.*/CFUSER=${CFUSER}/" /root/cf-v4-ddns.sh
    sed -i "s/^CFZONE_NAME=.*/CFZONE_NAME=${CFZONE_NAME}/" /root/cf-v4-ddns.sh
    sed -i "s/^CFRECORD_NAME=.*/CFRECORD_NAME=${CFRECORD_NAME}/" /root/cf-v4-ddns.sh

    echo "配置文件已更新。"

    /root/cf-v4-ddns.sh

    echo "设置定时任务..."
    (crontab -l 2>/dev/null; echo "*/2 * * * * /root/cf-v4-ddns.sh >/dev/null 2>&1") | crontab -

    echo "定时任务已设置。"
    echo "如果需要日志，请手动编辑crontab，替换为以下内容："
    echo "*/2 * * * * /root/cf-v4-ddns.sh >> /var/log/cf-ddns.log 2>&1"

    echo "运行完成。按回车键返回菜单。"
    read -r
}

dd_reinstall_script() {
    while true; do
        clear
        echo "安装依赖和更新系统..."

        # Debian/Ubuntu:
        if [ -f /etc/debian_version ]; then
            apt-get update
            apt-get install -y xz-utils openssl gawk file
        # RedHat/CentOS:
        elif [ -f /etc/redhat-release ]; then
            yum update
            yum install -y xz openssl gawk file
        else
            echo "未知的操作系统。"
            exit 1
        fi

        clear
        echo "选择一个 DD 重装脚本:"
        echo "1) DD Windows Server 2008 R2 64位 精简版"
        echo "2) DD Windows Server 2012 R2 64位 精简版"
        echo "3) DD Windows Server 2016 64位 精简版"
        echo "4) DD Windows Server 2019 64位 精简版"
        echo "5) DD Windows Server 2022 64位 精简版"
        echo "6) DD Windows7 32位 精简版"
        echo "7) DD Windows7 sp1 64位 企业精简版"
        echo "8) DD Windows8.1 64位 专业精简版"
        echo "9) DD Windows10 2016LTSB 64位 企业深度精简版"
        echo "10) DD Windows10 2019LTSC 64位 企业深度精简版"
        echo "11) DD Windows10 2021LTSC 64位 企业深度精简版"
        echo "12) 使用自定义链接"
        echo "13) 萌咖大佬脚本"
        echo "14) 直接回车返回菜单"
        read -p "请输入你的选择: " dd_choice

        case $dd_choice in
            1)
                dd_url='https://oss.suntl.com/Windows/Win_Server2008R2_sp1_64_Administrator_nat.ee.gz'
                account='Administrator'
                password='nat.ee'
                ;;
            2)
                dd_url='https://oss.suntl.com/Windows/Win_Server2012R2_64_Administrator_nat.ee.gz'
                account='Administrator'
                password='nat.ee'
                ;;
            3)
                dd_url='https://oss.suntl.com/Windows/Win_Server2016_64_Administrator_nat.ee.gz'
                account='Administrator'
                password='nat.ee'
                ;;
            4)
                dd_url='https://oss.suntl.com/Windows/Win_Server2019_64_Administrator_WinSrv2019dc-Chinese.gz'
                account='Administrator'
                password='WinSrv2019dc-Chinese'
                ;;
            5)
                dd_url='https://oss.suntl.com/Windows/Win_Server2022_64_Administrator_nat.ee.gz'
                account='Administrator'
                password='nat.ee'
                ;;
            6)
                dd_url='https://oss.suntl.com/Windows/Win7_86_Administrator_nat.ee.gz'
                account='Administrator'
                password='nat.ee'
                ;;
            7)
                dd_url='https://oss.suntl.com/Windows/Win7_sp1_64_Administrator_nat.ee.gz'
                account='Administrator'
                password='nat.ee'
                ;;
            8)
                dd_url='https://oss.suntl.com/Windows/Win8.1_64_Administrator_nat.ee.gz'
                account='Administrator'
                password='nat.ee'
                ;;
            9)
                dd_url='https://oss.suntl.com/Windows/Win10_2016LTSB_64_Administrator_nat.ee.gz'
                account='Administrator'
                password='nat.ee'
                ;;
            10)
                dd_url='https://oss.suntl.com/Windows/Win10_2019LTSC_64_Administrator_nat.ee.gz'
                account='Administrator'
                password='nat.ee'
                ;;
            11)
                dd_url='https://oss.suntl.com/Windows/Win10_2021LTSC_64_Administrator_nat.ee.gz'
                account='Administrator'
                password='nat.ee'
                ;;
            12)
                read -p "请输入自定义链接: " dd_url
                read -p "请输入账户名称: " account
                read -p "请输入密码: " password
                ;;
            13)
                read -p "请输入密码: " password
                read -p "请输入端口: " port
                echo "账户：root"
                echo "密码：$password"
                bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') -d 11 -v 64 -p $password -port $port -a -firmware
                echo "脚本运行完成。按回车键返回菜单。"
                read -r
                continue
                ;;
            14|"")
                echo "返回菜单。"
                return
                ;;
            *)
                echo "无效的选择，请重试。"
                continue
                ;;
        esac

        echo "账户：$account"
        echo "密码：$password"

        wget --no-check-certificate -qO InstallNET.sh 'https://suntl.com/other/oss/InstallNET.sh' && bash InstallNET.sh -dd "$dd_url"

        echo "脚本运行完成。按回车键返回菜单。"
        read -r
    done
}

comprehensive_test_script() {
    clear
    echo "选择一个综合测试脚本:"
    echo "1) 融合怪"
    echo "2) NodeBench"
    echo "3) yabs"
    echo "4) 使用 gb5 测试 yabs"
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
    echo "1) GB5 专测脚本"
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
    echo "1) media测试脚本"
    echo "2) check原生检测脚本"
    echo "3) Check准确度最高"
    echo "4) IP 质量体检脚本"
    echo "5) ChatGPT 解锁检测"
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

            # 定义一个函数来解析返回结果
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
    echo "1) Speedtest"
    echo "2) Taier"
    echo "3) hyperspeed"
    echo "4) 全球测速"
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
    echo "1) 直接显示回程（小白用这个）"
    echo "2) 回程详细测试（推荐）"
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
    clear
    echo "选择一个功能脚本:"
    echo "1) Fail2ban"
    echo "2) 一键开启BBR"
    echo "3) 多功能BBR安装脚本"
    echo "4) TCP窗口调优"
    echo "5) 测试访问优先级"
    echo "6) 添加SWAP"
    echo "7) 25端口开放测试"
    read -p "请输入你的选择: " function_choice
    case $function_choice in
        1)
            wget --no-check-certificate https://raw.githubusercontent.com/FunctionClub/Fail2ban/master/fail2ban.sh && bash fail2ban.sh 2>&1 | tee fail2ban.log
            ;;
        2)
            echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
            sysctl -p
            sysctl net.ipv4.tcp_available_congestion_control
            lsmod | grep bbr
            ;;
        3)
            wget -N --no-check-certificate "https://gist.github.com/zeruns/a0ec603f20d1b86de6a774a8ba27588f/raw/4f9957ae23f5efb2bb7c57a198ae2cffebfb1c56/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
            ;;
        4)
            wget http://sh.nekoneko.cloud/tools.sh -O tools.sh && bash tools.sh
            ;;
        5)
            curl ip.sb
            ;;
        6)
            wget https://www.moerats.com/usr/shell/swap.sh && bash swap.sh
            ;;
        7)
            telnet smtp.aol.com 25
            ;;
        *)
            echo "无效的选择，请重试。"
            ;;
    esac
    echo "脚本运行完成。按回车键返回菜单。"
    read -r
}

install_common_env_software() {
    clear
    echo "请选择要安装的项目:"
    echo "1) docker"
    echo "2) Python"
    echo "3) WARP"
    echo "4) Aria2"
    echo "5) aaPanel(宝塔国际版)"
    echo "6) 宝塔"
    echo "7) 宝塔开心版"
    read -p "请输入你的选择: " install_choice
    case $install_choice in
        1)
            echo "选择 docker 安装版本:"
            echo "1) 国外专用"
            echo "2) 国内专用"
            read -p "请输入你的选择: " docker_choice
            case $docker_choice in
                1)
                    curl -sSL https://get.docker.com/ | sh
                    ;;
                2)
                    curl -sSL https://get.daocloud.io/docker | sh
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
            wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh
            ;;
        4)
            wget -N git.io/aria2.sh && chmod +x aria2.sh && ./aria2.sh
            ;;
        5)
            URL=https://www.aapanel.com/script/install_7.0_en.sh && if [ -f /usr/bin/curl ];then curl -ksSO "$URL" ;else wget --no-check-certificate -O install_7.0_en.sh "$URL";fi;bash install_7.0_en.sh aapanel
            ;;
        6)
            url=https://download.bt.cn/install/install_lts.sh;if [ -f /usr/bin/curl ];then curl -sSO $url;else wget -O install_lts.sh $url;fi;bash install_lts.sh ed8484bec
            ;;
        7)
            echo "请访问：https://bt.sb/bbs/forum-37-1.html 获取"
            ;;
        *)
            echo "无效的选择，请重试。"
            ;;
    esac
    echo "脚本运行完成。按回车键返回菜单。"
    read -r
}


install_mieru_script() {
    clear
    echo "运行Mieru 综合功能脚本..."
    wget -N --no-check-certificate https://raw.githubusercontent.com/jianghulun123/mieru-script/main/mieru.sh && bash mieru.sh
    echo "运行完成。按回车键返回菜单。"
    read -r
}

while true; do
    clear
    show_menu
    read -p "请输入你的选择: " choice
    case $choice in
        1) kernel_optimization ;;
        2) install_and_test_nexttrace ;;
        3) xray_management ;;
        4) install_mieru_script ;;
        5) install_or_start_btop ;;
        6) install_techlion_script ;;
        7) install_skybox_script ;;
        8) install_v2bx_script ;;
        9) install_ddns_script ;;
        10) install_xboard ;;
        11) chicken_king_script ;;
        12) dd_reinstall_script ;;
        13) comprehensive_test_script ;;
        14) performance_test_script ;;
        15) media_ip_quality_test_script ;;
        16) network_speed_test_script ;;
        17) backtrace_test_script ;;
        18) function_script ;;
        19) install_common_env_software ;;
        20) echo "退出"; exit 0 ;;
        *) echo "无效的选择，请重试。"; read -r ;;
    esac
done
