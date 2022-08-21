#!/bin/bash
#os 1 인스턴스 이름 2 key 이름 3 cpu 4 ram 5 disk 6
ssh-keygen -q -f ~/.ssh/$3.pem -N ""

#생성한 public key move
cat /root/.ssh/$3.pem.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/$3.pem

#ip addr 받아오기 while문
while [ 1 ]
do
	randomip=$((RANDOM%252+3))
	check_result=$(mysql dchj -u root -ptest123 -h 172.16.1.103 -e "select * from vm where vmip='$randomip'" | grep $randomip | gawk '{print $1}')
	if [ -z $check_result ]
		then 
			break
	fi
done

ips=$(echo "211.183.3.${randomip}")
ips_eth1=$(echo "172.16.123.${randomip}")

sed -i "6s/.*/IPADDR=${ips}/g" /root/ifcfg-eth0
sed -i "5s/.*/IPADDR=${ips_eth1}/g" /root/ifcfg-eth1

#볼륨 수정
virt-builder $1 \
--size $6G \
--format qcow2 \
-o /remote/$2.qcow2 \
--root-password password:test123 \
--upload /root/ifcfg-eth0:/etc/sysconfig/network-scripts/ifcfg-eth0 \
--upload /root/ifcfg-eth1:/etc/sysconfig/network-scripts/ifcfg-eth1 \
--install httpd,net-tools,git \
--mkdir /root/.ssh \
--upload /root/.ssh/authorized_keys:/root/.ssh/authorized_keys \
--firstboot-command 'ifdown eth0 ; ifup eth0 ; ifdown eth1 ; ifup eth1' \
--firstboot-command 'mkdir /var/www/html/' \
--firstboot-command 'yum update -y nss curl libcurl' \
--firstboot-command "git clone '${7}' /var/www/html/" \
--firstboot-command "systemctl stop firewalld" \
--firstboot-command "systemctl disable firewalld" \
--firstboot-command "systemctl start httpd" \
--firstboot-command "systemctl enable httpd" \
--selinux-relabel


#인스턴스 배포
virt-install \
--name $2 \
--vcpus $4 \
--ram $5 \
--network bridge:vswitch01,model=virtio,virtualport_type=openvswitch \
--network bridge:vswitch02,model=virtio,virtualport_type=openvswitch \
--disk /remote/$2.qcow2 \
--import \
--graphics none \
--noautoconsole


#DB insert
HOSTIP=$(hostname -i | gawk '{print $2}')

# Check DB
mysql -h 172.16.1.103 -u root -ptest123 -e 'SHOW DATABASES' > databases.txt

# STORAGE DB 정상 접속인 경우
if [ $? -eq 0 ]
then
        checkhost=$(mysql dchj -u root -ptest123 -h 172.16.1.103 -e "select * from host where hostname='$HOSTNAME'" | grep $HOSTNAME | gawk '{print $1}')

        if [ -z $checkhost ]
        then
                mysql dchj -u root -ptest123 -h 172.16.1.103 -e "insert into host values ('$HOSTNAME', '$HOSTIP')"
        fi

        mysql dchj -u root -ptest123 -h 172.16.1.103 -e "insert into vm values ('$2', '$HOSTNAME', '$ips', $5, '$ips_eth1')"
# DB -> DB
else
# CEHCK Replication
        ssh DB /masterha/scripts/check_replication.sh > /dev/null

        checkhost=$(mysql dchj -u root -ptest123 -h 172.16.1.104 -e "select * from host where hostname='$HOSTNAME'" | grep $HOSTNAME | gawk '{print $1}')

        if [ -z $checkhost ]
        then
                mysql dchj -u root -ptest123 -h 172.16.1.104 -e "insert into host values ('$HOSTNAME', '$HOSTIP')"
        fi

        mysql dchj -u root -ptest123 -h 172.16.1.104 -e "insert into vm values ('$2', '$HOSTNAME', '$ips', $5, '$ips_eth1')"
fi


#출력용 반환
echo "$2 $4 $5 $6 $ips $ips_eth1"
