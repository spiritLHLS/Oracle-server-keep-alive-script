# Oracle-server-keep-alive-script

## 甲骨文服务器保活脚本

适配系统：已在Ubuntu 20+，Debian 10+, Centos 7+, Oracle linux 8+，AlmaLinux 8.5+

上述系统验证无问题，别的主流系统应该也没有问题

可选占用：CPU，内存，带宽

安装完毕后如果有问题请卸载脚本反馈问题(重复卸载也没问题)

所有资源都是动态占用，实时调整，避免服务器有别的任何资源已经超过限额了仍然再占用资源

为避免GitHub的CDN抽风加载不了新内容，所有新更新已使用[Gitlab仓库](https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script)，本仓库仅作存档

由于speedtest-go的release依赖于GitHub，所以请检查 [www.githubstatus.com](https://www.githubstatus.com/) ,有问题时无法安装带宽占用

请留意脚本当前更新日期：2023.04.20.17.40

### 更新

2023.04.26

更新内存占用脚本，使得计算精确度从GB改到MB，增加精准度

主体安装脚本未作修改，所以不更改版本号

### 基础开发完毕，测试中，有问题请在issues中反馈

选项1安装，选项2卸载，选项3更新安装引导脚本，选项4退出脚本

安装过程中无脑回车则全部可选的占用都占用，不需要什么占用输入```n```再回车

如果选择带宽占用，会询问使用speedtest-go占用还是使用wget占用，按照提示进行选择即可

最后会询问是否需要带宽占用的参数自定义，这时候默认选项就是```n```，回车就使用默认配置，输入```y```再回车则需要按照提示自定义参数

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

### 说明

- CPU占用有DD模拟占用模式和科学计算模式可自由选择，设定占用区间为15~25%
- CPU占用在守护进程中设置了最高占用
- CPU占用默认25%最高(核数✖12%如果低于25%时设置，高于25%则按照计算后的比例来)
- 内存占用设定占用20%总内存，占用300秒休息300秒
- 内存占用每300秒检测一遍，动态调整增加占用的大小，如果你内存大于20%则不增加占用
- 带宽占用每45分钟下载一次1G~10G大小的文件进行占用，只下载不保存，下载过程中会占用硬盘但下载完成后自动释放
- 带宽占用动态调整实际下载带宽/速率，限制下载时长最长6分钟，每次下载前先测试最大可用带宽实时调整为30%带宽下载
- 带宽占用测试使用speedtest-cli和speedtest-go双重保险，可自定义设置带宽占用
- 占用过程中使用守护进程和开机自启服务，保证占用任务持续且有效
- 可选择一键卸载所有占用服务，卸载会将所有脚本和服务卸载，包括任务、守护进程和开机自启的设置
- 一键检查更新，更新仅限于脚本更新，**更新后请重新设置占用服务**
- 对所有进程执行增加唯一性检测(PID文件判断)，避免重复运行

如若不希望一键的，希望自定义设置时间的，请查看[README_CRON.md](https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/blob/main/%20README_CRON.md)自行设置定时任务

### 待开发内容

使用docker整合所有脚本，方便使用

### 友链

VPS融合怪测评脚本

https://github.com/spiritLHLS/ecs

## Stargazers over time

[![Stargazers over time](https://starchart.cc/spiritLHLS/Oracle-server-keep-alive-script.svg)](https://starchart.cc/spiritLHLS/Oracle-server-keep-alive-script)
