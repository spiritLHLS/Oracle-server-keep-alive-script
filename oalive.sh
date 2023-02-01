#!/usr/bin/env bash
# by spiritlhl
# from https://github.com/spiritLHLS/Oracle-server-keep-alive-script

ver="2023.02.01"
_red() { echo -e "\033[31m\033[01m$@\033[0m"; }
_green() { echo -e "\033[32m\033[01m$@\033[0m"; }
_yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }
_blue() { echo -e "\033[36m\033[01m$@\033[0m"; }
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

    systemctl enable memory-limit.service
    systemctl start memory-limit.service

    _green "The memory limit script has been installed at /usr/local/bin/memory-limit.sh"
}

bandwidth(){

}

uninstall(){
    systemctl stop memory-limit.service
    systemctl disable memory-limit.service
    rm /etc/systemd/system/memory-limit.service
    rm /usr/local/bin/memory-limit.sh
    _yellow "The memory limit script has been uninstalled successfully."
    systemctl stop cpu-limit.service
    systemctl disable cpu-limit.service
    rm /etc/systemd/system/cpu-limit.service
    rm /usr/local/bin/cpu-limit.sh
    _yellow "The cpu limit script has been uninstalled successfully."
    docker stop boinc  
    docker rm boinc    
    docker rmi boinc   
    _yellow "The boinc has been uninstalled successfully."
}
