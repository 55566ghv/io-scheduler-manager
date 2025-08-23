#!/system/bin/sh

# I/O调度器管理服务脚本

MODDIR=${0%/*}

# 加载配置文件
CONFIG_FILE="$MODDIR/../config/io-scheduler.conf"

# 默认调度器
DEFAULT_SCHEDULER="kyber"

# 获取配置的调度器
get_configured_scheduler() {
    if [ -f "$CONFIG_FILE" ]; then
        local scheduler=$(grep "^scheduler=" "$CONFIG_FILE" | cut -d '=' -f 2)
        if [ -n "$scheduler" ]; then
            echo "$scheduler"
            return
        fi
    fi
    echo "$DEFAULT_SCHEDULER"
}

# 获取所有块设备
get_block_devices() {
    for queue in /sys/block/*/queue; do
        if [ -d "$queue" ]; then
            echo "$queue"
        fi
    done
}

# 设置调度器
set_scheduler() {
    local scheduler=$1
    local success_count=0
    local total_count=0
    
    for queue in $(get_block_devices); do
        local scheduler_file="$queue/scheduler"
        if [ -f "$scheduler_file" ]; then
            total_count=$((total_count + 1))
            # 检查调度器是否支持
            if echo "$(cat "$scheduler_file")" | grep -q "$scheduler"; then
                echo "$scheduler" > "$scheduler_file" 2>/dev/null
                if [ "$?" -eq 0 ]; then
                    success_count=$((success_count + 1))
                else
                    log -p w -t io-scheduler "无法设置调度器 $scheduler 在 $(dirname "$queue")"
                fi
            else
                log -p w -t io-scheduler "调度器 $scheduler 不支持在 $(dirname "$queue")"
            fi
        fi
    done
    
    log -p i -t io-scheduler "设置调度器 $scheduler: $success_count/$total_count 设备成功"
}

# 主程序
main() {
    # 等待系统初始化完成
    sleep 30
    
    # 获取配置的调度器
    SCHEDULER=$(get_configured_scheduler)
    
    # 应用调度器设置
    set_scheduler "$SCHEDULER"
    
    log -p i -t io-scheduler "I/O调度器服务启动完成，使用调度器: $SCHEDULER"
}

# 执行主程序
main