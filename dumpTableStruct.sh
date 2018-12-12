#!/bin/sh
#dumpTableStruct.sh

#this script is used to dump the definition of tables whose syncdir is base to trade

dir_cfg=/home/mysql/syncdata
dir_exp=/tmp/syncdata

flag=0

while read line
do 
  pooltype=$(echo $line | awk '{print $3}')
  if [ "$pooltype" = "0" ]; then
    #dump base
    user=$(echo $line | awk '{print $2}')
    ip=$(echo $line | awk '{print $4}')
    port=$(echo $line | awk '{print $5}')
    passwd_db=$(echo $line | awk '{print $7}')
    
    if [ -z $user -o -z $ip -o -z $port -o -z $passwd_db ]; then
      echo "invalid base configuration, username=$user, ip=$ip, port=$port, please check host.cnf, exit now..."
      exit 1
    else
      #get all table names whose syncdir is base to trade
      while read tableNameLine
      do
        syncDir=$(echo "$tableNameLine" | awk -F'\t' '{print $2}')
        if [ "$syncDir" = "0" ]; then
          tableName=$(echo "$tableNameLine" | awk -F'\t' '{print $1}')
          tableNameBase=$tableNameBase" $tableName"
        fi
      done < $dir_exp/ta_tsynctableinfo

      #dump start for base
      fileBase=${dir_exp}/tableStructBase.sql
      mysqldump -uroot -p$passwd_db -h$ip -P$port -d $user $tableNameBase > $fileBase
      if [ "$?" != "0" ]; then
        echo "dump table definition of base failed, user=$user, ip=$ip, port=$port, exit now..."
        exit 1
      fi
    fi
  elif [ "$pooltype" = "1" ]; then
    #dump  trade
    if [ "$flag" -eq "1" ]; then
      continue
    fi
    
    user=$(echo $line | awk '{print $2}')
    ip=$(echo $line | awk '{print $4}')
    port=$(echo $line | awk '{print $5}')
    passwd_db=$(echo $line | awk '{print $7}')
    #echo -e "$user\t$ip\t$port\t$passwd_db"
    if [ -z $user -o -z $ip -o -z $port -o -z $passwd_db ]; then
      echo "invalid base configuration, username=$user, ip=$ip, port=$port, please check host.cnf, exit now..."
      exit 1
    else
      #get all table names whose syncdir is trade to base
      while read tableNameLine
      do
        syncDir=$(echo "$tableNameLine" | awk -F'\t' '{print $2}')
        if [ "$syncDir" = "1" ]; then
          tableName=$(echo "$tableNameLine" | awk -F'\t' '{print $1}')
          tableNameTrade=$tableNameTrade" $tableName"
        fi
      done < $dir_exp/ta_tsynctableinfo

      #dump start for base
      fileTrade=${dir_exp}/tableStructTrade.sql
      mysqldump -uroot -p$passwd_db -h$ip -P$port -d $user $tableNameTrade > $fileTrade
      if [ "$?" != "0" ]; then
        echo "dump table definition of trade failed, user=$user, ip=$ip, port=$port, exit now..."
        exit 1
      fi
    fi
    
    flag=1
  else
    :
  fi
done < $dir_cfg/host.cnf


