#!/bin/bash

install_hy2() {
  echo "安装或升级 hy2..."
  bash <(curl -fsSL https://get.hy2.sh/)
}

install_acme_cert() {
  echo "安装 acme.sh..."
  curl https://get.acme.sh | sh
  source ~/.bashrc

  echo "安装 socat..."
  sudo apt update
  sudo apt install -y socat

  read -p "请输入你的邮箱: " email
  acme.sh --register-account -m "$email"

  read -p "请输入你的域名: " domain
  acme.sh --issue --standalone -d "$domain"

  echo "移动证书文件..."
  sudo mkdir -p /etc/hysteria
  acme.sh --install-cert -d "$domain" --ecc \
      --fullchain-file /etc/hysteria/server.crt \
      --key-file /etc/hysteria/server.key

  sudo chmod +r /etc/hysteria/server.key
}

install_self_signed_cert() {
  echo "生成自定义 TLS 证书..."
  sudo mkdir -p /etc/hysteria
  tmpfile=$(mktemp)
  openssl ecparam -name prime256v1 -out "$tmpfile"
  sudo openssl req -x509 -nodes -newkey ec:"$tmpfile" -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=as.idolmaster-official.jp" -days 36500
  sudo chown hysteria /etc/hysteria/server.key
  sudo chown hysteria /etc/hysteria/server.crt
  rm "$tmpfile"
}

setup_hysteria_config() {
  read -p "请输入你的密码（回车生成随机6位数字）: " password
  password=${password:-$(shuf -i 100000-999999 -n 1)}
  read -p "是否开启流量混淆（true/false，回车默认false）: " enable_obfs
  enable_obfs=${enable_obfs:-false}
  if [ "$enable_obfs" == "true" ]; then
    read -p "请输入混淆密码（回车生成随机6位数字）: " obfs_password
    obfs_password=${obfs_password:-$(shuf -i 100000-999999 -n 1)}
  fi
  read -p "请输入伪装网站（回车默认使用www.cisco.com）: " masquerade_url
  masquerade_url=${masquerade_url:-www.cisco.com}
  read -p "请输入上行速率（如：100 mbps，回车默认使用100 mbps）: " up_bandwidth
  up_bandwidth=${up_bandwidth:-100 mbps}
  read -p "请输入下行速率（如：100 mbps，回车默认使用100 mbps）: " down_bandwidth
  down_bandwidth=${down_bandwidth:-100 mbps}
  read -p "是否忽略客户端速率限制（true/false，回车默认false）: " ignore_bandwidth
  ignore_bandwidth=${ignore_bandwidth:-false}
  read -p "请输入监听端口（回车范围10000-50000内随机选一个）: " listen_port
  listen_port=${listen_port:-$((RANDOM % 40001 + 10000))}
  read -p "是否优先访问IPv4（输入true或false，回车默认true）: " prefer_ipv4
  prefer_ipv4=${prefer_ipv4:-true}

  mode=46
  if [ "$prefer_ipv4" == "false" ]; then
    mode=64
  fi

  sudo mkdir -p /etc/hysteria

  cat <<EOF | sudo tee /etc/hysteria/config.yaml
listen: 0.0.0.0:$listen_port

tls: 
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key
auth:
  type: password
  password: $password
EOF

  if [ "$enable_obfs" == "true" ]; then
    cat <<EOF | sudo tee -a /etc/hysteria/config.yaml
obfs:
  type: salamander
  salamander:
    password: $obfs_password
EOF
  fi

  cat <<EOF | sudo tee -a /etc/hysteria/config.yaml
masquerade:
  type: proxy
  proxy:
    url: $masquerade_url
    rewriteHost: true

ignoreClientBandwidth: $ignore_bandwidth 

quic:
  initStreamReceiveWindow: 8388608 
  maxStreamReceiveWindow: 8388608 
  initConnReceiveWindow: 20971520 
  maxConnReceiveWindow: 20971520 
  maxIdleTimeout: 30s 
  maxIncomingStreams: 1024 
  disablePathMTUDiscovery: false

bandwidth:
  up: $up_bandwidth
  down: $down_bandwidth

outbounds:
  - name: hoho
    type: direct
    direct:
      mode: $mode 
EOF

  read -p "是否使用端口跳跃（y/n，回车默认n）: " use_port_hopping
  use_port_hopping=${use_port_hopping:-n}

  if [ "$use_port_hopping" == "y" ]; then
    if ! command -v iptables &> /dev/null; then
      echo "安装 iptables..."
      sudo apt install -y iptables
    fi

    read -p "请输入端口跳跃范围（如：20000:50000）: " port_range
    echo "设置端口跳跃规则..."
    sudo iptables -t nat -A PREROUTING -i eth0 -p udp --dport "$port_range" -j REDIRECT --to-ports "$listen_port"
    sudo ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport "$port_range" -j REDIRECT --to-ports "$listen_port"
  fi
}

uninstall_hy2() {
  echo "卸载 hy2..."
  bash <(curl -fsSL https://get.hy2.sh/) --remove
}

upgrade_hy2() {
  echo "升级 hy2..."
  bash <(curl -fsSL https://get.hy2.sh/)
}

generate_share_link() {
  local ip=$(curl -s4 ifconfig.me)  # 使用IPv4地址
  if [ "$use_port_hopping" == "y" ]; then
    local share_link="hy2://$password@$ip:$listen_port?mport=$listen_port,$port_range&insecure=1&sni=$1#$ip"
  else
    local share_link="hy2://$password@$ip:$listen_port?insecure=1&sni=$1#$ip"
  fi
  echo "分享链接: $share_link"
}

clear
echo "选择一个选项:"
echo "1) 证书安装"
echo "2) 自签证书安装"
echo "3) 卸载 hy2"
echo "4) 升级 hy2"
read -p "请输入你的选择: " choice

case $choice in
  1)
    install_hy2
    install_acme_cert
    setup_hysteria_config
    systemctl enable --now hysteria-server.service
    generate_share_link "$domain"
    ;;
  2)
    install_hy2
    setup_hysteria_config
    install_self_signed_cert
    systemctl enable --now hysteria-server.service
    generate_share_link "$masquerade_url"
    ;;
  3)
    uninstall_hy2
    ;;
  4)
    upgrade_hy2
    ;;
  *)
    echo "无效的选择，请重试。"
    ;;
esac

echo "操作完成。"
