#!/bin/sh
#exportTradeData.sh

dir_cfg=/home/mysql/syncdata
dir_tmp=/tmp/syncdata
dir_export=/home/mysql/expdata
tmpdir=/tmp


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
      user_base=$(echo $line | awk '{print $2}')
      ip_base=$(echo $line | awk '{print $4}')
    else
      :
    fi 
    ;;
  *)
    continue
    ;;
  esac
done < $dir_cfg/host.cnf

if [ -z $user_base ]; then
  echo "no base user found, please check the configuration, exit now..."
  exit 1
else
  :
fi


#create file and clean it
file=$dir_tmp/exportTrade.sql

#export trade in local host
while read line
do
  case $line in
  \#*)
    continue
    ;;
  ins[0-9]*)
    pooltype=$(echo $line | awk '{print $3}')
    if [ "$pooltype" = "1" ]; then
      user=$(echo $line | awk '{print $2}')
      ip=$(echo $line | awk '{print $4}')
      port=$(echo $line | awk '{print $5}')
      passwd_host=$(echo $line | awk '{print $6}')
      passwd_db=$(echo $line | awk '{print $7}')
      
      if [ -z $user -o -z $ip -o -z $port ]; then
        echo "invalid trade configuration, user=$user,ip=$ip,port=$port, exit now..."
        exit 1
      else
        echo "use $user;" > $file
        while read line
          do
            syncdir=$(echo "$line" | awk -F'\t' '{print $2}')
            if [ "$syncdir" = "1" ]; then
              tablename=$(echo "$line" | awk -F'\t' '{print $1}')
              echo "select * from $tablename into outfile '$tmpdir/exp_$tablename';" >> $file
            fi
        done < $dir_tmp/ta_tsynctableinfo
        
        #login mysql and execute the sql         
        chmod +x $dir_cfg/cleanupRemote.exp

        #remove old files in /tmp to make sure data can be exported successfully
        $dir_cfg/cleanupRemote.exp $tmpdir/exp_* $ip $passwd_host
        rm -rf $tmpdir/exp_*

        mysql -uroot -p$passwd_db -h$ip -P$port << EOF
        source $file
EOF
        if [ "$?" = "0" ]; then
          echo "export data of $user in $ip:$port done."
        else
          echo "export data of $user in $ip:$port failed, exit now..."
          exit 1
        fi

        #move exported data to target path
        target_path=$dir_export"/expdata_"$user

        if [ "$ip" = "$ip_base" ]; then
          #this trade is in local host
          mkdir -p $target_path
          if [ "$?" != "0" ]; then
            echo "mkdir $target_path failed, exit now..."
            exit 1
          fi
          mv /tmp/exp_* $target_path
        else
          #this trade is in remote host
          chmod +x $dir_cfg/moveRemoteExportedData.exp
          $dir_cfg/moveRemoteExportedData.exp /tmp/exp_* $target_path $ip $passwd_host     
          if [ "$?" != "0" ]; then
            echo "move remote exported data failed for $user in $ip, exit now..."
            exit 1
          fi
          $dir_cfg/cleanupRemote.exp $tmpdir/exp_* $ip $passwd_host
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



