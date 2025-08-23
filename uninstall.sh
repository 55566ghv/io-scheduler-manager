#!/system/bin/sh
# 模块卸载脚本

MODDIR=${0%/*}
WEBSERVER_PID_FILE="$MODDIR/webserver.pid"

# 停止WebUI服务
stop_webui() {
    if [ -f "$WEBSERVER_PID_FILE" ]; then
        local pid=$(cat "$WEBSERVER_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log -p i -t io-scheduler "WebUI服务已停止 PID: $pid"
        fi
        rm -f "$WEBSERVER_PID_FILE"
    fi
}

# 主程序
main() {
    log -p i -t io-scheduler "卸载I/O调度器管理器"
    
    # 停止WebUI服务
    stop_webui
    
    # 可以选择恢复默认调度器或保持当前设置
    log -p i -t io-scheduler "I/O调度器管理器卸载完成"
}

# 执行主程序
main