#!/bin/bash

# --- 配置 ---
CONTAINER_NAME="komari"
IMAGE_NAME="ghcr.io/komari-monitor/komari:latest"
DATA_DIR="./data"

# --- 函数 ---

# 检查容器是否存在
container_exists() {
    if [ $(docker ps -a -f name=^/${CONTAINER_NAME}$ | grep -w ${CONTAINER_NAME} | wc -l) -gt 0 ]; then
        return 0 # 存在
    else
        return 1 # 不存在
    fi
}

# 获取用户配置
get_user_config() {
    read -p "请输入 Komari 的管理员用户名 (默认为 admin): " ADMIN_USERNAME
    ADMIN_USERNAME=${ADMIN_USERNAME:-admin}

    read -p "请输入 Komari 的管理员密码: " ADMIN_PASSWORD
    if [ -z "$ADMIN_PASSWORD" ]; then
        echo "错误：密码不能为空！"
        exit 1
    fi

    read -p "请输入端口映射 (例如: 25774:25774 或 127.0.0.1:25774:25774): " PORT_MAPPING
    PORT_MAPPING=${PORT_MAPPING:-"25774:25774"}
}

# 安装 Komari
install_komari() {
    if container_exists; then
        echo "错误: Komari 容器已存在。如果您想更新或重新配置，请选择 '更新' 选项。"
        return
    fi

    echo "--- 开始安装 Komari ---"
    get_user_config

    echo "正在创建数据目录 '${DATA_DIR}'..."
    mkdir -p ${DATA_DIR}

    echo "正在拉取最新的 Komari 镜像..."
    docker pull ${IMAGE_NAME}

    echo "正在启动 Komari 容器..."
    docker run -d \
      -p "${PORT_MAPPING}" \
      -v "$(pwd)/${DATA_DIR#./}:/app/data" \
      -e ADMIN_USERNAME="${ADMIN_USERNAME}" \
      -e ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
      --name ${CONTAINER_NAME} \
      ${IMAGE_NAME}

    if [ $? -eq 0 ]; then
        echo "--- Komari 安装成功！ ---"
        echo "访问地址: http://<your_server_ip>:${PORT_MAPPING##*:}"
        echo "用户名: ${ADMIN_USERNAME}"
        echo "密码: ${ADMIN_PASSWORD}"
    else
        echo "--- Komari 安装失败！ ---"
    fi
}

# 更新或重新配置 Komari
update_komari() {
    if ! container_exists; then
        echo "错误: Komari 容器不存在。请先选择 '安装' 选项。"
        return
    fi

    echo "--- 开始更新/重新配置 Komari ---"
    echo "请输入新的配置信息。"
    get_user_config

    echo "正在停止并删除旧容器..."
    docker stop ${CONTAINER_NAME}
    docker rm ${CONTAINER_NAME}

    echo "正在拉取最新的 Komari 镜像..."
    docker pull ${IMAGE_NAME}

    echo "正在使用新配置启动 Komari 容器..."
    docker run -d \
      -p "${PORT_MAPPING}" \
      -v "$(pwd)/${DATA_DIR#./}:/app/data" \
      -e ADMIN_USERNAME="${ADMIN_USERNAME}" \
      -e ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
      --name ${CONTAINER_NAME} \
      ${IMAGE_NAME}

    if [ $? -eq 0 ]; then
        echo "--- Komari 更新/重新配置成功！ ---"
        echo "访问地址: http://<your_server_ip>:${PORT_MAPPING##*:}"
        echo "用户名: ${ADMIN_USERNAME}"
        echo "密码: ${ADMIN_PASSWORD}"
    else
        echo "--- Komari 更新/重新配置失败！ ---"
    fi
}

# 卸载 Komari
uninstall_komari() {
    if ! container_exists; then
        echo "Komari 容器不存在，无需卸载。"
        return
    fi

    echo "正在停止并删除 Komari 容器..."
    docker stop ${CONTAINER_NAME}
    docker rm ${CONTAINER_NAME}
    echo "容器 '${CONTAINER_NAME}' 已被删除。"

    read -p "是否要删除数据目录 '${DATA_DIR}'? (这是一个危险操作，数据将无法恢复) [y/N]: " confirm_delete
    if [[ "$confirm_delete" == "y" || "$confirm_delete" == "Y" ]]; then
        echo "正在删除数据目录 '${DATA_DIR}'..."
        rm -rf ${DATA_DIR}
        echo "数据目录已删除。"
    else
        echo "已保留数据目录 '${DATA_DIR}'。"
    fi
    echo "--- Komari 卸载完成 ---"
}

# 主菜单
main_menu() {
    clear
    echo "============================="
    echo "  Komari Docker 管理脚本"
    echo "============================="
    echo "1. 安装 Komari"
    echo "2. 更新 / 重新配置 Komari"
    echo "3. 卸载 Komari"
    echo "4. 退出"
    echo "-----------------------------"
    read -p "请输入您的选择 [1-4]: " choice

    case $choice in
        1) install_komari ;;
        2) update_komari ;;
        3) uninstall_komari ;;
        4) exit 0 ;;
        *) echo "无效选项，请输入 1 到 4 之间的数字。" ;;
    esac
}

# --- 脚本开始执行 ---
main_menu