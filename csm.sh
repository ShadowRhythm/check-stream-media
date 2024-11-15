#!/bin/bash
shopt -s expand_aliases
Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"

while getopts ":I:M:EX:P:" optname; do
    case "$optname" in
    "I")
        iface="$OPTARG"
        useNIC="--interface $iface"
        ;;
    "M")
        if [[ "$OPTARG" == "4" ]]; then
            NetworkType=4
        elif [[ "$OPTARG" == "6" ]]; then
            NetworkType=6
        fi
        ;;
    "E")
        language="e"
        ;;
    "X")
        XIP="$OPTARG"
        xForward="--header X-Forwarded-For:$XIP"
        ;;
    "P")
        proxy="$OPTARG"
        usePROXY="-x $proxy"
        ;;
    ":")
        echo "Failedn error while processing options"
        exit 1
        ;;
    esac

done

if [ -z "$iface" ]; then
    useNIC=""
fi

if [ -z "$XIP" ]; then
    xForward=""
fi

if [ -z "$proxy" ]; then
    usePROXY=""
elif [ -n "$proxy" ]; then
    NetworkType=4
fi

if ! mktemp -u --suffix=RRC &>/dev/null; then
    is_busybox=1
fi

UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"
UA_Dalvik="Dalvik/2.1.0 (Linux; U; Android 9; ALP-AL00 Build/HUAWEIALP-AL00)"
Media_Cookie=$(curl -s --retry 3 --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/cookies")
IATACode=$(curl -s --retry 3 --max-time 10 "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/reference/IATACode.txt")
WOWOW_Cookie=$(echo "$Media_Cookie" | awk 'NR==3')
TVer_Cookie="Accept: application/json;pk=BCpkADawqM0_rzsjsYbC1k1wlJLU4HiAtfzjxdUmfvvLUQB-Ax6VA-p-9wOEZbCEm3u95qq2Y1CQQW1K9tPaMma9iAqUqhpISCmyXrgnlpx9soEmoVNuQpiyGsTpePGumWxSs1YoKziYB6Wz"

blue()
{
    echo -e "\033[34m[input]\033[0m"
}

countRunTimes() {
    if [ "$is_busybox" == 1 ]; then
        count_file=$(mktemp)
    else
        count_file=$(mktemp --suffix=RRC)
    fi
    RunTimes=$(curl -s --max-time 10 "https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fcheck.unclock.media&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=visit&edge_flat=false" >"${count_file}")
    TodayRunTimes=$(cat "${count_file}" | tail -3 | head -n 1 | awk '{print $5}')
    TotalRunTimes=$(($(cat "${count_file}" | tail -3 | head -n 1 | awk '{print $7}') + 2527395))
}
countRunTimes

checkOS() {
    ifTermux=$(echo $PWD | grep termux)
    ifMacOS=$(uname -a | grep Darwin)
    if [ -n "$ifTermux" ]; then
        os_version=Termux
        is_termux=1
    elif [ -n "$ifMacOS" ]; then
        os_version=MacOS
        is_macos=1
    else
        os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
    fi

    if [[ "$os_version" == "2004" ]] || [[ "$os_version" == "10" ]] || [[ "$os_version" == "11" ]]; then
        is_windows=1
        ssll="-k --ciphers DEFAULT@SECLEVEL=1"
    fi

    if [ "$(which apt 2>/dev/null)" ]; then
        InstallMethod="apt"
        is_debian=1
    elif [ "$(which dnf 2>/dev/null)" ] || [ "$(which yum 2>/dev/null)" ]; then
        InstallMethod="yum"
        is_redhat=1
    elif [[ "$os_version" == "Termux" ]]; then
        InstallMethod="pkg"
    elif [[ "$os_version" == "MacOS" ]]; then
        InstallMethod="brew"
    fi
}

checkCPU() {
    CPUArch=$(uname -m)
    if [[ "$CPUArch" == "aarch64" ]]; then
        arch=_arm64
    elif [[ "$CPUArch" == "i686" ]]; then
        arch=_i686
    elif [[ "$CPUArch" == "arm" ]]; then
        arch=_arm
    elif [[ "$CPUArch" == "x86_64" ]] && [ -n "$ifMacOS" ]; then
        arch=_darwin
    fi
}

checkDependencies() {

    # os_detail=$(cat /etc/os-release 2> /dev/null)

    if ! command -v python &>/dev/null; then
        if command -v python3 &>/dev/null; then
            alias python="python3"
        else
            if [ "$is_debian" == 1 ]; then
                echo -e "${Font_Green}Installing python${Font_Suffix}"
                $InstallMethod update >/dev/null 2>&1
                $InstallMethod install python -y >/dev/null 2>&1
            elif [ "$is_redhat" == 1 ]; then
                echo -e "${Font_Green}Installing python${Font_Suffix}"
                if [[ "$os_version" -gt 7 ]]; then
                    $InstallMethod makecache >/dev/null 2>&1
                    $InstallMethod install python3 -y >/dev/null 2>&1
                    alias python="python3"
                else
                    $InstallMethod makecache >/dev/null 2>&1
                    $InstallMethod install python -y >/dev/null 2>&1
                fi

            elif [ "$is_termux" == 1 ]; then
                echo -e "${Font_Green}Installing python${Font_Suffix}"
                $InstallMethod update -y >/dev/null 2>&1
                $InstallMethod install python -y >/dev/null 2>&1

            elif [ "$is_macos" == 1 ]; then
                echo -e "${Font_Green}Installing python${Font_Suffix}"
                $InstallMethod install python
            fi
        fi
    fi

    if ! command -v dig &>/dev/null; then
        if [ "$is_debian" == 1 ]; then
            echo -e "${Font_Green}Installing dnsutils${Font_Suffix}"
            $InstallMethod update >/dev/null 2>&1
            $InstallMethod install dnsutils -y >/dev/null 2>&1
        elif [ "$is_redhat" == 1 ]; then
            echo -e "${Font_Green}Installing bind-utils${Font_Suffix}"
            $InstallMethod makecache >/dev/null 2>&1
            $InstallMethod install bind-utils -y >/dev/null 2>&1
        elif [ "$is_termux" == 1 ]; then
            echo -e "${Font_Green}Installing dnsutils${Font_Suffix}"
            $InstallMethod update -y >/dev/null 2>&1
            $InstallMethod install dnsutils -y >/dev/null 2>&1
        elif [ "$is_macos" == 1 ]; then
            echo -e "${Font_Green}Installing bind${Font_Suffix}"
            $InstallMethod install bind
        fi
    fi

    if [ "$is_macos" == 1 ]; then
        if ! command -v md5sum &>/dev/null; then
            echo -e "${Font_Green}Installing md5sha1sum${Font_Suffix}"
            $InstallMethod install md5sha1sum
        fi
    fi

}
checkDependencies

local_ipv4=$(curl $useNIC $usePROXY -4 -s --max-time 10 api64.ipify.org)
local_ipv4_asterisk=$(awk -F"." '{print $1"."$2".*.*"}' <<<"${local_ipv4}")
local_ipv6=$(curl $useNIC -6 -s --max-time 20 api64.ipify.org)
local_ipv6_asterisk=$(awk -F":" '{print $1":"$2":"$3":*:*"}' <<<"${local_ipv6}")
local_isp4=$(curl $useNIC -s -4 --max-time 10 --user-agent "${UA_Browser}" "https://api.ip.sb/geoip/${local_ipv4}" | grep organization | cut -f4 -d '"')
local_isp6=$(curl $useNIC -s -6 --max-time 10 --user-agent "${UA_Browser}" "https://api.ip.sb/geoip/${local_ipv6}" | grep organization | cut -f4 -d '"')

ShowRegion() {
    echo -e "${Font_Yellow} ---${1}---${Font_Suffix}"
}


function check_ip_valide()
{
    local IPPattern='^(\<([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\>\.){3}\<([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\>$'
    IP="$1"
    for special_ip in ${special_ips[@]}
    do
         local ret=$(echo $IP | grep ${special_ip})
         if [ -n "$ret" ];then
             return 1
         fi
    done
    if [[ "${IP}" =~ ${IPPattern} ]]; then
        return 0
    else
        return 1
    fi
 
}
function calc_ip_net()
{
   sip="$1"
   snetmask="$2"
 
   check_ip_valide "$sip"
   if [ $? -ne 0 ];then echo "";return 1;fi
 
   local ipFIELD1=$(echo "$sip" |cut -d. -f1)
   local ipFIELD2=$(echo "$sip" |cut -d. -f2)
   local ipFIELD3=$(echo "$sip" |cut -d. -f3)
   local ipFIELD4=$(echo "$sip" |cut -d. -f4)
         
   local netmaskFIELD1=$(echo "$snetmask" |cut -d. -f1)
   local netmaskFIELD2=$(echo "$snetmask" |cut -d. -f2)
   local netmaskFIELD3=$(echo "$snetmask" |cut -d. -f3)
   local netmaskFIELD4=$(echo "$snetmask" |cut -d. -f4)
 
   local tmpret1=$[$ipFIELD1&$netmaskFIELD1]
   local tmpret2=$[$ipFIELD2&$netmaskFIELD2]
   local tmpret3=$[$ipFIELD3&$netmaskFIELD3]
   local tmpret4=$[$ipFIELD4&$netmaskFIELD4]
    
   echo "$tmpret1.$tmpret2.$tmpret3.$tmpret4"
}   

function Check_DNS_IP()
{
    if [ "$1" != "${1#*[0-9].[0-9]}" ]; then
        if [ "$(calc_ip_net "$1" 255.0.0.0)" == "10.0.0.0" ];then
            echo 0
        elif [ "$(calc_ip_net "$1" 255.240.0.0)" == "172.16.0.0" ];then
            echo 0
        elif [ "$(calc_ip_net "$1" 255.255.0.0)" == "169.254.0.0" ];then
            echo 0
        elif [ "$(calc_ip_net "$1" 255.255.0.0)" == "192.168.0.0" ];then
            echo 0
        elif [ "$(calc_ip_net "$1" 255.255.255.0)" == "$(calc_ip_net "$2" 255.255.255.0)" ];then
            echo 0
        else
            echo 1
        fi
    elif [ "$1" != "${1#*[0-9a-fA-F]:*}" ]; then
        if [ "${1:0:3}" == "fe8" ];then
            echo 0
        elif [ "${1:0:3}" == "FE8" ];then
            echo 0
        elif [ "${1:0:2}" == "fc" ];then
            echo 0
        elif [ "${1:0:2}" == "FC" ];then
            echo 0
        elif [ "${1:0:2}" == "fd" ];then
            echo 0
        elif [ "${1:0:2}" == "FD" ];then
            echo 0
        elif [ "${1:0:2}" == "ff" ];then
            echo 0
        elif [ "${1:0:2}" == "FF" ];then
            echo 0
        else
            echo 1
        fi
    else
        echo 0
    fi
}

function Check_Private_IP()
{
    if [ "$1" != "${1#*[0-9].[0-9]}" ]; then
        if [ "$(calc_ip_net "$1" 255.0.0.0)" == "10.0.0.0" ];then
            echo 0
        elif [ "$(calc_ip_net "$1" 255.240.0.0)" == "172.16.0.0" ];then
            echo 0
        elif [ "$(calc_ip_net "$1" 255.255.0.0)" == "169.254.0.0" ];then
            echo 0
        elif [ "$(calc_ip_net "$1" 255.255.0.0)" == "192.168.0.0" ];then
            echo 0
        else
            echo 1
        fi
    elif [ "$1" != "${1#*[0-9a-fA-F]:*}" ]; then
        if [ "${1:0:3}" == "fe8" ];then
            echo 0
        elif [ "${1:0:3}" == "FE8" ];then
            echo 0
        elif [ "${1:0:2}" == "fc" ];then
            echo 0
        elif [ "${1:0:2}" == "FC" ];then
            echo 0
        elif [ "${1:0:2}" == "fd" ];then
            echo 0
        elif [ "${1:0:2}" == "FD" ];then
            echo 0
        elif [ "${1:0:2}" == "ff" ];then
            echo 0
        elif [ "${1:0:2}" == "FF" ];then
            echo 0
        else
            echo 1
        fi
    else
        echo 0
    fi
}

function Check_DNS_1()
{
    local resultdns=$(nslookup $1)
    local resultinlines=(${resultdns//$'\n'/ })
    for i in ${resultinlines[*]}
    do
        if [[ "$i" == "Name:" ]]; then
            local resultdnsindex=$(( $resultindex + 3 ))
            break
        fi
        local resultindex=$(( $resultindex + 1 ))
    done
    echo `Check_DNS_IP ${resultinlines[$resultdnsindex]} ${resultinlines[1]}`
}

function Check_DNS_2()
{
    local resultdnstext=$(dig $1 | grep "ANSWER:")
    local resultdnstext=${resultdnstext#*"ANSWER: "}
    local resultdnstext=${resultdnstext%", AUTHORITY:"*}
    if [ "${resultdnstext}" == "0" ] || [ "${resultdnstext}" == "1" ] || [ "${resultdnstext}" == "2" ];then
        echo 0
    else
        echo 1
    fi
}

function Check_DNS_3()
{
    local resultdnstext=$(dig "test$RANDOM$RANDOM.${1}" | grep "ANSWER:")
    echo "test$RANDOM$RANDOM.${1}"
    local resultdnstext=${resultdnstext#*"ANSWER: "}
    local resultdnstext=${resultdnstext%", AUTHORITY:"*}
    if [ "${resultdnstext}" == "0" ];then
        echo 1
    else
        echo 0
    fi
}

function Get_Unlock_Type()
{
		    while [ $# -ne 0 ]
		    do
		        if [ "$1" = "0" ];then
		            echo "DNS"
		            return
		        fi
		        shift
		    done
		    echo "Native"
}

###########################################
#                                         #
#           required check item           #
#                                         #
###########################################

MediaUnlockTest_BBCiPLAYER() {
    local tmpresult=$(curl $useNIC $usePROXY $xForward --user-agent "${UA_Browser}" -${1} ${ssll} -fsL --max-time 10 "https://open.live.bbc.co.uk/mediaselector/6/select/version/2.0/mediaset/pc/vpid/bbc_one_london/format/json/jsfunc/JS_callbacks0" 2>&1)
    if [ "${tmpresult}" = "000" ]; then
        echo -n -e "\r BBC iPLAYER:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    if [ -n "$tmpresult" ]; then
        result=$(echo $tmpresult | grep 'geolocation')
        if [ -n "$result" ]; then
            echo -n -e "\r BBC iPLAYER:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            modifyJsonTemplate 'BBC_result' 'No'
        else
            echo -n -e "\r BBC iPLAYER:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            modifyJsonTemplate 'BBC_result' 'Yes'
        fi
    else
        echo -n -e "\r BBC iPLAYER:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        modifyJsonTemplate 'BBC_result' 'Failed'
    fi
}

MediaUnlockTest_AbemaTV_IPTest() {
    #
    local tempresult=$(curl $useNIC $usePROXY $xForward --user-agent "${UA_Dalvik}" -${1} -fsL --write-out %{http_code} --max-time 10 "https://api.abema.io/v1/ip/check?device=android" 2>&1)
    if [[ "$tempresult" == "000" ]]; then
        echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    result=$(curl $useNIC $usePROXY $xForward --user-agent "${UA_Dalvik}" -${1} -fsL --max-time 10 "https://api.abema.io/v1/ip/check?device=android" 2>&1 | python -m json.tool 2>/dev/null | grep isoCountryCode | awk '{print $2}' | cut -f2 -d'"')
    if [ -n "$result" ]; then
        if [[ "$result" == "JP" ]]; then
            echo -n -e "\r Abema.TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            modifyJsonTemplate 'AbemaTV_result' 'Yes'
        else
            echo -n -e "\r Abema.TV:\t\t\t\t${Font_Yellow}Oversea Only${Font_Suffix}\n"
            modifyJsonTemplate 'AbemaTV_result' 'Oversea Only'
        fi
    else
        echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        modifyJsonTemplate 'AbemaTV_result' 'No'
    fi
}

MediaUnlockTest_Netflix() {
    local checkunlockurl="netflix.com"
    local result1=`Check_DNS_1 ${checkunlockurl}`
    local result2=`Check_DNS_2 ${checkunlockurl}`
    local result3=`Check_DNS_3 ${checkunlockurl}`
    local resultunlocktype=`Get_Unlock_Type ${resultP} ${result1} ${result2} ${result3}`
	
    local result1=$(curl $useNIC $usePROXY $xForward -${1} --user-agent "${UA_Browser}" -fsLI -X GET --write-out %{http_code} --output /dev/null --max-time 10 --tlsv1.3 "https://www.netflix.com/title/81280792"  2>&1)
    local result2=$(curl $useNIC $usePROXY $xForward -${1} --user-agent "${UA_Browser}" -fsLI -X GET --write-out %{http_code} --output /dev/null --max-time 10 --tlsv1.3 "https://www.netflix.com/title/70143836" 2>&1)
    local regiontmp=$(curl $useNIC $usePROXY $xForward -${1} --user-agent "${UA_Browser}" -fSsI -X GET --max-time 10 --write-out %{redirect_url} --output /dev/null --tlsv1.3 "https://www.netflix.com/login" 2>&1 )
    if [[ "$regiontmp" == "curl"* ]]; then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local region=$(echo $regiontmp | cut -d '/' -f4 | cut -d '-' -f1 | tr [:lower:] [:upper:])
    if [[ ! -n "$region" ]]; then
        region="US"
    fi
    if [[ "$result1" == "404" ]] && [[ "$result2" == "404" ]]; then
        modifyJsonTemplate 'Netflix_result' 'Originals Only'
        echo -n -e "\r Netflix:\t\t\t${resultunlocktype}\t${Font_Yellow}Originals Only${Font_Suffix}\n" "${resultunlocktype}"
        return
    elif [[ "$result1" == "403" ]] && [[ "$result2" == "403" ]]; then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        modifyJsonTemplate 'Netflix_result' 'No'
        return
    elif [[ "$result1" == "200" ]] || [[ "$result2" == "200" ]]; then
        echo -n -e "\r Netflix:\t\t\t${resultunlocktype}\t${Font_Green}Yes (Region: ${region})${Font_Suffix}\n"
        modifyJsonTemplate 'Netflix_result' 'Yes' "${region}" "${resultunlocktype}"
        return
    else
        echo -n -e "\r Netflix:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        modifyJsonTemplate 'Netflix_result' 'Failed'
        return
    fi
}

MediaUnlockTest_DisneyPlus() {
    local checkunlockurl="disneyplus.com"
    local result1=`Check_DNS_1 ${checkunlockurl}`
    local result3=`Check_DNS_3 ${checkunlockurl}`
    local resultunlocktype=`Get_Unlock_Type ${resultP} ${result1} ${result3}`
	
    local PreAssertion=$(curl $useNIC $usePROXY $xForward -${1} --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://disney.api.edge.bamgrid.com/devices" -H "authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -H "content-type: application/json; charset=UTF-8" -d '{"deviceFamily":"browser","applicationRuntime":"chrome","deviceProfile":"windows","attributes":{}}' 2>&1)
    if [[ "$PreAssertion" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$PreAssertion" == "curl"* ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        modifyJsonTemplate 'DisneyPlus_result' 'Failed'
        return
    fi

    local assertion=$(echo $PreAssertion | python -m json.tool 2>/dev/null | grep assertion | cut -f4 -d'"')
    local PreDisneyCookie=$(echo "$Media_Cookie" | sed -n '1p')
    local disneycookie=$(echo $PreDisneyCookie | sed "s/DISNEYASSERTION/${assertion}/g")
    local TokenContent=$(curl $useNIC $usePROXY $xForward -${1} --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://disney.api.edge.bamgrid.com/token" -H "authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -d "$disneycookie" 2>&1)
    local isBanned=$(echo $TokenContent | python -m json.tool 2>/dev/null | grep 'forbidden-location')
    local is403=$(echo $TokenContent | grep '403 ERROR')

    if [ -n "$isBanned" ] || [ -n "$is403" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        modifyJsonTemplate 'DisneyPlus_result' 'No'
        return
    fi

    local fakecontent=$(echo "$Media_Cookie" | sed -n '8p')
    local refreshToken=$(echo $TokenContent | python -m json.tool 2>/dev/null | grep 'refresh_token' | awk '{print $2}' | cut -f2 -d'"')
    local disneycontent=$(echo $fakecontent | sed "s/ILOVEDISNEY/${refreshToken}/g")
    local tmpresult=$(curl $useNIC $usePROXY $xForward -${1} --user-agent "${UA_Browser}" -X POST -sSL --max-time 10 "https://disney.api.edge.bamgrid.com/graph/v1/device/graphql" -H "authorization: ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -d "$disneycontent" 2>&1)
    local previewcheck=$(curl $useNIC $usePROXY $xForward -${1} -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://disneyplus.com" | grep preview)
    local isUnabailable=$(echo $previewcheck | grep 'unavailable')
    local region=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'countryCode' | cut -f4 -d'"')
    local inSupportedLocation=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'inSupportedLocation' | awk '{print $2}' | cut -f1 -d',')

    if [[ "$region" == "JP" ]]; then
        echo -n -e "\r Disney+:\t\t\t${resultunlocktype}\t${Font_Green}Yes (Region: JP)${Font_Suffix}\n"
        modifyJsonTemplate 'DisneyPlus_result' 'Yes' 'JP' "${resultunlocktype}"
        return
    elif [ -n "$region" ] && [[ "$inSupportedLocation" == "false" ]] && [ -z "$isUnabailable" ]; then
        echo -n -e "\r Disney+:\t\t\t${resultunlocktype}\t${Font_Yellow}Available For [Disney+ $region] Soon${Font_Suffix}\n"
        modifyJsonTemplate 'DisneyPlus_result' 'No'
        return
    elif [ -n "$region" ] && [ -n "$isUnavailable" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        modifyJsonTemplate 'DisneyPlus_result' 'No'
        return
    elif [ -n "$region" ] && [[ "$inSupportedLocation" == "true" ]]; then
        echo -n -e "\r Disney+:\t\t\t${resultunlocktype}\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
        modifyJsonTemplate 'DisneyPlus_result' 'Yes' "${region}" "${resultunlocktype}"
        return
    elif [ -z "$region" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        modifyJsonTemplate 'DisneyPlus_result' 'No'
        return
    else
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        modifyJsonTemplate 'DisneyPlus_result' 'Failed'
        return
    fi

}

MediaUnlockTest_YouTube_Premium() {
    local checkunlockurl="www.youtube.com"
    local result1=`Check_DNS_1 ${checkunlockurl}`
    local result3=`Check_DNS_3 ${checkunlockurl}`
    local resultunlocktype=`Get_Unlock_Type ${resultP} ${result1} ${result3}`	

    local tmpresult=$(curl $useNIC $usePROXY $xForward -${1} --max-time 10 -sSL -H "Accept-Language: en" -b "YSC=BiCUU3-5Gdk; CONSENT=YES+cb.20220301-11-p0.en+FX+700; GPS=1; VISITOR_INFO1_LIVE=4VwPMkB7W5A; PREF=tz=Asia.Shanghai; _gcl_au=1.1.1809531354.1646633279" "https://www.youtube.com/premium" 2>&1)

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        modifyJsonTemplate 'YouTube_Premium_result' 'Failed'
        return
    fi

    local isCN=$(echo $tmpresult | grep 'www.google.cn')
    if [ -n "$isCN" ]; then
        echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}No${Font_Suffix} ${Font_Green} (Region: CN)${Font_Suffix} \n"
        modifyJsonTemplate 'YouTube_Premium_result' 'No' 'CN'
        return
    fi
    local isNotAvailable=$(echo $tmpresult | grep 'Premium is not available in your country')
    local region=$(echo $tmpresult | grep "countryCode" | sed 's/.*"countryCode"//' | cut -f2 -d'"')
    local isAvailable=$(echo $tmpresult | grep 'ad-free')

    if [ -n "$isNotAvailable" ]; then
        echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}No${Font_Suffix} \n"
        modifyJsonTemplate 'YouTube_Premium_result' 'No'
        return
    elif [ -n "$isAvailable" ] && [ -n "$region" ]; then
        echo -n -e "\r YouTube Premium:\t\t${resultunlocktype}\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
        modifyJsonTemplate 'YouTube_Premium_result' 'Yes' "${region}" "${resultunlocktype}"
        return
    elif [ -z "$region" ] && [ -n "$isAvailable" ]; then
        echo -n -e "\r YouTube Premium:\t\t${resultunlocktype}\t${Font_Green}Yes${Font_Suffix}\n"
        modifyJsonTemplate 'YouTube_Premium_result' 'Yes' "${resultunlocktype}"
        return
    else
        echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        modifyJsonTemplate 'YouTube_Premium_result' 'Failed'
    fi
}

OpenAITest(){
    local checkunlockurl="chat.openai.com"
    local result1=`Check_DNS_1 ${checkunlockurl}`
    local result2=`Check_DNS_2 ${checkunlockurl}`
    local result3=`Check_DNS_3 ${checkunlockurl}`
    local checkunlockurl="ios.chat.openai.com"
    local result4=`Check_DNS_1 ${checkunlockurl}`
    local result5=`Check_DNS_2 ${checkunlockurl}`
    local result6=`Check_DNS_3 ${checkunlockurl}`
    local checkunlockurl="api.openai.com"
    local result7=`Check_DNS_1 ${checkunlockurl}`
    local result8=`Check_DNS_3 ${checkunlockurl}`
    local resultunlocktype=`Get_Unlock_Type ${resultP} ${result1} ${result2} ${result3} ${result4} ${result5} ${result6} ${result7} ${result8}`
    
    local tmpresult1=$(curl $useNIC $usePROXY $xForward -${1} ${ssll} -sS --max-time 10 'https://api.openai.com/compliance/cookie_requirements'   -H 'authority: api.openai.com'   -H 'accept: */*'   -H 'accept-language: zh-CN,zh;q=0.9'   -H 'authorization: Bearer null'   -H 'content-type: application/json'   -H 'origin: https://platform.openai.com'   -H 'referer: https://platform.openai.com/'   -H 'sec-ch-ua: "Microsoft Edge";v="119", "Chromium";v="119", "Not?A_Brand";v="24"'   -H 'sec-ch-ua-mobile: ?0'   -H 'sec-ch-ua-platform: "Windows"'   -H 'sec-fetch-dest: empty'   -H 'sec-fetch-mode: cors'   -H 'sec-fetch-site: same-site'   -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36 Edg/119.0.0.0' 2>&1)
    local tmpresult2=$(curl $useNIC $usePROXY $xForward -${1} ${ssll} -sS --max-time 10 'https://ios.chat.openai.com/' -H 'authority: ios.chat.openai.com'   -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7'   -H 'accept-language: zh-CN,zh;q=0.9' -H 'sec-ch-ua: "Microsoft Edge";v="119", "Chromium";v="119", "Not?A_Brand";v="24"'   -H 'sec-ch-ua-mobile: ?0'   -H 'sec-ch-ua-platform: "Windows"'   -H 'sec-fetch-dest: document'   -H 'sec-fetch-mode: navigate'   -H 'sec-fetch-site: none'   -H 'sec-fetch-user: ?1'   -H 'upgrade-insecure-requests: 1'   -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36 Edg/119.0.0.0' 2>&1)
    local result1=$(echo $tmpresult1 | grep unsupported_country)
    local result2=$(echo $tmpresult2 | grep VPN)
    if [ -z "$result2" ] && [ -z "$result1" ] && [[ "$tmpresult1" != "curl"* ]] && [[ "$tmpresult2" != "curl"* ]]; then
        echo -n -e "\r ChatGPT:\t\t\t${resultunlocktype}\t${Font_Green}Yes${Font_Suffix}\n"
        modifyJsonTemplate 'OpenAI_result' 'Yes' "${resultunlocktype}"
        return
    elif [ -n "$result2" ] && [ -n "$result1" ]; then
        echo -n -e "\r ChatGPT:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        modifyJsonTemplate 'OpenAI_result' 'No'
        return
    elif [ -z "$result1" ] && [ -n "$result2" ] && [[ "$tmpresult1" != "curl"* ]]; then
        echo -n -e "\r ChatGPT:\t\t\t${resultunlocktype}\t${Font_Yellow}Only Available with Web Browser${Font_Suffix}\n"
        modifyJsonTemplate 'OpenAI_result' 'Only Web'
       return
    elif [ -n "$result1" ] && [ -z "$result2" ]; then
        echo -n -e "\r ChatGPT:\t\t\t${resultunlocktype}\t${Font_Yellow}Only Available with Mobile APP${Font_Suffix}\n"
        modifyJsonTemplate 'OpenAI_result' 'Only APP'
        return
    elif [[ "$tmpresult1" == "curl"* ]] && [ -n "$result2" ]; then
        echo -n -e "\r ChatGPT:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        modifyJsonTemplate 'OpenAI_result' 'No'
        return
    else
        echo -n -e "\r ChatGPT:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        modifyJsonTemplate 'OpenAI_result' 'Failed'
       return
    
    fi
}

###########################################
#                                         #
#   sspanel unlock check function code    #
#                                         #
###########################################

createJsonTemplate() {
    echo '{
    "YouTube": "YouTube_Premium_result",
    "Netflix": "Netflix_result",
    "Disney+": "DisneyPlus_result",
    "OpenAI": "OpenAI_result",
    "BBC": "BBC_result",
    "Abema": "AbemaTV_result"
}' > /root/media_test_tpl.json
}

modifyJsonTemplate() {
    key_word=$1
    result=$2
    region=$3
    resultunlocktype=$4

if [[ -n "$3" ]]; then
    # 如果字段3有值
    if [[ -n "$4" && "$4" != "Native" ]]; then
        # 如果字段4有值且不是 "Native"
        sed -i "s#${key_word}#${result} (${region}) (${resultunlocktype})#g" /root/media_test_tpl.json
    else
        # 如果字段4无值或为 "Native"
        sed -i "s#${key_word}#${result} (${region})#g" /root/media_test_tpl.json
    fi
else
    # 如果字段3没有值
    if [[ -n "$4" && "$4" != "Native" ]]; then
        # 如果字段4有值且不是 "Native"
        sed -i "s#${key_word}#${result} (${resultunlocktype})#g" /root/media_test_tpl.json
    else
        # 如果字段4无值或为 "Native"
        sed -i "s#${key_word}#${result}#g" /root/media_test_tpl.json
    fi
fi
}

setCronTask() {
    addTask() {
        execution_time_interval=$1

        crontab -l >/root/crontab.list
        echo "0 */${execution_time_interval} * * * /bin/bash /root/csm.sh" >>/root/crontab.list
        crontab /root/crontab.list
        rm -rf /root/crontab.list
        echo -e "$(green) The scheduled task is added successfully."
    }

    crontab -l | grep "csm.sh" >/dev/null
    if [[ "$?" != "0" ]]; then
        echo "[1] 1 hour"
        echo "[2] 2 hour"
        echo "[3] 3 hour"
        echo "[4] 4 hour"
        echo "[5] 6 hour"
        echo "[6] 8 hour"
        echo "[7] 12 hour"
        echo "[8] 24 hour"
        echo
        read -p "$(blue) Please select the detection frequency and enter the serial number (eg: 1):" time_interval_id

        if [[ "${time_interval_id}" == "5" ]];then
            time_interval=6
        elif [[ "${time_interval_id}" == "6" ]];then
            time_interval=8
        elif [[ "${time_interval_id}" == "7" ]];then
            time_interval=12
        elif [[ "${time_interval_id}" == "8" ]];then
            time_interval=24
        else
            time_interval=$time_interval_id
        fi

        case "${time_interval_id}" in
            [1-8])
                addTask ${time_interval};;
            *)
                echo -e "$(red) Choose one from the list given and enter the sequence number."
                exit;;
        esac
    fi
}

checkConfig() {
    getConfig() {
        read -p "$(blue) Please enter the panel address (eg: https://demo.sspanel.org):" panel_address
        read -p "$(blue) Please enter the mu key:" mu_key
        read -p "$(blue) Please enter the node id:" node_id

        if [[ "${panel_address}" = "" ]] || [[ "${mu_key}" = "" ]];then
            echo -e "$(red) Complete all necessary parameter entries."
            exit
        fi

        curl -s "${panel_address}/mod_mu/nodes?key=${mu_key}" | grep "invalid" > /dev/null
        if [[ "$?" = "0" ]];then
            echo -e "$(red) Wrong website address or mukey error, please try again."
            exit
        fi

        echo "${panel_address}" > /root/.csm.config
        echo "${mu_key}" >> /root/.csm.config
        echo "${node_id}" >> /root/.csm.config
    }

    if [[ ! -e "/root/.csm.config" ]];then
        getConfig
    fi
}

postData() {
    if [[ ! -e "/root/.csm.config" ]];then
        echo -e "$(red) Missing configuration file."
        exit
    fi
    if [[ ! -e "/root/media_test_tpl.json" ]];then
        echo -e "$(red) Missing detection report."
        exit
    fi

    panel_address=$(sed -n 1p /root/.csm.config)
    mu_key=$(sed -n 2p /root/.csm.config)
    node_id=$(sed -n 3p /root/.csm.config)

    curl -s -X POST -d "content=$(cat /root/media_test_tpl.json | base64 | xargs echo -n | sed 's# ##g')" "${panel_address}/mod_mu/media/save_report?key=${mu_key}&node_id=${node_id}" > /root/.csm.response
    if [[ "$(cat /root/.csm.response)" != "ok" ]];then
        curl -s -X POST -d "content=$(cat /root/media_test_tpl.json | base64 | xargs echo -n | sed 's# ##g')" "${panel_address}/mod_mu/media/saveReport?key=${mu_key}&node_id=${node_id}" > /root/.csm.response
    fi

    rm -rf /root/media_test_tpl.json /root/.csm.response
}

printInfo() {
    green_start='\033[32m'
    color_end='\033[0m'

    echo
    echo -e "${green_start}The code for this script to detect streaming media unlocking is all from the open source project https://github.com/lmc999/RegionRestrictionCheck , and the open source protocol is AGPL-3.0. This script is open source as required by the open source license. Thanks to the original author @lmc999 and everyone who made the pull request for this project for their contributions.${color_end}"
    echo
    echo -e "${green_start}Project: https://github.com/iamsaltedfish/check-stream-media${color_end}"
    echo -e "${green_start}Version: 2023-08-07 v.2.0.1${color_end}"
    echo -e "${green_start}Author: @iamsaltedfish${color_end}"
}

runCheck() {
    createJsonTemplate
    MediaUnlockTest_BBCiPLAYER 4
    MediaUnlockTest_AbemaTV_IPTest 4
    MediaUnlockTest_Netflix 6
    MediaUnlockTest_YouTube_Premium 6
    MediaUnlockTest_DisneyPlus 6
    OpenAITest 4
}

checkData()
{
    counter=0
    max_check_num=3
    cat /root/media_test_tpl.json | grep "_result" > /dev/null
    until [ $? != '0' ]  || [[ ${counter} -ge ${max_check_num} ]]
    do
        sleep 1
        runCheck > /dev/null
        echo -e "\033[33mThere is something wrong with the data and it is being retested for the ${counter} time...\033[0m"
        counter=$(expr ${counter} + 1)
    done
}

main() {
    echo
    checkOS
    checkCPU
    checkDependencies
    setCronTask
    checkConfig
    runCheck
    checkData
    postData
    printInfo
}

main
