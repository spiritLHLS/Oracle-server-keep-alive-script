### 自定义定时任务的命令


由于部分人需要自定义定时任务，我又懒得写定时套装，以下是和本脚本同类型占用的简短命令，怎么定时就自己搞吧，都是shell命令可以写到定时里

至于怎么定时，要么你在crontab中设置，要么在nezha监控面板设置，要么在宝塔定时任务中设置，怎么搞自己谷歌百度去吧


#### CPU

下载脚本
```
curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/cpu-limit.sh -o cpu-limit.sh && chmod +x cpu-limit.sh
mv cpu-limit.sh /usr/local/bin/cpu-limit.sh 
```

CPU占用
```
bash /usr/local/bin/cpu-limit.sh
```

CPU释放
```
kill $(ps -efA | grep cpu-limit.sh | awk '{print $2}') && kill -9 $(cat /tmp/cpu-limit.pid) && rm -rf /tmp/cpu-limit.pid
```

#### 内存

内存占用

内存以MB计算的大小，修改xxxxx为对应数目

```
mkdir /tmp/memory && mount -t tmpfs -o size=xxxxxM tmpfs /tmp/memory && dd if=/dev/zero of=/tmp/memory/block
```

内存释放
```
rm /tmp/memory/block && umount /tmp/memory && rmdir /tmp/memory
```

内存占用实际只有ARM有要求(如果我没理解错的话)

#### 网络占用，跑完自动释放

下载脚本
```
curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/bandwidth_occupier.sh -o bandwidth_occupier.sh && chmod +x bandwidth_occupier.sh
mv bandwidth_occupier.sh /usr/local/bin/bandwidth_occupier.sh
```

对应需要安装的```speedtest-cli```或```speedtest-go```自行安装

安装```speedtest-go```的记得执行```mv speedtest-go /usr/local/bin/ ```

运行脚本(也就是你需要定时的命令)
```
bash /usr/local/bin/bandwidth_occupier.sh 
```
