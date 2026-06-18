#!/bin/bash

# 常量定义
MANAGER_MODE="m"
STANDALONE_MODE="a"
DEFAULT_MODE="$MANAGER_MODE"
MAX_NOFILE=51200

# 确保必要目录存在
ensure_directories() {
    mkdir -p /var/run/shadowsocks /var/log/shadowsocks
}

# 获取 Python 版本
get_python_version() {
    # 优先使用 python3
    if command -v python3 &> /dev/null; then
        echo "python3"
    elif command -v python2.7 &> /dev/null; then
        echo "python2.7"
    else
        echo ""
    fi
}

# 获取 Shadowsocks 根目录
get_shadowsocks_root() {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
}

# 获取 server.py 路径
get_server_path() {
    local mode=$1
    local root_dir=$(get_shadowsocks_root)
    echo "${root_dir}/shadowsocks/server.py"
}

# 获取配置文件路径
get_config_path() {
    local mode=$1
    local root_dir=$(get_shadowsocks_root)
    local default_config="${root_dir}/shadowsocks.json"
    
    # 如果环境变量指定了配置文件，优先使用
    if [ -n "$SHADOWSOCKS_CONFIG_PATH" ] && [ -f "$SHADOWSOCKS_CONFIG_PATH" ]; then
        echo "$SHADOWSOCKS_CONFIG_PATH"
    elif [ -f "$default_config" ]; then
        echo "$default_config"
    else
        echo ""
        return 1
    fi
}

# 获取 PID 文件路径
get_pid_file() {
    local mode=$1
    echo "/var/run/shadowsocks/shadowsocks-${mode}.pid"
}

# 获取日志文件路径
get_log_file() {
    local mode=$1
    echo "/var/log/shadowsocks/shadowsocks-${mode}.log"
}

# 检查服务是否运行
is_running() {
    local mode=$1
    local pid_file=$(get_pid_file "$mode")
    [ -f "$pid_file" ] && kill -0 $(cat "$pid_file") 2>/dev/null
}

# 启动服务
start_server() {
    local mode=$1
    local log_enabled=$2
    local python_ver=$(get_python_version)
    local pid_file=$(get_pid_file "$mode")
    local log_file=$(get_log_file "$mode")
    local server_path=$(get_server_path "$mode")
    local config_path=$(get_config_path "$mode")
    
    # 检查配置文件
    if [ -z "$config_path" ]; then
        echo "错误：未找到有效的配置文件"
        return 1
    fi
    
    # 检查是否已经运行
    if is_running "$mode"; then
        echo "Shadowsocks is already running in $mode mode."
        return 1
    fi
    
    # 检查 Python 版本
    if [ -z "$python_ver" ]; then
        echo "Error: No suitable Python version found"
        return 1
    fi
    
    # 切换到 shadowsocks 目录
    cd "$(dirname "$server_path")"
    
    # 启动服务
    if [ "$log_enabled" = "true" ]; then
        nohup ${python_ver} "$server_path" -c "$config_path" >> "${log_file}" 2>&1 &
    else
        nohup ${python_ver} "$server_path" -c "$config_path" >> /dev/null 2>&1 &
    fi
    
    local pid=$!
    
    # 检查进程是否真正启动
    sleep 1
    if kill -0 $pid 2>/dev/null; then
        echo $pid > "$pid_file"
        echo "Shadowsocks started in $mode mode (PID: $pid)."
        return 0
    else
        echo "Failed to start Shadowsocks in $mode mode."
        if [ "$log_enabled" = "true" ]; then
            echo "Last few lines of log:"
            tail -n 5 "${log_file}"
        fi
        return 1
    fi
}

# 停止服务
stop_server() {
    local mode=$1
    local pid_file=$(get_pid_file "$mode")
    
    if [ ! -f "$pid_file" ]; then
        echo "Shadowsocks is not running in $mode mode."
        return 1
    fi
    
    local pid=$(cat "$pid_file")
    
    # 尝试正常终止
    kill "$pid" 2>/dev/null
    
    # 等待进程结束
    local timeout=10
    while [ $timeout -gt 0 ]; do
        if ! kill -0 "$pid" 2>/dev/null; then
            rm -f "$pid_file"
            echo "Shadowsocks stopped in $mode mode."
            return 0
        fi
        sleep 1
        ((timeout--))
    done
    
    # 强制终止
    kill -9 "$pid" 2>/dev/null
    rm -f "$pid_file"
    echo "Shadowsocks forcefully stopped in $mode mode."
    return 0
}

# 查看日志
tail_log() {
    local mode=$1
    local log_file=$(get_log_file "$mode")
    
    if [ ! -f "$log_file" ]; then
        echo "No log file found for $mode mode."
        return 1
    fi
    
    tail -f "$log_file"
}

# 获取服务状态
get_status() {
    local mode=$1
    local pid_file=$(get_pid_file "$mode")
    
    if [ -f "$pid_file" ] && kill -0 $(cat "$pid_file") 2>/dev/null; then
        echo "Shadowsocks is running in $mode mode (PID: $(cat "$pid_file"))."
    else
        echo "Shadowsocks is not running in $mode mode."
    fi
}
