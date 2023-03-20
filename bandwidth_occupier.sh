#!/bin/bash
# by spiritlhl
# from https://github.com/spiritLHLS/Oracle-server-keep-alive-script

pid_file=/tmp/bandwidth_occupier.pid
if [ -e "${pid_file}" ]; then
  # 如果 PID 文件存在，则读取其中的 PID
  pid=$(cat "${pid_file}")
  # 检查该 PID 是否对应一个正在运行的进程
  if ps -p "${pid}" > /dev/null; then
    echo "Error: Another instance of bandwidth_occupier.sh is already running with PID ${pid}"
    exit 1
  fi
  # 如果 PID 文件存在，但对应的进程已经停止运行，删除 PID 文件
  rm "${pid_file}"
fi
echo $$ > "${pid_file}"

urls=('http://mirror.nl.leaseweb.net/speedtest/10000mb.bin' 'http://mirror.dal10.us.leaseweb.net/speedtest/10000mb.bin' 'http://mirror.hk.leaseweb.net/speedtest/10000mb.bin' 'http://mirror.sfo12.us.leaseweb.net/speedtest/10000mb.bin' 'http://mirror.de.leaseweb.net/speedtest/10000mb.bin' 'http://mirror.syd10.au.leaseweb.net/speedtest/10000mb.bin' 'http://mirror.wdc1.us.leaseweb.net/speedtest/10000mb.bin' 'http://mirror.wdc1.us.leaseweb.net/speedtest/10000mb.bin' 'https://speed.hetzner.de/10GB.bin' 'http://proof.ovh.net/files/10Gio.dat' 'http://lg-sin.fdcservers.net/10GBtest.zip' 'http://lg-tok.fdcservers.net/10GBtest.zip' 'http://lg-hkg.fdcservers.net/10GBtest.zip' 'http://lg-atl.fdcservers.net/10GBtest.zip' 'http://lg-chie.fdcservers.net/10GBtest.zip' 'http://lg-dene.fdcservers.net/10GBtest.zip' 'http://lg-hou.fdcservers.net/10GBtest.zip' 'http://lg-lax.fdcservers.net/10GBtest.zip' 'http://lg-mia.fdcservers.net/10GBtest.zip' 'http://lg-minn.fdcservers.net/10GBtest.zip' 'http://lg-nyc.fdcservers.net/10GBtest.zip' 'http://lg-sea.fdcservers.net/10GBtest.zip' 'http://lg-tor.fdcservers.net/10GBtest.zip' 'http://lg-spb.fdcservers.net/10GBtest.zip' 'http://lg-ams.fdcservers.net/10GBtest.zip' 'http://lg-dub.fdcservers.net/10GBtest.zip' 'http://lg-fra.fdcservers.net/10GBtest.zip' 'http://lg-hel.fdcservers.net/10GBtest.zip' 'http://lg-kie.fdcservers.net/10GBtest.zip' 'http://lg-lis.fdcservers.net/10GBtest.zip' 'http://lg-lon.fdcservers.net/10GBtest.zip' 'http://lg-mad.fdcservers.net/10GBtest.zip' 'http://lg-par2.fdcservers.net/10GBtest.zip' 'http://lg-sof.fdcservers.net/10GBtest.zip' 'http://lg-sto.fdcservers.net/10GBtest.zip' 'http://lg-vie.fdcservers.net/10GBtest.zip' 'http://lg-war.fdcservers.net/10GBtest.zip' 'http://lg-zur.fdcservers.net/10GBtest.zip' 'http://speedtest-ca.turnkeyinternet.net/10000mb.bin' 'http://speedtest-ny.turnkeyinternet.net/10000mb.bin' 'http://sea-repo.hostwinds.net/tests/10gb.zip' 'http://dal-repo.hostwinds.net/tests/10gb.zip' 'http://ams-repo.hostwinds.net/tests/10gb.zip' 'http://zgb-speedtest-1.tele2.net/10GB.zip' 'http://fra36-speedtest-1.tele2.net/10GB.zip' 'http://bks4-speedtest-1.tele2.net/10GB.zip' 'http://vln038-speedtest-1.tele2.net/10GB.zip' 'http://ams-speedtest-1.tele2.net/10GB.zip' 'http://bck-speedtest-1.tele2.net/10GB.zip' 'http://hgd-speedtest-1.tele2.net/10GB.zip' )
selected_url=""
while [[ -z "$selected_url" ]]; do
  rand=$(date +%s)
  url=${urls[rand % ${#urls[@]}]}
  if timeout 5s wget --tries=3 --spider "$url" 2>/dev/null; then
    selected_url=$url
  fi
done
if ! command -v speedtest-cli > /dev/null 2>&1; then
  bandwidth=$(/usr/local/bin/speedtest-go | awk '/^Download/ {print $2}' | head -2 | tail -1)
else
  bandwidth=$(speedtest-cli --simple | awk '/^Download/ {print $2}')
fi
rate=$(echo "($bandwidth * 0.20)/1" | bc)
timeout 6m wget $selected_url --limit-rate=$rate -O /dev/null &
rm "${pid_file}"
