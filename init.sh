#!/bin/bash +x
#Author :Prince Abraham

if [ -d  ${HOME_DIR} ] 
 
 then
      
    # Setup environment 
    
    export TERM=vt100 
    

    #Delete contents of temp folders except the log file
    
    find ${HOME_DIR}/tmp{{cfg.user}}/* ! -name servdev.log -delete

    #Create empty log files


    su {{cfg.user}} -c "touch ${HOME_DIR}/tmp{{cfg.user}}/`hostname`proxylist.txt"
    su {{cfg.user}} -c "touch ${HOME_DIR}/tmp{{cfg.user}}/`hostname`ciphsuite.txt"

        
 
    # Install package dependencies

    for sw in expect bc
     do
      zypper search --match-exact $sw && zypper --non-interactive --no-gpg-checks --quiet install --auto-agree-with-licenses  $sw
     done

    # Search the files for old proxy server's name or IP addresses


    for i in `grep ^fc /etc/passwd|cut -f6 -d ':'`
      do  
       find $i -maxdepth 4 -type f -exec grep -Il . {} +|while IFS= read -r f 
         do egrep -l 'ppr.com|34.45.6.7.8' "$f" >> ${HOME_DIR}/tmp{{cfg.user}}/`hostname`proxylist.txt
         done
      done

   
    # Check whether or not the  local version of opnessl supports one of the  known weak ciphers

    for ciph in $(openssl ciphers 'ALL:eNULL' | tr ':' ' ')
      do  
         if [ $ciph == TLS_RSA_WITH_3DES_EDE_CBC_SHA ]
            then echo -e "$ciph :\t is supported by local version of openssl on $(hostname)">>${HOME_DIR}/tmp{{cfg.user}}/`hostname`ciphsuite.txt
         fi

         if [ $ciph == TLS_RSA_WITH_RC4_128_SHA ]
            then echo -e "$ciph :\t is supported by local version of openssl on $(hostname)">>${HOME_DIR}/tmp{{cfg.user}}/`hostname`ciphsuite.txt
         fi
         if [ $ciph == TLS_RSA_WITH_RC4_128_MD5 ]
            then echo -e "$ciph :\t is supported by local version of openssl on $(hostname)">>${HOME_DIR}/tmp{{cfg.user}}/`hostname`ciphsuite.txt
         fi
      done



    # Connect to all live ports and list the names of all  cipher suites that are currenytly supported
  

    re="^[0-9]+$"
    for port in $(netstat -tunlp|grep LISTEN|awk '{print $4}'|awk -F ":" '{print $NF}')
     do
      if [[ $port =~ $re ]]
       then for ssltls in $(openssl ciphers -v | awk '{print $2}' | sort | uniq)
        do  for ciph in $(openssl ciphers 'ALL:eNULL' | tr ':' ' ')
         do openssl s_client -connect localhost:$port  -cipher $ciph -$ssltls < /dev/null > /dev/null 2>&1 && echo -e "$(hostname) :\t$port :\t$ssltls :\t$ciph">>${HOME_DIR}/tmp{{cfg.user}}/`hostname`ciphsuite.txt
         done
        done
      fi
     done

    # Connect to all live ports and check for known weak cipher-suite support



    for port in $(netstat -tunlp|grep LISTEN|awk '{print $4}'|awk -F ":" '{print $NF}')
      do for ciph in TLS_RSA_WITH_3DES_EDE_CBC_SHA TLS_RSA_WITH_RC4_128_SHA TLS_RSA_WITH_RC4_128_MD5
          do 
           echo -n Testing $ciph...;
           result=$(echo -n | openssl s_client -cipher "$ciph" -connect localhost:$port 2>&1)
           if [[ "$result" =~ ":error:" ]] ; then
            error=$(echo -n $result | cut -d':' -f7);
            echo NO \($error\);
           else
             if [[ "$result" =~ "Cipher is ${ciph}" || "$result" =~ "Cipher    :" ]]
              then
               echo YES
               echo -e "$(hostname) :\t$port :\t$ciph">>${HOME_DIR}/tmp{{cfg.user}}/`hostname`ciphsuite.txt
             else
              echo "UNKNOWN RESPONSE :$(hostname) :\t$port :\t$ciph">>${HOME_DIR}/tmp{{cfg.user}}/`hostname`ciphsuite.txt
              echo $result
             fi
           fi
          sleep 2
          done
      done



 else echo -e "Pre-requisites are not met or a later version was found on the server..."

fi

## Install section ends here

[ -e  ${HOME_DIR}/tmp{{cfg.user}}/`hostname`proxylist.txt ] &&  echo "The FOR loop searche for cipher-suite config was successful"


## End of init hook
