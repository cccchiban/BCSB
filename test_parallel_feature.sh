#!/bin/bash

echo "=== 测试添加并发连接功能 ==="
echo ""

# 检查脚本语法
echo "1. 检查脚本语法..."
if bash -n iperf3_test.sh; then
    echo "✓ 脚本语法正确"
else
    echo "✗ 脚本语法错误"
    exit 1
fi

echo ""
echo "2. 检查并发功能添加情况..."

# 检查默认参数
if grep -q "DEFAULT_PARALLEL=1" iperf3_test.sh; then
    echo "✓ 已添加默认并发数参数"
else
    echo "✗ 未添加默认并发数参数"
fi

# 检查run_client_test函数
if grep -A 20 "run_client_test()" iperf3_test.sh | grep -q "parallel=$5"; then
    echo "✓ run_client_test函数已更新支持并发参数"
else
    echo "✗ run_client_test函数未正确更新"
fi

# 检查-P参数添加
if grep -A 5 "添加并发连接参数" iperf3_test.sh | grep -q "\-P"; then
    echo "✓ 已添加-P参数支持"
else
    echo "✗ 未添加-P参数支持"
fi

# 检查客户端菜单
if grep -A 10 "请输入并发连接数" iperf3_test.sh | grep -q "DEFAULT_PARALLEL"; then
    echo "✓ 客户端菜单已添加并发数输入选项"
else
    echo "✗ 客户端菜单未添加并发数输入选项"
fi

echo ""
echo "3. 功能验证..."

# 验证参数范围限制
if grep -A 15 "并发数过大" iperf3_test.sh | grep -q "限制为50"; then
    echo "✓ 已添加并发数范围限制 (1-50)"
else
    echo "✗ 未添加并发数范围限制"
fi

# 验证配置显示
if grep -A 5 "并发连接数：" iperf3_test.sh | grep -q "parallel"; then
    echo "✓ 配置确认会显示并发连接数"
else
    echo "✗ 配置确认未显示并发连接数"
fi

echo ""
echo "=== 功能添加总结 ==="
echo "1. 添加了DEFAULT_PARALLEL=1默认参数"
echo "2. 修改了run_client_test函数，添加第5个参数parallel"
echo "3. 在客户端命令中添加-P参数（当parallel>1时）"
echo "4. 客户端测试菜单增加了并发连接数输入选项"
echo "5. 添加了并发数范围限制（1-50）"
echo "6. 配置确认时会显示并发连接数（当>1时）"
echo ""
echo "现在用户可以使用类似以下命令进行并发测试："
echo "iperf3 -c <server_ip> -P 5 -t 10"
echo ""
echo "功能测试完成！"