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
        echo "가상머신 리스트"> $temp
        #ssh KVM1 virsh list --all >> $temp
	mysql dchj -u root -ptest123 -h STORAGE -e "select * from vm" >> $temp
        #echo "kvm2 가상머신 list" >> $temp
        #ssh ;KVM2 virsh list --all >> $temp
        dialog --textbox $temp 30 65
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
        for data in $(ssh KVM1 virsh list --all |grep -v Name |gawk '{print $2}' | sed '/^$/d'); do echo "${data}" "KVM1" OFF >> $dellist; done
        
        for data in $(ssh KVM2 virsh list --all |grep -v Name |gawk '{print $2}' | sed '/^$/d'); do echo ${data} "KVM2" OFF >> $dellist2; done

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
                        for data in $vmdelin; do ssh KVM1 virsh destroy $data > /dev/null; ssh KVM1 virsh undefine $data --remove-all-storage> /dev/null; mysql dchj -u root -ptest123 -h STORAGE -e "delete from vm where vmname='$data'"; ssh KVM1 rm -rf /root/.ssh/${data}.pem ; ssh KVM1 rm -rf /root/.ssh/${data}.pem.pub; done
                        for data in $vmdelin2; do ssh KVM2 virsh destroy $data > /dev/null ; ssh KVM2 virsh undefine $data --remove-all-storage> /dev/null; mysql dchj -u root -ptest123 -h STORAGE -e "delete from vm where vmname='$data'"; ssh KVM2 rm -rf /root/.ssh/${data}.pem ; ssh KVM2 rm -rf /root/.ssh/${data}.pem.pub; done
			#for data in $vmdelin; do echo $data ; mysql dchj -u root -ptest123 -h STORAGE -e "delete from vm where vmname='$data'" > /test/test.txt; done
			#for data in $vmdelin; do ssh KVM1 rm -rf /root/.ssh/${data}.pem ; ssh KVM1 rm -rf /root/.ssh/${data}.pem.pub; done
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
	#kvmname=KVM2
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
					
							
					dialog --msgbox  "설치중입니다"	10 50		
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
