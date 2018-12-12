#!/bin/sh
#exportCfgData.sh

#dir_cfg=/home/mysql/syncdata
dir_tmp=/tmp/syncdata

#check whether the config data is valid
#if [ -d $dir_cfg ]; then
#  :
#else
#  echo "cfg path $dir_cfg is invalid, exit now"
#  exit 1
#fi

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
      user=$(echo $line | awk '{print $2}')
      ip=$(echo $line | awk '{print $4}')
      port=$(echo $line | awk '{print $5}')
      passwd=$(echo $line | awk '{print $7}')
    else
      :
    fi 
    ;;
  *)
    continue
    ;;
  esac
done < host.cnf

if [ -z $user ]; then
  echo "no base user found, please check the configuration. exit now..."
  exit 1  
fi

mysql -uroot -p$passwd -h$ip -P$port << EOF
use $user;
select * from ta_tdbinstanceinfo into outfile '/tmp/ta_tdbinstanceinfo' FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n';
select * from ta_tdbinfo into outfile '/tmp/ta_tdbinfo' FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n';
select * from ta_tsynctableinfo into outfile '/tmp/ta_tsynctableinfo' FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n'; 
EOF

if [ "$?" -eq "0" ]; then
  :
else
  echo "export config data in $ip:$port failed, exit now..."
  exit 1
fi

if [ -d $dir_tmp ]; then
  chmod 600 $dir_tmp
else
  mkdir $dir_tmp
  chmod 600 $dir_tmp
fi

mv /tmp/ta_tdbinstanceinfo $dir_tmp
mv /tmp/ta_tdbinfo $dir_tmp
mv /tmp/ta_tsynctableinfo $dir_tmp

echo "export all config data done."
