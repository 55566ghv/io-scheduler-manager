#!/system/bin/sh
# 在文件系统准备就绪后尽早设置I/O调度器

MODDIR=${0%/*}

# 加载配置
CONFIG_FILE="$MODDIR/config/io-scheduler.conf"

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

# 设置调度器函数
set_scheduler() {
    local scheduler=$1
    local success_count=0
    local total_count=0
    
    # 遍历所有块设备
    for queue in /sys/block/*/queue; do
        if [ -d "$queue" ]; then
            local scheduler_file="$queue/scheduler"
            if [ -f "$scheduler_file" ]; then
                total_count=$((total_count + 1))
                # 检查调度器是否支持
                if echo "$(cat "$scheduler_file")" | grep -q "$scheduler"; then
                    echo "$scheduler" > "$scheduler_file" 2>/dev/null
                    if [ "$?" -eq 0 ]; then
                        success_count=$((success_count + 1))
                    fi
                fi
            fi
        fi
    done
    
    log -p i -t io-scheduler "早期阶段设置调度器 $scheduler: $success_count/$total_count 设备成功"
}

# 获取配置的调度器并应用
SCHEDULER=$(get_configured_scheduler)
set_scheduler "$SCHEDULER"