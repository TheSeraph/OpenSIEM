#!/bin/bash
umask 077

if ! id |grep -q uid=0; then
    echo "FAILURE: you need to be root"
    exit 1
fi
echo ""
echo "Installing requirements and repos."
echo "This may take a couple minutes."
echo ""
if which dnf >/dev/null 2>&1; then
    dnf install -y epel-release perl audit audispd-plugins >/dev/null 2>&1
elif which yum >/dev/null 2>&1; then
    yum install -y epel-release perl audit audispd-plugins >/dev/null 2>&1
else
    echo "FAILURE: could not find dnf or yum"
    exit 1
fi

echo ""
echo "Getting Treasure Data repo"
echo ""

rpm --import https://packages.treasuredata.com/GPG-KEY-td-agent
cat > /etc/yum.repos.d/td.repo <<EOF
[treasuredata]
name=TreasureData
baseurl=http://packages.treasuredata.com/3/redhat/\$releasever/\$basearch
gpgcheck=1
gpgkey=https://packages.treasuredata.com/GPG-KEY-td-agent
EOF


cat >> /etc/security/limits.conf <<EOF
root soft nofile 65536
root hard nofile 65536
* soft nofile 65536
* hard nofile 65536
EOF

if which dnf >/dev/null 2>&1; then
    dnf install -y td-agent >/dev/null 2>&1
elif which yum >/dev/null 2>&1; then
    yum install -y td-agent >/dev/null 2>&1
else
    echo "FAILURE: could not find dnf or yum"
    exit 1
fi

