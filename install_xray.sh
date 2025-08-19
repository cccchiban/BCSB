#!/bin/bash

# This script is extracted from the install_xtls_rprx_vision_reality function

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