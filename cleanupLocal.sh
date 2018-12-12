#!/bin/sh
#cleanupLocal.sh

dir_tmp=/tmp/syncdata

echo "clean up tmp files..."

rm -rf /tmp/ta_t*
rm -rf $dir_tmp

echo "clean up tmp files done."
