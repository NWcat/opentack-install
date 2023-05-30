#!/bin/bash

read -p "输入compute节点的管理ip:" compute_ip
read -p "输入controller节点的主机名:" controller_hosts
read -p "输入CINDER_DBPASS:" CINDER_DBPASS
read -p "输入cinder_pass:" cinder_pass
read -p "输入RABBIT_PASS:" RABBIT_PASS

yum -y install lvm2 device-mapper-persistent-data
systemctl enable lvm2-lvmetad.service
systemctl start lvm2-lvmetad.service

pvcreate /dev/sdb
vgcreate cinder-volumes /dev/sdb
sed -i "/^devices/a \       \ filter = [ "a/sdb/", "r/.*/"]" /etc/lvm/lvm.conf

yum -y install openstack-cinder targetcli python-keystone

cat > /etc/cinder/cinder.conf << EOF
[DEFAULT]
transport_url = rabbit://openstack:$RABBIT_PASS@$controller_hosts
auth_strategy = keystone
my_ip = $compute_ip
enabled_backends = lvm
glance_api_servers = http://$controller_hosts:9292
[backend]
[backend_defaults]
[barbican]
[brcd_fabric_example]
[cisco_fabric_example]
[coordination]
[cors]
[database]
connection = mysql+pymysql://cinder:$CINDER_DBPASS@$controller_hosts/cinder
[fc-zone-manager]
[healthcheck]
[key_manager]
[keystone_authtoken]
www_authenticate_uri = http://$controller_hosts:5000
auth_url = http://$controller_hosts:5000
memcached_servers = $controller_hosts:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = cinder
password = $cinder_pass
[nova]
[oslo_concurrency]
lock_path = /var/lib/cinder/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[oslo_versionedobjects]
[privsep]
[profiler]
[sample_castellan_source]
[sample_remote_file_source]
[service_user]
[ssl]
[vault]
[lvm]
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group = cinder-volumes
target_protocol = iscsi
target_helper = lioadm
EOF

systemctl enable openstack-cinder-volume.service target.service
systemctl start openstack-cinder-volume.service target.service
