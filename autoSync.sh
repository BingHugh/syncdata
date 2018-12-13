#!/bin/sh
#autoSync.sh

#this script is used to make base and trade tables keep synchronized 
#before starting slave-master synchronization.

#remove tmp files and tmp folder
sh cleanupLocal.sh

#export basic configurations from base database
sh exportCfgData.sh
if [ "$?" != 0 ]; then
  echo "exportCfgData failed, exit now..."
  sh cleanupLocal.sh
  exit 1
fi


#export base data to local host
sh exportBaseData.sh
if [ "$?" != 0 ]; then
  echo "exportBaseData failed, exit now..."
  sh cleanupLocal.sh
  exit 1
fi


#export trade data and then move them all to local host
sh exportTradeData.sh
if [ "$?" != 0 ]; then
  echo "exportTradeData failed, exit now..."
  sh cleanupLocal.sh
  exit 1
fi


#dump table struct of base and trade database
sh dumpTableStruct.sh
if [ "$?" != 0 ]; then
  echo "dumpTableStruct failed, exit now..."
  sh cleanupLocal.sh
  exit 1
fi

#import exported data to each database
sh importData.sh
if [ "$?" != 0 ]; then
  echo "importData failed, exit now..."
  sh cleanupLocal.sh
  exit 1
fi

#clean up tmp files
sh cleanupLocal.sh

#all jobs done
echo -e "\ncongratulations, all jobs are done. :-)"
echo "now you can go on to configure master-slave synchronization. good luck!"

