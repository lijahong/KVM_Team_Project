# KVM_Team_Project
3 node kvm team project
> [velog 참조](https://velog.io/@lijahong/0%EB%B6%80%ED%84%B0-%EC%8B%9C%EC%9E%91%ED%95%98%EB%8A%94-KVM-%EA%B3%B5%EB%B6%80-Team-Project-3-Node-KVM)

### 목차
0. [프로젝트 목표](#0.-프로젝트-목표)
1. [프로젝트 개요](#1.-프로젝트-개요)
2. [스크립트 구조](#2.-스크립트-구조)
3. [기간 별 진행사항](#3.-기간-별-진행사항)
4. [실행 화면](#4.-실행-화면)
5. [DataBase 저장](#5.-DataBase-저장)
6. [Storage Node](#6.-Storage-Node)
7. [Zabbix Monitoring](#7.-Zabbix-Monitoring)
8. [환경 구성](#8.-환경-구성)
9. [Dialog 스크립트](#9.-Dialog-스크립트---makeinstance.sh)
10. [Instance 생성 스크립트](#10.-Instance-생성-스크립트---makevm.sh)
11. [이번 Project 를 통해 얻은 효과 & 소감](#11.-이번-Project-를-통해-얻은-효과-&-소감)
12. [Team Project 간 어려웠던 점](#12.-Team-Project-간-어려웠던-점)
13. [개선 희망 사항](#13.-개선-희망-사항)

============================================================================================

### 0. 프로젝트 목표

- #### 3 Node - KVM / Control / DB 를 이용하여 Local Instance 생성 환경 구축하기

### 1. 프로젝트 개요

![](https://velog.velcdn.com/images/lijahong/post/705e685f-9e7f-4566-a0f4-be2d7a9a0ab5/image.png)
- Bastion Host 란 침입 차단 소프트웨어가 설치되어 내부와 외부 네트워크 사이에서 일종의 게이트 역할을 수행하는 Host 이다. 외부에서 Bastion Host 에 ssh 로 접속 한다
- Bastion Host 는 Bridge 에 연결

#### Team Project 설계도
![](https://velog.velcdn.com/images/lijahong/post/8af1eb7c-b7f8-46c8-b558-ab384228b640/image.png)

#### 사용 기술
![](https://velog.velcdn.com/images/lijahong/post/d99ad46a-c360-4934-b724-18bfbf6e28f4/image.png)
- KVM & MariaDB & ZABBIX 를 사용한다

#### Node 사양
- control : ram 2gb
- kvm : ram 4gb , Disk 20gb
- storage : ram 2gb , Disk 120gb
- db : ram 2gb

#### 본인이 담당할 일

0. control node & kvm node 환경 구성
1. kvm 자원 비교하기
2. control node 의 dialog 구현
3. kvm 에 가상 머신 생성 스크립트 구현
4. kvm 에 가상 머신 생성시 실행할 명령어 스크립트 구현

### 2. 스크립트 구조

![](https://velog.velcdn.com/images/lijahong/post/08cfd391-0e7b-43a0-92d2-5d3255196d56/image.png)

- 스크립트는 다음과 같이 두 가지 Node 에 구성된다

#### Control Node
- 메뉴 dialog 파일을 통해 사용자에게 기능을 제공한다
- Instance 조회 & Network list 조회 & 삭제 & 생성 을 제공한다
- 생성 기능시
> - Resource.sh 에서 각 KVM Node 의 cpu & ram 사용량을 7:3 으로 비교하여 여유 KVM Node 를 판단하고, 매개변수로 makeinstance.sh 에 넘겨준다
> - 사용자로부터 입력받은 Instance 사양을 매개변수로 모아 ssh 연결을 통해 KVM NODE 의 Makevm.sh 에 매개변수로 넘겨주어 실행시킨다
> - web Instance 생성시 사용자로부터 git 주소를 받아와 매개 변수로 KVM Node 에 넘겨준다

#### KVM Node
- KVM Node 의 makevm.sh 는 인스턴스 생성 부분과 DB Node 에 Data 전달 부분으로 나뉘어진다
- 매개변수로 받은 Instance 사양을 통해 Instance 를 생성한다. 이때 Instance 의 외부 연결용 Network eth0 와 Overlay 용 Network eth1 은 KVM Node 에서 ifcfg-eth0, ifcfg-eth1 파일을 만들어 Instance 에 붙여넣기를 통해 설정한다
- virt-builder 를 사용하면, domifaddr 에서 Instance 의 Ip 를 받아오지 못하는 문제점을 해결하기 위해 Ip 는 랜덤 함수를 통해 Ip 주소 끝자리를 랜덤으로 받아와 정적 할당해준다. 이 Ip 를 ifcfg-eth 파일들에 넣어 Instance 에 설정해준다
- 매개 변수로 전달 받은 git 주소를 clone 하여 해당 git repository 에서 출력할 web 페이지를 불러온다
- 사용자가 입력한 Instance 이름을 이용해 ssh key 를 생성하여 KVM Node 에 Public key 를, Instance 에 Private Key 를 저장해준다. 이를 통해 생성한 Instance 에 ssh 연결이 가능해진다
- Virt-Builder 를 사용하여 Volume 에 대한 수정 작업을 진행한다. Network 설정, 패키지 설치, ssh 설정, git clone 을 통한 web 페이지 저장, 패키지 실행, 방화벽 설정 을 진행한다
- 수정된 Volume 을 이용하여 Instance 생성에는 Virt-Install 을 사용한다

#### Instance 생성시 전달하는 매개변수
- 작업할 KVM Node 명
- 사용 이미지
- 인스턴스 이름
- 인스턴스 용도
- git repository 주소
- vcpu
- ram
- disk 용량

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

- ssh_config 는 위와 같이 설정한다. 이는 control node 에만 설정하자
![](https://velog.velcdn.com/images/lijahong/post/149e47c9-2ed1-4698-8ccd-a802093e731d/image.png)

- sshd_config 는 5 개의 node 모두 위와 같이 Public Key 로만 인증하게 설정하자
![](https://velog.velcdn.com/images/lijahong/post/cd30b1d0-cd8e-48b2-8076-77087071d6c7/image.png)

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

### 9. Dialog 스크립트 - [makeinstance.sh](https://github.com/lijahong/kvm_project/blob/main/kvm_file/makeInstance.sh)

> makeinstance.sh 는 Control node 에서 메뉴를 담당하는 dialog 를 구현한 스크립트이다

- 스크립트를 통해 dialog 를 구현하였다

- dialog 에서 인스턴스 생성시 각 단계별 정상 종료 코드를 확인하여 다음 단계로 넘어간다

- 인스턴스 생성시 resource.sh 가 실행되어 각 KVM Node 의 물리 자원 CPU 와 RAM 을 7:3 비율로 비교하여 물리 자원에 여유가 있는 Node 를 판단해서 해당 KVM Node 이름과 물리 자원량을 매개변수로 넘겨준다

- 사용자의 입력을 모두 받으면 이를 ssh 연결을 통해 kvm 의 makevm.sh 에 매개변수로 넘겨준다

- 인스턴스 생성시 web 용도와 customize 용도를 선택 가능하며, web 용도를 선택시 git 주소를 입력받는다. 해당 주소는 매개 변수로 makevm.sh 에 넘겨준다

### 10. Instance 생성 스크립트 - [makevm.sh](https://github.com/lijahong/kvm_project/blob/main/kvm_file/makevm.sh)

> makevm.sh 에서는 makeinstance.sh 로부터 넘겨받은 매개 변수를 이용해 Instance 를 생성한다

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
