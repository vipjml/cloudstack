#!/bin/bash
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

. /opt/cloud/bin/setup/common.sh

consoleproxy_svcs() {
   systemctl disable --now apache2
   systemctl disable --now cloud-passwd-srvr
   systemctl disable --now conntrackd
   systemctl disable --now dnsmasq
   systemctl disable --now haproxy
   systemctl disable --now keepalived
   systemctl disable --now nfs-common
   systemctl disable --now portmap
   systemctl enable postinit
   systemctl enable ssh
   echo "cloud postinit ssh" > /var/cache/cloud/enabled_svcs
   echo "cloud-passwd-srvr haproxy dnsmasq apache2 nfs-common portmap" > /var/cache/cloud/disabled_svcs
   mkdir -p /var/log/cloud
}

setup_console_proxy() {
  log_it "Setting up console proxy system vm"
  setup_common eth0 eth1 eth2
  setup_system_rfc1918_internal
  public_ip=`getPublicIp`
  sed -i  /gateway/d /etc/hosts
  echo "$public_ip $NAME" >> /etc/hosts
  cp /etc/iptables/iptables-consoleproxy /etc/iptables/rules.v4
  cp /etc/iptables/iptables-consoleproxy /etc/iptables/rules
  local hyp=$HYPERVISOR
  if [ "$hyp" == "vmware" ] || [ "$hyp" == "hyperv" ]; then
    setup_sshd $ETH1_IP "eth1"
  else
    setup_sshd $ETH0_IP "eth0"
  fi

  systemctl enable --now cloud
  disable_rpfilter
  enable_fwding 0
  enable_irqbalance 0
  rm -f /etc/logrotate.d/cloud
}

consoleproxy_svcs
if [ $? -gt 0 ]
then
  log_it "Failed to execute consoleproxy_svcs"
  exit 1
fi
setup_console_proxy
