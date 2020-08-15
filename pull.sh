#!/bin/bash
#set -x
#Author: Prince Abraham

#The script gathers Server Model,/S/N,CPU Speed,Memory Size, Virtualzation specs and SAR Averages
umask 0002
###Begin Variables Section
MSGFILE="$HOME/message.txt"
SFILE="$HOME/myserver_db.txt"
BASE="$HOME/sarlog"
FILE=SUSE_Srvs
HWINFO=/usr/sbin/hwinfo
CPUFREQ=/usr/bin/cpufreq-info
CPUPWR=/usr/bin/cpupower
CPUPWRF="/usr/bin/cpupower frequency-info"
SARW="sar -W"
LSCPU=/usr/bin/lscpu
VXP=/usr/sbin/vxprint
SSHQt="/usr/bin/ssh -o ConnectTimeout=30  -2qt"
SSHQ="/usr/bin/ssh -o ConnectTimeout=30  -2q"
EMAIL1=aa@comp.com
EMAIL2=ddd@comp.com
##done setting up the recipient e-mail
EMAILST1="$EMAIL1 ddd@comp.com"
EMAILST2="$EMAILST1 eee@comp.com"
EMAIIST3="dd@comp.com aa@comp.com bb@comp.com cc@comp.com"
###End Variables Section######
#Check whether or not the server DB file exists
if [ ! -f $SFILE ]
   then
     echo "$HOME/myserver_db.txt does nt exist. Copy server_db.txt to myserver_db.txt or copy it from home"
     exit
fi
#Done Cheking the presence of DB file
#Ignore interrupts
#trap '' INT
#Create $HOME/sarlog directory if it does not exist
if [ ! -e $BASE ]
  then
   mkdir $BASE
fi
#Done creating $HOME/sarlog directory
#Keep a copy of the Allserver.db file from prvious run
cp $BASE/SUSE_Srvs.db $BASE/backup  2> /dev/null
#Keep a copy of the error log from previuos run before removing logs.
rm $BASE/cpudisksanerr.txt 2> /dev/null
cp $BASE/errorlog $BASE/errlog 2> $HOME/cpudisksanerr.txt
cp $HOME/cron* $BASE/errlog 2> /dev/null
cp $BASE/*_v $BASE/backup 2> /dev/null
rm $BASE/failed.txt 2> /dev/null
rm $HOME/$FILE.txt 2> /dev/null
rm -f $BASE/* 2> /dev/null
#Done removing logs
#####Make sure the server DB file is not empty and has the name at least a single server in it
while [ `egrep -v '^#' $SFILE|egrep -v fc6789|cut -d ',' -f1|wc -l` -gt 0 ]; do
 #Confirm with the user whether he/she wants to run the script unless the confirmation was already supplied as an arguemt
 if [ "$1" = yes ]
    then yn=yes
  else
   read -p "Are you sure you want to gather Server specs from all SUSE servers?  " yn
 fi
 #End confirmation
 case $yn  in
   [Yy][Ee][Ss] )
      for s in `egrep -v '^#' $HOME/myserver_db.txt|egrep -v '^$'|egrep -v fcdf89029|egrep -v '^dtm'|cut -d ',' -f1`;\
       do
         #print the name of the server to the screen
         echo $s;\
         #Check whether or not the server is up and running
         if $SSHQt $s ls -d >/dev/null
           then
           #Get the hostname from the server and write it to  the report
            $SSHQt $s test -e /etc/HOSTNAME  && $SSHQt $s cat /etc/HOSTNAME|awk '{print "Host Name:            ",$1}' >>$BASE/$s.txt
           if [ ! -e $BASE/$s.txt 2> /dev/null ] && [ -z `egrep Host $BASE/$s.txt 2> /dev/null|cut -d ' ' -f1` ];
             then $SSHQt $s hostname|awk '{print "Host Name:            ",$1}' >>$BASE/$s.txt;
           fi
           #Write the short Hostname
           echo -n 'Hostname:              '>>$BASE/$s.txt
           nslookup $s |grep Name:|cut -f2|cut -f1 -d '.'>>$BASE/$s.txt
           #Hostname gathering complete
           #Write Server IP
           echo -n 'IP Address:           '>>$BASE/$s.txt
           nslookup $s|grep "Address:"|tail -1|cut -d ':' -f2>>$BASE/$s.txt
           #IP address writing complete
           #Write the OS Version to the report
           $SSHQt $s printf '"`grep FU /etc/.FUSEINFO||grep PRE /etc/.EINFO|cut -d '=' -f2`\n"'|awk -F  "-"  '/F/ {print "OS Ver:             ",$1}'>>$BASE/$s.txt
           #Write FQDN
           echo -n 'FQDN:                  '>>$BASE/$s.txt
           grep $s $SFILE|cut -d ',' -f1>>$BASE/$s.txt
           #Get CPU Model and Speed
           $SSHQt $s /bin/egrep @ /proc/cpuinfo|head -1|awk '{print "CPU Model:            ",$4,$7,$8,$9,$10}'|tr -d $'\r'>>$BASE/$s.txt
           #Get CPU Operating Speed
           $SSHQt $s $LSCPU|egrep '^CPU MHz'|tr -s ' '|cut -d ':' -f 2|cut -d '.' -f 1|awk '{ print "CPU Operating  @:     ",$1, "MHz"}'>>$BASE/$s.txt
           if [ -z `egrep Operating $BASE/$s.txt|cut -d ' ' -f1` ];
            then $SSHQt $s sudo /usr/sbin/dmidecode|grep 'Current Speed'|head -1|cut -d ':' -f 2|awk '{ print "CPU Operating  @:     ",$1, "MHz"}'>>$BASE/$s.txt
           fi
           #CPU Operating Speed gathering complete
           ###Check whether the server is physical or virtual
           ##Begin VM identification section
           $SSHQt $s grep -i vmware /proc/mounts|cut -d ' ' -f1>>$BASE/$s.txt
           if [ -z `egrep vmblock $BASE/$s.txt|cut -d ' ' -f1` ];
             then $SSHQt $s grep -i vmblock /proc/filesystems 2> /dev/null|cut -f2>>$BASE/$s.txt;
           fi
           if [ -z `egrep vmblock $BASE/$s.txt|cut -d ' ' -f1` ];
             then $SSHQt $s $HWINFO|grep 'system.hardware.product'|sed -e 's/^[ \t]*//'|head -1>>$BASE/$s.txt;
           fi
           if [ -z `egrep 'VMware|vmware|vmblock|Xen|HVM' $BASE/$s.txt|cut -d ' ' -f1` ];
             then $SSHQt $s $HWINFO|grep 'Server Module'|tr -s ' '|cut -d ':' -f2>>$BASE/$s.txt;
           fi
           if [ -z `egrep 'VMware|vmware|vmblock|Xen|HVM' $BASE/$s.txt|cut -d ' ' -f1` ];
             then $SSHQt $s $LSCPU|grep 'Xen'|cut -d ':' -f2|sed -e 's/^[ \t]*//'>>$BASE/$s.txt;
           fi
          #Check whether the server was idetified as a VMware/Xen  and it is not a SLES12 system prior to capturing Server Model.
           if [ ! -z `egrep 'ProLiant' $BASE/$s.txt|head -1|cut -d ' ' -f1` ] && [ -z `egrep -i 'FUSE Version 12|VM|vmware|vmblock|full|para|HVM' $BASE/$s.txt|cut -c2` ];
             #The above if statement checks whether the server was idetified as a VMware VM or Xen VM before attempting to gather server Model Numbers
               then echo -n 'Server Model:         '>>$BASE/$s.txt
                 $SSHQt $s $HWINFO|grep 'smbios.system.product\|system.hardware.product'|cut -d '=' -f2|sed "s/'//g">>$BASE/$s.txt;
           #SLES 12 Physical Machine Special
            elif [ ! -z `egrep 'FUSE Version 12' $BASE/$s.txt|head -1|cut -d ' ' -f1` ] && [ -z `egrep -i 'vmware|vmblock|full|para|HVM' $BASE/$s.txt|cut -c2` ];

            then  echo -n "Server Model:          ">>$BASE/$s.txt;
            $SSHQt $s $HWINFO|egrep 'MODALIAS.*ProLiant'|awk -F ':' '{print $7}'|cut -c 3->>$BASE/$s.txt;
           #END SLES 12 Special
            else echo  "Server Model:          VM">>$BASE/$s.txt
           fi
           #Check whether the server was idetified as a VM before gathering Server serial numbers and CPU Governor info
           if [ ! -z `egrep 'ProLiant' $BASE/$s.txt|head -1|cut -d ' ' -f1` ] && [ -z `egrep 'FUSE Version 12|VM|VMware|HVM|para|full|vmblock|vmware' $BASE/$s.txt|cut -c2` ]
           #Pull Serial Number from physical machines
           then echo -n 'Server S/N:           '>>$BASE/$s.txt
           $SSHQt $s $HWINFO|grep 'hardware.serial\|smbios.system.serial'|cut -d '=' -f2|sed "s/'//g">>$BASE/$s.txt
           #SLES 12 Special Subsection
             #SLES 12 LAB Servers
           elif  [ ! -z `egrep 'FUSE Version 12' $BASE/$s.txt|head -1|cut -d ' ' -f1` ] && [ `echo $s|cut -c 1-3` == fmc ];
             then SER=`$SSHQt $s sudo $HWINFO|grep 'Serial: "'|head -1|cut -d ':' -f2|sed "s/\"//g"|sed "s/\ //g"`;
             if [ -z `echo $SER|egrep 'VMw'` ];
              then echo "Server S/N:            $SER">>$BASE/$s.txt;
              else echo "Server S/N:            It's a VM">>$BASE/$s.txt;
             fi
           #END SLES 12 Special Subsection
           #HWINFO does not respond with the S/N pn SLES12 SP2 and later. Record No Access to info if that is the case
           elif  [  -z `egrep 'Proli' $BASE/$s.txt|head -1|cut -d ' ' -f1` ] && [  -z `egrep 'VM' $BASE/$s.txt|head -1|cut -d ' ' -f1` ];
             then echo "Server S/N:            No Access">>$BASE/$s.txt;
           #For all VMs,Put 'VM' for Serial S/N
           else echo "Server S/N:            It's a VM">>$BASE/$s.txt;
           fi
           #Server Model section complete

           if [ ! -z `egrep 'ProLiant' $BASE/$s.txt|head -1|cut -d ' ' -f1` ] && [ -z `egrep 'FUSE Version 12|VMware|HVM|para|full|vmblock|vmware' $BASE/$s.txt|cut -c2` ]
            #Get CPU Governor info
                then $SSHQt $s test -e $CPUFREQ && $SSHQt $s $CPUFREQ -p|awk '{ print "CPU FreQ Governor:    ",$3}'>>$BASE/$s.txt
                #The following is for SLES 12 physical machines. SLES 12 does not have the cpufreq command
                elif [ ! -z `egrep 'FUSE Version 12' $BASE/$s.txt|head -1|cut -d ' ' -f1` ] && [ -z `egrep 'VMware|HVM|para|full|vmblock|vmware' $BASE/$s.txt|cut -c2` ];
                  then $SSHQt $s test -e $CPUPWR && $SSHQt $s $CPUPWRF -g|grep governors|awk -F":" '{ print "CPU FreQ Governor:   ",$2}'>>$BASE/$s.txt
               #For all VMs,Put 'Not Applicable' for CPU Governor
                else echo "CPU FreQ Governor:     Not Applicable">>$BASE/$s.txt
           fi
           #Some physical servers do not respond well to cpufreq command.Report "No governor is used" for such servers
           if grep -q "Server S/N:            It's a VM" $BASE/$s.txt
                 then :
           elif grep -q "CPU FreQ Governor:" $BASE/$s.txt
                 then :
                 else echo "CPU FreQ Governor:     No governor is used">>$BASE/$s.txt
           fi
           #The following lines check the VM Server Manfacturer's name'
           if  [ -z `egrep 'Manufacturer|vmware|VMware|para|vmblock|HVM|Xen' $BASE/$s.txt|head -1|cut -c2` ]
            then echo  'Manufacturer:          HP'>>$BASE/$s.txt
           fi
           if [ -z `egrep 'Manufacturer|vmware|VMware|HVM|vmblock|VT-x|ProLiant' $BASE/$s.txt|head -1|cut -d ' ' -f1` ]
               #Get Manufacture's name
               then echo -n 'Manufacturer:          '>>$BASE/$s.txt
                 $SSHQt $s  $LSCPU|grep 'vendor'|awk '{print $3}'>>$BASE/$s.txt
           fi
           if [ -z `egrep 'Manufacturer|VMware|para|vmblock' $BASE/$s.txt|head -1|cut -d ' ' -f1` ]  && [  ! -z `egrep ProLiant $BASE/$s.txt|head -1|cut -d ' ' -f1` ]
              then echo  'Manufacturer:          HP'>>$BASE/$s.txt
           fi
           if [ -z `egrep Manufacturer $BASE/$s.txt|head -1|cut -d ' ' -f1` ]  && [  ! -z `egrep 'vmblock|VMware' $BASE/$s.txt|head -1|cut -d ' ' -f1` ]
            then echo  'Manufacturer:          VMware'>>$BASE/$s.txt
           fi
           if [ -z `egrep Manufacturer $BASE/$s.txt|head -1|cut -d ' ' -f1` ]  && [  ! -z `egrep 'HVM' $BASE/$s.txt|head -1|cut -d ' ' -f1` ]
            then echo  'Manufacturer:          SUSE Xen VM'>>$BASE/$s.txt
           fi
           #Virtualization type

           if [ -z `grep vmblock $BASE/$s.txt|cut -d ' ' -f1` ] && [ `echo $s|cut -c 1-3` = fmc ]
            #The below statemnet checks for the presence of lscpu on LAB Servers and run it as root
             then $SSHQt $s test -e $LSCPU && $SSHQt $s sudo $LSCPU|grep Virtualization|tr -s ' '|cut -d ':' -f 2|awk '{print "Virtualization type:  ",$1}'|tr -d $'\r'>>$BASE/$s.txt
           fi
           #Check for the presence of lscpu on all other servers and run it as non-root account
           if [ -z `grep vmblock $BASE/$s.txt|cut -d ' ' -f1` ] && [ `echo $s|cut -c 1-3` != fmc ]
             then $SSHQt $s test -e $LSCPU && $SSHQt $s $LSCPU|grep Virtualization|tr -s ' '|cut -d ':' -f 2|awk '{print "Virtualization type:  ",$1}'|tr -d $'\r'>>$BASE/$s.txt
           fi;
           if [ -z `grep Virtualization $BASE/$s.txt|cut -d ' ' -f1` ] && [  ! -z `egrep VMware $BASE/$s.txt|head -1|cut -d ' ' -f1` ]
             then echo "Virtualization type:   VMware VM">>$BASE/$s.txt
             elif [ -z `grep Virtualization $BASE/$s.txt|cut -d ' ' -f1` ]
              then echo "Virtualization type:   Physical Machine">>$BASE/$s.txt
           fi;

           ##END of VM identification
           ###End of physical/VM check
           #Get the # of CPUs(CPU Threads-Physical and Logical)
           declare -i CPUSS=`$SSHQt $s test -e $LSCPU && $SSHQt $s ls $LSCPU 2> /dev/null|wc -l`
           if [[ $CPUSS == 1 ]]
            then $SSHQt $s test -e $LSCPU && $SSHQt $s $LSCPU|egrep '^CPU\('|awk '{print $2}'>$BASE/$s
            else $SSHQt $s grep processor /proc/cpuinfo|wc -l>$BASE/$s
           fi
           if [ `cat $BASE/$s|wc -l` -gt 0 ]
            then declare -i CCOUNT
            read -a CCOUNT < <(echo $(cat $BASE/$s|tr -d $'\r'))
           fi
           #Gather CPU cores/sockets and hyper-threading specs
           if [[ $CCOUNT > 1 ]] && [[ $CPUSS < 1 ]]
            #The below two commands are only run if the target server does not have lscpu comand
            then $SSHQt $s grep 'physical\ id' /proc/cpuinfo |sort|uniq|wc -l|awk '{print $1}'|awk '{print "CPU socket(s):        ",$1}'>>$BASE/$s.txt
              $SSHQt $s test ! -e $LSCPU && $SSHQt $s grep 'cpu\ cores' /proc/cpuinfo|head -1||awk '{print $4}'|awk '{print "Core(s) per socket:   ",$4}'>>$BASE/$s.txt
            elif [[ $CCOUNT > 1 ]] && [[ $CPUSS == 1 ]]
            #The below three commands are only run when the  target server has the lscpu comand
              then $SSHQt $s $LSCPU|egrep '^CPU soc|^Socket\('|tr -s ' '|cut -d ':' -f 2|awk '{print "CPU socket(s):        ",$1}'>>$BASE/$s.txt
              $SSHQt $s $LSCPU|egrep '^Core'|awk '{print $4}'|awk '{print "Core(s) per socket:   ",$1}'>>$BASE/$s.txt
              $SSHQt $s $LSCPU|egrep '^Thread'|awk '{print $4}'>$BASE/$s.ttxt
            #The below command is run if the server reported having a single CPU thread
             elif [[ $CCOUNT == 1 ]]
               then echo 1 > $BASE/$s.ttxt
               echo "CPU socket(s):         1">>$BASE/$s.txt
               echo "Core(s) per socket:    1">>$BASE/$s.txt
           fi
           #Calculate the number of CPU cores
           if [ `cat $BASE/$s.ttxt|wc -l` -gt 0 ]
            then declare -i TCOUNT
            read -a TCOUNT < <(echo $(cat $BASE/$s.ttxt|tr -d $'\r'))
           fi
           if [[ $TCOUNT = 1 ]]
            then echo -n 'CPU Cores:             '>>$BASE/$s.txt
             cat $BASE/$s>>$BASE/$s.txt
             echo  'CPU Threads:           No HyperThreading'>>$BASE/$s.txt
            elif [[ $TCOUNT > 1 ]]
              then echo -n 'CPU Cores:             '>>$BASE/$s.txt
              echo $(($CCOUNT/$TCOUNT))>>$BASE/$s.txt
              #Calculate Thread
              echo -n 'CPU Threads:           '>>$BASE/$s.txt
              cat $BASE/$s>>$BASE/$s.txt
              #An altenate method to calculate the Cores
              #echo $CCOUNT|awk '{print $1/"'$TCOUNT'"}  '>>$BASE/$s.txt
           fi
           #End of CPU core calcualtion
           #Gather the size of physical memory
           echo -n 'Physical memory(RAM):  '>>$BASE/$s.txt
           #Check if it is LAB Server
           if [ `echo $s|cut -c 1-3` = fmc ] && [ `echo $s|cut -c 1-8` != GHC8900 ]
            #The below lines runs dmidecode to determine the total RAM on LAB servers
            then $SSHQt $s sudo /usr/sbin/dmidecode -t memory|grep Size|grep MB|awk -F ' ' '{print $2}'|awk '{ sum+=$1/1024} END {print sum,"GB"}'>>$BASE/$s.txt
            elif [ `echo $s|cut -c 1-8` = GHC8900 ]
             then $SSHQt $s $HWINFO --memory|grep GB|awk -F ' ' '{print $3,$4}'>>$BASE/$s.txt
            else
             $SSHQt $s free -m|egrep Mem:|awk '{print $2}'|tr '\n' ' '>>$BASE/$s.txt
            echo MB>>$BASE/$s.txt
           fi
           #Physical Memory complete
           #Calculate the total of all Disk Space
           echo -n 'Local Disk size in GB: '>>$BASE/$s.txt
           if [ `echo $s|cut -c 1-3` = fmc ]
             then
              #$SSHQt $s df -PT|egrep -v '^tmpfs'|grep -v blocks|awk '!seen[$1]++'|awk -F ' ' '{print $3}'|awk '{ sum+=$1/1024/1024} END {print sum}'>$BASE/$s.dtxt
              #$SSHQt $s sudo /sbin/pvscan|grep PV|grep MiB|awk -F '[' '{print $2}'|awk -F '/' '{print $2}'|awk -F ' ' '{print $1/1024}'>>$BASE/$s.dtxt
              #$SSHQt $s sudo /sbin/pvscan|grep PV|grep -v MiB|awk -F '[' '{print $2}'|awk -F '/' '{print $2}'|awk -F ' ' '{print $1}'>>$BASE/$s.dtxt
              #$SSHQt $s sudo /sbin/pvscan|grep Total|awk -F '[' '{print $3}'|awk -F ': ' '{print $2}'>>$BASE/$s.dtxt
              #$SSHQt $s sudo /sbin/pvs|grep -v PSize|awk -F ' ' '{print $5}'| rev | cut -c 2- | rev|awk '{ sum+=$1} END {print sum}'>>$BASE/$s.dtxt
              $SSHQt $s sudo /sbin/pvs 2>> $BASE/$s.etxt|grep -v PSize|awk -F ' ' '{print $5}'>$BASE/$s.pvtxt
              for i in `cat $BASE/$s.pvtxt`
                do S=`echo $i| rev | cut -c 1`
                  if [ `echo $S` == G ]
                   then echo $i|rev|cut -c 2- |rev>$BASE/$s.dtxt
                  elif [ `echo $S` == g ]
                   then echo $i|rev|cut -c 2- |rev>>$BASE/$s.dtxt
                  elif [ `echo $S` == m ]
                   #Convert the disk sizes reported in Mbytes to GB
                   then echo $i|rev|cut -c 2- |rev|awk -F ' ' '{print $1/1024}'>>$BASE/$s.dtxt
                  else echo $i>>$BASE/$s.derrtxt
                  fi
                done
              $SSHQt $s test -e $VXP && $SSHQt $s /usr/sbin/vxprint |grep 'dg '|awk -F ' ' '{print $2 }'>$BASE/$s.vxptxt
              if [ -e $BASE/$s.vxptxt ]
               then
                for i in `cat $BASE/$s.vxptxt`
                 do VG=`echo $i`
                  $SSHQt $s $VXP -g $VG -dF "%publen"|awk 'BEGIN {s = 0} {s += $1} END {print s}'|awk '{ sum+=$1/2/1024/1024} END {print sum}'>>$BASE/$s.dtxt
                 done
              fi
              $SSHQt $s df -PT|egrep -v '^tmpfs'|grep -v blocks|grep -v mapper|awk '!seen[$1]++'|awk -F ' ' '{print $3}'|awk '{ sum+=$1/1024/1024} END {print sum}'>>$BASE/$s.dtxt
              cat $BASE/$s.dtxt|awk '{ sum+=$1} END {print sum}'>>$BASE/$s.txt
            else
              $SSHQt $s df -PT|egrep -v '^tmpfs'|grep -v blocks|grep -v vgSAN|awk '!seen[$1]++'|awk -F ' ' '{print $3}'|awk '{ sum+=$1/1024/1024} END {print sum}'>>$BASE/$s.txt
           fi
           #End Disk space check
           #SAN Disk Space
           echo -n 'SAN Size in GB:        '>>$BASE/$s.txt
           if [ `$SSHQt $s df -PT|egrep SAN|wc -l` -gt 0 ]
            then $SSHQt $s df -PT|egrep SAN|awk -F ' ' '{print $3}'|awk '{ sum+=$1/1024/1024} END {print sum}'>>$BASE/$s.txt
            else echo '0'>>$BASE/$s.txt
           fi
           #check for IHS instances and print the total number of HTTP Processes
           $SSHQt $s ps -efl|grep ihs|grep httpd|wc -l>$BASE/"$s"IH.Stxt
           #Count the Processes
           if [ `cat $BASE/"$s"IH.Stxt|wc -l` -gt 0 ]
            then declare -i IHSPCOUNT
            read -a IHSPCOUNT < <(echo $(cat $BASE/"$s"IH.Stxt|tr -d $'\r'))
             if  [ $IHSPCOUNT -gt 0 ]
              then echo IBM HTTP Processes:"    "$IHSPCOUNT>>$BASE/$s.txt
              else echo IBM HTTP Processes:"    None">>$BASE/$s.txt
             fi
           fi
           #Server Application
           echo -n 'Application:           '>>$BASE/$s.txt
           grep $s $HOME/myserver_db.txt|cut -d ',' -f6>>$BASE/$s.txt
           # End Server Application

           #Server Env
           echo -n 'Environment:           '>>$BASE/$s.txt
           if [ `echo $s|cut -d '.' -f 2` = md6 ]
             then echo 'Prod' >>$BASE/$s.txt
             elif [ `echo $s|cut -d '.' -f 2` = md6q ]
             then echo 'QA' >>$BASE/$s.txt
             elif [ `echo $s|cut -d '.' -f 2` = md7 ]
             then echo 'DR/Prod' >>$BASE/$s.txt
             else grep $s $HOME/myserver_db.txt|cut -d ',' -f5>>$BASE/$s.txt
           fi
           #End Server env
           #Write Server Location
           echo -n 'Location:              '>>$BASE/$s.txt
           if [ `echo $s|cut -c 1-3` = fmc ]
             then echo 'lAB801' >>$BASE/$s.txt
             elif [ `echo $s|cut -c 1-2` = fc ]
             then echo lOCAL dc1 >>$BASE/$s.txt
             elif [ `echo $s|cut -c 1-3` = ecc ]
             then echo lOCAL dc2 >>$BASE/$s.txt
             elif [ `echo $s|cut -c 1-3` = edc ]
             then echo lOCAL dc >>$BASE/$s.txt
             elif [ `echo $s|cut -c 1-3` = cqp ]
             then echo 'Remote CC' >>$BASE/$s.txt
             elif [ `echo $s|cut -c 1-3` = cqd ]
             then echo 'lOCAL dc' >>$BASE/$s.txt
             elif [ `echo $s|cut -c 1-3` = cnr ]
             then echo lOCAL dc >>$BASE/$s.txt
             elif [ `echo $s|cut -c 1-3` = fsc ]
             then echo 'lOCAL dc' >>$BASE/$s.txt
             elif [ `echo $s|cut -c 1-3` = ito ]
             then echo 'EDC' >>$BASE/$s.txt
             else
             echo 'Fiil in' >>$BASE/$s.txt
           fi
         #End Server Location
         #check whether or not Symantec CSP or Symantec data ceneter security software is installed
           echo -n 'Symantec CSP/DSS:      '>>$BASE/$s.txt
           $SSHQt $s rpm -qa|grep SYMCcsp>>$BASE/$s.txt|| $SSHQt $s rpm -qa|grep sdcss|tail -1>>$BASE/$s.txt
           #$SSHQt $s rpm -qa|grep SYMCcsp>>$BASE/$s.txt|| $SSHQt $s rpm -qa|grep sdcss|tail -1>>$BASE/$s.txt || echo 'Not Installed'>>$BASE/$s.txt
           if [ -z `egrep 'SYMCcsp|sdcss' $BASE/$s.txt|cut -d ' ' -f1` ]
            then echo 'Not Installed'>>$BASE/$s.txt
           fi
           #Get the Kernel Vesrion
           echo -n 'Kernel Version:        '>>$BASE/$s.txt
           $SSHQt $s uname -r>>$BASE/$s.txt
          else echo "Unable to access $s. $s may be down "|tee -a $BASE/failed.txt>>$BASE/$s.txt
         fi
         echo "_____________________________________________________________________________________________________">>$BASE/$s.txt
       done
      break;;
   [Nn]?  ) exit;;
          * ) echo "Please answer yes or no.";exit;;
  esac
 done

#Start Formatting
#The nex few lines remove text 'vmware','vmware-block',c0t0..' etc  and replace with "VMWare VM or Physical Machine"
for i in `ls $BASE/*.txt`;
 do
  cp $i $i`echo 1`
  cp $i`echo 1` $BASE/backup/
  sed '/^vmware-vmblock/ d' $i > $i`echo 2`
  sed '/^ vmware/ d' $i`echo 2` > $i`echo 3`
  sed '/^ mga\|system.hardware.product/ d' $i`echo 3`> $i`echo 4`
  sed '/^ cirrus\|system.firmware.vendor\|info.product\|radeon/ d' $i`echo 4`> $i`echo 5`
  sed '/^Xen/ d' $i`echo 5`> $i`echo 6`
  sed 's/c0d.*/Virtualization type:     Physical Machine/' $i`echo 6` > $i`echo 7`
  sed 's/Virtualization type.*none/Virtualization type:   Physical Machine/' $i`echo 7` > $i`echo 8`
  sed 's/^.*\(VT-x\)/\Virtualization type:   Physical Machine/' $i`echo 8` > $i`echo 9`
  cp $i`echo 9` $i`echo _v`
  mv $i`echo 9` $i
 done

#Formatting complete

#Output Verfication

for f in `ls $BASE/*.com.txt`;
 do wc -l $f|awk '{print $1}'|tr -d $'\r' 2> /dev/null >$f`echo 10`;
  declare -i LINESS;
  read -a LINESS < <(echo $(cat $f`echo 10`|tr -d $'\r'));
  if [[ $LINESS == 26 ]]
   #The below line combines all files with 25 lines of responses into a sinlge file
   then cat $f >>$HOME/$FILE.txt  2> /dev/null
  elif [[ $LINESS == 2 ]];
   then :;
  else
   echo lines missing from $f >>$BASE/failed.txt;
   #The next line add all files with the number of lines between 23 and 2 into the same file
    cat $f >>$HOME/$FILE.txt  2> /dev/null;
  fi;
 done
#End of Output verfication


# Preparing the files for a python program
for i in `ls $BASE/*.txt`;
 do
  #The below code removes the last line from each file
  sed '/^____/ d' $i> $i`echo 11`
  #The next line removes all white spaces after the colon
  sed 's/:[[:blank:]]*/:/g' $i`echo 11` > $i`echo 12`
  #The below code removes the first line line from each file
  sed '/^Host Nam/ d' $i`echo 12`> $i`echo 13`
  mv $i`echo 13` $i;
 done

#Run the python program
/usr/bin/python  $HOME/PycharmProjects/dfgd/pullcpumemdisksan.py

# Preparing the text file for emailing.
  #Remove the short hostname
sed '/^Hostname/ d' $HOME/$FILE.txt > $BASE/$FILE.txt
# Preparing the CSV file for MySQL/SQLite
  #Remove the heading
sed  '/^Host/ d' $HOME/PycharmProjects/dfgd/SUSE_Srvs.csv > $BASE/SUSE_Srvs.db #Remove the last character from each line
sed  -i 's/,$//' $BASE/SUSE_Srvs.db
#Create a file for the second table
cat  $BASE/SUSE_Srvs.db|cut -d ',' -f1 > $BASE/host.db
#CSV files for DB creted

#Build the list of files to E-mail
FLIST=
for file in $BASE/$FILE.?xt
 do
  if [ -e $file ]
   then FLIST="$FLIST -a $file"
  fi
 done
if [ -e $BASE/failed.txt ]
then FLIST="$FLIST -a $BASE/failed.txt"
fi

if [ -e $HOME/PycharmProjects/fcsrvd/SUSE_Srvs.csv ]
then FLIST="$FLIST -a $HOME/PycharmProjects/fcsrvd/SUSE_Srvs.csv"
fi

#Completed compiling the list of files to E-mail

#Create a message file
SUBJ="Uptime, Server Specs(Physical or VM,Model/Serial), CPU (Speed,Model,Opearting Speed,Speed Governor,Cores,Threads etc), RAM, Disk,SAN,HTTP,CSP and Kernel Vesrion)"
echo $SUBJ > $MSGFILE
#Message file completed

#E-mail
function MAIlx {
  mailx -s" $SUBJ for $DATE - Mailed from `cat /etc/HOSTNAME`" $FLIST -r $EMAIL1 $1 < $MSGFILE
     }
#Call function MAIlx to send e-mails
MAIlx $EMAIL2
#MAIlx $EMAILST1
#MAIlx $EMAILST2
#MAIlx $EMAILST3

#Copy the server specs to ghvg5756 and ghvg5757 for Django
scp $BASE/SUSE_Srvs.db ghvg5756.com:~/sarlog/
scp $BASE/SUSE_Srvs.db ghvg5757.com~/sarlog/
