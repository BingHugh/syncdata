#!/bin/sh
#exportBaseData.sh

dir_export=/home/mysql/expdata
dir_tmp=/tmp/syncdata
dir_cfg=/home/mysql/syncdata

if [ -d $dir_export ]; then
  :
else
  echo "export path $dir_export is invalid, exit now..."
  exit 1
fi

if [ -d $dir_tmp ]; then
  :
else
  echo "tmp path $dir_tmp in invalid, exit now..."
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
done < $dir_cfg/host.cnf

if [ -z $user ]; then
  echo "no base user found, please check the configuration, exit now..."
  exit 1
else
  :
fi

#create file and clean it
file=$dir_tmp/exportBase.sql 
echo "use $user;" > $file

#foreach table in ta_tsynctableinfo
#select * from ta_tsynctableinfo into outfile 'tmp/ta_tsynctableinfo' FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n';
while read line
do
  syncdir=$(echo "$line" | awk -F'\t' '{print $2}')

  if [ "$syncdir" = "0" ]; then
    tablename=$(echo "$line" | awk -F'\t' '{print $1}')
    echo "select * from $tablename into outfile '/tmp/exp_$tablename';" >> $file
  fi
done < $dir_tmp/ta_tsynctableinfo


#login mysql and execute the sql
mysql -uroot -p$passwd -h$ip -P$port << EOF
  source $file;
EOF

if [ "$?" -eq "0" ]; then
  echo "export base data done."
else
  echo "export base data failed, exit now..."
  exit 1
fi


dir_base=$dir_export"/expdata_"$user
mkdir -p $dir_base > /dev/null 2>&1
if [ "$?" -eq "0" ]; then
  :
else
  echo "mkdir $dir_base failed, exit now..."
  exit 1
fi

mv /tmp/exp_* $dir_base


echo "move base data to $dir_base done."

