#!/bin/bash

# This script is extracted from the install_vless_tls_splithttp_h3 function

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