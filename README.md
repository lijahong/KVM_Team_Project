# kvm_project
3 node kvm team project

### 0. 프로젝트 목표

- #### 3 Node - KVM / Control / DB 를 이용하여 Local Instance 생성 환경 구축하기

### 1. 프로젝트 개요

![](https://velog.velcdn.com/images/lijahong/post/705e685f-9e7f-4566-a0f4-be2d7a9a0ab5/image.png)
> - Bastion Host 란 침입 차단 소프트웨어가 설치되어 내부와 외부 네트워크 사이에서 일종의 게이트 역할을 수행하는 Host 이다. 외부에서 Bastion Host 에 ssh 로 접속 한다
> - Bastion Host 는 Bridge 에 연결

#### Team Project 설계도
![](https://velog.velcdn.com/images/lijahong/post/8af1eb7c-b7f8-46c8-b558-ab384228b640/image.png)

#### 사용 기술
![](https://velog.velcdn.com/images/lijahong/post/d99ad46a-c360-4934-b724-18bfbf6e28f4/image.png)
- KVM & MariaDB & ZABBIX 를 사용한다

#### Node 사양
> - control : ram 2gb
> - kvm : ram 4gb , Disk 20gb
> - storage : ram 2gb , Disk 120gb
> - db : ram 2gb

#### 필자가 해야 할 일
0. control node & kvm node 환경 구성
1. kvm 자원 비교하기
2. control node 의 dialog 구현
3. kvm 에 가상 머신 생성 스크립트 구현
4. kvm 에 가상 머신 생성시 실행할 명령어 스크립트 구현

### 2. 스크립트 구조

![](https://velog.velcdn.com/images/lijahong/post/08cfd391-0e7b-43a0-92d2-5d3255196d56/image.png)

- 스크립트는 다음과 같이 두 가지 Node 에 구성된다

#### Control Node
> - 메뉴 dialog 파일을 통해 사용자에게 기능을 제공한다
> - Instance 조회 & Network list 조회 & 삭제 & 생성 을 제공한다
> - 생성 기능시
> > - Resource.sh 에서 각 KVM Node 의 cpu & ram 사용량을 7:3 으로 비교하여 여유 KVM Node 를 판단하고, 매개변수로 makeinstance.sh 에 넘겨준다
> > - 사용자로부터 입력받은 Instance 사양을 매개변수로 모아 ssh 연결을 통해 KVM NODE 의 Makevm.sh 에 매개변수로 넘겨주어 실행시킨다
> > - web Instance 생성시 사용자로부터 git 주소를 받아와 매개 변수로 KVM Node 에 넘겨준다

#### KVM Node
> - KVM Node 의 makevm.sh 는 인스턴스 생성 부분과 DB Node 에 Data 전달 부분으로 나뉘어진다
> - 매개변수로 받은 Instance 사양을 통해 Instance 를 생성한다. 이때 Instance 의 외부 연결용 Network eth0 와 Overlay 용 Network eth1 은 KVM Node 에서 ifcfg-eth0, ifcfg-eth1 파일을 만들어 Instance 에 붙여넣기를 통해 설정한다
> - virt-builder 를 사용하면, domifaddr 에서 Instance 의 Ip 를 받아오지 못하는 문제점을 해결하기 위해 Ip 는 랜덤 함수를 통해 Ip 주소 끝자리를 랜덤으로 받아와 정적 할당해준다. 이 Ip 를 ifcfg-eth 파일들에 넣어 Instance 에 설정해준다
> - 매개 변수로 전달 받은 git 주소를 clone 하여 해당 git repository 에서 출력할 web 페이지를 불러온다
> - 사용자가 입력한 Instance 이름을 이용해 ssh key 를 생성하여 KVM Node 에 Public key 를, Instance 에 Private Key 를 저장해준다. 이를 통해 생성한 Instance 에 ssh 연결이 가능해진다
> - Virt-Builder 를 사용하여 Volume 에 대한 수정 작업을 진행한다. Network 설정, 패키지 설치, ssh 설정, git clone 을 통한 web 페이지 저장, 패키지 실행, 방화벽 설정 을 진행한다
> - 수정된 Volume 을 이용하여 Instance 생성에는 Virt-Install 을 사용한다

#### Instance 생성시 전달하는 매개변수
> - 작업할 KVM Node 명
> - 사용 이미지
> - 인스턴스 이름
> - 인스턴스 용도
> - git repository 주소
> - vcpu
> - ram
> - disk 용량

### 3. 기간 별 진행사항

![](https://velog.velcdn.com/images/lijahong/post/7ae53fab-d854-41c7-acfb-87c3ef81181b/image.png)

### 4. 실행 화면

#### dialog 실행
![](https://velog.velcdn.com/images/lijahong/post/2b67f49a-e7b8-45d1-a23e-cef28e2edfc7/image.png)
- dialog 메인 화면이다. 해당 화면에서 Instance 리스트, Network 리스트, Instance 생성과 삭제, dialog 종료를 선택할 수 있다

#### Instance 생성
![](https://velog.velcdn.com/images/lijahong/post/76a73e71-6c8f-40cb-a284-7b7109ec6f79/image.png)
- 실행시 먼저, KVM 자원을 비교하여 물리 자원에 여유가 있는 KVM Node 를 자동으로 선택해주고, 해당 Node 의 물리 자원량을 출력해준다
![](https://velog.velcdn.com/images/lijahong/post/558ae483-fcc5-4124-9bd1-786a80316f08/image.png)
- 다음으로 Instance 용도 선택이다. web 과 customize 를 선택 가능하다
![](https://velog.velcdn.com/images/lijahong/post/1df44eec-fbb4-40d5-9ad2-ab2ade2cd299/image.png)
- 출력할 web 페이지를 불러올 git 저장소를 입력받는다. 입력시 해당 git repository 를 clone 하여 해당 저장소 안에 있는 index.html 을 불러온다
![](https://velog.velcdn.com/images/lijahong/post/6cc61150-5e7f-4767-b2ef-ee4a8b1e1bc0/image.png)
- web Instance 를 생성한 후 해당 주소에 접속시, web 페이지가 잘 출력된다

#### Instance 삭제
![](https://velog.velcdn.com/images/lijahong/post/de1b6edc-0b22-428b-8bcc-07fafecd7d94/image.png)
- 삭제 기능을 선택하면, 각 KVM 별로 Instance 리스트가 출력된다
![](https://velog.velcdn.com/images/lijahong/post/32344e18-45fa-4275-899f-b3d520720cb8/image.png)
- Instance 선택시 삭제 여부가 출력된다. Yes 를 선택시 선택한 Instance 가 삭제된다
> - 이때, DB 에 저장된 해당 Instance 에 대한 Data 도 삭제된다

### 5. DataBase 저장

![](https://velog.velcdn.com/images/lijahong/post/cc33d2d1-ffc2-4cdf-86fc-95946d247522/image.png)
- host Table 에는 KVM Node 의 DATA 가 저장되어있다
![](https://velog.velcdn.com/images/lijahong/post/a9e8e8c7-7e73-45dd-8083-dfd1e4b1f0a0/image.png)
- vm Table 에는 Instance 의 DATA 가 저장되어있다

### 6. Storage Node

![](https://velog.velcdn.com/images/lijahong/post/36bac105-aba5-4313-97f4-4980751525e1/image.png)
- Storage 의 /cloud Directory 와 KVM 1, KVM2 각각의 /remote Directory 와 NFS 방식으로 Mount 되었다
![](https://velog.velcdn.com/images/lijahong/post/e27de3c5-d3ca-4283-9bd8-ac5aa92c6712/image.png)
- Storage Node 와 DB Node 에는 각각 MariaDB 가 설치되어있으며, Stoargae Node 의 DB 를 Master Node , DB Node 를 백업용 Slave Node 로 두어 Fault Tolerant 를 구현하였다
> - Fault Tolerant 란? 하드웨어나 소프트웨어의 결함, 오동작, 오류 등이 발생하더라도 규정된 기능을 지속적으로 수행할 수 있게 하는 것

![](https://velog.velcdn.com/images/lijahong/post/22f1445a-99d8-47eb-bc8d-93c8f529969c/image.png)

### 7. Zabbix Monitoring
![](https://velog.velcdn.com/images/lijahong/post/57b85a41-0f96-4a37-9c02-31bcadd1634d/image.png)
- Zabbix 구현에는 https://jjeongil.tistory.com/1468 를 참조하였다

- Zabbix 란? 다수의 네트워크 매개 변수 및 서버의 상태와 무결성을 모니터링 하는 소프트웨어

### 8. 환경 구성

#### control node

- 먼저, control node 에 vim , kvm, dialog, net-tools 를 설치해주자
```shell
yum –y install vim && yum -y install libvirt qemu-kvm virt-install virt-manager openssh-askpass libguestfs-tools 
&& yum –y install dialog && yum –y install net-tools
```

- 다음, ssh 연결을 위해 방화벽, selinux, networkmanager 를 꺼주자
```shell
systemctl stop firewalld ; systemctl disable firewalld
&& systemctl stop NetworkManager ; systemctl disable NetworkManager
&& sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config && setenforce 0
```
- hosts 에 Domain 이름을 다음과 같이 설정하자
![](https://velog.velcdn.com/images/lijahong/post/d3c840ac-6fc2-4f07-9ae5-4be195def853/image.png)

- ssh key 를 두 개 생성해서, 외부에서 control node 에 접속할 수 있게 하나, control node 에서 다른 Server 에 접속할 수 있게 하나 생성하였다
![](https://velog.velcdn.com/images/lijahong/post/43927dc0-e753-4ed4-8bc9-11ffa94c0ab5/image.png)

- sshd_config & ssh_config 설정
> ![](https://velog.velcdn.com/images/lijahong/post/149e47c9-2ed1-4698-8ccd-a802093e731d/image.png)
> - ssh_config 는 위와 같이 설정한다. 이는 control node 에만 설정하자
> ![](https://velog.velcdn.com/images/lijahong/post/cd30b1d0-cd8e-48b2-8076-77087071d6c7/image.png)
> - sshd_config 는 5 개의 node 모두 위와 같이 Public Key 로만 인증하게 설정하자

#### kvm node

- kvm 에서는 ovs 사용을 위해 kernel update 를 해주자
```shell
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
yum --enablerepo=elrepo-kernel install kernel-ml
```

![](https://velog.velcdn.com/images/lijahong/post/d924adc8-a251-4682-8133-b6b227acf4c5/image.png)
- kernel 5 version 을 부팅시 default 로 설정해주자
![](https://velog.velcdn.com/images/lijahong/post/9854bf64-000e-436b-b119-593d76ce3451/image.png)
- 재부팅시 kernel 이 잘 바뀐 것을 확인할 수 있다

### 9. Dialog 스크립트 - makeinstance.sh

> makeinstance.sh 는 Control node 에서 메뉴를 담당하는 dialog 를 구현한 스크립트이다

``` shell

#!/bin/bash

# 변수 선언
kvminfo=$(mktemp -t test.XXX)   # kvm 정보 받기
temp=$(mktemp -t test.XXX)      # 함수내에서 결과를 파일로 저장하기위해
ans=$(mktemp -t test.XXX)       # 메뉴에서 선택한 번호담기위한 변수
vmname=$(mktemp -t test.XXX)    # 가상머신 이름 담기위한 변수
flavor=$(mktemp -t test.XXX)    # CPU/RAM 세트인 flavor 정보 담기위한 변수
instancetype=$(mktemp -t test.XXX) # web or default instance type
clonename=$(mktemp -t test.XXX)   # clone url 이름
image=$(mktemp -t test.XXX)     # 이미지 이름 저장
dellist=$(mktemp -t del.XXX)    # 가상 KVM1 머신 리스트를 checkList에 전달하기 위해 변환한 Data 를 담은 변수
dellist2=$(mktemp -t del.XXX)   # 가상 KVM2 머신 리스트를 checkList에 전달하기 위해 변환한 Data 를 담은 변수
delinstance=$(mktemp -t del.XXX) #KVM1 삭제할 인스턴스 번호를 담은 변수
delinstance2=$(mktemp -t del.XXX) #KVM2 삭제할 인스턴스 번호를 담은 변수
disktemp=$(mktemp -t test.XXX)  #입력받은 disk 양
vmresult=$(mktemp -t test.XXX)  #가상 머신 생성 결과

# 함수 선언
# 가상머신 리스트 출력 함수
vmlist(){
        echo "kvm1 가상머신 리스트"> $temp
        ssh KVM1 virsh list --all >> $temp
        echo "kvm2 가상머신 list" >> $temp
        ssh KVM2 virsh list --all >> $temp
        dialog --textbox $temp 20 50
}

# 가상 네트워크 리스트 출력 함수
vmnetlist(){
        kvm1 가상 네트워크  리스트 > $temp
        ssh KVM1 virsh net-list --all >> $temp
        kvm2 가상 네트워크  리스트 >> $temp
        ssh KVM2 virsh net-list --all >> $temp

        dialog --textbox $temp 20 50
}
# 가상머신 삭제
vmdel(){

        : ${DIALOG=dialog}
        : ${DIALOG_OK=0}
        : ${DIALOG_CANCEL=1}
        : ${DIALOG_ESC=255}

        echo " " > $dellist
        echo " " > $dellist2

        #checkList에 사용할 리스트 제작
        for data in $(ssh KVM1 virsh list --all |grep -v Name |gawk '{print $2}' | sed '/^$/d'); 
        do echo "${data}" "KVM1" OFF >> $dellist; 
        done
        
        for data in $(ssh KVM2 virsh list --all |grep -v Name |gawk '{print $2}' | sed '/^$/d'); 
        do echo ${data} "KVM2" OFF >> $dellist2; 
        done

        dialoglist=$(cat $dellist)
        dialoglist2=$(cat $dellist2)

        # Print delete list in checklist
        $DIALOG --backtitle "Delete KVM1" --title "CHECK IN KVM1" --checklist "kvm1 checklist" 20 61 5 $dialoglist 2> $delinstance
        $DIALOG --backtitle "Delete KVM2" --title "CHECK IN KVM2" --checklist "kvm2 checklist" 20 61 5 $dialoglist2 2> $delinstance2
       
        retval=$?
        vmdelin=$(cat $delinstance)
        vmdelin2=$(cat $delinstance2)

        case $retval in
        $DIALOG_OK)
                dialog --title "삭제 여부" --yesno " ${vmdelin} ${vmdelin2} 인스턴스를 삭제하시겠습니까?" 10 40
                if [ $? -eq 0 ]
                then
                        for data in $vmdelin; 
                        do ssh KVM1 virsh destroy $data > /dev/null\
                        && ssh KVM1 virsh undefine $data --remove-all-storage> /dev/null\
                        && mysql dchj -u root -ptest123 -h STORAGE -e "delete from vm where vmname='$data'"\
                        && ssh KVM1 rm -rf /root/.ssh/${data}.pem\
                        && ssh KVM1 rm -rf /root/.ssh/${data}.pem.pub; 
                        done
                        
                        for data in $vmdelin2; 
                        do ssh KVM2 virsh destroy $data > /dev/null\
                        && ssh KVM2 virsh undefine $data --remove-all-storage> /dev/null\
                        && mysql dchj -u root -ptest123 -h STORAGE -e "delete from vm where vmname='$data'"\
                        && ssh KVM2 rm -rf /root/.ssh/${data}.pem\
                        && ssh KVM2 rm -rf /root/.ssh/${data}.pem.pub
                        done
                        
                        if [ $? -eq 0 ]
                        then
                        dialog --msgbox "success" 10 20
                        fi
                fi
        ;;
        $DIALOG_CANCEL)
                return;;
        $DIALOG_ESC)
                return;;
        *)
                return;;
        esac

}
# 가상머신 생성 함수
vmcreation(){

        echo $(/root/makeinstance/getresource.sh) > $kvminfo
        kvmname=$(gawk '{print $1}' $kvminfo)
        kvmall=$( cat $kvminfo )
        dialog --msgbox " $kvmname 에 설치합니다\n $kvmall  " 10 50
        if [ $? -eq 0 ]
        then

        #이미지 선택
        dialog --title "이미지 선택" --radiolist " 베이스 이미지 선택" 15 50 5 "CentOS7" "센토스 7 베이스 이미지" ON   2>$image

        vmimage=$(cat $image)
        case $vmimage in
        CentOS7)
                os=centos-7.0 ;;
        *)
                dialog --msgbox "잘못된 선택입니다" 10 40 ;;
        esac

        #os 선택이 정상 처리라면 인스턴스 이름 입력하기로 이동
        if [ $? -eq 0 ]
        then
                dialog --title "인스턴스 이름" --inputbox "인스턴스의 이름을 입력하세요 : " 10 50 2>$vmname

                #check instance type
                dialog --title "인스턴스 용도" --radiolist "사용할 인스턴스 용도를 선택하세요" 15 50 5 "web"  "install httpd" ON "customize" "default" OFF 2> $instancetype
                instancetypes=$(cat $instancetype)
                instancekey=$(cat $vmname) #keyname == vmname 
                instancename=$(cat $vmname)
                if [ $? -eq 0 ]
                then

                # delete input keyname, keyname == instancename

                        if [ $instancetypes = "web" ]
                        then
                                dialog --title "" --inputbox " clone 받을 깃허브 주소를 입력하세요 : " 10 50 2>$clonename
                                cloneUrl=$( cat $clonename )
                        fi
                #종료 코드가 0 인 경우 다음 실행 - flavor
                        if [ $? -eq 0 ]
                        then
                                dialog --title "스펙 선택" --radiolist "필요한 자원을 선택하세요" 15 50 5 "m1.small"  "가상 cpu 1개, 메모리 1GM" ON "m1.medium" "가상 cpu 2개, 메모리 2GB" OFF "m1.large" "가상 cpu 4개, 메모리 8GB " OFF 2> $flavor

                        #flavor 에 따라 변수에 자원 개수 입력
                        spec=$(cat $flavor)
                        case $spec in
                        m1.small)
                                vcpus="1"
                                ram="1024"
                                dialog --msgbox "CPU:${vcpus}core(s) RAM:${ram}MB" 10 50  ;;
                        m1.medium)
                                vcpus="1"
                                ram="2048"
                                dialog --msgbox "CPU:${vcpus}core(s) RAM:${ram}MB" 10 50  ;;
                        m1.large)
                                vcpus="2"
                                ram="8192"
                                dialog --msgbox "CPU:${vcpus}core(s) RAM:${ram}MB" 10 50  ;;
                        esac

                        if [ $? -eq 0 ]
                        then
                                dialog --title " Disk 용량 지정" --inputbox " Disk 용량을 GB 단위로 입력해주세요 : " 10 50 2>$disktemp
                                disks=$( cat $disktemp )

                                #설치 진행
                                if [ $? -eq 0 ]
                                then
                                        case $instancetypes in
                                        web)
                                                echo $os $instancename $instancekey $vcpus $ram $disks $cloneUrl
                                                ssh $kvmname /root/vmtool/makevm.sh $os $instancename $instancekey $vcpus $ram $disks $cloneUrl>$vmresult
                                                resultlist=$(cat $vmresult) ;;
                                        customize)
                                                echo $os $instancename $instancekey $vcpus $ram $disks
                                                ssh $kvmname /root/vmtool/makevm.sh $os $instancename $instancekey $vcpus $ram $disks>$vmresult
                                                resultlist=$(cat $vmresult) ;;
                                        *)
                                                echo "none";;
                                        esac


                                        dialog --msgbox  "설치중입니다" 10 50
                                fi
                                dialog --msgbox " 설치가 완료되었습니다" 10 50
                        fi
                     fi
                fi
        fi
        fi
}

# 메인코드
while [ 1 ]
do
        # 메인메뉴 출력하기
        dialog --menu "KVM 관리 시스템" 20 40 8 1 "가상머신 리스트" 2 "가상 네트워크 리스트" 3 "가상머신 생성" 4 "가상머신 삭제" 0 "종료" 2> $ans

        # 종료코드 확인하여 cancel 이면 프로그램 종료
        if [ $? -eq 1 ]
        then
                break
        fi

        selection=$(cat $ans)
        case $selection in
        1)
                vmlist ;;
        2)
                vmnetlist ;;
        3)
                vmcreation ;;
        4)
                vmdel ;;
        0)
                break ;;
        *)
                dialog --msgbox "잘못된 번호 선택됨" 10 40
        esac
done

# 종료전 임시파일 삭제하기
rm -rf $temp 2> /dev/null
rm -rf $ans 2> /dev/null
rm -rf $keyname 2> /dev/null
rm -rf $vmnet 2> /dev/null
rm -rf $flavor 2> /dev/null
rm -rf $dellist 2> /dev/null
rm -rf $delinstance 2> /dev/null
rm -rf $image 2> /dev/null
rm -rf $kvminfo 2> /dev/null
rm -rf $disktemp 2> /dev/null
rm -rf $vmresult 2> /dev/null

```

- 위의 스크립트를 통해 dialog 를 구현하였다

- dialog 에서 인스턴스 생성시 각 단계별 정상 종료 코드를 확인하여 다음 단계로 넘어간다

- 인스턴스 생성시 resource.sh 가 실행되어 각 KVM Node 의 물리 자원 CPU 와 RAM 을 7:3 비율로 비교하여 물리 자원에 여유가 있는 Node 를 판단해서 해당 KVM Node 이름과 물리 자원량을 매개변수로 넘겨준다

- 사용자의 입력을 모두 받으면 이를 ssh 연결을 통해 kvm 의 makevm.sh 에 매개변수로 넘겨준다

- 인스턴스 생성시 web 용도와 customize 용도를 선택 가능하며, web 용도를 선택시 git 주소를 입력받는다. 해당 주소는 매개 변수로 makevm.sh 에 넘겨준다

### 10. Instance 생성 스크립트 - makevm.sh

```shell
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
```

- makevm.sh 에서는 makeinstance.sh 로부터 넘겨받은 매개 변수를 이용해 Instance 를 생성한다

- Instance 정보와 Host 정보를 DB Node 에 설치된 MariaDB 에 저장한다

- 넘겨받은 git 주소를 clone 하여 해당 주소의 저장소에서 index.html 을 받아와 출력할 web 페이지를 불러온다

- 사용자가 입력한 key 이름을 이용해 ssh key 를 생성하여 KVM Node 에 Public key 를, Instance 에 Private Key 를 저장해준다

### 11. 이번 Project 를 통해 얻은 효과 & 소감

#### 이번 Project 를 통해 얻은 효과

- 팀 프로젝트 진행을 통해 역할 분배, 각 역할간 연계등
협업 프로젝트에 대한 경험 습득

- 프로그램 구현 및 구현 중 발생하는 오류를 수정하며 linux
Shell 프로그래밍과 KVM 에 대한 복습

- MariaDB 와 같은 경우, 수많은 오류를 해결하며, 기존에
멀게만 느껴졌던 DB 에 한층 익숙해짐

- 기존에 배운 것을 따라하는 것이 아닌, 배웠던 것을 기초로
팀원들간의 논의하에 프로젝트 목표에 맞추어 새로운
구조로 프로그램을 구현

#### 소감

- 팀 프로젝트를 통해 협업 및 각종 이슈를 해결하며 스스로의 학습과 팀 협업 경험에 큰 도움이 되었으며, 팀원들 덕분에 프로젝트를 성공적으로 마칠 수 있어서 다행이라고 생각합니다

### 12. Team Project 간 어려웠던 점

#### Tech 부분

필자가 Project 진행간 겪었던 기술적인 부분에는 Instance Ip 정보 불러오기 문제가 있었습니다. Virt-Builder 로 Volume 을 수정하여 Network 를 설정하여 Ip 를 KVM 의 dhcp server 로 부터 동적 할당을 받게 되면, 해당 Node 에서 domifaddr 명령어를 통해 생성한 Instance 의 Ip 정보를 불러오지 못해 DB 에 저장을 할 수 없었습니다. 해당 Ip 주소를 모르니 ssh 연결도 불가능한 상황에 이를 해결하고자 정적 할당 기법을 사용하였습니다

Ip 를 지정된 범위에서 랜덤한 수를 받아와서, DB 로 부터 해당 Ip 가 사용중인지 확인하고, 사용 가능한 Ip 주소라면, 이를 ifcfg-eth 파일에 넣어서 직접 Instance 의 Ip 를 할당해주는 방식을 사용하여 DB 에 저장했습니다. Virt-Builder 로 인한 DB IP 저장 문제를 해결하였습니다
#### 환경 부분

필자는 Project 진행 도중 Covid-19 에 확진되어 Team Project 진행간 소통에 대한 어려움을 겪었습니다. 이를 해결하고자, 소셜 네트워크 및 Zoom 을 통해 협업하여 Team Project 를 진행하여 서로 맡은 분야에 최선을 다해 Project 를 완료할 수 있었습니다

### 13. 개선 희망 사항

> - Dialog를 이용한 다중 인스턴스 생성 기능
> - Git 을 이용해 자동으로 웹이 업데이트 되는 기능
> - MariaDB 에 galera 클러스터 구현
> - 다중 가상머신 제어 명령 추가
> - 가상 머신 Ip 할당시 수동적 부여가 아닌 DHCP 를 이용한
> - 자동 부여 및 Ip 정보 가져오는 기능 추가
> - KVM과 WOK & Kimchi 연동
