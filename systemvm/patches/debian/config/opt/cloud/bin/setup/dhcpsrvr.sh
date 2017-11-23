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


setup_dhcpsrvr() {
  log_it "Setting up dhcp server system vm"
  setup_common eth0 eth1
  setup_dnsmasq
  setup_apache2 $ETH0_IP

  sed -i  /gateway/d /etc/hosts
  [ $ETH0_IP ] && echo "$ETH0_IP $NAME" >> /etc/hosts
  [ $ETH0_IP6 ] && echo "$ETH0_IP6 $NAME" >> /etc/hosts

  systemctl enable dnsmasq cloud-passwd-srvr
  systemctl restart dnsmasq cloud-passwd-srvr
  enable_irqbalance 0
  enable_fwding 0
  systemctl disable nfs-common

  cp /etc/iptables/iptables-router /etc/iptables/rules.v4
  cp /etc/iptables/iptables-router /etc/iptables/rules

  #Only allow DNS service for current network
  sed -i "s/-A INPUT -i eth0 -p udp -m udp --dport 53 -j ACCEPT/-A INPUT -i eth0 -p udp -m udp --dport 53 -s $DHCP_RANGE\/$CIDR_SIZE -j ACCEPT/g" /etc/iptables/rules.v4
  sed -i "s/-A INPUT -i eth0 -p udp -m udp --dport 53 -j ACCEPT/-A INPUT -i eth0 -p udp -m udp --dport 53 -s $DHCP_RANGE\/$CIDR_SIZE -j ACCEPT/g" /etc/iptables/rules
  sed -i "s/-A INPUT -i eth0 -p tcp -m tcp --dport 53 -j ACCEPT/-A INPUT -i eth0 -p tcp -m tcp --dport 53 -s $DHCP_RANGE\/$CIDR_SIZE -j ACCEPT/g" /etc/iptables/rules.v4
  sed -i "s/-A INPUT -i eth0 -p tcp -m tcp --dport 53 -j ACCEPT/-A INPUT -i eth0 -p tcp -m tcp --dport 53 -s $DHCP_RANGE\/$CIDR_SIZE -j ACCEPT/g" /etc/iptables/rules

  if [ "$SSHONGUEST" == "true" ]
  then
    setup_sshd $ETH0_IP "eth0"
  else
    setup_sshd $ETH1_IP "eth1"
  fi

  if [ -x /opt/cloud/bin/update_config.py ]
  then
      /opt/cloud/bin/update_config.py cmd_line.json
  fi
}

setup_dhcpsrvr
