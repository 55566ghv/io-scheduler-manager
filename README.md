# I/O Scheduler Manager

一个 KernelSU 模块，用于管理 Android 设备上的 I/O 调度器。

## 功能

1. 开机时自动设置 I/O 调度器
2. 支持多种调度器选项：
   - none
   - mq-deadline
   - kyber (默认)
   - bfq
3. WebUI 管理界面，可实时查看和更改 I/O 调度器

## 使用说明

安装模块后，设备将在启动时自动将 I/O 调度器设置为 kyber（默认）。您可以通过 KernelSU 的 WebUI 功能访问管理界面，实时查看当前调度器状态并进行更改。