# Oracle-server-keep-alive-script

## 甲骨文服务器保活脚本

### 开发中，勿要使用，开发进度90%

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

- CPU占用有计算素数模式和科学计算模式可自由选择，设定占用区间为20~25%(这块占用也是动态的，每几秒检测一遍)
- 内存占用设定占用20%(这块每120秒检测一遍，占用是动态的，如果你内存大于20%则不增加占用)
- 带宽占用为100%带宽下的20%带宽每30分钟下载一次1G~10G大小的文件进行占用(只下载不保存，下载过程中不会占用硬盘)(也是动态调整的)
- 占用过程中使用守护进程和开机自启服务，保证占用任务持续且有效
- 可选择一键卸载所有占用服务
