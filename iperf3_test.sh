#!/bin/bash

# iperf3 网络性能测试脚本
# 支持自定义端口、协议、持续时间的网络测试工具

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认参数
DEFAULT_PORT=5201
DEFAULT_DURATION=10
DEFAULT_PROTOCOL="tcp"
DEFAULT_SERVER_IP="127.0.0.1"

# 全局变量
SERVER_PID=""
CLIENT_PID=""
CONFIG_FILE="/tmp/iperf3_config.conf"

# 检查iperf3是否安装
check_iperf3() {
    if ! command -v iperf3 &> /dev/null; then
        echo -e "${RED}错误：iperf3 未安装${NC}"
        echo "正在尝试安装 iperf3..."
        
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y iperf3
        elif command -v yum &> /dev/null; then
            sudo yum install -y iperf3
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y iperf3
        else
            echo -e "${RED}无法自动安装 iperf3，请手动安装${NC}"
            exit 1
        fi
        
        if command -v iperf3 &> /dev/null; then
            echo -e "${GREEN}iperf3 安装成功！${NC}"
        else
            echo -e "${RED}iperf3 安装失败${NC}"
            exit 1
        fi
    fi
}

# 检查端口是否可用
check_port() {
    local port=$1
    if lsof -i :$port &> /dev/null; then
        echo -e "${RED}端口 $port 已被占用${NC}"
        return 1
    fi
    return 0
}

# 启动iperf3服务器
start_server() {
    local port=$1
    local protocol=$2
    
    echo -e "${BLUE}正在启动 iperf3 服务器...${NC}"
    echo "端口：$port"
    echo "协议：$protocol"
    
    if ! check_port $port; then
        return 1
    fi
    
    # 构建服务器命令
    local server_cmd="iperf3 -s -p $port"
    
    if [[ "$protocol" == "udp" ]]; then
        server_cmd="$server_cmd -u"
    fi
    
    # 启动服务器（后台运行）
    eval "$server_cmd &"
    SERVER_PID=$!
    
    echo $SERVER_PID > /tmp/iperf3_server.pid
    
    # 等待服务器启动
    sleep 2
    
    # 检查服务器是否成功启动
    if ps -p $SERVER_PID > /dev/null; then
        echo -e "${GREEN}iperf3 服务器启动成功！PID：$SERVER_PID${NC}"
        echo -e "${YELLOW}服务器正在监听端口 $port${NC}"
        echo -e "${BLUE}服务器信息：${NC}"
        echo "  PID: $SERVER_PID"
        echo "  端口: $port"
        echo "  协议: $protocol"
        return 0
    else
        echo -e "${RED}iperf3 服务器启动失败${NC}"
        return 1
    fi
}

# 运行iperf3客户端测试
run_client_test() {
    local server_ip=$1
    local port=$2
    local protocol=$3
    local duration=$4
    
    echo -e "${BLUE}正在运行 iperf3 客户端测试...${NC}"
    echo "服务器地址：$server_ip"
    echo "端口：$port"
    echo "协议：$protocol"
    echo "持续时间：$duration 秒"
    
    # 构建客户端命令
    local client_cmd="iperf3 -c $server_ip -p $port -t $duration"
    
    if [[ "$protocol" == "udp" ]]; then
        client_cmd="$client_cmd -u -b 0"
    fi
    
    # 添加详细输出格式
    client_cmd="$client_cmd --json"
    
    echo -e "${YELLOW}开始测试...${NC}"
    echo "================================"
    
    # 运行测试
    eval "$client_cmd"
    
    local result=$?
    echo "================================"
    
    if [ $result -eq 0 ]; then
        echo -e "${GREEN}测试完成！${NC}"
    else
        echo -e "${RED}测试失败，错误代码：$result${NC}"
    fi
    
    return $result
}

# 停止iperf3服务器
stop_server() {
    if [ -f /tmp/iperf3_server.pid ]; then
        SERVER_PID=$(cat /tmp/iperf3_server.pid)
        if ps -p $SERVER_PID > /dev/null; then
            kill $SERVER_PID
            echo -e "${GREEN}iperf3 服务器已停止（PID：$SERVER_PID）${NC}"
        else
            echo -e "${YELLOW}iperf3 服务器进程不存在${NC}"
        fi
        rm -f /tmp/iperf3_server.pid
    else
        echo -e "${YELLOW}未找到运行的 iperf3 服务器${NC}"
    fi
    
    # 清理其他可能的iperf3进程
    pkill -f "iperf3 -s" 2>/dev/null
}

# 显示服务器状态
show_server_status() {
    echo -e "${BLUE}iperf3 服务器状态：${NC}"
    
    if [ -f /tmp/iperf3_server.pid ]; then
        SERVER_PID=$(cat /tmp/iperf3_server.pid)
        if ps -p $SERVER_PID > /dev/null; then
            echo -e "${GREEN}✓ 服务器正在运行${NC}"
            echo "  PID: $SERVER_PID"
            
            # 显示进程详情
            ps -p $SERVER_PID -o pid,ppid,cmd --no-headers
            
            # 显示端口监听状态
            echo ""
            echo "  端口监听状态："
            netstat -tlnp 2>/dev/null | grep iperf3 || echo "  无法获取端口信息"
        else
            echo -e "${RED}✗ 服务器进程不存在${NC}"
            rm -f /tmp/iperf3_server.pid
        fi
    else
        echo -e "${RED}✗ 未找到运行的服务器${NC}"
    fi
}

# 获取用户输入参数
get_user_input() {
    local prompt=$1
    local default=$2
    local validation_regex=$3
    
    echo -ne "${YELLOW}$prompt${NC} [默认: $default]: "
    read input
    
    if [[ -z "$input" ]]; then
        echo "$default"
        return
    fi
    
    if [[ -n "$validation_regex" ]]; then
        if [[ ! "$input" =~ $validation_regex ]]; then
            echo -e "${RED}输入无效，使用默认值：$default${NC}"
            echo "$default"
            return
        fi
    fi
    
    echo "$input"
}

# 服务器端配置菜单
server_config_menu() {
    echo -e "\n${BLUE}=== iperf3 服务器配置 ===${NC}"
    
    # 获取配置参数
    port=$(get_user_input "请输入监听端口" "$DEFAULT_PORT" "^[0-9]+$")
    
    echo -e "${BLUE}选择协议：${NC}"
    echo "1) TCP (推荐)"
    echo "2) UDP"
    echo -ne "${YELLOW}请选择 (1-2)${NC} [默认: 1]: "
    read protocol_choice
    
    case $protocol_choice in
        2) protocol="udp" ;;
        *) protocol="tcp" ;;
    esac
    
    echo -e "\n${BLUE}配置确认：${NC}"
    echo "端口：$port"
    echo "协议：$protocol"
    
    echo -ne "${YELLOW}确认启动服务器？(y/n)${NC} [默认: y]: "
    read confirm
    
    if [[ "$confirm" == "n" || "$confirm" == "N" ]]; then
        echo "取消启动服务器"
        return
    fi
    
    # 停止现有服务器
    stop_server
    
    # 启动新服务器
    if start_server $port $protocol; then
        echo -e "${GREEN}服务器配置完成！${NC}"
    else
        echo -e "${RED}服务器配置失败！${NC}"
    fi
}

# 客户端测试菜单
client_test_menu() {
    echo -e "\n${BLUE}=== iperf3 客户端测试 ===${NC}"
    
    # 获取配置参数
    server_ip=$(get_user_input "请输入服务器IP地址" "$DEFAULT_SERVER_IP" "")
    port=$(get_user_input "请输入服务器端口" "$DEFAULT_PORT" "^[0-9]+$")
    duration=$(get_user_input "请输入测试持续时间(秒)" "$DEFAULT_DURATION" "^[0-9]+$")
    
    echo -e "${BLUE}选择协议：${NC}"
    echo "1) TCP (推荐)"
    echo "2) UDP"
    echo -ne "${YELLOW}请选择 (1-2)${NC} [默认: 1]: "
    read protocol_choice
    
    case $protocol_choice in
        2) protocol="udp" ;;
        *) protocol="tcp" ;;
    esac
    
    echo -e "\n${BLUE}测试配置：${NC}"
    echo "服务器地址：$server_ip"
    echo "端口：$port"
    echo "协议：$protocol"
    echo "持续时间：$duration 秒"
    
    echo -ne "${YELLOW}确认开始测试？(y/n)${NC} [默认: y]: "
    read confirm
    
    if [[ "$confirm" == "n" || "$confirm" == "N" ]]; then
        echo "取消测试"
        return
    fi
    
    # 运行测试
    run_client_test $server_ip $port $protocol $duration
}

# 快速测试菜单
quick_test_menu() {
    echo -e "\n${BLUE}=== 快速测试 ===${NC}"
    
    echo "1) 启动默认服务器 (TCP, 5201端口)"
    echo "2) 连接本地服务器测试"
    echo "3) 自定义测试"
    echo "4) 返回主菜单"
    
    echo -ne "${YELLOW}请选择 (1-4)${NC} [默认: 1]: "
    read choice
    
    case $choice in
        2)
            echo -e "${BLUE}连接本地服务器测试...${NC}"
            stop_server
            start_server $DEFAULT_PORT "tcp"
            sleep 3
            run_client_test "127.0.0.1" $DEFAULT_PORT "tcp" $DEFAULT_DURATION
            ;;
        3)
            client_test_menu
            ;;
        4)
            return
            ;;
        *)
            echo -e "${BLUE}启动默认服务器...${NC}"
            stop_server
            start_server $DEFAULT_PORT "tcp"
            ;;
    esac
}

# 主菜单
show_main_menu() {
    clear
    echo -e "${GREEN}"
    echo "================================"
    echo "    iperf3 网络性能测试工具"
    echo "================================"
    echo -e "${NC}"
    echo -e "${BLUE}主菜单：${NC}"
    echo "1) 服务器管理"
    echo "2) 客户端测试"
    echo "3) 快速测试"
    echo "4) 查看服务器状态"
    echo "5) 停止服务器"
    echo "6) 帮助"
    echo "7) 退出"
}

# 帮助信息
show_help() {
    echo -e "\n${BLUE}=== 帮助信息 ===${NC}"
    echo -e "${YELLOW}功能说明：${NC}"
    echo "• 服务器管理：配置和启动iperf3服务器"
    echo "• 客户端测试：连接到服务器进行网络性能测试"
    echo "• 快速测试：一键启动默认配置进行测试"
    echo "• 服务器状态：查看当前服务器运行状态"
    echo "• 停止服务器：关闭正在运行的iperf3服务器"
    
    echo -e "\n${YELLOW}使用场景：${NC}"
    echo "• 测试网络带宽性能"
    echo "• 评估网络连接质量"
    echo "• 诊断网络问题"
    echo "• 服务器性能基准测试"
    
    echo -e "\n${YELLOW}参数说明：${NC}"
    echo "• 端口：1-65535之间的端口号"
    echo "• 协议：TCP或UDP"
    echo "• 持续时间：测试运行时间（秒）"
    echo "• 服务器IP：目标服务器的IP地址"
    
    echo -e "\n${YELLOW}注意事项：${NC}"
    echo "• 确保防火墙允许指定端口的通信"
    echo "• 服务器和客户端需要在同一网络或可互相访问"
    echo "• UDP测试可能产生大量流量"
    echo "• 测试结果受网络状况影响"
}

# 主程序
main() {
    # 检查iperf3安装
    check_iperf3
    
    while true; do
        show_main_menu
        
        echo -ne "${YELLOW}请选择 (1-7)${NC} [默认: 1]: "
        read choice
        
        case $choice in
            2)
                client_test_menu
                ;;
            3)
                quick_test_menu
                ;;
            4)
                show_server_status
                ;;
            5)
                stop_server
                ;;
            6)
                show_help
                ;;
            7)
                echo -e "${GREEN}感谢使用 iperf3 测试工具！${NC}"
                stop_server
                exit 0
                ;;
            *)
                server_config_menu
                ;;
        esac
        
        echo -e "\n${YELLOW}按回车键继续...${NC}"
        read
    done
}

# 检查是否直接运行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi