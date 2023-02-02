#!/usr/bin/env bash
# by spiritlhl
# from https://github.com/spiritLHLS/Oracle-server-keep-alive-script

ver="2023.02.01"
_red() { echo -e "\033[31m\033[01m$@\033[0m"; }
_green() { echo -e "\033[32m\033[01m$@\033[0m"; }
_yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }
_blue() { echo -e "\033[36m\033[01m$@\033[0m"; }
reading(){ read -rp "$(_green "$1")" "$2"; }
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "fedora" "arch")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Fedora" "Arch")
PACKAGE_UPDATE=("! apt-get update && apt-get --fix-broken install -y && apt-get update" "apt-get update" "yum -y update" "yum -y update" "yum -y update" "pacman -Sy")
PACKAGE_INSTALL=("apt-get -y install" "apt-get -y install" "yum -y install" "yum -y install" "yum -y install" "pacman -Sy --noconfirm --needed")
PACKAGE_REMOVE=("apt-get -y remove" "apt-get -y remove" "yum -y remove" "yum -y remove" "yum -y remove" "pacman -Rsc --noconfirm")
PACKAGE_UNINSTALL=("apt-get -y autoremove" "apt-get -y autoremove" "yum -y autoremove" "yum -y autoremove" "yum -y autoremove" "")
CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')" "$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)") 
SYS="${CMD[0]}"
[[ -n $SYS ]] || exit 1
for ((int = 0; int < ${#REGEX[@]}; int++)); do
    if [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]]; then
        SYSTEM="${RELEASE[int]}"
        [[ -n $SYSTEM ]] && break
    fi
done

boinc() {
    _green "\n Install docker.\n "
    if ! systemctl is-active docker >/dev/null 2>&1; then
        if [ $SYSTEM = "CentOS" ]; then
          ${PACKAGE_INSTALL[int]} yum-utils
          yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo &&
          ${PACKAGE_INSTALL[int]} docker-ce docker-ce-cli containerd.io
          systemctl enable --now docker
        else
          ${PACKAGE_INSTALL[int]} docker.io
        fi
    fi
    docker ps -a | awk '{print $NF}' | grep -qw boinc && _yellow " Remove the boinc container.\n " && docker rm -f boinc >/dev/null 2>&1
    if [ "$SYSTEM" == "Ubuntu" ] || [ "$SYSTEM" == "Debian" ]; then
      docker run -d --restart unless-stopped --name boinc -v /var/lib/boinc:/var/lib/boinc -e "BOINC_CMD_LINE_OPTIONS=--allow_remote_gui_rpc --cpu_usage_limit=20" boinc/client
    elif [ "$SYSTEM" == "Centos" ] ; then
      docker run -d --restart unless-stopped --name boinc -v /var/lib/boinc:/var/lib/boinc -e "BOINC_CMD_LINE_OPTIONS=--allow_remote_gui_rpc --cpu_usage_limit=20" boinc/client:centos
    else
      echo "Error: The operating system is not supported."
      exit 1
    fi
    systemctl enable docker
    _green "Boinc is installed as docker and using"
}

calculate() {
    cat > /usr/local/bin/cpu-limit.sh << EOL
#!/bin/bash
while true
do
  cpu=$(top -bn1 | awk '/Cpu\(s\)/ {print $2}' | sed 's/%//')
  if [ $cpu -gt 20 ]; then
    sleep 1
  else
    stress --cpu 1
  fi
done
EOL
    chmod +x /usr/local/bin/cpu-limit.sh
    cat > /etc/systemd/system/cpu-limit.service << EOL
[Unit]
Description=Keep CPU usage under 20%

[Service]
User=root
ExecStart=/bin/bash /usr/local/bin/cpu-limit.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOL
    systemctl daemon-reload
    systemctl enable cpu-limit.service
    systemctl start cpu-limit.service
    _green "The CPU limit script has been installed at /usr/local/bin/cpu-limit.sh"
}

memory(){
    cat > /usr/local/bin/memory-limit.sh << EOL
#!/bin/bash
while true
do
  mem=$(free | awk '/Mem/ {printf("%.2f%\n"), $3/$2 * 100.0}')
  if [ $(echo "$mem > 15" | bc) -eq 1 ]; then
    sleep 1
  else
    stress --vm 1 --vm-bytes 128M
  fi
done
EOL
    chmod +x /usr/local/bin/memory-limit.sh
    cat > /etc/systemd/system/memory-limit.service << EOL
[Unit]
Description=Keep memory usage under 15%

[Service]
User=root
ExecStart=/bin/bash /usr/local/bin/memory-limit.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOL
    systemctl daemon-reload
    systemctl enable memory-limit.service
    systemctl start memory-limit.service
    _green "The memory limit script has been installed at /usr/local/bin/memory-limit.sh"
}

bandwidth(){
    if ! command -v speedtest-cli > /dev/null 2>&1; then
      echo "speedtest-cli not found, installing..."
      _yellow "Installing speedtest-cli"
	  ${PACKAGE_INSTALL[int]} speedtest-cli
    fi
    if ! command -v bc > /dev/null 2>&1; then
      echo "bc not found, installing..."
      _yellow "Installing bc"
    	${PACKAGE_INSTALL[int]} bc
    fi
    cat > /usr/local/bin/bandwidth_occupier.sh << EOL
#!/bin/bash
max_bandwidth=$(speedtest-cli --bytes --simple | grep -Eo "[0-9]+")
bandwidth_to_use=$(echo "$max_bandwidth * 0.15" | bc)
dd if=/dev/zero bs=$bandwidth_to_use count=$((5 * 60))
EOL
    sudo chmod +x /usr/local/bin/bandwidth_occupier.sh
    cat > /etc/systemd/system/bandwidth_occupier.timer << EOL
[Unit]
Description=Run the Bandwidth Occupier every 45 minutes

[Timer]
OnBootSec=15min
OnUnitActiveSec=45min

[Install]
WantedBy=timers.target
EOL
    cat > /etc/systemd/system/bandwidth_occupier.service << EOL
[Unit]
Description=Bandwidth Occupier Service

[Service]
ExecStart=/bin/bash /usr/local/bin/bandwidth_occupier.sh

[Install]
WantedBy=multi-user.target
EOL
    systemctl daemon-reload
    systemctl start bandwidth_occupier.timer
    systemctl enable bandwidth_occupier.timer
}

uninstall(){
    docker stop boinc &> /dev/null  
    docker rm boinc &> /dev/null    
    docker rmi boinc &> /dev/null   
    _yellow "The boinc has been uninstalled successfully."
    if [ -f "/etc/systemd/system/cpu-limit.service" ]; then
        systemctl stop cpu-limit.service
        systemctl disable cpu-limit.service
        rm /etc/systemd/system/cpu-limit.service
        rm /usr/local/bin/cpu-limit.sh
        _yellow "The cpu limit script has been uninstalled successfully."
    fi
    if [ -f "/etc/systemd/system/memory-limit.service" ]; then
        systemctl stop memory-limit.service
        systemctl disable memory-limit.service
        rm /etc/systemd/system/memory-limit.service
        rm /usr/local/bin/memory-limit.sh
        _yellow "The memory limit script has been uninstalled successfully."
    fi
    if [ -f "/etc/systemd/system/bandwidth_occupier.service" ]; then
        systemctl stop bandwidth_occupier
        systemctl disable bandwidth_occupier
        rm /etc/systemd/system/bandwidth_occupier.service
        rm /usr/local/bin/bandwidth_occupier.sh
        _yellow "The bandwidth occupier script has been uninstalled successfully."
    fi
    systemctl daemon-reload
}

main() {
    echo "选择你的选项:"
    echo "1. 安装保活服务"
    echo "2. 卸载保活服务"
    reading "你的选择：" option
    case $option in
        1)
            echo "选择你需要占用CPU时使用的程序:"
            echo "1. BOINC docker服务 (https://github.com/BOINC/boinc)"
            echo "2. 本机无效stress占用"
            reading "你的选择：" cpu_option
            if [ $cpu_option == 1 ]; then
                boinc
            else
                calculate
            fi
            memory
            bandwidth
            ;;
        2)
            uninstall
            exit 0
            ;;
        *)
            echo "无效选项，退出程序"
            exit 1
            ;;
    esac
}

main
