#!/system/bin/sh

# I/O调度器管理器API脚本

MODDIR=${0%/*}/..
CONFIG_FILE="$MODDIR/config/io-scheduler.conf"

# 设置内容类型
set_content_type() {
    echo "Content-Type: application/json"
    echo ""
}

# 获取当前调度器状态
get_status() {
    local current_scheduler=""
    local device_count=0
    
    # 从配置文件获取当前调度器
    if [ -f "$CONFIG_FILE" ]; then
        current_scheduler=$(grep "^scheduler=" "$CONFIG_FILE" | cut -d '=' -f 2)
    fi
    
    # 统计支持的设备数量
    for queue in /sys/block/*/queue; do
        if [ -d "$queue" ]; then
            device_count=$((device_count + 1))
        fi
    done
    
    cat << EOF
{
  "current_scheduler": "${current_scheduler:-kyber}",
  "device_count": $device_count,
  "module_version": "v1.0"
}
EOF
}

# 获取可用的调度器列表
get_schedulers() {
    local current_scheduler=""
    local schedulers=()
    
    # 从配置文件获取当前调度器
    if [ -f "$CONFIG_FILE" ]; then
        current_scheduler=$(grep "^scheduler=" "$CONFIG_FILE" | cut -d '=' -f 2)
    fi
    
    # 获取第一个设备的可用调度器（假设所有设备支持相同的调度器）
    local first_queue="/sys/block/$(ls /sys/block/ | head -1)/queue/scheduler"
    if [ -f "$first_queue" ]; then
        schedulers=($(cat "$first_queue" | sed 's/\[//g' | sed 's/\]//g' | tr ' ' '\n'))
    else
        # 默认调度器列表
        schedulers=("none" "mq-deadline" "kyber" "bfq")
    fi
    
    echo "{\"schedulers\": ["
    local first=true
    for scheduler in "${schedulers[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        echo "\"$scheduler\""
    done
    echo "], \"current\": \"${current_scheduler:-kyber}\"}"
}

# 应用新的调度器
apply_scheduler() {
    local scheduler=""
    
    # 从POST数据中读取调度器
    while read -r line; do
        if echo "$line" | grep -q "scheduler="; then
            scheduler=$(echo "$line" | cut -d '=' -f 2)
            break
        fi
    done
    
    if [ -z "$scheduler" ]; then
        echo '{"success": false, "message": "未指定调度器"}'
        return 1
    fi
    
    # 更新配置文件
    if [ -f "$CONFIG_FILE" ]; then
        if grep -q "^scheduler=" "$CONFIG_FILE"; then
            sed -i "s/^scheduler=.*/scheduler=$scheduler/" "$CONFIG_FILE"
        else
            echo "scheduler=$scheduler" >> "$CONFIG_FILE"
        fi
    else
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo "scheduler=$scheduler" > "$CONFIG_FILE"
        echo "enabled=true" >> "$CONFIG_FILE"
    fi
    
    # 立即应用调度器
    local success_count=0
    local total_count=0
    
    for queue in /sys/block/*/queue; do
        if [ -d "$queue" ]; then
            local scheduler_file="$queue/scheduler"
            if [ -f "$scheduler_file" ]; then
                total_count=$((total_count + 1))
                if echo "$(cat "$scheduler_file")" | grep -q "$scheduler"; then
                    echo "$scheduler" > "$scheduler_file" 2>/dev/null
                    if [ "$?" -eq 0 ]; then
                        success_count=$((success_count + 1))
                    fi
                fi
            fi
        fi
    done
    
    echo "{\"success\": true, \"message\": \"成功应用到 $success_count/$total_count 设备\"}"
}

# 主程序
main() {
    local request_method="$REQUEST_METHOD"
    local path_info="$PATH_INFO"
    
    set_content_type
    
    case "$path_info" in
        "/status")
            get_status
            ;;
        "/schedulers")
            get_schedulers
            ;;
        "/apply")
            if [ "$request_method" = "POST" ]; then
                apply_scheduler
            else
                echo '{"success": false, "message": "只支持POST请求"}'
            fi
            ;;
        *)
            echo '{"success": false, "message": "无效的API端点"}'
            ;;
    esac
}

# 执行主程序
main