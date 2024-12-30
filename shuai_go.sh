#!/bin/bash

# 添加新的端口转发规则
add_forward_rule() {
    echo "逐步添加端口转发规则："
    read -p "请输入源IP（例如 192.168.1.1）: " source_ip
    read -p "请输入源端口（例如 443）: " source_port
    read -p "请输入目标IP或域名（例如 192.168.1.x 或 www.example.com）: " target_ip
    read -p "请输入目标端口（例如 443）: " target_port

    # 添加转发规则并立即生效
    sudo iptables -t nat -A PREROUTING -p tcp --dport "$source_port" -d "$source_ip" -j DNAT --to-destination "$target_ip":"$target_port"
    sudo iptables -t nat -A POSTROUTING -p tcp -d "$target_ip" --dport "$target_port" -j MASQUERADE
    echo "已添加转发规则: $source_ip:$source_port -> $target_ip:$target_port"
}

# 获取并显示现有的端口转发规则
get_forward_rules() {
    echo "当前端口转发规则："
    sudo iptables -t nat -L -n -v | grep 'DNAT' | nl
}

# 删除某个端口转发规则
delete_forward_rule() {
    get_forward_rules
    read -p "请输入要删除的规则编号: " rule_number

    # 获取规则的行号并删除
    line_num=$(sudo iptables -t nat -L -n -v --line-numbers | grep 'DNAT' | nl | grep -w "$rule_number" | awk '{print $1}')
    
    if [ -z "$line_num" ]; then
        echo "无效的编号！"
        return
    fi
    
    # 删除规则
    sudo iptables -t nat -D PREROUTING $line_num
    sudo iptables -t nat -D POSTROUTING $line_num
    echo "已删除规则编号为 $rule_number 的转发规则"
}

# 显示简化菜单
show_menu() {
    clear
    echo "帅转发 (ShuaiGo) 端口转发管理"
    echo "-------------------------------"
    echo "1. 添加"
    echo "2. 查看"
    echo "3. 删除"
    echo "0. 退出"
    echo "-------------------------------"
}

# 处理用户输入
process_input() {
    case $1 in
        1) add_forward_rule ;;
        2) get_forward_rules ;;
        3) delete_forward_rule ;;
        0) exit 0 ;;
        *) echo "无效选项，请重新选择。" ;;
    esac
}

# 主程序
while true; do
    show_menu
    read -p "请输入选项: " option
    process_input $option
done
