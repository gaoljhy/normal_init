#!/bin/bash

#=================================================================#
#   System Required:  CentOS 6+, Debian 7+, Ubuntu 12+            #
#   Description: init server operate set all                      #
#   Author: Mr.G <gjove666@hotmail.com>                           #
#=================================================================#

clear
echo 
echo "#############################################################"
echo "# init        server operate set                            #"
echo "# Author: Mr.G <gjove666@hotmail.com>                       #"
echo "# Github: https://github.com/gaoljhy                        #"
echo "#############################################################"
echo

# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1

input_20(){
    # if read  -t 20 -p "$1" input 
    if read  -p "$1" input 
    # if out time 20 seconds no input，then do else operate
    then
        echo $input
    else
        exit 1
        echo  "timeout"
    fi
}

#  add administraor user
add_user(){
    name=`input_20 "input what ur want to add username: "`
    pass=`input_20 'input what ur want to set password: '`
    echo "you are setting username : ${name}"
    echo "you are setting password : $pass for ${name}"

    #ADD USER
    sudo useradd $name
    if [ $? -eq 0 ];then
        echo "user ${name} is created successfully!!!"
    else
        echo "user ${name} is created failly!!!"
        exit 1
    fi

    # Pasword change
    echo $pass | sudo passwd $name --stdin  &>/dev/null
    if [ $? -eq 0 ];then
        echo "${name}'s password is set successfully"
    else
        echo "${name}'s password is set failly!!!"
        exit 1
    fi

    # sudoers
    echo "$name  ALL=(ALL)    ALL" >> /etc/sudoers      
}

# Disable selinux
disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}


# Get public IP address
get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ ! -z ${IP} ] && echo ${IP} || echo
}

# set hostname Tools-Chain
set_hostname(){
    hostname=`input_20 "input what ur want to set hostname:"`
    hostnamectl set-hostname $hostname
    result=`hostname`
    if [ $result = $hostname ];then
        echo "hostname ${hostname} is set successfully!!!"
    else
        echo "hostname ${hostname} is set faied!!!"
        exit 1
    fi
}

# set ssh connect time out 100s
set_ssh_timeout(){
    echo export TMOUT=100 >> /root/.bash_profile
    cat /root/.bash_profile | grep TMOUT
    source .bash_profile
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config_bak
    # set socket connect heart beat timeout
    echo ClientAliveInterval=60 >> /etc/ssh/sshd_config
    service sshd restart
    cat /etc/ssh/sshd_config | grep ClientAliveInterval
    service sshd restart
}

# install docker
install_docker(){
    curl -sSL https://get.docker.com/ | sh
    systemctl enable docker
    systemctl start docker
    docker version
    if [ $? -ne 0 ]; then
        echo "docker install failed \n"
        exit 1
    else 
        echo "docker install successful \n"
    fi
}

# root passwd length 20 change
root_random_passwd(){
    if [ `whoami` = "root" ];then
        echo $RANDOM |md5sum |cut -c 1-20 > password_$(hostname).txt
        cat password_$(hostname).txt | passwd --stdin root
        echo ""
        echo -e "\033[33m################ New Password ################\033[0m"
        cat password_$(hostname).txt
        echo ""
    else
        echo -e "\033[33m Change Passwd Failed! \033[0m"
        echo -e "\033[33m Please run under root user! \033[0m"
    fi
    # rm password_$(hostname).txt
}

# ROOT ssh no login
root_ssh_nolgin(){
    if [ -s /etc/ssh/sshd_config ] && grep 'PermitRootLogin=yes' /etc/ssh/sshd_config; then
        sed -i 's/PermitRootLogin=yes/PermitRootLogin=no/g' /etc/ssh/sshd_config
    fi
    systemctl restart sshd.service
}

# Port change
ssh_port(){
    port=`input_20 "input which port u want to set for sshd : "`
    if [ -s /etc/ssh/sshd_config ] && grep 'Port 22' /etc/ssh/sshd_config; then
        sed -i "s/#Port 22/Port $port/g" /etc/ssh/sshd_config
    fi
    systemctl restart sshd.service
}

# yum
yum_update(){
    wget -O /etc/yum.repos.d/CentOS-Base.repo \
    https://mirrors.aliyun.com/repo/Centos-7.repo

    yum clean all
    yum makecache
}

# rm alias trash
rm_protect(){
    sudo yum -y install trash-cli
    # .bashrc
    echo alias rm=trash >> ~/.bash_profile
}




# disable_selinux
set_hostname
add_user
yum_update
set_ssh_timeout
install_docker
root_random_passwd
root_ssh_nolgin
ssh_port
# rm_protect
