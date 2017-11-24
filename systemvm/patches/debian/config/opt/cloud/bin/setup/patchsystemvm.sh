#/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

#set -x
logfile="/var/log/patchsystemvm.log"

# To use existing console proxy .zip-based package file
patch_systemvm() {
   local patchfile=$1
   local backupfolder="/tmp/.conf.backup"
   if [ -f /usr/local/cloud/systemvm/conf/cloud.jks ]; then
      rm -fr $backupfolder
      mkdir -p $backupfolder
      cp -r /usr/local/cloud/systemvm/conf/* $backupfolder/
   fi
   rm /usr/local/cloud/systemvm -rf
   mkdir -p /usr/local/cloud/systemvm
   echo "All" | unzip $patchfile -d /usr/local/cloud/systemvm >$logfile 2>&1
   find /usr/local/cloud/systemvm/ -name \*.sh | xargs chmod 555
   if [ -f $backupfolder/cloud.jks ]; then
      cp -r $backupfolder/* /usr/local/cloud/systemvm/conf/
      echo "Restored keystore file and certs using backup" >> $logfile
   fi
   rm -fr $backupfolder
   return 0
}

CMDLINE=/var/cache/cloud/cmdline
PATCH_MOUNT=$1
TYPE=$2

for str in $(cat $CMDLINE)
  do
    KEY=$(echo $str | cut -d= -f1)
    VALUE=$(echo $str | cut -d= -f2)
    case $KEY in
      type)
        TYPE=$VALUE
        ;;
      *)
        ;;
    esac
done

echo "Patching systemvm for cloud service with mount=$PATCH_MOUNT for type=$TYPE" >> $logfile

rm -f /root/.rnd
echo "" > /root/.ssh/known_hosts

if [ "$TYPE" == "consoleproxy" ] || [ "$TYPE" == "secstorage" ]  && [ -f ${PATCH_MOUNT}/systemvm.zip ]
then
  patch_systemvm ${PATCH_MOUNT}/systemvm.zip
  if [ $? -gt 0 ]
  then
    printf "Failed to apply patch systemvm\n" >$logfile
    exit 1
  fi
fi
