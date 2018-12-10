#!/bin/sh
#scpToRemote.sh

#scp local exported base data to remote trade machine
#/home/mysql/expdata/expdata_base/*

dir_cfg=/home/mysql/syncdata
dir_base=/home/mysql/expdata/expdata_base

#check whether the data dir is valid
if [ -d $dir_base ]; then
  :
else
  echo "data path $dir_base is invalid, exit now"
  exit 1
fi

#check whether the config data is valid
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
done < $dir_cfg/host.cnf

if [ -z $ip_base ]; then
  echo "no base host information found, please check the configuration. exit now..."
  exit 1  
fi

chmod +x $dir_cfg/scpFileToRemote.exp

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
      passwd=$(echo $line | awk '{print $6}')
      #other param if needed
      if [ -n $ip_trade -a "$ip_trade" != "$ip_base" ]; then
        $dir_cfg/scpFileToRemote.exp $dir_base $ip_trade $passwd
        if [ "$?" = "0" ]; then
          echo "scp files $dir_base to remote host $ip_trade done."
        else
          echo "scp files $dir_base to remote host $ip_trade failed, exit now..."
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
done < $dir_cfg/host.cnf

echo "scp files to all remote hosts done."


