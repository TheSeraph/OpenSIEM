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
    dnf install -y epel-release java-1.8.0-openjdk.x86_64 nano >/dev/null 2>&1
elif which yum >/dev/null 2>&1; then
    yum install -y epel-release java-1.8.0-openjdk.x86_64 nano >/dev/null 2>&1
else
    echo "FAILURE: could not find dnf or yum"
    exit 1
fi

echo ""
echo "Getting Elastic.co 6.x repo"
rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
cat > /etc/yum.repos.d/elasticsearch.repo <<EOF
[elasticsearch-6.x]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

echo ""
echo "Getting Treasure Data repo"
rpm --import https://packages.treasuredata.com/GPG-KEY-td-agent
cat > /etc/yum.repos.d/td.repo <<EOF
[treasuredata]
name=TreasureData
baseurl=http://packages.treasuredata.com/3/redhat/\$releasever/\$basearch
gpgcheck=1
gpgkey=https://packages.treasuredata.com/GPG-KEY-td-agent
EOF


echo ""
echo "Installing Treasure Data FluentD, Elasticsearch 6.x, Kibana 6.x and Nginx"

cat >> /etc/security/limits.conf <<EOF
root soft nofile 65536
root hard nofile 65536
* soft nofile 65536
* hard nofile 65536
EOF

if which dnf >/dev/null 2>&1; then
    dnf install -y td-agent elasticsearch kibana nginx setools-console >/dev/null 2>&1
elif which yum >/dev/null 2>&1; then
    yum install -y td-agent elasticsearch kibana nginx setools-console >/dev/null 2>&1
else
    echo "FAILURE: could not find dnf or yum"
    exit 1
fi
echo ""
echo "Enabling Services"
systemctl daemon-reload >/dev/null 2>&1
systemctl enable td-agent elasticsearch kibana nginx >/dev/null 2>&1

echo ""
echo "Creating temporary self-signed certificates for Nginx"
echo "This may take awhile"
# openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096
openssl req -x509 -days 365 -nodes -newkey rsa:2048 -keyout /etc/ssl/certs/opensiem-pkcs5.key -out  /etc/ssl/certs/opensiem-pkcs5.crt -subj "/C=GB/O=Arkferos Ltd/CN=kibana.arkferos.com"

echo ""
echo "Configuring Services"
echo "Elasticsearch..."
sed -i -e 's/#cluster.name: my-application/cluster.name: OpenSIEM/g' /etc/elasticsearch/elasticsearch.yml
echo "Creating Nginx configuration file..."
cp opensiem.conf /etc/nginx/conf.d/opensiem.conf
echo "Creating FluentD Config file..."
cp td-agent-svr.conf /etc/td-agent/td-agent.conf

# echo ""
# echo "Turning it on"
# systemctl start elasticsearch 
# systemctl start kibana 
# systemctl start nginx 
# systemctl start td-agent

# systemctl status td-agent elasticsearch kibana nginx >/dev/null 2>&1

# echo "Turning off selinux to configure nginx"
# setenforce 0 
# echo ""
# systemctl start td-agent elasticsearch kibana nginx >/dev/null 2>&1
# echo ""
# echo "Creating selinux policies"
# cat /var/log/audit/audit.log | grep nginx | grep denied | audit2allow -M OpenSIEM
# sudo semodule -i OpenSIEM.pp
# setenforce 1
# echo ""

# systemctl restart td-agent elasticsearch kibana nginx >/dev/null 2>&1



