# Oracle-server-keep-alive-script

## 甲骨文服务器保活脚本

所有资源都是动态占用，实时调整，避免服务器有别的任何资源已经超过限额了仍然再占用资源。

### 开发完毕，测试中，有问题请在issues中反馈

```
bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/spiritLHLS/Oracle-server-keep-alive-script/main/oalive.sh)
```

或

```
curl -L https://raw.githubusercontent.com/spiritLHLS/Oracle-server-keep-alive-script/main/oalive.sh -o oalive.sh && chmod +x oalive.sh && bash oalive.sh
```

或

```
bash oalive.sh
```

### 说明

- CPU占用有计算素数模式和科学计算模式可自由选择，设定占用区间为20~25%
- CPU占用是动态的，每几秒检测一遍，计算任务动态调整
- 内存占用设定占用20%总内存
- 内存占用每120秒检测一遍，占用是动态的，如果你内存大于20%则不增加占用
- 带宽占用为100%带宽下的20%带宽每30分钟下载一次1G~10G大小的文件进行占用
- 带宽占用只下载不保存，下载过程中不会占用硬盘，也是动态调整实际下载带宽/速率，限制下载时长最长10分钟
- 占用过程中使用守护进程和开机自启服务，保证占用任务持续且有效
- 可选择一键卸载所有占用服务，卸载会将所有脚本和服务卸载，包括任务、守护进程和开机自启的设置
