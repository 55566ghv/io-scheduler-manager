#!/system/bin/sh

# 模块安装脚本

# 设置权限
set_perm_recursive $MODDIR 0 0 0755 0644

# 创建默认配置文件
CONFIG_DIR="$MODDIR/config"
CONFIG_FILE="$CONFIG_DIR/io-scheduler.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$CONFIG_DIR"
    echo "scheduler=kyber" > "$CONFIG_FILE"
    echo "enabled=true" >> "$CONFIG_FILE"
fi

set_perm "$CONFIG_FILE" 0 0 0644

# 确保所有脚本具有执行权限
set_perm_recursive "$MODDIR/service.d" 0 0 0755 0755
set_perm_recursive "$MODDIR/customize.d" 0 0 0755 0755

# 如果post-fs-data.sh存在，设置执行权限
if [ -f "$MODDIR/post-fs-data.sh" ]; then
    set_perm "$MODDIR/post-fs-data.sh" 0 0 0755
fi

# 如果service.sh存在，设置执行权限
if [ -f "$MODDIR/service.sh" ]; then
    set_perm "$MODDIR/service.sh" 0 0 0755
fi

log -p i -t io-scheduler "模块安装完成"