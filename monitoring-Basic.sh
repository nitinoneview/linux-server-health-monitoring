#!/bin/bash

DISK_THRESHOLD=80
MEM_THRESHOLD=80
CPU_THRESHOLD=85
EMAIL="nitinoneview@gmail.com"

############### 1. Disk Usage  ######################

Disk=$(df -h / | awk 'NR==2 {print $5}' |tr -d "%")

 if [ "$Disk" -ge "$DISK_THRESHOLD" ]
 then 
	 echo "Disk Usage is $Disk%" |mail -s "Disk Alert" $EMAIL
 fi

############### 2. Memory Usage  #########################
Total_Mem=$(free | awk 'NR==2 {print $2}')
Used_Mem=$(free | awk 'NR==2 {print $3}')
Mem=$(( $Used_Mem * 100 / $Total_Mem ))
 
 if [ "$Mem" -gt $MEM_THRESHOLD ]
 then
	 echo "Memory Usage is $Mem%" | mail -s "Memory Alert" $EMAIL
 fi

################## 3. CPU Usage  #######################
cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print int(100 - $8)}')
 
 if [ "$cpu" -gt $CPU_THRESHOLD ]
 then
       echo  "CPU Usage is $cpu%" | mail -s "CPU Alert" $EMAIL
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

