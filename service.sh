#!/system/bin/sh
# 启动服务

MODDIR=${0%/*}

# 设置权限
set_permissions() {
    # 确保配置文件有正确的权限
    if [ -f "$MODDIR/config/io-scheduler.conf" ]; then
        chmod 644 "$MODDIR/config/io-scheduler.conf"
    fi
    
    # 确保脚本有执行权限
    chmod 755 "$MODDIR/service.d/io-scheduler-service.sh"
    
    # 确保WebUI脚本有执行权限
    if [ -f "$MODDIR/webroot/api.sh" ]; then
        chmod 755 "$MODDIR/webroot/api.sh"
    fi
}

# 主程序
main() {
    log -p i -t io-scheduler "I/O调度器管理器服务启动"
    
    # 设置权限
    set_permissions
    
    # 启动I/O调度器服务
    "$MODDIR/service.d/io-scheduler-service.sh" &
    
    log -p i -t io-scheduler "I/O调度器管理器服务启动完成"
}

# 执行主程序
main