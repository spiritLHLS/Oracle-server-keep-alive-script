# Oracle-server-keep-alive-script

## 甲骨文服务器保活脚本

适配系统：已在Ubuntu 20+，Debian 10+, Centos 7+, Oracle linux 8+，AlmaLinux 8.5+

上述系统验证无问题，别的主流系统应该也没有问题

可选占用：CPU，内存，带宽

安装完毕后如果有问题请卸载脚本反馈问题(重复卸载也没问题)

所有资源(除了CPU)可选默认配置则动态占用，实时调整，避免服务器有别的任何资源已经超过限额了仍然再占用资源

为避免GitHub的CDN抽风加载不了新内容，所有新更新已使用[Gitlab仓库](https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script)

由于speedtest-go的release依赖于GitHub，所以请检查 [www.githubstatus.com](https://www.githubstatus.com/) ,有问题时无法安装带宽占用

请留意脚本当前更新日期：2023.05.26.19.40

**由于友人实测，资源占用感觉也是玄学，一个号四个服务器全部停机，但号还在，也有人一直不占用，但就是没停机的问题，所以该项目将长期保持现有状态，非必要不再更新**

### 更新

2023.05.26 修复部分地区下载speedtest-go缓慢的问题，自动判断可用cdn使用CDN加速下载，选项修复支持输入错误重新输入

### 说明

选项1安装，选项2卸载，选项3更新安装引导脚本，选项4退出脚本

安装过程中无脑回车则全部可选的占用都占用，不需要什么占用输入```n```再回车

如果选择带宽占用，会询问使用speedtest-go占用还是使用wget占用，按照提示进行选择即可

有询问是否需要带宽占用的参数自定义，这时候默认选项就是```n```，回车就使用默认配置，输入```y```再回车则需要按照提示自定义参数

```
curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/oalive.sh -o oalive.sh && chmod +x oalive.sh && bash oalive.sh
```

或

```
bash oalive.sh
```

或

```
bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/oalive.sh)
```

### 特点

- 提供两种CPU占用模式：DD模拟占用和科学计算模式，用户可以自由选择，占用范围设置在15%至25%之间，更推荐DD模拟占用
- DD模拟占用在守护进程中设置了CPU占用的最高限制
- 默认情况下，CPU占用设置为25%最高值，计算方法是核数乘以12%，如果计算结果低于25%，则设置为该值；如果计算结果高于25%，则按照计算结果的比例进行设置。
- 内存占用设置为占用总内存的20%，占用时间为300秒，休息时间为300秒。
- 每300秒检测一次内存占用情况，并根据需要动态调整占用大小。如果内存占用已经大于20%，则不增加占用。
- 在占用过程中，使用守护进程和开机自启服务，以确保占用任务持续且有效。
- 默认选项的带宽占用每45分钟下载一次大小在1G至10G之间的文件，只进行下载而不保存。在下载过程中会占用硬盘空间，但在下载完成后会自动释放。
- 默认选项的带宽占用动态调整实际下载的带宽/速率，限制每次下载的最长时长为6分钟。在每次下载之前，会测试最大可用带宽，并根据实时结果将下载速率设置为30%的带宽。
- 带宽占用测试使用了speedtest-cli和speedtest-go两种工具，以防其中之一不可用时使用第二种工具，用户可以自定义设置带宽占用，此时详见设置提示。
- 提供一键卸载所有占用服务的选项，卸载将删除所有脚本、服务、任务、守护进程和开机自启设置。
- 提供一键检查更新的功能，更新范围仅限于脚本更新。**请在更新后重新设置占用服务**
- 对所有进程执行增加唯一性检测，避免重复运行，使用PID文件进行判断。

如若不希望一键的，希望自定义设置时间的，请查看[README_CRON.md](https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/blob/main/%20README_CRON.md)自行设置定时任务

### 友链

VPS融合怪测评脚本

https://github.com/spiritLHLS/ecs

## Stargazers over time

[![Stargazers over time](https://starchart.cc/spiritLHLS/Oracle-server-keep-alive-script.svg)](https://starchart.cc/spiritLHLS/Oracle-server-keep-alive-script)
