#!/bin/bash

# Function to display current port forwarding rules
show_rules() {
    # List current port forwarding rules
    rules=$(sudo iptables -t nat -L PREROUTING --line-numbers -n | grep DNAT)
    if [ -z "$rules" ]; then
        echo "当前没有端口转发规则。"
    else
        echo "当前的端口转发规则："
        echo "$rules"
    fi
}

# Function to check if the target is a domain
is_domain() {
    # Check if the target contains a dot, indicating it's likely a domain
    if [[ "$1" =~ \. ]]; then
        return 0  # It's a domain
    else
        return 1  # It's an IP address
    fi
}

# Main menu
while true; do
    clear
    echo "===== ShuaiGo 端口转发管理 ====="
    echo "1. 添加新的端口转发"
    echo "2. 查看现有端口转发"
    echo "3. 删除端口转发"
    echo "0. 退出"
    echo "请输入选项 (0-3)："
    read choice

    case $choice in
        1)
            # Add new port forwarding
            echo "请输入本地源 IP 地址："
            read local_ip
            echo "请输入本地源端口："
            read local_port
            echo "请输入目标 IP 地址或域名："
            read target_ip
            echo "请输入目标端口："
            read target_port

            # Check if target is a domain or IP address
            if is_domain "$target_ip"; then
                # If it's a domain, resolve to IP
                target_ip_resolved=$(dig +short "$target_ip" | head -n 1)  # Only take the first resolved IP
                if [ -z "$target_ip_resolved" ]; then
                    echo "无法解析域名 $target_ip"
                    continue
                else
                    target_ip=$target_ip_resolved
                    echo "域名 $target_ip 解析为 IP 地址 $target_ip"
                fi
            fi

            # Add port forwarding rule using iptables
            sudo iptables -t nat -A PREROUTING -p tcp --dport "$local_port" -j DNAT --to-destination "$target_ip":"$target_port"
            sudo iptables -A FORWARD -p tcp -d "$target_ip" --dport "$target_port" -j ACCEPT
            echo "端口转发已添加：$local_ip:$local_port -> $target_ip:$target_port"
            ;;
        2)
            # Show current port forwarding rules
            show_rules
            echo "按任意键返回主菜单..."
            read -n 1 -s
            ;;
        3)
            # Delete port forwarding rule
            show_rules
            echo "请输入要删除的规则编号："
            read rule_number
            sudo iptables -t nat -D PREROUTING "$rule_number"
            sudo iptables -D FORWARD "$rule_number"
            echo "端口转发规则已删除。"
            ;;
        0)
            # Exit
            echo "退出程序"
            exit 0
            ;;
        *)
            echo "无效选项，请重新选择！"
            ;;
    esac
done
