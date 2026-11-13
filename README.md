# Oracle-server-keep-alive-script

[![Hits](https://hits.spiritlhl.net/Oracle-server-keep-alive-script.svg?action=hit&title=Hits&title_bg=%23555555&count_bg=%2324dde1&edge_flat=false)](https://hits.spiritlhl.net)

## 甲骨文服务器保活脚本

这个项目是给低负载机器做保活用的，占用项可选：CPU、内存、带宽。

运行脚本已统一为 POSIX `sh` 兼容，也可以直接用 `bash` 启动。

英文文档见 [README_EN.md](README_EN.md)。

## 支持范围

- Linux：Debian、Ubuntu、RHEL/CentOS/Oracle Linux/AlmaLinux/Rocky、Fedora、Amazon Linux、Arch、Alpine、openSUSE/SLES、Void、Gentoo 等常见发行版。
- BSD：FreeBSD、OpenBSD、NetBSD、DragonFly BSD 等带 `cron` 和标准 POSIX 工具的系统。
- 调度：Linux 且有 systemd 时走 systemd；非 systemd 的 Linux 和 BSD 走 cron 监督器。
- 包管理器：`apt-get`、`dnf`、`yum`、`microdnf`、`zypper`、`apk`、`pacman`、`pkg`、`pkg_add`、`pkgin`、`xbps-install`、`emerge`。

系统差异会自动降级处理。比如 BSD 没有 systemd 就走 cron；没有 speedtest 工具时，带宽模式会回退到默认速率估算，不会直接报错退出。

## 安装

使用 `sh`：

```sh
curl -fsSL https://raw.githubusercontent.com/spiritLHLS/Oracle-server-keep-alive-script/main/oalive.sh -o oalive.sh
chmod +x oalive.sh
sh oalive.sh
```

或使用 `bash`：

```sh
curl -fsSL https://raw.githubusercontent.com/spiritLHLS/Oracle-server-keep-alive-script/main/oalive.sh -o oalive.sh
chmod +x oalive.sh
bash oalive.sh
```

在仓库目录内运行：

```sh
sh oalive.sh
```

脚本需要 root 权限安装服务、cron、配置和日志目录。

## 菜单

- `1`：安装或重装保活服务
- `2`：卸载保活服务
- `3`：更新安装引导脚本
- `4`：退出

也可以使用命令行参数：

```sh
sh oalive.sh --install
sh oalive.sh --uninstall
sh oalive.sh --status
sh oalive.sh --update
```

## 特点

- CPU：默认使用 POSIX 兼容占用逻辑，按“单核配额百分比”工作；2 到 4 核机器默认 `核心数 * 20%`，其他机器默认 `25%`。在 systemd 环境会再写入 `CPUQuota` 做双重限制。
- 内存：默认目标为总内存 `25%`，每轮占用 300 秒、休息 300 秒。会读取 Linux `/proc/meminfo` 或 BSD `sysctl` 指标，并按临时目录可用空间限幅。
- 带宽：默认每 45 分钟触发一次，最长下载 6 分钟，速率按测速结果的 30%。下载源使用多个普通静态测试文件逐个探测；源全部不可用时跳过本轮并等待下次调度，不会反复请求失效的特殊下载地址。自定义模式可直接指定 Mbps、时长、间隔和下载源。
- 调度：systemd 环境安装 `cpu-limit.service`、`memory-limit.service`、`bandwidth_occupier.timer`；cron 环境安装 `oalive-cron-runner.sh` 监督器。
- 安全：所有任务都有原子目录锁，避免并发重入；卸载时按锁和精确脚本路径停止任务，不再靠模糊进程名匹配。
- 日志：日志写入 `/var/log/oalive`，单文件默认 128 KiB 自动轮转到 `.1`。

## 文件位置

- 配置：`/etc/oalive/oalive.conf`
- 启用状态：`/etc/oalive/enabled.conf`
- 日志：`/var/log/oalive/`
- 状态：`/var/lib/oalive/`
- 运行锁：`/tmp/oalive-*.lock`
- 运行脚本：`/usr/local/bin/cpu-limit.sh`、`/usr/local/bin/memory-limit.sh`、`/usr/local/bin/bandwidth_occupier.sh`、`/usr/local/bin/oalive-cron-runner.sh`

## 卸载

```sh
sh oalive.sh --uninstall
```

卸载会停止 systemd 服务或删除 cron 块，清理运行脚本、配置、状态文件和锁。重复卸载是安全的。

## 自定义

安装后可以编辑 `/etc/oalive/oalive.conf`，再重启对应调度：

带宽下载源可以用单个 URL、逗号或空格分隔的 URL 列表，或一个“每行一个 URL”的文件覆盖默认候选。探测使用短 `GET` 请求，避免只支持 `GET` 的源被错误排除；`BANDWIDTH_URL_CHECKS=0` 表示检查全部候选。所有源都失败时本轮会记录并跳过。

```sh
BANDWIDTH_URL=""
BANDWIDTH_URLS="https://example.com/large-file.bin,https://mirror.example.com/large-file.bin"
BANDWIDTH_URL_FILE=""
BANDWIDTH_URL_CHECKS=0
BANDWIDTH_PROBE_TIMEOUT=5
BANDWIDTH_PROBE_RATE=16384
```

systemd:

```sh
systemctl daemon-reload
systemctl restart cpu-limit.service memory-limit.service
systemctl restart bandwidth_occupier.timer
```

cron:

```sh
sh /usr/local/bin/oalive-cron-runner.sh --check
```

更多手动定时示例见 [README_CRON.md](README_CRON.md)。英文版定时说明见 [README_CRON_EN.md](README_CRON_EN.md)。

## 说明

资源占用能否影响云厂商回收策略，没有确定保证。

这个项目只提供可控、可卸载、低风险的占用任务，请按服务商条款和自己的实际用途自行判断。

## 友链

VPS融合怪测评项目：

- Go版本: <https://github.com/oneclickvirt/ecs>
- Shell版本: <https://github.com/spiritLHLS/ecs>

一键虚拟化项目：

- 国内: <https://virt.spiritlhl.net/>
- 国际: <https://www.spiritlhl.net/>

## Stargazers over time

[![Stargazers over time](https://api.star-history.com/chart?repos=spiritLHLS/Oracle-server-keep-alive-script&type=date)](https://starchart.cc/spiritLHLS/Oracle-server-keep-alive-script)
