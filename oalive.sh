#!/usr/bin/env bash
# by spiritlhl
# from https://github.com/spiritLHLS/Oracle-server-keep-alive-script

ver="2023.09.24.08.37"
cd /root >/dev/null 2>&1
_red() { echo -e "\033[31m\033[01m$@\033[0m"; }
_green() { echo -e "\033[32m\033[01m$@\033[0m"; }
_yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }
_blue() { echo -e "\033[36m\033[01m$@\033[0m"; }
reading() { read -rp "$(_green "$1")" "$2"; }
RED="\033[31m"
PLAIN="\033[0m"
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
utf8_locale=$(locale -a 2>/dev/null | grep -i -m 1 -E "UTF-8|utf8")
if [[ -z "$utf8_locale" ]]; then
  echo "No UTF-8 locale found"
else
  export LC_ALL="$utf8_locale"
  export LANG="$utf8_locale"
  export LANGUAGE="$utf8_locale"
  echo "Locale set to $utf8_locale"
fi
[[ $EUID -ne 0 ]] && echo -e "${RED}请使用 root 用户运行本脚本！${PLAIN}" && exit 1

checkver() {
  running_version=$(grep "ver=\"[0-9]\{4\}\.[0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{2\}" "$0" | awk -F '"' '{print $2}')
  curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/oalive.sh -o oalive1.sh && chmod +x oalive1.sh
  downloaded_version=$(grep "ver=\"[0-9]\{4\}\.[0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{2\}" oalive1.sh | awk -F '"' '{print $2}')
  if [ "$running_version" != "$downloaded_version" ]; then
    _yellow "更新脚本从 $ver 到 $downloaded_version"
    mv oalive1.sh "$0"
    uninstall
    _yellow "5秒后请重新设置占用，已自动卸载原有占用"
    sleep 5
    bash oalive.sh
  else
    _green "本脚本已是最新脚本无需更新"
    rm -rf oalive1.sh*
  fi
}

checkupdate() {
  _yellow "Updating package management sources"
  ${PACKAGE_UPDATE[int]} >/dev/null 2>&1
}

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
  elif [ "$SYSTEM" == "Centos" ]; then
    docker run -d --restart unless-stopped --name boinc -v /var/lib/boinc:/var/lib/boinc -e "BOINC_CMD_LINE_OPTIONS=--allow_remote_gui_rpc --cpu_usage_limit=20" boinc/client:centos
  else
    echo "Error: The operating system is not supported."
    exit 1
  fi
  systemctl enable docker
  _green "CPU限制安装成功"
  _green "Boinc is installed as docker and using"
}

calculate() {
  curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/cpu-limit.sh -o cpu-limit.sh && chmod +x cpu-limit.sh
  mv cpu-limit.sh /usr/local/bin/cpu-limit.sh
  chmod +x /usr/local/bin/cpu-limit.sh
  curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/cpu-limit.service -o cpu-limit.service && chmod +x cpu-limit.service
  mv cpu-limit.service /etc/systemd/system/cpu-limit.service
  line_number=7
  total_cores=0
  if [ -f "/proc/cpuinfo" ]; then
    total_cores=$(grep -c ^processor /proc/cpuinfo)
  else
    total_cores=$(nproc)
  fi
  if [ "$total_cores" == "2" ] || [ "$total_cores" == "3" ] || [ "$total_cores" == "4" ]; then
    cpu_limit=$(echo "$total_cores * 20" | bc)
  else
    cpu_limit=25
  fi
  sed -i "${line_number}a CPUQuota=${cpu_limit}%" /etc/systemd/system/cpu-limit.service
  systemctl daemon-reload
  systemctl enable cpu-limit.service
  if systemctl start cpu-limit.service; then
    _green "CPU限制安装成功 脚本路径: /usr/local/bin/cpu-limit.sh"
  else
    restorecon /etc/systemd/system/cpu-limit.service
    systemctl enable cpu-limit.service
    systemctl start cpu-limit.service
    _green "CPU限制安装成功 脚本路径: /usr/local/bin/cpu-limit.sh"
  fi
  _green "The CPU limit script has been installed at /usr/local/bin/cpu-limit.sh"
}

memory() {
  curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/memory-limit.sh -o memory-limit.sh && chmod +x memory-limit.sh
  mv memory-limit.sh /usr/local/bin/memory-limit.sh
  chmod +x /usr/local/bin/memory-limit.sh
  curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/memory-limit.service -o memory-limit.service && chmod +x memory-limit.service
  mv memory-limit.service /etc/systemd/system/memory-limit.service
  systemctl daemon-reload
  systemctl enable memory-limit.service
  if systemctl start memory-limit.service; then
    _green "内存限制安装成功 脚本路径: /usr/local/bin/memory-limit.sh"
  else
    restorecon /etc/systemd/system/memory-limit.service
    systemctl enable memory-limit.service
    systemctl start memory-limit.service
    _green "内存限制安装成功 脚本路径: /usr/local/bin/memory-limit.sh"
  fi
  _green "The memory limit script has been installed at /usr/local/bin/memory-limit.sh"
}

bandwidth() {
  curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/bandwidth_occupier.sh -o bandwidth_occupier.sh && chmod +x bandwidth_occupier.sh
  mv bandwidth_occupier.sh /usr/local/bin/bandwidth_occupier.sh
  chmod +x /usr/local/bin/bandwidth_occupier.sh
  curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/bandwidth_occupier.timer -o bandwidth_occupier.timer && chmod +x bandwidth_occupier.timer
  mv bandwidth_occupier.timer /etc/systemd/system/bandwidth_occupier.timer
  curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/bandwidth_occupier.service -o bandwidth_occupier.service && chmod +x bandwidth_occupier.service
  mv bandwidth_occupier.service /etc/systemd/system/bandwidth_occupier.service
  reading "需要自定义带宽占用的设置吗? (y/[n]) " answer
  if [ "$answer" == "y" ]; then
    # sed -i '/^bandwidth\|^rate/s/^/#/' /usr/local/bin/bandwidth_occupier.sh
    sed -i '41,47s/^/# /' /usr/local/bin/bandwidth_occupier.sh
    reading "输入你需要的带宽大小(以mbps为单位，例如10mbps输入10): " rate_mbps
    rate=$((rate_mbps * 1000000))
    reading "输入你需要请求的时长(以分钟为单位，例如10分钟输入10): " timeout
    # sed -i 's/^timeout/#timeout/' /usr/local/bin/bandwidth_occupier.sh
    sed -i '47a\timeout '$timeout'm wget $selected_url --limit-rate='$rate' -O /dev/null &' /usr/local/bin/bandwidth_occupier.sh
    reading "输入你需要间隔的时长(以分钟为单位，例如45分钟输入45): " interval
    sed -i "s/^OnUnitActiveSec.*/OnUnitActiveSec=$interval/" /etc/systemd/system/bandwidth_occupier.timer
  else
    _green "\n使用默认配置，45分钟间隔，请求6分钟，请求速率为最大速度的30%"
    if ! command -v speedtest-cli >/dev/null 2>&1; then
      echo "speedtest-cli not found, installing..."
      _yellow "Installing speedtest-cli"
      rm -rf /etc/apt/sources.list.d/speedtest.list >/dev/null 2>&1
      ${PACKAGE_REMOVE[int]} speedtest >/dev/null 2>&1
      ${PACKAGE_REMOVE[int]} speedtest-cli >/dev/null 2>&1
      checkupdate
      ${PACKAGE_INSTALL[int]} speedtest-cli
    fi
    if ! command -v speedtest-cli >/dev/null 2>&1; then
      ARCH=$(uname -m)
      if [[ "$ARCH" == "armv7l" || "$ARCH" == "armv8" || "$ARCH" == "armv8l" || "$ARCH" == "aarch64" ]]; then
        FILE_URL="${cdn_success_url}https://github.com/showwin/speedtest-go/releases/download/v1.5.2/speedtest-go_1.5.2_Linux_arm64.tar.gz"
      elif [[ $ARCH == "i386" ]]; then
        FILE_URL="${cdn_success_url}https://github.com/showwin/speedtest-go/releases/download/v1.5.2/speedtest-go_1.5.2_Linux_i386.tar.gz"
      elif [[ $ARCH == "x86_64" ]]; then
        FILE_URL="${cdn_success_url}https://github.com/showwin/speedtest-go/releases/download/v1.5.2/speedtest-go_1.5.2_Linux_x86_64.tar.gz"
      else
        _red "不支持该架构：$ARCH"
        exit 1
      fi
      wget -q -O speedtest-go_1.5.2_Linux.tar.gz $FILE_URL
      if ! command -v tar >/dev/null 2>&1; then
        yum install -y tar
      fi
      chmod 777 speedtest-go_1.5.2_Linux.tar.gz
      tar -xvf speedtest-go_1.5.2_Linux.tar.gz
      chmod 777 speedtest-go
      mv speedtest-go /usr/local/bin/
      rm -rf README.md* LICENSE* >/dev/null 2>&1
      rm -rf speedtest-go_1.5.2_Linux.tar.gz* >/dev/null 2>&1
    fi
  fi
  systemctl daemon-reload
  systemctl enable bandwidth_occupier.timer
  if systemctl start bandwidth_occupier.timer; then
    _green "带宽限制安装成功 脚本路径: /usr/local/bin/bandwidth_occupier.sh"
  else
    restorecon /etc/systemd/system/bandwidth_occupier.timer
    restorecon /etc/systemd/system/bandwidth_occupier.service
    systemctl enable bandwidth_occupier.timer
    systemctl start bandwidth_occupier.timer
    _green "带宽限制安装成功 脚本路径: /usr/local/bin/bandwidth_occupier.sh"
  fi
  _green "The bandwidth limit script has been installed at /usr/local/bin/bandwidth_occupier.sh"
}

cdn_urls=("https://cdn0.spiritlhl.top/" "http://cdn3.spiritlhl.net/" "http://cdn1.spiritlhl.net/" "https://ghproxy.com/" "http://cdn2.spiritlhl.net/")

check_cdn() {
  local o_url=$1
  for cdn_url in "${cdn_urls[@]}"; do
    if curl -sL -k "$cdn_url$o_url" --max-time 6 | grep -q "success" >/dev/null 2>&1; then
      export cdn_success_url="$cdn_url"
      return
    fi
    sleep 0.5
  done
  export cdn_success_url=""
}

check_cdn_file() {
  check_cdn "https://raw.githubusercontent.com/spiritLHLS/ecs/main/back/test"
  if [ -n "$cdn_success_url" ]; then
    _yellow "CDN available, using CDN"
  else
    _yellow "No CDN available, no use CDN"
  fi
}

download_speedtest_go_file() {
  cd /root >/dev/null 2>&1
  file="/etc/speedtest-cli/speedtest-go"
  if [[ -e "$file" ]]; then
    _green "speedtest-go found"
    return
  fi
  local sys_bit="$1"
  if [ "$sys_bit" = "aarch64" ]; then
    sys_bit="arm64"
  fi
  rm -rf speedtest-go*
  local url3="${cdn_success_url}https://github.com/showwin/speedtest-go/releases/download/v1.6.0/speedtest-go_1.6.0_Linux_${sys_bit}.tar.gz"
  wget $url3
  if [ $? -eq 0 ]; then
    _green "Used speedtest-go"
  fi
  if [ ! -d "/etc/speedtest-cli" ]; then
    mkdir -p "/etc/speedtest-cli"
  fi
  if [ -f "./speedtest-go_1.6.0_Linux_${sys_bit}.tar.gz" ]; then
    tar -zxf speedtest-go_1.6.0_Linux_${sys_bit}.tar.gz -C /etc/speedtest-cli
    chmod 777 /etc/speedtest-cli/speedtest-go
    rm -f speedtest-go*
  else
    _red "Error: Failed to download speedtest tool."
    exit 1
  fi
}

install_speedtest_go() {
  cd /root >/dev/null 2>&1
  _yellow "checking speedtest"
  sys_bit=""
  local sysarch="$(uname -m)"
  case "${sysarch}" in
  "x86_64" | "x86" | "amd64" | "x64") sys_bit="x86_64" ;;
  "i386" | "i686") sys_bit="i386" ;;
  "aarch64" | "armv7l" | "armv8" | "armv8l") sys_bit="aarch64" ;;
  "s390x") sys_bit="s390x" ;;
  "riscv64") sys_bit="riscv64" ;;
  "ppc64le") sys_bit="ppc64le" ;;
  "ppc64") sys_bit="ppc64" ;;
  *) sys_bit="x86_64" ;;
  esac
  download_speedtest_go_file "${sys_bit}"
}

bandwidth_speedtest_go() {
  install_speedtest_go
  cd /root >/dev/null 2>&1
  curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/bandwidth_occupier.timer -o bandwidth_occupier.timer && chmod +x bandwidth_occupier.timer
  mv bandwidth_occupier.timer /etc/systemd/system/bandwidth_occupier.timer
  curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/bandwidth_occupier.service -o bandwidth_occupier.service && chmod +x bandwidth_occupier.service
  mv bandwidth_occupier.service /etc/systemd/system/bandwidth_occupier.service
  file_content=$(cat /etc/systemd/system/bandwidth_occupier.service)
  new_file_content=$(echo "$file_content" | sed '7s/.*/ExecStart=\/bin\/bash -c '\''for i in {1..10}; do \/etc\/speedtest-cli\/speedtest-go; done'\''/')
  echo "$new_file_content" >/etc/systemd/system/bandwidth_occupier.service
  systemctl daemon-reload
  systemctl enable bandwidth_occupier.timer
  if systemctl start bandwidth_occupier.timer; then
    _green "带宽占用安装成功 speedtest-go路径: /etc/speedtest-cli/speedtest-go"
  fi
  _green "The speedtest-go has been installed at /etc/speedtest-cli/speedtest-go"
}

uninstall() {
  docker stop boinc &>/dev/null
  docker rm boinc &>/dev/null
  docker rmi boinc &>/dev/null
  if [ -f "/etc/systemd/system/cpu-limit.service" ]; then
    systemctl stop cpu-limit.service
    systemctl disable cpu-limit.service
    rm -rf /etc/systemd/system/cpu-limit.service
    rm -rf /usr/local/bin/cpu-limit.sh*
    kill $(pgrep dd) &>/dev/null
    kill $(ps -efA | grep cpu-limit.sh | awk '{print $2}') &>/dev/null
  fi
  rm -rf /tmp/cpu-limit.pid &>/dev/null
  _yellow "已卸载CPU占用 - The cpu limit script has been uninstalled successfully."
  if [ -f "/etc/systemd/system/memory-limit.service" ]; then
    systemctl stop memory-limit.service
    systemctl disable memory-limit.service
    rm -rf /etc/systemd/system/memory-limit.service
    rm -rf /usr/local/bin/memory-limit.sh*
    rm -rf /dev/shm/file
    kill $(ps -efA | grep memory-limit.sh | awk '{print $2}') &>/dev/null
    rm -rf /tmp/memory-limit.pid &>/dev/null
    _yellow "已卸载内存占用 - The memory limit script has been uninstalled successfully."
  fi
  if [ -f "/etc/systemd/system/bandwidth_occupier.service" ]; then
    systemctl stop bandwidth_occupier
    systemctl disable bandwidth_occupier
    rm -rf /etc/systemd/system/bandwidth_occupier.service
    rm -rf /usr/local/bin/bandwidth_occupier.sh*
    systemctl stop bandwidth_occupier.timer
    systemctl disable bandwidth_occupier.timer
    rm -rf /etc/systemd/system/bandwidth_occupier.timer
    rm -rf /usr/local/bin/speedtest-go &>/dev/null
    kill $(ps -efA | grep bandwidth_occupier.sh | awk '{print $2}') &>/dev/null
    rm -rf /tmp/bandwidth_occupier.pid &>/dev/null
    rm -rf /etc/speedtest-cli &>/dev/null
    _yellow "已卸载带宽占用 - The bandwidth occupier and timer script has been uninstalled successfully."
  fi
  systemctl daemon-reload
}

check_and_install() {
  local command_name=$1
  local package_name=$2

  if ! command -v $command_name >/dev/null 2>&1; then
    echo "$command_name not found, installing..."
    _yellow "Installing $package_name"
    ${PACKAGE_INSTALL[int]} $package_name
  fi
}

pre_check() {
  reading "是否需要更新软件包管理器？y/[n]：" apt_option
  if [ "$apt_option" == y ] || [ "$apt_option" == Y ]; then
    checkupdate
  fi
  if [[ "$SYSTEM" == "CentOS" ]]; then
    ${PACKAGE_INSTALL[int]} epel-release
  fi
  ${PACKAGE_INSTALL[int]} dmidecode >/dev/null 2>&1
  check_and_install wget wget
  check_and_install bc bc
  check_and_install fallocate util-linux
  check_and_install nproc coreutils
  check_cdn_file
}

check_service_status() {
  service_name="$1"
  if systemctl is-active --quiet "$service_name"; then
    _blue "$service_name 已设置"
  else
    _blue "$service_name 未设置"
  fi
}

check_services_status() {
  check_service_status "cpu-limit.service"
  check_service_status "memory-limit.service"
  if [ -e "/usr/local/bin/bandwidth_occupier.sh" ]; then
    if grep -qE '^\s*#' <(sed -n '32,38p' /usr/local/bin/bandwidth_occupier.sh); then
      line=$(sed -n '39p' /usr/local/bin/bandwidth_occupier.sh)
      timeout=$(echo "$line" | awk '{print $2}' | awk -F 'm' '{print $1}')
      limit_rate=$(echo "$line" | awk -F '--limit-rate=' '{print $2}' | awk '{print $1}')
      limit_rate_mbps=$(echo "scale=2; $limit_rate/1000000" | bc)
      on_unit_active_sec=$(grep -oP '^OnUnitActiveSec *= *\K[^ ]+' /etc/systemd/system/bandwidth_occupier.timer)
      _blue "带宽占用使用配置：每隔 $on_unit_active_sec 分钟占用 $limit_rate_mbps Mbps 速率下载文件 $timeout 分钟"
    else
      _blue "带宽占用使用配置：自动检测带宽每隔45分钟占用6分钟以最大带宽的30%速率下载文件"
    fi
    _blue "bandwidth_occupier.service 已设置"
  elif [ -e "/etc/speedtest-cli/speedtest-go" ]; then
    _blue "带宽占用使用配置：使用speedtest-go每45分钟执行10次进行占用，使用机器最大的带宽"
    _blue "bandwidth_occupier.service 已设置"
  else
    _blue "bandwidth_occupier.service 未设置"
  fi
}

main() {
  _green "当前脚本更新时间(请注意比对仓库说明)： $ver"
  _green "仓库：https://github.com/spiritLHLS/Oracle-server-keep-alive-script"
  check_services_status
  echo "选择你的选项:"
  echo "1. 安装保活服务"
  echo "2. 卸载保活服务"
  echo "3. 一键更新脚本"
  echo "4. 退出程序"
  while true; do
    reading "你的选择：" option
    case $option in
    1)
      pre_check
      echo "选择你需要占用CPU时使用的程序:"
      echo "1. 本机DD模拟占用(20%~25%) [推荐]"
      echo "2. BOINC-docker服务(20%)(https://github.com/BOINC/boinc) [不推荐]"
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
      if [ "$memory_confirm" != "n" ] && [ "$memory_confirm" != "N" ]; then
        memory
      fi
      reading "需要限制带宽吗? ([y]/n): " bandwidth_confirm
      if [ "$bandwidth_confirm" != "n" ] && [ "$bandwidth_confirm" != "N" ]; then
        echo "(1) 使用speedtest-go消耗带宽(无法实时限制流量，消耗时占满机器带宽，但所有机器都能保证有占用)"
        echo "(2) 使用wget下载测速文件消耗带宽(可实时限制流量，消耗时按百分比占用带宽，但可能在某些机器上执行失败无法占用)"
        reading "请输入选择的选项(默认回车为选项2): " wget_confirm
        if [ "$wget_confirm" == "1" ] || [ "$wget_confirm" == 1 ]; then
          bandwidth_speedtest_go
        else
          bandwidth
        fi
      fi
      break
      ;;
    2)
      uninstall
      exit 0
      break
      ;;
    3)
      checkver
      break
      ;;
    4)
      echo "退出程序"
      exit 1
      break
      ;;
    *)
      echo "无效选项，请重新输入"
      ;;
    esac
  done
}

main
