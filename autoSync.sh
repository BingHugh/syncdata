#!/bin/sh
#autoSync.sh

#this script is used to make base and trade tables keep synchronized 
#before starting slave-master synchronization.

#remove tmp files and tmp folder
sh cleanupLocal.sh

#export basic configurations from base database
sh exportCfgData.sh

#export base data to local host
sh exportBaseData.sh

#export trade data and then move them all to local host
sh exportTradeData.sh

#dump table struct of base and trade database
sh dumpTableStruct.sh

#import exported data to each database
sh importData.sh

#clean up tmp files
sh cleanupLocal.sh

#all jobs done
echo -e "\ncongratulations, all jobs are done. :-)"
echo "now you can go on to configure master-slave synchronization. good luck!"

