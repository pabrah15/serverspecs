#!/bin/bash

function fixsomesrvwrapper {

    if [[ ! -d /hab/pkgs/somepkg ]]  &&  [[ -L /usr/local/sbin/some-srvice.wrapper ]];    
        then  { echo "some-srvice-wrapper link broken";
        echo "fixing it.......";
         installsome pkg install somepkg --channel somechannel;
        ln -sf "$( installsome pkg path somepkg)"/sbin/some-srvice.wrapper /usr/local/sbin/some-srvice.wrapper;
        # Restart some-srvice
        systemctl daemon-reload;
        systemctl restart some-srvice;
        (( $? )) && echo "service restarted"; };  
    fi;

      }

function fixhabiperror {
    if systemctl status some-srvice|grep "\<failed\>" >/someENV/null && systemctl status some-srvice|grep "SYS_IP_ADDRESS}" >/someENV/null;
        then  { echo "some-srvice encountered SYS_IP_ADDRESS error";
        echo "fixing it.......";
         installsome pkg install somepkg --channel somechannel;
        ln -sf "$( installsome pkg path somepkg)"/sbin/some-srvice.wrapper /usr/local/sbin/some-srvice.wrapper;
        # Restart some-srvice
        systemctl daemon-reload;
        systemctl restart some-srvice;
        (( $? )) && echo "service restarted"; };
    fi;
      }

function fixchefbasechannel {
    if echo "${habchannel}"|grep -i apom >/someENV/null && [[ ! -e /etc/redhat-release ]] ; then
      if [[ $srvenv == "someENV" ]] && [[ ! $habchannel == "somecannel" ]]; then
        hab svc update somepkg --channel somecannel
      elif [[ $srvenv == "someENV" ]] && [[ ! $habchannel == "somecannel" ]]; then       
        hab svc update somepkg --channel somecannel  
      elif [[ $srvenv == "someENV" ]] && [[ ! $habchannel == "somechannel" ]]; then
        hab svc update somepkg --channel somechannel    
      fi;
    fi;    
     }

function updateunixops {
    if echo "${habchannel}"|egrep -i $srvenv >/someENV/null && [[ ! -e /etc/redhat-release ]] ; then
      habupdated=false;
      loadunixops="hab svc load somehabpkg"
      envinname=false;
      echo  $uxopchannel| grep -i $srvenv >/someENV/null && envinname="true";
      if [[ $srvenv == "someENV" ]] && [[ ! $envinname == "true" ]]; then
        hab svc update $package --channel somecannel --strategy at-once > /someENV/null 2>&1 && habupdated=true;
        [[ $habupdated == "true" ]] || { ${loadunixops} --channel somecannel --strategy at-once --force; (( $? )) && habupdated=true; }
      elif [[ $srvenv == "someENV" ]] && [[ ! $envinname == "true" ]]; then
        hab svc update $package --channel somecannel --strategy at-once > /someENV/null 2>&1 && habupdated=true;
        [[ $habupdated == "true" ]] || { ${loadunixops} --channel somecannel --strategy at-once --force; (( $? )) && habupdated=true; }
      elif [[ $srvenv == "someENV" ]] && [[ ! $envinname == "true" ]]; then
        hab svc update somehabpkg --channel somechannel --strategy at-once > /someENV/null 2>&1 && habupdated=true;
         [[ $habupdated == "true" ]] || { ${loadunixops} --channel somechannel --strategy at-once --force; (( $? )) && habupdated=true; }
      fi;
      [[ $uxoplower > $bldruxoplower ]] && { hab svc unload somehabpkg ; sleep 5;  installsome pkg uninstall somehabpkg/${uxopver}; \
                             installsome pkg install somehabpkg/${bldruxopver}; ${loadunixops}/${bldruxopver} --channel ${habchannel} --strategy at-once --force; \
                             (( $? )) && habupdated=true; }
    fi;    
     }

function syncpkgchannel {
    if echo "${habchannel}"|egrep -i 'apom|stable' >/someENV/null && [[ ! -e /etc/redhat-release ]] ; then
      for i in `grep chan /hab/sup/default/specs/*|cut -f1 -d '.'|cut -f6 -d '/'`;
        do channel=`curl -s http://someurl/$i/default | jq -r '.channel'`;
          if echo $channel|grep apom>/someENV/null;
            then 
            if [[ ! $habchannel == $channel ]];
              then pkgname=`hab svc status|grep $i|cut -f1-2 -d '/'`;
                [[ -z "$pkgname" ]] || hab svc update $pkgname --channel $habchannel;      
            fi;
          fi;
        done;
    fi;    
     }

function sacmvfcams {
   if  [[ ! "${sacmenv}" ==  "${fcamsenv}" ]] && [[ ! -z "${sacmenv}" ]] ; then 
      echo "sacm env do not match fcams"; exit 7;
   fi;       
     }

# Run somesrvwrapper on SLES 12 or above
function somesrvwrapper {
    ls /hab/sup/default/specs/automate*.spec &>/someENV/null && exit 8;

    if [[ -d /hab/pkgs/somepkg ]]  &&  [[ ! -e /usr/local/sbin/some-srvice.wrapper ]] ;     
        then  { echo "some-srvice-wrapper link broken";exit 9; };
    fi;
    if [[ ! -d /hab/pkgs/somepkg ]]  &&  [[ -L /usr/local/sbin/some-srvice.wrapper ]]  ;      
        then  { echo "some-srvice-wrapper link broken";exit 9; };
    fi;
      }

function curlchk {
     which curl &>/someENV/null    
    (( $? )) && { echo "curl not found";exit 10; };
     }

function jqchk {
     which jq &>/someENV/null     
    (( $? )) && { echo "jq not found";exit 11; };     
     }

function gethabchannel {
    chefburl="http://someurl/default"
    uxpurl="http://someurl/unixops_admin/default"
    pahurl="http://someurl/pah/default"
    if [[ ! -e /etc/redhat-release ]];
     then [[ $(echo "${habchannel}"|wc -c) -gt 1 ]] ||  habchannel=$(curl -s "${chefburl}"| jq -r '.channel');
      [[ $(echo "${habchannel}"|wc -c) -gt 1 ]] ||  habchannel=$(wget --no-proxy -qO - "${chefburl}"| jq -r '.channel');
      [[ $(echo "${habchannel}"|wc -c) -gt 1 ]] ||  habchannel=$(curl -s "${uxpurl}" | jq -r '.channel');
      [[ $(echo "${habchannel}"|wc -c) -gt 1 ]] ||  habchannel=$(wget --no-proxy -qO - "${uxpurl}" | jq -r '.channel');
      # [[ -z "$habchannel" ]]  &&  echo "Could not determine the habitat channel";

    elif [[ -e /etc/redhat-release ]];
     then [[ $(echo "${habchannel}"|wc -c) -gt 1 ]] ||  habchannel=$(curl -s "${pahurl}" | jq -r '.channel');
      [[ $(echo "${habchannel}"|wc -c) -gt 1 ]] ||  habchannel=$(wget --no-proxy -qO -  "${pahurl}" | jq -r '.channel');
      [[ $(echo "${habchannel}"|wc -c) -gt 1 ]] ||  habchannel=$(curl -s "${uxpurl}" | jq -r '.channel');
      [[ $(echo "${habchannel}"|wc -c) -gt 1 ]] ||  habchannel=$(wget --no-proxy -qO - "${uxpurl}" | jq -r '.channel'); 
      # [[ -z "$habchannel" ]]  &&  echo "Could not determine the habitat channel";
    fi;    
    [[ -z "$habchannel" ]]  || export habchannel
     }

function curldcserrorprintscreen {
   curlfail=false;
   ident_version=$(curl -s https://someurl/"${habchannel}"/pkgs/unixops_admin/latest | jq -r '.ident.version');
   [[ -z "$ident_version" ]]  && ident_version=$(curl -s https://someurl/somechannel/pkgs/unixops_admin/latest | jq -r '.ident.version');
   [[ -z "$ident_version" ]]  && { curlfail="true"; echo "curl connection to the builder someENVuced an error"; };
   }

function wgetchk {
   which wget &> /someENV/null || { echo "wget not found"; };
   which wget > /someENV/null 2>&1;
   (( $? )) && if [[ $(find /hab/pkgs/core -name wget|grep bin|tail -1) ]]; then PATH=$PATH:$(find /hab/pkgs/core -name wget|grep bin|tail -1|rev|cut -f 2- -d '/'|rev);fi; 
    }

function adminpkgchk {
    unixopsloaded=false;
    adminaccountloaded=false;
      if [[ ! $(curl -s http://someurl/unixops_admin/default | jq -r '.pkg.version'|wc -c) -gt 0 ]] && \
          [[ ! $(wget --no-proxy -qO - http://someurl/unixops_admin/default | jq -r '.pkg.version'|wc -c) -gt 0 ]];
        then  unixopsloaded=true;
     fi;
     if [[ ! $(curl -s http://someurl/admin-accounts/default | jq -r '.pkg.version'|wc -c) -gt 0 ]] && \
          [[ ! $(wget --no-proxy -qO - http://someurl/admin-accounts/default | jq -r '.pkg.version'|wc -c) -gt 0 ]];
        then adminaccountloaded=true;
     fi;
     if [[ "${unixopsloaded}" == "true" ]] && [[ "${adminaccountloaded}" == "true" ]] ;
      then exit 12;
     elif  [[ "${unixopsloaded}" == "true" ]];
      then exit 13;
     elif  [[ "${adminaccountloaded}" == "true" ]] ;
      then exit 14;
     fi;    
     }

# function unixopsadminchk {
#       if [[ ! $(curl -s http://someurl/unixops_admin/default | jq -r '.pkg.version'|wc -c) -gt 0 ]] && \
#           [[ ! $(wget --no-proxy -qO - http://someurl/unixops_admin/default | jq -r '.pkg.version'|wc -c) -gt 0 ]];
#         then  exit 13;
#      fi;
#      }
# function uxopadminchk {
#       if [[ ! $(curl -s http://someurl/admin-accounts/default | jq -r '.pkg.version'|wc -c) -gt 0 ]] && \
#           [[ ! $(wget --no-proxy -qO - http://someurl/admin-accounts/default | jq -r '.pkg.version'|wc -c) -gt 0 ]];
#         then  exit 14;
#      fi;
#      }

function unixopsverchk {
    uxpurl="http://someurl/unixops_admin/default"
    uxopver=$(curl -s ${uxpurl} | jq -r '.pkg.version');
    [[ -z "$uxopver" ]] &&  uxopver=$(wget -qO- ${uxpurl} | jq -r '.pkg.version');
    bldruxopver=$(curl -s https://someurl/${habchannel}/pkgs/unixops_admin/latest | jq -r '.ident.version');
    [[ -z "$bldruxopver" ]] &&  bldruxopver=$(wget --no-proxy -qO - https://someurl/${habchannel}/pkgs/unixops_admin/latest| jq -r '.ident.version');
    if  ! [[ "$uxopver" == "$bldruxopver" ]] ;
      then uxoplower=`echo $uxopver|cut -f2- -d '.'`;
      bldruxoplower=`echo $bldruxopver|cut -f2- -d '.'`;
      [[ $uxoplower < $bldruxoplower ]] && { uxopchannel=$(curl -s ${uxpurl} | jq -r '.channel'); \
                            [[ $habupdated == "true" ]] && exit 15; } ;
                            # updateunixops; [[ $habupdated == "true" ]] && exit 15; } ;
      [[ $uxoplower > $bldruxoplower ]] && { uxopchannel=$(curl -s ${uxpurl} | jq -r '.channel'); \
                             exit 16; } ;
                            # updateunixops; exit 16; } ;
    fi
    }

function chefbasechk {
    chef_base_loaded=false;
    if [[ ! $(curl -s http://someurl/default | jq -r '.channel'|wc -c) -gt 0 ]] ;
      then  chef_base_loaded=true;
    elif  which wget &> /someENV/null && [[ $(wget --no-proxy -qO - http://someurl/default | jq -r '.channel'|wc -c) -gt 0 ]] ;
      then chef_base_loaded=true;
    fi;       
    if [[ "$chef_base_loaded" == "false" ]] &&  [[ ! -e /etc/redhat-release ]] ; 
        then exit 17;
    fi;
     }

function pahchk {
    isredhat=false;
    [[ -e /etc/redhat-release ]] && isredhat=true;
    if [[ -e /etc/redhat-release ]] && [[  ! $(curl -s http://someurl/pah/default | jq -r '.channel'|wc -c) -gt 0 ]] && \
          [[ ! $(wget --no-proxy -qO - http://someurl/pah/default | jq -r '.channel'|wc -c) -gt 0 ]] ;
      then exit 18;
    fi;
     }

function curl_hab_error {
    curldcsblock=false;
    curlblock=false;
    habdown=false;
    ident_version=$(curl -s https://someurl/"${habchannel}"/pkgs/unixops_admin/latest | jq -r '.ident.version');
    [[ -z "$ident_version" ]] && ident_version=$(curl -s https://someurl/somechannel/pkgs/unixops_admin/latest | jq -r '.ident.version');
    [[ -z "$ident_version" ]] && ident_version=$(curl -s https://someurl/somecannel/pkgs/unixops_admin/latest | jq -r '.ident.version');
    [[ -z "$ident_version" ]] && export curlblock="true";    
    if [[ "${curlblock}" == "true" ]] ;
      then export DATETDAY=`date +"%Y-%m-%d"`;
        which nslookup > /someENV/null 2>&1;
        (( $? )) && if [[ $(find /hab/pkgs/core -name nslookup|tail -1) ]]; then PATH="$PATH":$(find /hab/pkgs/core -name nslookup|grep bin|tail -1|rev|cut -f 2- -d '/'|rev);fi; 
        ls somedir/SISRTEvents*.csv &>/someENV/null && export logdir="somedir"
        [[ -z "$logdir" ]]  &&  export logdir="someotherdir";  
        for i in `somesrvr|tr -s ' '|grep Address|grep -v '#'|grep -v ':53'|cut -d: -f2|sed 's/^ *//g'`;
          do [[ `grep ,D "${logdir}"/SISRTEvents*.csv|grep -i curl|grep root|grep -v grep|grep "$DATETDAY"|grep "$i"|tail -1` ]] && curldcsblock=true;
              if [[ "${curldcsblock}" == "true" ]];then curlblock=false; break;fi;
          done; 
        [[ -z "$curlblock" ]]  || export curlblock;   
    fi; 
    if [[ -e /usr/bin/systemctl ]]; 
     then systemctl status some-srvice|grep "\<active\>" >/someENV/null || habdown=true ;
    else 
       service some-srvice status|grep running >/someENV/null || habdown=true ;
    fi
    if [[ "${habdown}" == "true" ]] && [[ "${curldcsblock}" == "true" ]] ;
      then exit 19;
    elif  [[ "${curldcsblock}" == "true" ]];
     then exit 20;
    elif [[ "${curldcsblock}" == "false" ]] && [[ "${curlblock}" == "true" ]] ;
     then exit 21;
    fi;    
     }


 # Run suplock on SLES 12 or above
  function suplock {
    suplock=false;
    suprunning=true;
    systemctl status some-srvice|grep "\<active\>" >/someENV/null || suprunning=false;
    systemctl status some-srvice|grep "error -> I/O error" >/someENV/null && suplock=true;
    if [[ "$suplock" == "true" ]] && [[ "$suprunning" == "false" ]]; 
     then [[ ! -e /hab/sup/default/LOCK ]] && suplock=true;
     else suplock=false;
    fi;
    if [[ "$suplock" == "true" ]];then exit 22;fi;       
     }
     
function low_mem {
    lowmem=false;
    curlblock=false;
    habdown=false;
    ident_version=$(curl -s https://someurl/"${habchannel}"/pkgs/unixops_admin/latest | jq -r '.ident.version');
    [[ -z "$ident_version" ]]  &&  ident_version=$(curl -s https://someurl/somechannel/pkgs/unixops_admin/latest | jq -r '.ident.version');
    [[ -z "$ident_version" ]]  &&  ident_version=$(curl -s https://someurl/somecannel/pkgs/unixops_admin/latest | jq -r '.ident.version');
    [[ -z "$ident_version" ]]  && lowmem="true";    
    # if free -h|grep 'buffers/'>/someENV/null;
    #   then memavialble=`free -h|grep 'buffers/'|awk '{print $4}'`;
    #   echo $memavialble|grep G>/someENV/null  || lowmem=true ;
    # fi

     if free -g|grep 'buffers/'>/someENV/null;
      then memavialble=`free -g|grep 'buffers/'|awk '{print $4}'`;
      [[ $memavialble < 2 ]] && lowmem=true ;
    fi
    if [[ -e /usr/bin/systemctl ]]; 
     then systemctl status some-srvice|grep "\<active\>" >/someENV/null || habdown=true ;
    else 
       service some-srvice status|grep running >/someENV/null || habdown=true ;
    fi
    if [[ "${habdown}" == "true" ]] && [[ "${lowmem}" == "true" ]] ;
      then exit 23;  
    fi;    
     }

 # Run systemerr on SLES 12 or above
  function systemerr {
    syserr=false;
    systemctl status>/someENV/null 2>&1 || syserr=true;
    if [[ "$syserr" == "true" ]];then exit 24;fi;       
     }

  function oomkillhab {
    oomkill=false;
    for i in {0..5};
     do DSTRING=$(date -d "$date -$i days" +"%a %b %d");
        dmesg -T|grep "$DSTRING"|grep some-srvice|grep -i Killed >/someENV/null && oomkill=true;
        if [[ "$oomkill" == "true" ]];then break;fi;    
      done
    if [[ "$oomkill" == "true" ]];then exit 25;fi;   
     }

  function compareenv {
    if echo "${habchannel}"|grep -i apom >/someENV/null && [[ ! -e /etc/redhat-release ]] ; then 
      if ! echo "${habchannel}"|grep -i "$srvenv" >/someENV/null; then
       if ! echo "$srvenv"|egrep 'EDU|someENVsomeENV|TEST' >/someENV/null; then
        [[ -z "$sacmenv" ]] && exit 26;
        #  fixchefbasechannel;
        exit 27; 
       fi;      
      fi;
    fi;    
     }

  function comparehabchannel {
    if echo "${habchannel}"|grep -i apom >/someENV/null && [[ ! -e /etc/redhat-release ]] ; then 
      for i in `grep chan /hab/sup/default/specs/*|cut -f1 -d '.'|cut -f6 -d '/'`;
        do channel=`curl -s http://someurl/$i/default | jq -r '.channel'`;
          if echo "$channel"|grep apom>/someENV/null;
            then 
            if [[ ! "$habchannel" == "$channel" ]];
              # then syncpkgchannel;
              then exit 28;                 
            fi;
          fi;
        done;
    fi;
    }

  function sacmcheck {
    [[ -z "$sacmenv" ]]  && exit 29;     
     }

  function chkfile {
    filefound=false;
    if ls /etc/systemd/system/onea* >/someENV/null 2>&1; then
     filefound=true;     
     filecount=$(ls /etc/systemd/system/onea*|wc -l) ;
     echo filepresent $filecount; 
    fi; 
     }

status=true;

if [[ -e /bin/hab ]] &&  [[ -e /usr/bin/systemctl ]]; 
  then 
    # Run systemerr on SLES 12 or above 
    # Check for system errors
    systemerr;
    # Check for curl errors and some-srvice failures
    curl_hab_error; 
    #fixsomesrvwrapper
    #fixhabiperror     
    # Run suplock on SLES 12 or above
    # Check whether or not the habitat supervisor was purposely brought down
    suplock;
    # Check for low memory
    low_mem

  systemctl status some-srvice|grep "\<active\>" >/someENV/null || status=false;

  if [[ $status == "true" ]]; then

    #Check for jq
    jqchk;

    #Check for curl 
    curlchk;
        
    # Set the habitat channel 
    gethabchannel;

    # Check for the presence of chef-base
    chefbasechk;

    # Run somesrvwrapper on SLES 12 or above
    #Check for somesrvwrapper
    somesrvwrapper;

    # Report error if curl is unable to connect to the builder
    #curlfwerror;

    #Check for wget
    wgetchk;

    #Check for unixops-admin and admin-accounts packages

    adminpkgchk

    # #Check for unixops-admin package
    # unixopsadminchk;

    # #Check for admin-accounts package
    # uxopadminchk;


    # Set bldruxopver to the latest stable version of unixops-admin - Exit if the version found on the builder does not match local version
    unixopsverchk;

    # Check for the presence of pah
    pahchk;

    # Compare the serv env to habitat channel name
    compareenv

    # Compare the chef-base's channel to others'
    comparehabchannel

    #Compare env
    sacmvfcams

    # Check server env in sacm
    sacmcheck;

    # Check file
    # chkfile;

    # Run oomkillhab on SLES 12 or above
    # Check the ring buffer for messages realated to some-srvice termination
    else oomkillhab;

  fi;

## Run on SLES 11.x servers, exclude redhat servers
elif [[ -e /bin/hab ]] &&  [[ -e /sbin/service ]] && [[ ! -e /etc/redhat-release ]] ;
  then service some-srvice status|grep running >/someENV/null || status=false;
    # Check for curl errors and some-srvice failures
    curl_hab_error; 
    # Check for low memory
    low_mem

    #Compare env
    sacmvfcams

  if [[ $status == "true" ]]; then

    #Check for jq
    jqchk;

    #Check for curl 
    curlchk;
        
    # Set the habitat channel 
    gethabchannel;

    #Check for somesrvwrapper-  This check is not run on SLES11
    #somesrvwrapper;

    #Check for wget
    wgetchk;

    #Check for unixops-admin and admin-accounts packages

    adminpkgchk



    # Set bldruxopver to the latest stable version of unixops-admin - Exit if the version found on the builder does not match local version
    unixopsverchk;
    
    # Check for the presence of chef-base
    chefbasechk;

    # Check for the presence of pah
    pahchk;

    #Compare env
    sacmvfcams

    # Check server env in sacm
    sacmcheck;

  fi;  

fi;   

if [[ $status == "false" ]] ;  
   then  exit 1;

else
    exit 0;
fi;
