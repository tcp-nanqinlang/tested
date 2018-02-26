#!/bin/bash
Green_font="\033[32m" && Yellow_font="\033[33m" && Red_font="\033[31m" && Font_suffix="\033[0m"
Info="${Green_font}[Info]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
reboot="${Yellow_font}重启${Font_suffix}"
echo -e "${Green_font}
#==================================================
# Project: tcp_nanqinlang
# Description: -super-powered-testing -Debian -fool
# Version: 1.0.0
# Author: nanqinlang
# Blog:   https://sometimesnaive.org
# Github: https://github.com/nanqinlang
#==================================================
${Font_suffix}"

check_system(){
	[[ -z "`cat /etc/issue | grep -iE "debian"`" ]] && echo -e "${Error} only support Debian !" && exit 1
}

check_root(){
	[[ "`id -u`" != "0" ]] && echo -e "${Error} must be root user !" && exit 1
}

check_kvm(){
	apt-get update
	apt-get install -y virt-what
	[[ "`virt-what`" != "kvm" ]] && echo -e "${Error} only support KVM !" && exit 1
}

directory(){
	[[ ! -d /home/tcp_nanqinlang ]] && mkdir -p /home/tcp_nanqinlang
	cd /home/tcp_nanqinlang
}

get_url(){
	bit=`uname -m`
	if [[ "${bit}" = "x86_64" ]]; then
		image_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10.10/ | grep "linux-image" | grep "lowlatency" | awk -F'\">' '/amd64.deb/{print $2}' | cut -d'<' -f1 | head -1`
		image_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10.10/${image_name}"
	elif [[ "${bit}" = "i386" ]]; then
		image_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10.10/ | grep "linux-image" | grep "lowlatency" | awk -F'\">' '/i386.deb/{print $2}' | cut -d'<' -f1 | head -1`
		image_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10.10/${image_name}"
	else
		echo -e "${Error} not support bit !" && exit 1
	fi
}

delete_surplus_image(){
	for((integer = 1; integer <= ${surplus_total_image}; integer++))
	do
		 surplus_sort_image=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "4.10.10" | head -${integer}`
		 apt-get purge -y ${surplus_sort_image}
	done
	apt-get autoremove -y
	if [[ "${surplus_total_image}" = "0" ]]; then
		 echo -e "${Info} uninstall all surplus images successfully, continuing"
	fi
}

delete_surplus_headers(){
	for((integer = 1; integer <= ${surplus_total_headers}; integer++))
	do
		 surplus_sort_headers=`dpkg -l|grep linux-headers | awk '{print $2}' | grep -v "4.10.10" | head -${integer}`
		 apt-get purge -y ${surplus_sort_headers}
	done
	apt-get autoremove -y
	if [[ "${surplus_total_headers}" = "0" ]]; then
		 echo -e "${Info} uninstall all surplus headers successfully, continuing"
	fi
}

install_image(){
	if [[ -f "${image_name}" ]]; then
		 echo -e "${Info} deb file exist"
	else echo -e "${Info} downloading image" && wget ${image_url}
	fi
	if [[ -f "${image_name}" ]]; then
		 echo -e "${Info} installing image" && dpkg -i ${image_name}
	else echo -e "${Error} image download failed, please check !" && exit 1
	fi
}

#check/install required version and remove surplus kernel
check_kernel(){
	get_url

	#when kernel version = required version, response required version number.
	digit_ver_image=`dpkg -l | grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep "4.10.10"`

	#total digit of kernel without required version
	surplus_total_image=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "4.10.10" | wc -l`
	surplus_total_headers=`dpkg -l|grep linux-headers | awk '{print $2}' | grep -v "4.10.10" | wc -l`

	if [[ -z "${digit_ver_image}" ]]; then
		 echo -e "${Info} installing required image" && install_image
	else echo -e "${Info} image already installed a required version"
	fi

	if [[ "${surplus_total_image}" != "0" ]]; then
		 echo -e "${Info} removing surplus image" && delete_surplus_image
	else echo -e "${Info} no surplus image need to remove"
	fi

	if [[ "${surplus_total_headers}" != "0" ]]; then
		 echo -e "${Info} removing surplus headers" && delete_surplus_headers
	else echo -e "${Info} no surplus headers need to remove"
	fi

	update-grub
}

dpkg_list(){
	echo -e "${Info} 这是当前已安装的所有内核的列表："
    dpkg -l |grep linux-image   | awk '{print $2}'
    dpkg -l |grep linux-headers | awk '{print $2}'
	echo -e "${Info} 这是需要安装的所有内核的列表：\nlinux-image-4.10.10-lowlatency"
	echo -e "${Info} 请确保上下两个列表完全一致！"
}

# (1)while kernel is 4.10.10
ver_4.10.10(){
	[[ ! -f /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko ]] && echo -e "${Info} loading mod" && cd /lib/modules/`uname -r`/kernel/net/ipv4 && wget -O tcp_nanqinlang.ko "https://raw.githubusercontent.com/nanqinlang/tcp_nanqinlang-test/master/tcp_nanqinlang.ko" && insmod tcp_nanqinlang.ko && depmod -a
	[[ ! -f /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko ]] && echo -e "${Error} download mod failed,please check !" && exit 1
}

check_status(){
	#status_sysctl=`sysctl net.ipv4.tcp_available_congestion_control | awk '{print $3}'`
	#status_lsmod=`lsmod | grep nanqinlang`
	if [[ "`lsmod | grep nanqinlang`" != "" ]]; then
		echo -e "${Info} tcp_nanqinlang is installed !"
			if [[ "`sysctl net.ipv4.tcp_available_congestion_control | awk '{print $3}'`" = "nanqinlang" ]]; then
				 echo -e "${Info} tcp_nanqinlang is running !"
			else echo -e "${Error} tcp_nanqinlang is installed but not running !"
			fi
	else
		echo -e "${Error} tcp_nanqinlang not installed !"
	fi
}

install(){
	check_system
	check_root
	check_kvm
	directory	
	check_kernel
	dpkg_list
	echo -e "${Info} 确认内核安装无误后, ${reboot}你的VPS, 开机后再次运行该脚本的第二项！"
}

start(){
	check_system
	check_root
	check_kvm
	directory
	ver_4.10.10
	sed -i '/net\.core\.default_qdisc/d' /etc/sysctl.conf
	sed -i '/net\.ipv4\.tcp_congestion_control/d' /etc/sysctl.conf
	echo -e "\nnet.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo -e "net.ipv4.tcp_congestion_control=nanqinlang\c" >> /etc/sysctl.conf
	sysctl -p
	check_status
	rm -rf /home/tcp_nanqinlang
}

status(){
	check_status
}

uninstall(){
	check_root
	sed -i '/net\.core\.default_qdisc=/d'          /etc/sysctl.conf
	sed -i '/net\.ipv4\.tcp_congestion_control=/d' /etc/sysctl.conf
	sysctl -p
	rm  /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko
	echo -e "${Info} please remember ${reboot} to stop tcp_nanqinlang !"
}




echo -e "${Info} 选择你要使用的功能: "
echo -e "1.安装内核\n2.安装并开启算法\n3.检查算法运行状态\n4.卸载算法"
read -p "输入数字以选择:" function

while [[ ! "${function}" =~ ^[1-4]$ ]]
	do
		echo -e "${Error} 无效输入"
		echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" function
	done

if [[ "${function}" == "1" ]]; then
	install
elif [[ "${function}" == "2" ]]; then
	start
elif [[ "${function}" == "3" ]]; then
	status
else
	uninstall
fi