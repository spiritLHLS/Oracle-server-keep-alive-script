# Oracle-server-keep-alive-script

## 甲骨文服务器保活脚本

所有资源都是动态占用，实时调整，避免服务器有别的任何资源已经超过限额了仍然再占用资源。

适配系统：暂时已在Ubuntu，Debian中验证无问题，别的主流系统应该也没有问题

可选占用：CPU，内存，带宽

安装完毕后等待5分钟看看占用情况(CPU占用初始压力参数很低，时间不够看不出负载的)，如果超过10分钟无占用则有问题请卸载脚本反馈问题

因为更新有延迟需要等待CDN加载最新脚本，请留意脚本当前更新日期：2023.02.05

### 开发完毕，测试中，有问题请在issues中反馈

选项1安装，选项2卸载，选项3退出脚本

安装过程中无脑回车则全部可选的占用都占用，不需要什么占用输入```n```再回车

最后会询问是否需要带宽占用的参数自定义，这时候默认选项就是```n```，回车就使用默认配置，输入```y```再回车则需要按照提示自定义参数

```
curl -L https://raw.githubusercontent.com/spiritLHLS/Oracle-server-keep-alive-script/main/oalive.sh -o oalive.sh && chmod +x oalive.sh && bash oalive.sh
```

或

```
bash oalive.sh
```

或

```
bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/spiritLHLS/Oracle-server-keep-alive-script/main/oalive.sh)
```

### 说明

- CPU占用有计算素数模式和科学计算模式可自由选择，设定占用区间为15~25%
- CPU占用是动态的，每几秒检测一遍，计算任务动态调整，检测间隔也是动态调整
- CPU占用增加了双重保险，不仅动态调整，还在守护进程中设置了最高占用，默认30%最高(核数✖13%如果低于30%时设置)
- 内存占用设定占用20%总内存，占用300秒休息300秒
- 内存占用每300秒检测一遍，动态调整增加占用的大小，如果你内存大于20%则不增加占用
- 带宽占用每45分钟下载一次1G~10G大小的文件进行占用，只下载不保存，下载过程中不会占用硬盘
- 带宽占用动态调整实际下载带宽/速率，限制下载时长最长10分钟，每次下载前先测试最大可用带宽实时调整为20%带宽下载
- 占用过程中使用守护进程和开机自启服务，保证占用任务持续且有效
- 可选择一键卸载所有占用服务，卸载会将所有脚本和服务卸载，包括任务、守护进程和开机自启的设置

### 友链

VPS融合怪测评脚本

https://github.com/spiritLHLS/ecs

## Stargazers over time

[![Stargazers over time](https://starchart.cc/spiritLHLS/Oracle-server-keep-alive-script.svg)](https://starchart.cc/spiritLHLS/Oracle-server-keep-alive-script)

### SEO关键词

甲骨文保活，甲骨文OCI保活，甲骨文资源占用，甲骨文免费服务器，甲骨文服务器闲置使用必备。

资源定期浪费，可用于 Oracle 甲骨文保活。

为了应对甲骨文最新回收机制而作的脚本。


