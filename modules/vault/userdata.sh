#!/bin/bash

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Installing Deps"
sudo apt-get -y update
sudo apt-get -y install python-pip python-dev openssl python3-pip jq
sudo pip install pip --upgrade
sudo pip install ansible==2.3 awscli==1.11.151

# Here we install pip3 and upgrade ssh-import-id because of a bug in the
# 5.5 version of ssh-import-id. If you can install a newer version of
# ssh-import-id from apt-get do that instead.
sudo pip3 install pip --upgrade
sudo pip3 install ssh-import-id --upgrade

echo "importing keys"
sudo -Hu ubuntu ssh-import-id gh:voidfiles

curl -O https://releases.hashicorp.com/terraform/${vault_version}/valut_${vault_version}_linux_amd64.zip
curl -O https://releases.hashicorp.com/terraform/${vault_version}/valut_${vault_version}_SHA256SUMS

grep -q `shasum -a 256 terraform_${vault_version}_linux_amd64.zip` terraform_${vault_version}_SHA256SUMS

mkdir -p /var/vault/

sudo mount -t nfs \
  -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport \
  ${file_system_id}.efs.${region}.amazonaws.com:/ \
  /var/vault/

cat > /etc/init/ecs-awslogs.conf <<- 'EOF'
storage "file" {
  path = "/var/vault/"
}
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}
seal "awskms" {
  region     = "${region}"
  kms_key_id = "${kms_key_id}"
}
EOF

cat > /etc/systemd/system/vault.service <<- 'EOF'
[Unit]
Description=vault server
Requires=network-online.target
After=network-online.target consul.service

[Service]
EnvironmentFile=-/etc/sysconfig/vault
Restart=on-failure
ExecStart=/usr/local/sbin/vault server $OPTIONS -config=/etc/vault.d
ExecStartPost=/bin/bash -c "for key in $KEYS; do /usr/local/sbin/vault unseal $CERT $key; done"

[Install]
WantedBy=multi-user.target
EOF
