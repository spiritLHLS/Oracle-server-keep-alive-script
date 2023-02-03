#!/usr/bin/env bash
# by spiritlhl
# from https://github.com/spiritLHLS/Oracle-server-keep-alive-script

ver="2023.02.03"
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
    _green "CPU限制安装成功 - Boinc is installed as docker and using"
}

calculate() {
    curl -L https://raw.githubusercontent.com/spiritLHLS/Oracle-server-keep-alive-script/main/cpu-limit.sh -o cpu-limit.sh && chmod +x cpu-limit.sh
    mv cpu-limit.sh /usr/local/bin/cpu-limit.sh 
    chmod +x /usr/local/bin/cpu-limit.sh
    curl -L https://raw.githubusercontent.com/spiritLHLS/Oracle-server-keep-alive-script/main/cpu-limit.service -o cpu-limit.service && chmod +x cpu-limit.service
    mv cpu-limit.service /etc/systemd/system/cpu-limit.service
    line_number=$(grep -n "Restart=always" /etc/systemd/system/cpu-limit.service | cut -d: -f1)
    sed -i "${line_number}a CPUQuota=45%" /etc/systemd/system/cpu-limit.service
    systemctl daemon-reload
    systemctl enable cpu-limit.service
    systemctl start cpu-limit.service
    _green "CPU限制安装成功 - The CPU limit script has been installed at /usr/local/bin/cpu-limit.sh"
}

memory(){
    curl -L https://raw.githubusercontent.com/spiritLHLS/Oracle-server-keep-alive-script/main/memory-limit.sh -o memory-limit.sh && chmod +x memory-limit.sh
    mv memory-limit.sh /usr/local/bin/memory-limit.sh
    chmod +x /usr/local/bin/memory-limit.sh
    curl -L https://raw.githubusercontent.com/spiritLHLS/Oracle-server-keep-alive-script/main/memory-limit.service -o memory-limit.service && chmod +x memory-limit.service
    mv memory-limit.service /etc/systemd/system/memory-limit.service
    systemctl daemon-reload
    systemctl enable memory-limit.service
    systemctl start memory-limit.service
    _green "内存限制安装成功 - The memory limit script has been installed at /usr/local/bin/memory-limit.sh"
}

bandwidth(){
    if ! command -v speedtest-cli > /dev/null 2>&1; then
      echo "speedtest-cli not found, installing..."
      _yellow "Installing speedtest-cli"
	  ${PACKAGE_INSTALL[int]} speedtest-cli
    fi
    curl -L https://raw.githubusercontent.com/spiritLHLS/Oracle-server-keep-alive-script/main/bandwidth_occupier.sh -o bandwidth_occupier.sh && chmod +x bandwidth_occupier.sh
    mv bandwidth_occupier.sh /usr/local/bin/bandwidth_occupier.sh
    chmod +x /usr/local/bin/bandwidth_occupier.sh
    curl -L https://raw.githubusercontent.com/spiritLHLS/Oracle-server-keep-alive-script/main/bandwidth_occupier.timer -o bandwidth_occupier.timer && chmod +x bandwidth_occupier.timer
    mv bandwidth_occupier.timer /etc/systemd/system/bandwidth_occupier.timer
    curl -L https://raw.githubusercontent.com/spiritLHLS/Oracle-server-keep-alive-script/main/bandwidth_occupier.service -o bandwidth_occupier.service && chmod +x bandwidth_occupier.service
    mv bandwidth_occupier.service /etc/systemd/system/bandwidth_occupier.service
    systemctl daemon-reload
    systemctl start bandwidth_occupier.timer
    systemctl enable bandwidth_occupier.timer
    _green "带宽限制安装成功 - The bandwidth limit script has been installed at /usr/local/bin/memory-limit.sh"
}

uninstall(){
    docker stop boinc &> /dev/null  
    docker rm boinc &> /dev/null    
    docker rmi boinc &> /dev/null   
    if [ -f "/etc/systemd/system/cpu-limit.service" ]; then
        systemctl stop cpu-limit.service
        systemctl disable cpu-limit.service
        rm /etc/systemd/system/cpu-limit.service
        rm /usr/local/bin/cpu-limit.sh
    fi
    _yellow "已卸载CPU占用 - The cpu limit script has been uninstalled successfully."
    if [ -f "/etc/systemd/system/memory-limit.service" ]; then
        systemctl stop memory-limit.service
        systemctl disable memory-limit.service
        rm /etc/systemd/system/memory-limit.service
        rm /usr/local/bin/memory-limit.sh
	rm /dev/shm/file
        _yellow "已卸载内存占用 - The memory limit script has been uninstalled successfully."
    fi
    if [ -f "/etc/systemd/system/bandwidth_occupier.service" ]; then
        systemctl stop bandwidth_occupier
        systemctl disable bandwidth_occupier
        rm /etc/systemd/system/bandwidth_occupier.service
        rm /usr/local/bin/bandwidth_occupier.sh
	systemctl stop bandwidth_occupier.timer
    	systemctl disable bandwidth_occupier.timer
	rm /etc/systemd/system/bandwidth_occupier.timer
        _yellow "已卸载带宽占用 - The bandwidth occupier and timer script has been uninstalled successfully."
    fi
    systemctl daemon-reload
}

main() {
    _green "更新时间： $ver"
    _green "仓库：https://github.com/spiritLHLS/Oracle-server-keep-alive-script"
    if ! command -v bc > /dev/null 2>&1; then
      echo "bc not found, installing..."
      _yellow "Installing bc"
    	${PACKAGE_INSTALL[int]} bc
    fi
    if ! command -v fallocate > /dev/null 2>&1; then
      echo "fallocate not found, installing..."
      _yellow "Installing fallocate"
      ${PACKAGE_INSTALL[int]} fallocate
    fi
    echo "选择你的选项:"
    echo "1. 安装保活服务"
    echo "2. 卸载保活服务"
    echo "3. 退出程序"
    reading "你的选择：" option
    case $option in
        1)
            echo "选择你需要占用CPU时使用的程序:"
            echo "1. 本机素数计算模拟占用(20%~25%) [推荐]"
            echo "2. BOINC-docker服务(20%)(https://github.com/BOINC/boinc)"
	    echo "3. 不限制"
            reading "你的选择：" cpu_option
            if [ $cpu_option == 2 ]; then
                boinc
	    elif [ $cpu_option == 3 ]; then
    		echo ""
            else
                calculate
            fi
            reading "需要限制内存吗? ([y]/n): " memory_confirm
            if [ "$memory_confirm" != "n" ]; then
                memory
            fi
            reading "需要限制带宽吗? ([y]/n): " bandwidth_confirm
            if [ "$bandwidth_confirm" != "n" ]; then
                bandwidth
            fi
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
