#!/bin/bash

# 设置错误处理
set -e

# 导入共享库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# 显示用法
usage() {
    echo "Usage: $0 {start|stop|restart|status|log} [-m mode] [-l] [-c config_path]"
    echo "Options:"
    echo "  -m mode   运行模式: 'm' (manager) 或 'a' (standalone), 默认: 'm'"
    echo "  -l        启用日志记录"
    echo "  -c path   指定配置文件路径 (可选)"
    echo "Commands:"
    echo "  start     启动服务"
    echo "  stop      停止服务"
    echo "  restart   重启服务"
    echo "  status    查看服务状态"
    echo "  log       查看服务日志"
    exit 1
}

# 参数解析
MODE=${DEFAULT_MODE}
LOG_ENABLED="false"
CONFIG_PATH=""

while getopts "m:lc:" opt; do
    case $opt in
        m)
            MODE=$OPTARG
            if [ "$MODE" != "$MANAGER_MODE" ] && [ "$MODE" != "$STANDALONE_MODE" ]; then
                echo "错误: 无效的模式 '$MODE'. 必须是 'm' 或 'a'."
                usage
            fi
            ;;
        l)
            LOG_ENABLED="true"
            ;;
        c)
            CONFIG_PATH=$OPTARG
            # 验证配置文件是否存在
            if [ ! -f "$CONFIG_PATH" ]; then
                echo "错误: 配置文件 '$CONFIG_PATH' 不存在."
                exit 1
            fi
            export SHADOWSOCKS_CONFIG_PATH="$CONFIG_PATH"
            ;;
        *)
            usage
            ;;
    esac
done

shift $((OPTIND-1))
COMMAND=$1

# 确保必要的目录存在
ensure_directories

# 执行命令
case "$COMMAND" in
    start)
        if ! start_server "$MODE" "$LOG_ENABLED"; then
            echo "错误: 启动服务失败."
            exit 1
        fi
        ;;
    stop)
        if ! stop_server "$MODE"; then
            echo "错误: 停止服务失败."
            exit 1
        fi
        ;;
    restart)
        stop_server "$MODE" || true
        sleep 1
        if ! start_server "$MODE" "$LOG_ENABLED"; then
            echo "错误: 重启服务失败."
            exit 1
        fi
        ;;
    status)
        get_status "$MODE"
        ;;
    log)
        if ! tail_log "$MODE"; then
            echo "错误: 无法查看日志."
            exit 1
        fi
        ;;
    *)
        usage
        ;;
esac
