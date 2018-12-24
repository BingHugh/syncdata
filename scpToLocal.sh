#!/bin/sh
#scpToLocal.sh

#scp trade data from all remote hosts to local dir

dir_remote=/home/mysql/expdata
dir_local=/home/mysql/expdata
dir_cfg=/home/mysql/syncdata

if [ -d $dir_local ]; then
  :
else
  echo "local data path $dir_local is invalid, exit now"
  exit 1
fi

if [ -d $dir_cfg ]; then
  :
else
  echo "cfg path $dir_cfg is invalid, exit now"
  exit 1
fi


#pick up information of base host
while read line
do
  case $line in
  \#*)
    continue
    ;;
  ins[0-9]*)
    pooltype=$(echo $line | awk '{print $3}')
    if [ "$pooltype" = "0" ]; then
      ip_base=$(echo $line | awk '{print $4}')
      #other param if needed
    else
      :
    fi 
    ;;
  *)
    continue
    ;;
  esac
done < host.cnf

if [ -z $ip_base ]; then
  echo "no base host information found, please check the configuration. exit now..."
  exit 1  
fi

chmod +x scpFileToLocal.exp

#foreach remote host,execute scp
while read line
do
  case $line in
  \#*)
    continue
    ;;
  ins[0-9]*)
    pooltype=$(echo $line | awk '{print $3}')         
    if [ "$pooltype" = "1" ]; then
      ip_trade=$(echo $line | awk '{print $4}')
      if [ -n $ip_trade -a "$ip_trade" != "$ip_base" ]; then
        passwd=$(echo $line | awk '{print $6}')
        user=$(echo $line | awk '{print $2}')
        folder="expdata_"$user
        scpFileToLocal.exp $dir_remote/$folder $ip_trade $passwd $dir_local

        if [ "$?" = "0" ]; then
          echo "scp files $dir_remote/$folder from remote host $ip_trade done."
        else
          echo "scp files $dir_remote/$folder from remote host $ip_trade failed, exit now..."
          exit 1
        fi 
      fi
    else
      :
    fi 
    ;;
  *)
    continue
    ;;
  esac
done < host.cnf

echo "scp files from all remote hosts done."

