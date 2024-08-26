#!/bin/bash

install_docker() {
    echo "Docker 未安装。是否现在安装 Docker? (y/n)"
    read -p "请输入你的选择: " install_choice
    case $install_choice in
        [Yy]* )
            echo "开始安装 Docker..."
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            sudo apt-get update
            sudo apt-get install -y docker-ce
            echo "Docker 安装完成。"
            ;;
        [Nn]* )
            echo "用户选择不安装 Docker。退出脚本。"
            exit 1
            ;;
        * )
            echo "无效的选择，请输入 y 或 n。"
            install_docker
            ;;
    esac
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        install_docker
    else
        echo "Docker 已安装。"
    fi
}

manage_betterforward() {
    clear
    echo "请选择操作:"
    echo -e "\033[32m1)\033[0m 部署 betterforward"
    echo -e "\033[32m2)\033[0m 更新 betterforward"
    read -p "请输入你的选择: " operation_choice

    case $operation_choice in
        1)
            clear
            echo "请选择语言选项:"
            echo -e "\033[32m1)\033[0m 英语 - en"
            echo -e "\033[32m2)\033[0m 中文 - zh_CN"
            echo -e "\033[32m3)\033[0m 日语 - ja_JP"
            read -p "请输入你的选择: " language_choice
            case $language_choice in
                1)
                    language="en"
                    ;;
                2)
                    language="zh_CN"
                    ;;
                3)
                    language="ja_JP"
                    ;;
                *)
                    echo "无效的选择，请重试。"
                    return
                    ;;
            esac

            read -p "请输入你的 Bot Token: " bot_token
            read -p "请输入你的 Group ID: " group_id
            read -p "请输入数据路径 (例如 /path/to/data): " data_path

            echo "正在部署 betterforward Docker 容器..."
            docker run -d --name betterforward \
                -e TOKEN="$bot_token" \
                -e GROUP_ID="$group_id" \
                -e LANGUAGE="$language" \
                -v "$data_path:/app/data" \
                --restart unless-stopped \
                pplulee/betterforward:latest

            echo "部署完成。按回车键返回菜单。"
            read -r
            ;;
        2)
            clear
            read -p "请输入容器名称 (默认: betterforward): " container_name
            container_name=${container_name:-betterforward}

            echo "使用 WatchTower 更新 Docker 容器..."
            docker run --rm \
                -v /var/run/docker.sock:/var/run/docker.sock \
                containrrr/watchtower -cR \
                "$container_name"

            echo "更新完成。按回车键返回菜单。"
            read -r
            ;;
        *)
            echo "无效的选择，请重试。"
            ;;
    esac
}

check_docker

manage_betterforward
