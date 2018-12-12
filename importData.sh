#!/bin/sh
#importData.sh
#import exported data to each database

#dir_cfg=/home/mysql/syncdata
dir_exp=/home/mysql/expdata
dir_tmp=/tmp/syncdata

#import data to base database

#get base host ip
while read line
do
  pooltype_base=$(echo $line | awk '{print $3}')
  if [ "$pooltype_base" = "0" ]; then
    user_base=$(echo $line | awk '{print $2}')
    ip_base=$(echo $line | awk '{print $4}')
    port_base=$(echo $line | awk '{print $5}')
    passwd_db_base=$(echo $line | awk '{print $7}')
  fi
done < host.cnf

if [ -z $user_base -o -z $ip_base -o -z $port_base ]; then
  echo "base host not found, username=$user_base, ip=$ip_base, please check host.cnf, exit now..."
  exit
fi


fileBase=${dir_tmp}"/dropViewOnBase.sql"
fileTrade=${dir_tmp}"/dropViewOnTrade.sql"
>$fileBase
>$fileTrade
while read syncTableLine
do
  syncdir=$(echo "$syncTableLine" | awk -F'\t' '{print $2}')
  tablename=$(echo "$syncTableLine" | awk -F'\t' '{print $1}')

  if [ "$syncdir" = "0" ]; then
    tablename=$(echo "$syncTableLine" | awk -F'\t' '{print $1}')
    echo "DROP VIEW IF EXISTS $tablename;" >> $fileTrade
  elif [ "$syncdir" = "1" ]; then
    echo "DROP VIEW IF EXISTS $tablename;" >> $fileBase
  else
    :
  fi  
done < $dir_tmp/ta_tsynctableinfo


#export table struct of trade database to base database
mysql -uroot -p$passwd_db_base -h$ip_base -P$port_base << EOF
use $user_base;
source $dir_tmp/dropViewOnBase.sql;
source $dir_tmp/tableStructTrade.sql;
EOF

if [ "$?" != "0" ]; then
  echo "import table struct to base faild, ip=${ip_base}, port=${port_base}, exit now..."
  exit 1
fi

while read line
do
  pooltype_base=$(echo $line | awk '{print $3}')
  if [ "$pooltype_base" = "1" ]; then
    user=$(echo $line | awk '{print $2}')
    ip=$(echo $line | awk '{print $4}')
    port=$(echo $line | awk '{print $5}')
    passwd_db=$(echo $line | awk '{print $7}')

    if [ -z $user -o -z $ip -o -z $port ]; then
      echo "invalid trade configuration, username=$user, ip=$ip, port=$port, please check host.cnf, exit now..."
      exit 1
    fi

    #################import data to base begin################
    #generate import sql file for base
    file_base=${dir_tmp}"/importToBase.sql"
    dir_trade=${dir_exp}"/expdata_"${user}
    echo "use $user_base;" > $file_base

    while read syncTableLine
    do
      syncdir=$(echo "$syncTableLine" | awk -F'\t' '{print $2}')
      if [ "$syncdir" = "1" ]; then
        tablename=$(echo "$syncTableLine" | awk -F'\t' '{print $1}')
        echo "truncate table $tablename;" >> $file_base
        echo "load data LOCAL infile '$dir_trade/exp_$tablename' REPLACE INTO TABLE $tablename FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n';" >> $file_base
      fi
    done < $dir_tmp/ta_tsynctableinfo
    
    #import data to base database
    mysql -uroot -p$passwd_db_base -h$ip_base -P$port_base << EOF
    use $user_base;
    source $file_base;
EOF
    echo "import data for $user_base done."
    #################import data to base end##################



    #***************import data to trade begin**************#

    #generate import sql file for trade
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

    #import data to trade database
    mysql -uroot -p$passwd_db -h$ip -P$port << EOF
    use $user;
    source $dir_tmp/dropViewOnTrade.sql
    source $dir_tmp/tableStructBase.sql;
    source $file;
EOF
    echo "import data for $user done."
    #**************import data to trade end***************#
  fi
done < host.cnf

echo "import data for all databases done."
