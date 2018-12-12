#!/bin/sh
#importToTrade.sh
#import exported base data to trade database

dir_cfg=/home/mysql/syncdata
dir_exp=/home/mysql/expdata
dir_tmp=/tmp/syncdata

#foreach trade in remote host, import base data for them



#get base host ip
while read line
do
  pooltype_base=$(echo $line | awk '{print $3}')
  if [ "$pooltype_base" = "0" ]; then
    user_base=$(echo $line | awk '{print $2}')
    ip_base=$(echo $line | awk '{print $4}')
  fi
done < $dir_cfg/host.cnf

if [ -z $user_base -o -z $ip_base ]; then
  echo "base host not found, username=$user_base, ip=$ip_base, please check host.cnf, exit now..."
  exit
fi

while read line
do
  pooltype_base=$(echo $line | awk '{print $3}')
  if [ "$pooltype_base" = "1" ]; then
    user=$(echo $line | awk '{print $2}')
    ip=$(echo $line | awk '{print $4}')
    port=$(echo $line | awk '{print $5}')

    if [ -z $user -o -z $ip -o -z $port ]; then
      echo "invalid trade configuration, username=$user, ip=$ip, port=$port, please check host.cnf, exit now..."
      exit 1
    fi

    #generate import sql file
    file=$dir_tmp/importToTrade.sql          
    dir_base=$dir_exp"/expdata_"$user_base

    echo "use $user;" > $file
    
    while read syncTableLine
      do
        syncdir=$(echo "$syncTableLine" | awk -F'\t' '{print $2}')
        if [ "$syncdir" = "0" ]; then
          tablename=$(echo "$syncTableLine" | awk -F'\t' '{print $1}')
          echo "truncate table $tablename;" >> $file
         
          echo "load data LOCAL infile '$dir_base/exp_$tablename' REPLACE INTO TABLE $tablename FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n';" >> $file
        fi
      done < $dir_tmp/ta_tsynctableinfo

    if [ "$ip" = "$ip_base" ]; then
      #trade shares the same ip with base
      
      :
    else
      #trade is in different host
      :
    fi
  fi
done < $dir_cfg/host.cnf

