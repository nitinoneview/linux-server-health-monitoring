#!/bin/bash

DISK_THRESHOLD=80
MEM_THRESHOLD=80
CPU_THRESHOLD=85
EMAIL="nitinoneview@gmail.com"
DISK_FLAG="/home/nitin/Project/script/disk_alert.flag"
MEM_FLAG="/home/nitin/Project/script/mem_alert.flag"
CPU_FLAG="/home/nitin/Project/script/cpu_alert.flag"

############### 1. Disk Usage  ######################

Disk=$(df -h / | awk 'NR==2 {print $5}' |tr -d "%")

 if [ "$Disk" -ge "$DISK_THRESHOLD" ]
 then
    if [ ! -f "$DISK_FLAG" ]
    then
        echo "Disk Usage is $Disk%" | mail -s "Disk Alert" $EMAIL
        touch "$DISK_FLAG"
    fi
 else
     rm -f "$DISK_FLAG"
 fi 
############### 2. Memory Usage  #########################
Total_Mem=$(free | awk 'NR==2 {print $2}')
Used_Mem=$(free | awk 'NR==2 {print $3}')
Mem=$(( $Used_Mem * 100 / $Total_Mem ))
 
 if [ "$Mem" -ge "$MEM_THRESHOLD" ]
 then
    if [ ! -f "$MEM_FLAG" ]
    then
        echo "Memory Usage is $Mem%" | mail -s "Mem Alert" $EMAIL
        touch "$MEM_FLAG"
    fi
 else
    rm -f "$MEM_FLAG"
 fi
################## 3. CPU Usage  #######################
cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print int(100 - $8)}')

 if [ "$cpu" -ge "$CPU_THRESHOLD" ]
 then
    if [ ! -f "$CPU_FLAG" ]
    then
        echo "CPU Usage is $cpu%" | mail -s "CPU Alert" $EMAIL
        touch "$CPU_FLAG"
    fi
 else
    rm -f "$CPU_FLAG"
 fi
############### 4. Service Monitoring  ###################

a=$(systemctl is-active httpd)
b=$(systemctl is-active sshd)
c=$(systemctl is-active crond)

 if [ "$a" != "active" ]
 then 
	echo "httpd Service is Down" |mail -s "Service Alert" $EMAIL
 fi

 if [ "$b" != "active" ]
 then
	 echo "sshd service is Down" | mail -s "Service Alert" $EMAIL
 fi

 if [ "$c" != "active" ]
 then
	 echo "crond service is Down" | mail -s "Service Alert" $EMAIL
fi

##############################################################

 echo
 echo ===== SERVER HEALTH REPORT =======
 echo
 echo "Hostname     : $(hostname)"
 echo "Date         : $(date '+%Y-%m-%d %H:%M:%S')"
 echo "Disk Usage   : $Disk%"
 echo "Memory Usage : $Mem% "
 echo "CPU Usage    : $cpu% "
 echo "HTTPD        : $a    "
 echo "SSHD         : $b    "
 echo "CROND        : $c    "

