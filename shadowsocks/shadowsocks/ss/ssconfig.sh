#!/bin/sh

# shadowsocks script for AM382 kernel 4.1.27 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

eval `dbus export ss`
source /koolshare/scripts/base.sh
source helper.sh
# Variable definitions
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
ss_basic_version_local=`cat /koolshare/ss/version`
dbus set ss_basic_version_local=$ss_basic_version_local
main_url="https://raw.githubusercontent.com/koolshare/rogsoft/master/shadowsocks"
backup_url="https://rogsoft.ngrok.wang/shadowsocks"
CONFIG_FILE=/koolshare/ss/ss.json
DNS_PORT=7913
ISP_DNS=$(nvram get wan0_dns|sed 's/ /\n/g'|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 1p)
lan_ipaddr=$(nvram get lan_ipaddr)
[ "$ss_basic_mode" == "4" ] && ss_basic_mode=3
game_on=`dbus list ss_acl_mode|cut -d "=" -f 2 | grep 3`
[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && mangle=1
ip_prefix_hex=`nvram get lan_ipaddr | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("00/0xffffff00\n")}'`
ss_basic_password=`echo $ss_basic_password|base64_decode`
IFIP=`echo $ss_basic_server|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
if [ -n "$ss_basic_rss_protocol" ];then
	ss_basic_type=1
else
	if [ -n "$ss_basic_koolgame_udp" ];then
		ss_basic_type=2
	else
		ss_basic_type=0
	fi
fi

install_ss(){
	echo_date 开始解压压缩包...
	tar -zxf shadowsocks.tar.gz
	chmod a+x /tmp/shadowsocks/install.sh
	echo_date 开始安装更新文件...
	sh /tmp/shadowsocks/install.sh

	rm -rf /tmp/shadowsocks*
}

update_ss(){
	echo_date 更新过程中请不要做奇怪的事，不然可能导致问题！
	echo_date 开启SS检查更新：使用主服务器：$main_url...
	echo_date 检测主服务器在线版本号...
	ss_basic_version_web1=`curl --connect-timeout 5 -s "$main_url"/version | sed -n 1p`
	if [ ! -z $ss_basic_version_web1 ];then
		echo_date 检测到主服务器在线版本号：$ss_basic_version_web1
		dbus set ss_basic_version_web=$ss_basic_version_web1
		if [ "$ss_basic_version_local" != "$ss_basic_version_web1" ];then
		echo_date 主服务器在线版本号："$ss_basic_version_web1" 和本地版本号："$ss_basic_version_local" 不同！
			cd /tmp
			md5_web1=`curl -s "$main_url"/version | sed -n 2p`
			echo_date 开启下载进程，从主服务器上下载更新包...
			wget --no-check-certificate --timeout=5 "$main_url"/shadowsocks.tar.gz
			md5sum_gz=`md5sum /tmp/shadowsocks.tar.gz | sed 's/ /\n/g'| sed -n 1p`
			if [ "$md5sum_gz" != "$md5_web1" ]; then
				echo_date 更新包md5校验不一致！估计是下载的时候出了什么状况，请等待一会儿再试...
				rm -rf /tmp/shadowsocks* >/dev/null 2>&1
				sleep 1
				echo_date 更换备用备用更新地址，请稍后...
				sleep 1
				update_ss2
			else
				echo_date 更新包md5校验一致！ 开始安装！...
				install_ss
			fi
		else
			echo_date 主服务器在线版本号："$ss_basic_version_web1" 和本地版本号："$ss_basic_version_local" 相同！
			sleep 1
			echo_date 那还更新个毛啊，关闭更新进程!
			exit
		fi
	else
		echo_date 没有检测到主服务器在线版本号,访问github服务器有点问题哦~
		sleep 2
		echo_date 更换备用备用更新地址，请稍后...
		sleep 1
		update_ss2
	fi
}

update_ss2(){
	echo_date 开启SS检查更新：使用备用服务器：$backup_url...
	echo_date 检测备用服务器在线版本号...
	ss_basic_version_web2=`curl --connect-timeout 5 -s "$backup_url"/version | sed -n 1p`
	if [ ! -z $ss_basic_version_web2 ];then
	echo_date 检测到备用服务器在线版本号：$ss_basic_version_web1
		dbus set ss_basic_version_web=$ss_basic_version_web2
		if [ "$ss_basic_version_local" != "$ss_basic_version_web2" ];then
		echo_date 备用服务器在线版本号："$ss_basic_version_web1" 和本地版本号："$ss_basic_version_local" 不同！
			cd /tmp
			md5_web2=`curl -s "$backup_url"/version | sed -n 2p`
			echo_date 开启下载进程，从备用服务器上下载更新包...
			wget "$backup_url"/shadowsocks.tar.gz
			md5sum_gz=`md5sum /tmp/shadowsocks.tar.gz | sed 's/ /\n/g'| sed -n 1p`
			if [ "$md5sum_gz" != "$md5_web2" ]; then
				echo_date 更新包md5校验不一致！估计是下载的时候除了什么状况，请等待一会儿再试...
				rm -rf /tmp/shadowsocks* >/dev/null 2>&1
				sleep 2
				echo_date 然而只有这一台备用更更新服务器，请尝试离线手动安装...
				exit
			else
				echo_date 更新包md5校验一致！ 开始安装！...
				install_ss
			fi
		else
			echo_date 备用服务器在线版本号："$ss_basic_version_web1" 和本地版本号："$ss_basic_version_local" 相同！
			sleep 2
			echo_date 那还更新个毛啊，关闭更新进程!
			exit 0
		fi
	else
		echo_date 没有检测到备用服务器在线版本号,访问备用服务器有点问题哦，你网络很差欸~
		sleep 2
		echo_date 然而只有这一台备用更更新服务器，请尝试离线手动安装...
		exit
	fi
}
# ================================= ss stop ===============================
restore_conf(){
	# restore dnsmasq conf file
	if [ -f /jffs/configs/dnsmasq.conf.add ]; then
		echo_date 恢复dnsmasq配置文件.
		rm -f /jffs/configs/dnsmasq.conf.add
	fi
	#--------------------------------------------------------------------------
	# delete dnsmasq postconf file
	if [ -f /jffs/scripts/dnsmasq.postconf ]; then
		echo_date 删除/jffs/scripts/dnsmasq.postconf
		rm -f /jffs/scripts/dnsmasq.postconf
	fi
	#--------------------------------------------------------------------------
	# delete custom.conf
	if [ -f /jffs/configs/dnsmasq.d/custom.conf ];then
		echo_date 删除 /jffs/configs/dnsmasq.d/custom.conf
		rm -rf /jffs/configs/dnsmasq.d/custom.conf
	fi	
}

kill_process(){
	#--------------------------------------------------------------------------
	# kill dnscrypt-proxy
	dnscrypt=$(ps | grep "dnscrypt-proxy" | grep -v "grep")
	if [ ! -z "$dnscrypt" ]; then 
		echo_date 关闭dnscrypt-proxy进程...
		killall dnscrypt-proxy
	fi
	#--------------------------------------------------------------------------
	# kill redsocks2
	redsocks2=$(ps | grep "redsocks2" | grep -v "grep")
	if [ ! -z "$redsocks2" ]; then 
		echo_date 关闭redsocks2进程...
		killall redsocks2
	fi
	#--------------------------------------------------------------------------
	# kill ss-redir
	ssredir=$(ps | grep "ss-redir" | grep -v "grep" | grep -vw "rss-redir")
	if [ ! -z "$ssredir" ];then 
		echo_date 关闭ss-redir进程...
		killall ss-redir
	fi

	rssredir=$(ps | grep "rss-redir" | grep -v "grep" | grep -vw "ss-redir")
	if [ ! -z "$rssredir" ];then 
		echo_date 关闭ssr-redir进程...
		killall rss-redir
	fi
	#--------------------------------------------------------------------------
	# kill ss-local
	sslocal=`ps | grep -w ss-local | grep -v "grep" | grep -w "23456" | awk '{print $1}'`
	if [ ! -z "$sslocal" ];then 
		echo_date 关闭ss-local进程:23456端口...
		kill $sslocal  >/dev/null 2>&1
	fi

	ssrlocal=`ps | grep -w rss-local | grep -v "grep" | grep -w "23456" | awk '{print $1}'`
	if [ ! -z "$ssrlocal" ];then 
		echo_date 关闭ssr-local进程:23456端口...
		kill $ssrlocal  >/dev/null 2>&1
	fi

	#--------------------------------------------------------------------------
	# kill ss-tunnel
	sstunnel=$(ps | grep "ss-tunnel" | grep -v "grep" | grep -vw "rss-tunnel")
	if [ ! -z "$sstunnel" ];then 
		echo_date 关闭ss-tunnel进程...
		killall ss-tunnel
	fi
	
	rsstunnel=$(ps | grep "rss-tunnel" | grep -v "grep" | grep -vw "ss-tunnel")
	if [ ! -z "$rsstunnel" ];then 
		echo_date 关闭rss-tunnel进程...
		killall rss-tunnel
	fi
	
	#--------------------------------------------------------------------------
	# kill pdnsd
	pdnsd=$(ps | grep "pdnsd" | grep -v "grep")
	if [ ! -z "$pdnsd" ];then 
	echo_date 关闭pdnsd进程...
	killall pdnsd
	fi
	#--------------------------------------------------------------------------
	# kill Pcap_DNSProxy
	Pcap_DNSProxy=$(ps | grep "Pcap_DNSProxy" | grep -v "grep")
	if [ ! -z "$Pcap_DNSProxy" ];then 
		echo_date 关闭Pcap_DNSProxy进程...
		pid1=`ps|grep /koolshare/ss/dns/dns.sh | grep -v grep | awk '{print $1}'`
		kill -9 $pid1 >/dev/null 2>&1
		killall Pcap_DNSProxy >/dev/null 2>&1
	fi
	#--------------------------------------------------------------------------
	# kill chinadns
	chinadns=$(ps | grep "chinadns" | grep -v "grep")
	if [ ! -z "$chinadns" ];then 
		echo_date 关闭chinadns进程...
		killall chinadns
	fi
	#--------------------------------------------------------------------------
	# kill dns2socks
	DNS2SOCK=$(ps | grep "dns2socks" | grep -v "grep")
	if [ ! -z "$DNS2SOCK" ];then 
		echo_date 关闭dns2socks进程...
		killall dns2socks
	fi
	
	# kill all koolgame
	koolgame_process=$(ps | grep "koolgame" | grep -v "grep"|grep -v "pdu")
	if [ ! -z "$koolgame_process" ];then 
		echo_date 关闭koolgame进程...
		killall koolgame >/dev/null 2>&1
	fi

	pdu_process=`pidof pdu`
	if [ -n "$pdu_process" ];then 
		echo_date 关闭pdu进程...
		kill -9 $pdu >/dev/null 2>&1
	fi
	
	# kill kcp
	client_linux_arm7_process=$(ps | grep "client_linux_arm7" | grep -v "grep")
	if [ ! -z "$client_linux_arm7_process" ];then 
		echo_date 关闭kcp协议进程...
		killall client_linux_arm7 >/dev/null 2>&1
	fi
	
	# kill load balance
	haproxy_process=$(ps | grep "haproxy" | grep -v "grep")
	if [ -n "$haproxy_process" ];then 
		echo_date 关闭haproxy进程...
		killall haproxy >/dev/null 2>&1
	fi

	speederv1_process=$(pidof speederv1)
	if [ -n "$speederv1_process" ];then 
		echo_date 关闭speederv1进程...
		killall speederv1 >/dev/null 2>&1
	fi

	speederv2_process=$(pidof speederv2)
	if [ -n "$speederv2_process" ];then 
		echo_date 关闭speederv2进程...
		killall speederv2 >/dev/null 2>&1
	fi

	ud2raw_process=$(pidof udp2raw)
	if [ -n "$ud2raw_process" ];then 
		echo_date 关闭ud2raw进程...
		killall udp2raw >/dev/null 2>&1
	fi
}

remove_conf_and_settings(){
	echo_date 删除ss相关的名单配置文件.
	# remove conf under /jffs/configs/dnsmasq.d
	rm -rf /jffs/configs/dnsmasq.d/gfwlist.conf
	rm -rf /jffs/configs/dnsmasq.d/cdn.conf
	rm -rf /jffs/configs/dnsmasq.d/zzcdn.conf
	rm -rf /jffs/configs/dnsmasq.d/custom.conf
	rm -rf /jffs/configs/dnsmasq.d/wblist.conf
	rm -rf /tmp/sscdn.conf
	rm -rf /tmp/custom.conf
	rm -rf /tmp/wblist.conf
	rm -rf /jffs/configs/dnsmasq.conf.add

	# remove ss state
	dbus remove ss_basic_state_china
	dbus remove ss_basic_state_foreign
}
# ================================= ss prestart ===========================
ss_pre_start(){
	lb_enable=`dbus get ss_lb_enable`
	if [ "$lb_enable" == "1" ];then
		if [ `dbus get ss_basic_server | grep -o "127.0.0.1"` ] && [ `dbus get ss_basic_port` == `dbus get ss_lb_port` ];then
		echo_date ss启动前触发:触发启动负载均衡功能！
			#start haproxy
			sh /koolshare/scripts/ss_lb_config.sh
			#start kcptun
			lb_node=`dbus list ssconf_basic_use_lb_|sed 's/ssconf_basic_use_lb_//g' |cut -d "=" -f 1 | sort -n`
			for node in $lb_node
			do	
				name=`dbus get ssconf_basic_name_$node`
				kcp=`dbus get ssconf_basic_use_kcp_$node`
				kcp_server=`dbus get ssconf_basic_server_$node`
				# marked for change in future 
				server_ip=`nslookup "$kcp_server" 119.29.29.29 | sed '1,4d' | awk '{print $3}' | grep -v :|awk 'NR==1{print}'`
				kcp_port=`dbus get ss_basic_kcp_port`
				kcp_para=`dbus get ss_basic_kcp_parameter`
				if [ "$kcp" == "1" ];then
					export GOGC=40
					if [ "$ss_basic_kcp_method" == "1" ];then
						[ -n "$ss_basic_kcp_encrypt" ] && KCP_CRYPT="--crypt $ss_basic_kcp_encrypt"
						[ -n "$ss_basic_kcp_password" ] && KCP_KEY="--key $ss_basic_kcp_password" || KCP_KEY=""
						[ -n "$ss_basic_kcp_sndwnd" ] && KCP_SNDWND="--sndwnd $ss_basic_kcp_sndwnd" || KCP_SNDWND=""
						[ -n "$ss_basic_kcp_rcvwnd" ] && KCP_RNDWND="--rcvwnd $ss_basic_kcp_rcvwnd" || KCP_RNDWND=""
						[ -n "$ss_basic_kcp_mtu" ] && KCP_MTU="--mtu $ss_basic_kcp_mtu" || KCP_MTU=""
						[ -n "$ss_basic_kcp_conn" ] && KCP_CONN="--conn $ss_basic_kcp_conn" || KCP_CONN=""
						[ "$ss_basic_kcp_nocomp" == "1" ] && COMP="--nocomp" || COMP=""
						[ -n "$ss_basic_kcp_mode" ] && KCP_MODE="--mode $ss_basic_kcp_mode" || KCP_MODE=""

						start-stop-daemon -S -q -b -m \
						-p /tmp/var/kcp.pid \
						-x /koolshare/bin/client_linux_arm7 \
						-- -l 127.0.0.1:1091 \
						-r $server_ip:$kcp_port \
						$KCP_CRYPT $KCP_KEY $KCP_SNDWND $KCP_RNDWND $KCP_MTU $KCP_CONN $COMP $KCP_MODE $ss_basic_kcp_extra
					else
						start-stop-daemon -S -q -b -m -p /tmp/var/kcp.pid -x /koolshare/bin/client_linux_arm7 -- -l 127.0.0.1:1091 -r $server_ip:$kcp_port $kcp_para
					fi
				fi
			done
		else
			echo_date ss启动前触发:未选择负载均衡节点，不触发负载均衡启动！
		fi
	else
		if [ `dbus get ss_basic_server | grep -o "127.0.0.1"` ] && [ `dbus get ss_basic_port` == `dbus get ss_lb_port` ];then
			echo_date ss启动前触发【警告】：你选择了负载均衡节点，但是负载均衡开关未启用！！
		else
			echo_date ss启动前触发：你选择了普通节点，不触发负载均衡启动！.
		fi
	fi
}
# ================================= ss start ==============================

[ "$ss_dns_china" == "1" ] && [ ! -z "$ISP_DNS" ] && CDN="$ISP_DNS"
[ "$ss_dns_china" == "1" ] && [ -z "$ISP_DNS" ] && CDN="114.114.114.114"
[ "$ss_dns_china" == "2" ] && CDN="223.5.5.5"
[ "$ss_dns_china" == "3" ] && CDN="223.6.6.6"
[ "$ss_dns_china" == "4" ] && CDN="114.114.114.114"
[ "$ss_dns_china" == "5" ] && CDN="114.114.115.115"
[ "$ss_dns_china" == "6" ] && CDN="1.2.4.8"
[ "$ss_dns_china" == "7" ] && CDN="210.2.4.8"
[ "$ss_dns_china" == "8" ] && CDN="112.124.47.27"
[ "$ss_dns_china" == "9" ] && CDN="114.215.126.16"
[ "$ss_dns_china" == "10" ] && CDN="180.76.76.76"
[ "$ss_dns_china" == "11" ] && CDN="119.29.29.29"
[ "$ss_dns_china" == "12" ] && CDN="$ss_dns_china_user"

# try to resolv the ss server ip if it is domain...
resolv_server_ip(){
	if [ -z "$IFIP" ];then
		echo_date 使用nslookup方式解析SS服务器的ip地址,解析dns：$ss_basic_dnslookup_server
		if [ "$ss_basic_dnslookup" == "1" ];then
			server_ip=`nslookup "$ss_basic_server" $ss_basic_dnslookup_server | sed '1,4d' | awk '{print $3}' | grep -v :|awk 'NR==1{print}'`
			if [ "$?" == "0" ]; then
				echo_date SS服务器的ip地址解析成功：$server_ip.
			else
				echo_date SS服务器域名解析失败！
				echo_date 尝试用resolveip方式解析...
				server_ip=`resolveip -4 -t 2 $ss_basic_server|awk 'NR==1{print}'`
				if [ "$?" == "0" ]; then
			    	echo_date SS服务器的ip地址解析成功：$server_ip.
				else
					echo_date 使用resolveip方式SS服务器域名解析失败！请更换nslookup解析方式的DNS地址后重试！
				fi
			fi
		else
			echo_date 使用resolveip方式解析SS服务器的ip地址.
			server_ip=`resolveip -4 -t 2 $ss_basic_server|awk 'NR==1{print}'`
		fi

		if [ ! -z "$server_ip" ];then
			ss_basic_server="$server_ip"
			dbus set ss_basic_server_ip="$server_ip"
			dbus set ss_basic_dns_success="1"
		else
			dbus remvoe ss_basic_server_ip
			echo_date SS服务器的ip地址解析失败，将由ss-redir自己解析.
			dbus set ss_basic_dns_success="0"
		fi
	else
		dbus set ss_basic_server_ip=$ss_basic_server
		echo_date 检测到你的SS服务器已经是IP格式：$ss_basic_server,跳过解析... 
		dbus set ss_basic_dns_success="1"
	fi
}
# create shadowsocks config file...
creat_ss_json(){
	# simple obfs
	ARG_OBFS=""
	if [ -n "$ss_basic_ss_obfs_host" ];then
		if [ "$ss_basic_ss_obfs" == "http" ];then
			ARG_OBFS="--plugin obfs-local --plugin-opts obfs=http;obfs-host=$ss_basic_ss_obfs_host"
		elif [ "$ss_basic_ss_obfs" == "tls" ];then
			ARG_OBFS="--plugin obfs-local --plugin-opts obfs=tls;obfs-host=$ss_basic_ss_obfs_host"
		else
			ARG_OBFS=""
		fi
	else
		if [ "$ss_basic_ss_obfs" == "http" ];then
			ARG_OBFS="--plugin obfs-local --plugin-opts obfs=http"
		elif [ "$ss_basic_ss_obfs" == "tls" ];then
			ARG_OBFS="--plugin obfs-local --plugin-opts obfs=tls"
		else
			ARG_OBFS=""
		fi
	fi
	
	if [ "$ss_basic_type" == "0" ];then
		echo_date 创建SS配置文件到$CONFIG_FILE
		cat > $CONFIG_FILE <<-EOF
			{
			    "server":"$ss_basic_server",
			    "server_port":$ss_basic_port,
			    "local_address":"0.0.0.0",
			    "local_port":3333,
			    "password":"$ss_basic_password",
			    "timeout":600,
			    "method":"$ss_basic_method"
			}
		EOF
	elif [ "$ss_basic_type" == "1" ];then
		echo_date 创建SSR配置文件到$CONFIG_FILE
		cat > $CONFIG_FILE <<-EOF
			{
			    "server":"$ss_basic_server",
			    "server_port":$ss_basic_port,
			    "local_address":"0.0.0.0",
			    "local_port":3333,
			    "password":"$ss_basic_password",
			    "timeout":600,
			    "protocol":"$ss_basic_rss_protocol",
			    "protocol_param":"$ss_basic_rss_protocol_param",
			    "obfs":"$ss_basic_rss_obfs",
			    "obfs_param":"$ss_basic_rss_obfs_param",
			    "method":"$ss_basic_method"
			}
		EOF
	elif [ "$ss_basic_type" == "2" ];then
		echo_date 创建koolgame配置文件到$CONFIG_FILE
		cat > $CONFIG_FILE <<-EOF
			{
			    "server":"$ss_basic_server",
			    "server_port":$ss_basic_port,
			    "local_port":3333,
			    "sock5_port":23456,
			    "dns2ss":7913,
			    "adblock_addr":"",
			    "dns_server":"$ss_dns2ss_user",
			    "password":"$ss_basic_password",
			    "timeout":600,
			    "method":"$ss_basic_method",
			    "use_tcp":$ss_basic_koolgame_udp
			}
		EOF
	fi
	
	if [ "$ss_basic_udp2raw_boost_enable" == "1" ] || [ "$ss_basic_udp_boost_enable" == "1" ];then
		if [ "$ss_basic_udp_upstream_mtu" == "1" ] && [ "$ss_basic_udp_node" == "$ssconf_basic_node" ];then
			echo_date 设定UDP为 $ss_basic_udp_upstream_mtu_value
			cat /koolshare/ss/ss.json | jq --argjson MTU $ss_basic_udp_upstream_mtu_value '. + {MTU: $MTU}' > /koolshare/ss/ss_tmp.json
			mv /koolshare/ss/ss_tmp.json /koolshare/ss/ss.json
		fi
	fi
}

start_sslocal(){
	if [ "$ss_basic_type" == "1" ];then
		rss-local -l 23456 -c $CONFIG_FILE -u -f /var/run/sslocal1.pid >/dev/null 2>&1
	elif  [ "$ss_basic_type" == "0" ];then
		if [ "$ss_basic_ss_obfs" == "0" ];then
			ss-local -l 23456 -c $CONFIG_FILE -u -f /var/run/sslocal1.pid >/dev/null 2>&1
		else
			ss-local -l 23456 -c $CONFIG_FILE $ARG_OBFS -u -f /var/run/sslocal1.pid >/dev/null 2>&1
		fi
	fi
}

start_dns(){
	# start ss-local on port 23456
	echo_date 开启ss-local，提供socks5代理端口：23456
	start_sslocal
	# Start DNS2SOCKS
	if [ "1" == "$ss_dns_foreign" ] || [ -z "$ss_dns_foreign" ]; then
		echo_date 开启dns2socks，监听端口：23456
		dns2socks 127.0.0.1:23456 "$ss_dns2socks_user" 127.0.0.1:$DNS_PORT > /dev/null 2>&1 &
	fi

	# Start ss-tunnel
	[ "$ss_sstunnel" == "1" ] && gs="208.67.220.220:53"
	[ "$ss_sstunnel" == "2" ] && gs="8.8.8.8:53"
	[ "$ss_sstunnel" == "3" ] && gs="8.8.4.4:53"
	[ "$ss_sstunnel" == "4" ] && gs="$ss_sstunnel_user"	
	if [ "2" == "$ss_dns_foreign" ];then
		if [ "$ss_basic_type" == "1" ];then
			echo_date 开启ssr-tunnel...
			rss-tunnel -c $CONFIG_FILE -l $DNS_PORT -L "$gs" -u -f /var/run/sstunnel.pid >/dev/null 2>&1
		elif  [ "$ss_basic_type" == "0" ];then
			echo_date 开启ss-tunnel...
			if [ "$ss_basic_ss_obfs" == "0" ];then
				ss-tunnel -c $CONFIG_FILE -l $DNS_PORT -L "$gs" -u -f /var/run/sstunnel.pid >/dev/null 2>&1
			else
				ss-tunnel -c $CONFIG_FILE -l $DNS_PORT -L "$gs" $ARG_OBFS -u -f /var/run/sstunnel.pid >/dev/null 2>&1
			fi
		fi
	fi

	# Start dnscrypt-proxy
	if [ "3" == "$ss_dns_foreign" ];then
		echo_date 开启 dnscrypt-proxy，你选择了"$ss_opendns"节点.
		dnscrypt-proxy --local-address=127.0.0.1:$DNS_PORT --daemonize -L /koolshare/ss/rules/dnscrypt-resolvers.csv -R $ss_opendns >/dev/null 2>&1
	fi

	
	# Start pdnsd
	if [ "4" == "$ss_dns_foreign"  ]; then
		echo_date 开启 pdnsd，pdnsd进程可能会不稳定，请自己斟酌.
		echo_date 创建/koolshare/ss/pdnsd文件夹.
		mkdir -p /koolshare/ss/pdnsd
		if [ "$ss_pdnsd_method" == "1" ];then
			echo_date 创建pdnsd配置文件到/koolshare/ss/pdnsd/pdnsd.conf
			echo_date 你选择了-仅udp查询-，需要开启上游dns服务，以防止dns污染.
			cat > /koolshare/ss/pdnsd/pdnsd.conf <<-EOF
				global {
					perm_cache=2048;
					cache_dir="/koolshare/ss/pdnsd/";
					run_as="nobody";
					server_port = $DNS_PORT;
					server_ip = 127.0.0.1;
					status_ctl = on;
					query_method=udp_only;
					min_ttl=$ss_pdnsd_server_cache_min;
					max_ttl=$ss_pdnsd_server_cache_max;
					timeout=10;
				}
				
				server {
					label= "RT-AC68U"; 
					ip = 127.0.0.1;
					port = 1099;
					root_server = on;   
					uptest = none;    
				}
				EOF
			if [ "$ss_pdnsd_udp_server" == "1" ];then
				echo_date 开启dns2socks作为pdnsd的上游服务器.
				#echo_date 开启ss-local,为dns2socks提供socks5端口：23456
				#start_sslocal
				dns2socks 127.0.0.1:23456 "$ss_pdnsd_udp_server_dns2socks" 127.0.0.1:1099 > /dev/null 2>&1 &
			elif [ "$ss_pdnsd_udp_server" == "2" ];then
				echo_date 开启dnscrypt-proxy作为pdnsd的上游服务器.
				dnscrypt-proxy --local-address=127.0.0.1:1099 --daemonize -L /koolshare/ss/rules/dnscrypt-resolvers.csv -R "$ss_pdnsd_udp_server_dnscrypt"
			elif [ "$ss_pdnsd_udp_server" == "3" ];then
				[ "$ss_pdnsd_udp_server_ss_tunnel" == "1" ] && dns1="208.67.220.220:53"
				[ "$ss_pdnsd_udp_server_ss_tunnel" == "2" ] && dns1="8.8.8.8:53"
				[ "$ss_pdnsd_udp_server_ss_tunnel" == "3" ] && dns1="8.8.4.4:53"
				[ "$ss_pdnsd_udp_server_ss_tunnel" == "4" ] && dns1="$ss_pdnsd_udp_server_ss_tunnel_user"
				if [ "$ss_basic_type" == "1" ];then
					echo_date 开启ssr-tunnel作为pdnsd的上游服务器.
					rss-tunnel -c $CONFIG_FILE -l 1099 -L "$dns1" -u -f /var/run/sstunnel.pid >/dev/null 2>&1
				elif  [ "$ss_basic_type" == "0" ];then
					echo_date 开启ss-tunnel作为pdnsd的上游服务器.
					if [ "$ss_basic_ss_obfs" == "0" ];then
						ss-tunnel -s $ss_basic_server -p $ss_basic_port -m $ss_basic_method -k $ss_basic_password -l $DNS_PORT -L "$dns1" -u -f /var/run/sstunnel.pid >/dev/null 2>&1
					else
						ss-tunnel -s $ss_basic_server -p $ss_basic_port -m $ss_basic_method -k $ss_basic_password -l $DNS_PORT -L "$dns1" $ARG_OBFS -u -f /var/run/sstunnel.pid >/dev/null 2>&1
					fi
				fi
			fi
		elif [ "$ss_pdnsd_method" == "2" ];then
			echo_date 创建pdnsd配置文件到/koolshare/ss/pdnsd/pdnsd.conf
			echo_date 你选择了-仅tcp查询-，使用"$ss_pdnsd_server_ip":"$ss_pdnsd_server_port"进行tcp查询.
			cat > /koolshare/ss/pdnsd/pdnsd.conf <<-EOF
				global {
					perm_cache=2048;
					cache_dir="/koolshare/ss/pdnsd/";
					run_as="nobody";
					server_port = $DNS_PORT;
					server_ip = 127.0.0.1;
					status_ctl = on;
					query_method=tcp_only;
					min_ttl=$ss_pdnsd_server_cache_min;
					max_ttl=$ss_pdnsd_server_cache_max;
					timeout=10;
				}
				
				server {
					label= "RT-AC68U"; 
					ip = $ss_pdnsd_server_ip;
					port = $ss_pdnsd_server_port;
					root_server = on;   
					uptest = none;    
				}
				EOF
		fi
		
		chmod 644 /koolshare/ss/pdnsd/pdnsd.conf
		CACHEDIR=/koolshare/ss/pdnsd
		CACHE=/koolshare/ss/pdnsd/pdnsd.cache
		USER=nobody
		GROUP=nogroup
	
		if ! test -f "$CACHE"; then
			echo_date 创建pdnsd缓存文件.
			#dd if=/dev/zero of=/koolshare/ss/pdnsd/pdnsd.cache bs=1 count=4 2> /dev/null
			touch /koolshare/ss/pdnsd/pdnsd.cache
			chown -R $USER.$GROUP $CACHEDIR 2> /dev/null
		fi

		echo_date 启动pdnsd进程...
		#pdnsd --daemon -c /koolshare/ss/pdnsd/pdnsd.conf -p /var/run/pdnsd.pid
		pdnsd -c /koolshare/ss/pdnsd/pdnsd.conf -p /var/run/pdnsd.pid >/dev/null 2>&1 &
	fi

	# Start chinadns
	if [ "5" == "$ss_dns_foreign" ];then
		echo_date ┏你选择了chinaDNS作为解析方案！
		[ "$ss_chinadns_china" == "1" ] && rcc="223.5.5.5"
		[ "$ss_chinadns_china" == "2" ] && rcc="223.6.6.6"
		[ "$ss_chinadns_china" == "3" ] && rcc="114.114.114.114"
		[ "$ss_chinadns_china" == "4" ] && rcc="114.114.115.115"
		[ "$ss_chinadns_china" == "5" ] && rcc="1.2.4.8"
		[ "$ss_chinadns_china" == "6" ] && rcc="210.2.4.8"
		[ "$ss_chinadns_china" == "7" ] && rcc="112.124.47.27"
		[ "$ss_chinadns_china" == "8" ] && rcc="114.215.126.16"
		[ "$ss_chinadns_china" == "9" ] && rcc="180.76.76.76"
		[ "$ss_chinadns_china" == "10" ] && rcc="119.29.29.29"
		[ "$ss_chinadns_china" == "11" ] && rcc="$ss_chinadns_china_user"

		if [ "$ss_chinadns_foreign_method" == "1" ];then
			[ "$ss_chinadns_foreign_dns2socks" == "1" ] && rcfd="208.67.220.220:53"
			[ "$ss_chinadns_foreign_dns2socks" == "2" ] && rcfd="8.8.8.8:53"
			[ "$ss_chinadns_foreign_dns2socks" == "3" ] && rcfd="8.8.4.4:53"
			[ "$ss_chinadns_foreign_dns2socks" == "4" ] && rcfd="$ss_chinadns_foreign_dns2socks_user"
			#echo_date ┣开启ss-local,为dns2socks提供socks5端口：23456
			#start_sslocal
			echo_date ┣开启dns2socks，作为chinaDNS上游国外dns，转发dns：$rcfd
			dns2socks 127.0.0.1:23456 "$rcfd" 127.0.0.1:1055 > /dev/null 2>&1 &
		elif [ "$ss_chinadns_foreign_method" == "2" ];then
			echo_date ┣开启 dnscrypt-proxy，作为chinaDNS上游国外dns，你选择了"$ss_chinadns_foreign_dnscrypt"节点.
			dnscrypt-proxy --local-address=127.0.0.1:1055 --daemonize -L /koolshare/ss/rules/dnscrypt-resolvers.csv -R $ss_chinadns_foreign_dnscrypt >/dev/null 2>&1
		elif [ "$ss_chinadns_foreign_method" == "3" ];then
			[ "$ss_chinadns_foreign_sstunnel" == "1" ] && rcfs="208.67.220.220:53"
			[ "$ss_chinadns_foreign_sstunnel" == "2" ] && rcfs="8.8.8.8:53"
			[ "$ss_chinadns_foreign_sstunnel" == "3" ] && rcfs="8.8.4.4:53"
			[ "$ss_chinadns_foreign_sstunnel" == "4" ] && rcfs="$ss_chinadns_foreign_sstunnel_user"
			if [ "$ss_basic_type" == "1" ];then
				echo_date ┣开启ssr-tunnel，作为chinaDNS上游国外dns，转发dns：$rcfs
				rss-tunnel -b 127.0.0.1 -c $CONFIG_FILE -l 1055 -L "$rcfs" -u -f /var/run/sstunnel.pid >/dev/null 2>&1
			elif  [ "$ss_basic_type" == "0" ];then
				echo_date ┣开启ss-tunnel，作为chinaDNS上游国外dns，转发dns：$rcfs
				if [ "$ss_basic_ss_obfs" == "0" ];then
					ss-tunnel -s $ss_basic_server -p $ss_basic_port -m $ss_basic_method -k $ss_basic_password -l 1055 -L "$rcfs" -u -f /var/run/sstunnel.pid
				else
					ss-tunnel -s $ss_basic_server -p $ss_basic_port -m $ss_basic_method -k $ss_basic_password -l 1055 -L "$rcfs" $ARG_OBFS -u -f /var/run/sstunnel.pid >/dev/null 2>&1
				fi
			fi
		elif [ "$ss_chinadns_foreign_method" == "4" ];then
			echo_date ┣你选择了自定义chinadns国外dns！dns：$ss_chinadns_foreign_method_user
		fi
		echo_date ┗开启chinadns进程！
		chinadns -p $DNS_PORT -s "$rcc",127.0.0.1:1055 -m -d -c /koolshare/ss/rules/chnroute.txt  >/dev/null 2>&1 &
	fi
	# Start Pcap_DNSProxy
	if [ "6" == "$ss_dns_foreign" ]; then
		echo_date 开启Pcap_DNSProxy..
		Pcap_DNSProxy -c /koolshare/ss/dns
	fi
}
#--------------------------------------------------------------------------------------

load_cdn_site(){
	# append china site
	rm -rf /tmp/sscdn.conf

	if [ "$ss_dns_plan" == "2" ] && [ "$ss_dns_foreign" != "5" ] && [ "$ss_dns_foreign" != "6" ];then
		echo_date 生成cdn加速列表到/tmp/sscdn.conf，加速用的dns：$CDN
		echo "#for china site CDN acclerate" >> /tmp/sscdn.conf
		cat /koolshare/ss/rules/cdn.txt | sed "s/^/server=&\/./g" | sed "s/$/\/&$CDN/g" | sort | awk '{if ($0!=line) print;line=$0}' >>/tmp/sscdn.conf
	fi

	# append user defined china site
	if [ ! -z "$ss_isp_website_web" ];then
		cdnsites=$(echo $ss_isp_website_web | base64_decode)
		echo_date 生成自定义cdn加速域名到/tmp/sscdn.conf
		echo "#for user defined china site CDN acclerate" >> /tmp/sscdn.conf
		for cdnsite in $cdnsites
		do
			echo "$cdnsite" | sed "s/^/server=&\/./g" | sed "s/$/\/&$CDN/g" >> /tmp/sscdn.conf
		done
	fi
}

custom_dnsmasq(){
	rm -rf /tmp/custom.conf
	if [ ! -z "$ss_dnsmasq" ];then
		echo_date 添加自定义dnsmasq设置到/tmp/custom.conf
		echo "$ss_dnsmasq" | base64_decode | sort -u >> /tmp/custom.conf
	fi
}

append_white_black_conf(){
	# append white domain list, bypass ss
	rm -rf /tmp/wblist.conf
	# github need to go ss
	if [ "$ss_basic_mode" != "6" ];then
		echo "#for router itself" >> /tmp/wblist.conf
		echo "server=/.google.com.tw/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.google.com.tw/router" >> /tmp/wblist.conf
		echo "server=/.github.com/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.github.com/router" >> /tmp/wblist.conf
		echo "server=/.github.io/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.github.io/router" >> /tmp/wblist.conf
		echo "server=/.raw.githubusercontent.com/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.raw.githubusercontent.com/router" >> /tmp/wblist.conf
		echo "server=/.adblockplus.org/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.adblockplus.org/router" >> /tmp/wblist.conf
		echo "server=/.entware.net/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.entware.net/router" >> /tmp/wblist.conf
		echo "server=/.apnic.net/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.apnic.net/router" >> /tmp/wblist.conf
	fi
	# append white domain list,not through ss
	wanwhitedomain=$(echo $ss_wan_white_domain | base64_decode)
	if [ ! -z $ss_wan_white_domain ];then
		echo_date 应用域名白名单
		echo "#for white_domain" >> /tmp/wblist.conf
		for wan_white_domain in $wanwhitedomain
		do 
			echo "$wan_white_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/$CDN#53/g" >> /tmp/wblist.conf
			echo "$wan_white_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_list/g" >> /tmp/wblist.conf
		done
	fi
	
	# apple 和microsoft不能走ss
	echo "#for special site" >> /tmp/wblist.conf
	for wan_white_domain2 in "apple.com" "microsoft.com"
	do 
		echo "$wan_white_domain2" | sed "s/^/server=&\/./g" | sed "s/$/\/$CDN#53/g" >> /tmp/wblist.conf
		echo "$wan_white_domain2" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_list/g" >> /tmp/wblist.conf
	done
	
	# append black domain list,through ss
	wanblackdomain=$(echo $ss_wan_black_domain | base64_decode)
	if [ ! -z $ss_wan_black_domain ];then
		echo_date 应用域名黑名单
		echo "#for black_domain" >> /tmp/wblist.conf
		for wan_black_domain in $wanblackdomain
		do 
			echo "$wan_black_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/127.0.0.1#7913/g" >> /tmp/wblist.conf
			echo "$wan_black_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/black_list/g" >> /tmp/wblist.conf
		done
	fi
}

ln_conf(){
	# custom dnsmasq
	rm -rf /jffs/configs/dnsmasq.d/custom.conf
	if [ -f /tmp/custom.conf ];then
		#echo_date 创建域自定义dnsmasq配置文件软链接到/jffs/configs/dnsmasq.d/custom.conf
		ln -sf /tmp/custom.conf /jffs/configs/dnsmasq.d/custom.conf
	fi
	
	# custom dnsmasq
	rm -rf /jffs/configs/dnsmasq.d/wblist.conf
	if [ -f /tmp/wblist.conf ];then
		#echo_date 创建域名黑/白名单软链接到/jffs/configs/dnsmasq.d/wblist.conf
		mv -f /tmp/wblist.conf /jffs/configs/dnsmasq.d/wblist.conf
	fi
	rm -rf /jffs/configs/dnsmasq.d/cdn.conf
	if [ -f /tmp/sscdn.conf ];then
		#echo_date 创建cdn加速列表软链接/jffs/configs/dnsmasq.d/cdn.conf
		mv -f /tmp/sscdn.conf /jffs/configs/dnsmasq.d/cdn.conf
	fi

	gfw_on=`dbus list ss_acl_mode_|cut -d "=" -f 2 | grep 1`
	chn_on=`dbus list ss_acl_mode_|cut -d "=" -f 2 | grep -E "2|3"`
	rm -rf /jffs/configs/dnsmasq.d/gfwlist.conf
	if [ "$ss_basic_mode" == "1" ];then
		echo_date 创建gfwlist的软连接到/jffs/etc/dnsmasq.d/文件夹.
		ln -sf /koolshare/ss/rules/gfwlist.conf /jffs/configs/dnsmasq.d/gfwlist.conf
	elif [ "$ss_basic_mode" == "2" ] || [ "$ss_basic_mode" == "3" ];then
		if [ ! -f /jffs/configs/dnsmasq.d/gfwlist.conf ] && [ "$ss_dns_plan" == "1" ] || [ -n "$gfw_on" ];then
			echo_date 创建gfwlist的软连接到/jffs/etc/dnsmasq.d/文件夹.
			ln -sf /koolshare/ss/rules/gfwlist.conf /jffs/configs/dnsmasq.d/gfwlist.conf
		fi
	fi

	#echo_date 创建dnsmasq.postconf软连接到/jffs/scripts/文件夹.
	rm -rf /jffs/scripts/dnsmasq.postconf
	ln -sf /koolshare/ss/rules/dnsmasq.postconf /jffs/scripts/dnsmasq.postconf
}

#--------------------------------------------------------------------------------------
start_kcp(){
	# Start kcp
	if [ "$ss_basic_use_kcp" == "1" ];then
		echo_date 启动KCP协议进程，为了更好的体验，建议在路由器上创建虚拟内存.
		export GOGC=30
		[ -z "$ss_basic_kcp_server" ] && ss_basic_kcp_server="$ss_basic_server"
		if [ "$ss_basic_kcp_method" == "1" ];then
			[ -n "$ss_basic_kcp_encrypt" ] && KCP_CRYPT="--crypt $ss_basic_kcp_encrypt"
			[ -n "$ss_basic_kcp_password" ] && KCP_KEY="--key $ss_basic_kcp_password" || KCP_KEY=""
			[ -n "$ss_basic_kcp_sndwnd" ] && KCP_SNDWND="--sndwnd $ss_basic_kcp_sndwnd" || KCP_SNDWND=""
			[ -n "$ss_basic_kcp_rcvwnd" ] && KCP_RNDWND="--rcvwnd $ss_basic_kcp_rcvwnd" || KCP_RNDWND=""
			[ -n "$ss_basic_kcp_mtu" ] && KCP_MTU="--mtu $ss_basic_kcp_mtu" || KCP_MTU=""
			[ -n "$ss_basic_kcp_conn" ] && KCP_CONN="--conn $ss_basic_kcp_conn" || KCP_CONN=""
			[ "$ss_basic_kcp_nocomp" == "1" ] && COMP="--nocomp" || COMP=""
			[ -n "$ss_basic_kcp_mode" ] && KCP_MODE="--mode $ss_basic_kcp_mode" || KCP_MODE=""

			start-stop-daemon -S -q -b -m \
			-p /tmp/var/kcp.pid \
			-x /koolshare/bin/client_linux_arm7 \
			-- -l 127.0.0.1:1091 \
			-r $ss_basic_kcp_server:$ss_basic_kcp_port \
			$KCP_CRYPT $KCP_KEY $KCP_SNDWND $KCP_RNDWND $KCP_MTU $KCP_CONN $COMP $KCP_MODE $ss_basic_kcp_extra
		else
			start-stop-daemon -S -q -b -m \
			-p /tmp/var/kcp.pid \
			-x /koolshare/bin/client_linux_arm7 \
			-- -l 127.0.0.1:1091 \
			-r $ss_basic_kcp_server:$ss_basic_kcp_port \
			$ss_basic_kcp_parameter
		fi
	fi
}

start_speeder(){
	#只有游戏模式下或者访问控制中有游戏模式主机，且udp加速节点和当前使用节点一致
	if [ "$ss_basic_use_kcp" == "1" ] && [ "$ss_basic_kcp_server" == "127.0.0.1" ] && [ "$ss_basic_kcp_port" == "1092" ];then
		echo_date 检测到你配置了KCP与UDPspeeder串联.
		SPEED_KCP=1
	fi
	
	if [ "$ss_basic_use_kcp" == "1" ] && [ "$ss_basic_kcp_server" == "127.0.0.1" ] && [ "$ss_basic_kcp_port" == "1093" ];then
		echo_date 检测到你配置了KCP与UDP2raw串联.
		SPEED_KCP=2
	fi
		
	if [ "$mangle" == "1" ] && [ "$ss_basic_udp_node" == "$ssconf_basic_node" ] || [ "$SPEED_KCP" == "1" ] || [ "$SPEED_KCP" == "2" ];then
		#开启udpspeeder
		if [ "$ss_basic_udp_boost_enable" == "1" ];then
			if [ "$ss_basic_udp_software" == "1" ];then
				echo_date 开启UDPspeederV1进程.
				[ -n "$ss_basic_udpv1_duplicate_time" ] && duplicate_time="-t $ss_basic_udpv1_duplicate_time" || duplicate_time=""
				[ -n "$ss_basic_udpv1_jitter" ] && jitter="-j $ss_basic_udpv1_jitter" || jitter=""
				[ -n "$ss_basic_udpv1_report" ] && report="--report $ss_basic_udpv1_report" || report=""
				[ -n "$ss_basic_udpv1_drop" ] && drop="--random-drop $ss_basic_udpv1_drop" || drop=""
				[ -n "$ss_basic_udpv1_duplicate_nu" ] && duplicate="-d $ss_basic_udpv1_duplicate_nu" || duplicate=""
				[ -n "$ss_basic_udpv1_password" ] && key1="-k $ss_basic_udpv1_password" || key1=""
				[ "$ss_basic_udpv1_disable_filter" == "1" ] && filter="--disable-filter" || filter=""

				if [ "$ss_basic_udp2raw_boost_enable" == "1" ];then
					#串联：如果两者都开启了，则把udpspeeder的流udp量转发给udp2raw
					speederv1 -c -l 0.0.0.0:1092 -r 127.0.0.1:1093 $key1 $ss_basic_udpv1_password \
					$duplicate_time $jitter $report $drop $filter $duplicate $ss_basic_udpv1_duplicate_nu >/dev/null 2>&1 &
					#如果只开启了udpspeeder，则把udpspeeder的流udp量转发给服务器
				else
					speederv1 -c -l 0.0.0.0:1092 -r $ss_basic_udpv1_rserver:$ss_basic_udpv1_rport $key1 \
					$duplicate_time $jitter $report $drop $filter $duplicate $ss_basic_udpv1_duplicate_nu >/dev/null 2>&1 &
				fi
			elif [ "$ss_basic_udp_software" == "2" ];then
				echo_date 开启UDPspeederV2进程.
				[ "$ss_basic_udpv2_disableobscure" == "1" ] && disable_obscure="--disable-obscure" || disable_obscure=""
				[ -n "$ss_basic_udpv2_timeout" ] && timeout="--timeout $ss_basic_udpv2_timeout" || timeout=""
				[ -n "$ss_basic_udpv2_mode" ] && mode="--mode $ss_basic_udpv2_mode" || mode=""
				[ -n "$ss_basic_udpv2_report" ] && report="--report $ss_basic_udpv2_report" || report=""
				[ -n "$ss_basic_udpv2_mtu" ] && mtu="--mtu $ss_basic_udpv2_mtu" || mtu=""
				[ -n "$ss_basic_udpv2_jitter" ] && jitter="--jitter $ss_basic_udpv2_jitter" || jitter=""
				[ -n "$ss_basic_udpv2_interval" ] && interval="-interval $ss_basic_udpv2_interval" || interval=""
				[ -n "$ss_basic_udpv2_drop" ] && drop="-random-drop $ss_basic_udpv2_drop" || drop=""
				[ -n "$ss_basic_udpv2_password" ] && key2="-k $ss_basic_udpv2_password" || key2=""
				[ -n "$ss_basic_udpv2_fec" ] && fec="-f $ss_basic_udpv2_fec" || fec=""

				if [ "$ss_basic_udp2raw_boost_enable" == "1" ];then
					#串联：如果两者都开启了，则把udpspeeder的流udp量转发给udp2raw
					speederv2 -c -l 0.0.0.0:1092 -r 127.0.0.1:1093 $key2 \
					$fec $timeout $mode $report $mtu $jitter $interval $drop $disable_obscure $ss_basic_udpv2_other --fifo /tmp/fifo.file >/dev/null 2>&1 &
					#如果只开启了udpspeeder，则把udpspeeder的流udp量转发给服务器
				else
					speederv2 -c -l 0.0.0.0:1092 -r $ss_basic_udpv2_rserver:$ss_basic_udpv2_rport $key2 \
					$fec $timeout $mode $report $mtu $jitter $interval $drop $disable_obscure $ss_basic_udpv2_other --fifo /tmp/fifo.file >/dev/null 2>&1 &
				fi
			fi
		fi
		#开启udp2raw
		if [ "$ss_basic_udp2raw_boost_enable" == "1" ];then
			echo_date 开启UDP2raw进程.
			[ "$ss_basic_udp2raw_a" == "1" ] && UD2RAW_EX1="-a" || UD2RAW_EX1=""
			[ "$ss_basic_udp2raw_keeprule" == "1" ] && UD2RAW_EX2="--keep-rule" || UD2RAW_EX2=""
			[ -n "$ss_basic_udp2raw_lowerlevel" ] && UD2RAW_LOW="--lower-level $ss_basic_udp2raw_lowerlevel" || UD2RAW_LOW=""
			[ -n "$ss_basic_udp2raw_password" ] && key3="-k $ss_basic_udp2raw_password" || key3=""
			
			udp2raw -c -l 0.0.0.0:1093 -r $ss_basic_udp2raw_rserver:$ss_basic_udp2raw_rport $key3 $UD2RAW_EX1 $UD2RAW_EX2\
			--raw-mode $ss_basic_udp2raw_rawmode --cipher-mode $ss_basic_udp2raw_ciphermode --auth-mode $ss_basic_udp2raw_authmode \
			$UD2RAW_LOW $ss_basic_udp2raw_other >/dev/null 2>&1 &
		fi
	fi
}

start_ss_redir(){
	if [ "$ss_basic_type" == "1" ];then
		echo_date 开启ssr-redir进程，用于透明代理.
		BIN=rss-redir
		ARG_OBFS=""
	elif  [ "$ss_basic_type" == "0" ];then
		echo_date 开启ss-redir进程，用于透明代理.
		if [ "$ss_basic_ss_obfs" == "0" ];then
			BIN=ss-redir
			ARG_OBFS=""
		else
			BIN=ss-redir
		fi
	fi

	if [ "$ss_basic_udp_boost_enable" == "1" ];then
		#只要udpspeeder开启，不管udp2raw是否开启，均设置为1092,
		SPEED_PORT=1092
	else
		# 如果只开了udp2raw，则需要吧udp转发到1093
		SPEED_PORT=1093
	fi

	if [ "$ss_basic_udp2raw_boost_enable" == "1" ] || [ "$ss_basic_udp_boost_enable" == "1" ];then
		#udp2raw开启，udpspeeder未开启则ss-redir的udp流量应该转发到1093
		SPEED_UDP=1
	fi
	
	if [ "$ss_basic_use_kcp" == "1" ] && [ "$ss_basic_kcp_server" == "127.0.0.1" ] && [ "$ss_basic_kcp_port" == "1092" ];then
		SPEED_KCP=1
	fi
	
	if [ "$ss_basic_use_kcp" == "1" ] && [ "$ss_basic_kcp_server" == "127.0.0.1" ] && [ "$ss_basic_kcp_port" == "1093" ];then
		SPEED_KCP=2
	fi
	# Start ss-redir
	if [ "$ss_basic_use_kcp" == "1" ];then
		if [ "$mangle" == "1" ];then
			if [ "$SPEED_UDP" == "1" ] && [ "$ss_basic_udp_node" == "$ssconf_basic_node" ];then
				# tcp go kcp
				if [ "$SPEED_KCP" == "1" ];then
					echo_date $BIN的 tcp 走kcptun, kcptun的 udp 走 udpspeeder
				elif [ "$SPEED_KCP" == "2" ];then
					echo_date $BIN的 tcp 走kcptun, kcptun的 udp 走 udpraw
				else
					echo_date $BIN的 tcp 走kcptun.
				fi
				$BIN -s 127.0.0.1 -p 1091 -c $CONFIG_FILE $ARG_OBFS -f /var/run/shadowsocks.pid >/dev/null 2>&1
				# udp go udpspeeder
				[ "$ss_basic_udp2raw_boost_enable" == "1" ]  && [ "$ss_basic_udp_boost_enable" == "1" ] && echo_date $BIN的 udp 走udpspeeder, udpspeeder的 udp 走 udpraw
				[ "$ss_basic_udp2raw_boost_enable" == "1" ]  && [ "$ss_basic_udp_boost_enable" != "1" ] && echo_date $BIN的 udp 走udpraw.
				[ "$ss_basic_udp2raw_boost_enable" != "1" ]  && [ "$ss_basic_udp_boost_enable" == "1" ] && echo_date $BIN的 udp 走udpspeeder.
				[ "$ss_basic_udp2raw_boost_enable" != "1" ]  && [ "$ss_basic_udp_boost_enable" != "1" ] && echo_date $BIN的 udp 走$BIN.
				$BIN -s 127.0.0.1 -p $SPEED_PORT -c $CONFIG_FILE $ARG_OBFS -U -f /var/run/shadowsocks.pid >/dev/null 2>&1
			else
				# tcp go kcp
				if [ "$SPEED_KCP" == "1" ];then
					echo_date $BIN的 tcp 走kcptun, kcptun的 udp 走 udpspeeder
				elif [ "$SPEED_KCP" == "2" ];then
					echo_date $BIN的 tcp 走kcptun, kcptun的 udp 走 udpraw
				else
					echo_date $BIN的 tcp 走kcptun.
				fi
				$BIN -s 127.0.0.1 -p 1091 -c $CONFIG_FILE $ARG_OBFS -f /var/run/shadowsocks.pid >/dev/null 2>&1
				# udp go ss
				echo_date $BIN的 udp 走$BIN.
				$BIN -c $CONFIG_FILE $ARG_OBFS -U -f /var/run/shadowsocks.pid >/dev/null 2>&1
			fi
		else
			# tcp only go kcp
			if [ "$SPEED_KCP" == "1" ];then
				echo_date $BIN的 tcp 走kcptun, kcptun的 udp 走 udpspeeder
			elif [ "$SPEED_KCP" == "2" ];then
				echo_date $BIN的 tcp 走kcptun, kcptun的 udp 走 udpraw
			else
				echo_date $BIN的 tcp 走kcptun.
			fi
			echo_date $BIN的 udp 未开启.
			$BIN -s 127.0.0.1 -p 1091 -c $CONFIG_FILE $ARG_OBFS -f /var/run/shadowsocks.pid >/dev/null 2>&1
		fi
	else
		if [ "$mangle" == "1" ];then
			if [ "$SPEED_UDP" == "1" ] && [ "$ss_basic_udp_node" == "$ssconf_basic_node" ];then
				# tcp go ss
				echo_date $BIN的 tcp 走$BIN.
				$BIN -c $CONFIG_FILE $ARG_OBFS -f /var/run/shadowsocks.pid >/dev/null 2>&1
				# udp go udpspeeder
				[ "$ss_basic_udp2raw_boost_enable" == "1" ]  && [ "$ss_basic_udp_boost_enable" == "1" ] && echo_date $BIN的 udp 走udpspeeder, udpspeeder的 udp 走 udpraw
				[ "$ss_basic_udp2raw_boost_enable" == "1" ]  && [ "$ss_basic_udp_boost_enable" != "1" ] && echo_date $BIN的 udp 走udpraw.
				[ "$ss_basic_udp2raw_boost_enable" != "1" ]  && [ "$ss_basic_udp_boost_enable" == "1" ] && echo_date $BIN的 udp 走udpspeeder.
				[ "$ss_basic_udp2raw_boost_enable" != "1" ]  && [ "$ss_basic_udp_boost_enable" != "1" ] && echo_date $BIN的 udp 走$BIN.
				$BIN -s 127.0.0.1 -p $SPEED_PORT -c $CONFIG_FILE $ARG_OBFS -U -f /var/run/shadowsocks.pid >/dev/null 2>&1
			else
				# tcp udp go ss
				echo_date $BIN的 tcp 走$BIN.
				echo_date $BIN的 udp 走$BIN.
				$BIN -c $CONFIG_FILE $ARG_OBFS -u -f /var/run/shadowsocks.pid >/dev/null 2>&1
			fi
		else
			# tcp only go ss
			echo_date $BIN的 tcp 走$BIN.
			echo_date $BIN的 udp 未开启.
			$BIN -c $CONFIG_FILE $ARG_OBFS -f /var/run/shadowsocks.pid >/dev/null 2>&1		
		fi
	fi
	echo_date $BIN 启动完毕！.
	
	start_speeder
}

start_koolgame(){
	# Start koolgame
	pdu=`ps|grep pdu|grep -v grep`
	if [ -z "$pdu" ]; then
	echo_date 开启pdu进程，用于优化mtu...
		pdu br0 /tmp/var/pdu.pid >/dev/null 2>&1
		sleep 1
	fi
	echo_date 开启koolgame主进程...
	start-stop-daemon -S -q -b -m -p /tmp/var/koolgame.pid -x /koolshare/bin/koolgame -- -c $CONFIG_FILE
	
	if [ "$mangle" == "1" ] && [ "$ss_basic_udp_node" == "$ssconf_basic_node" ];then
		if [ "$ss_basic_udp_boost_enable" == "1" ];then
			if [ "$ss_basic_udp_software" == "1" ];then
				echo_date 检测到你启用了UDPspeederV1，但是koolgame下不支持UDPspeederV1加速，不启用！
				dbus set ss_basic_udp_boost_enable=0
			elif [ "$ss_basic_udp_software" == "2" ];then
				echo_date 检测到你启用了UDPspeederV2，但是koolgame下不支持UDPspeederV1加速，不启用！
				dbus set ss_basic_udp_boost_enable=0
			fi
		fi
		if [ "$ss_basic_udp2raw_boost_enable" == "1" ];then
			echo_date 检测到你启用了UDP2raw，但是koolgame下不支持UDP2raw，不启用！
			dbus set ss_basic_udp2raw_boost_enable=0
		fi
	fi
}

write_cron_job(){
	sed -i '/ssupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	if [ "1" == "$ss_basic_rule_update" ]; then
		echo_date 添加ss规则定时更新任务，每天"$ss_basic_rule_update_time"自动检测更新规则.
		cru a ssupdate "0 $ss_basic_rule_update_time * * * /bin/sh /koolshare/scripts/ss_rule_update.sh"
	else
		echo_date ss规则定时更新任务未启用！
	fi
	sed -i '/ssnodeupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	if [ "$ss_basic_node_update" = "1" ];then
		if [ "$ss_basic_node_update_day" = "7" ];then
			cru a ssnodeupdate "0 $ss_basic_node_update_hr * * * /koolshare/scripts/ss_online_update.sh 3"
			echo_date "设置订阅服务器自动更新订阅服务器在每天 $ss_basic_node_update_hr 点。"
		else
			cru a ssnodeupdate "0 $ss_basic_node_update_hr * * ss_basic_node_update_day /koolshare/scripts/ss_online_update.sh 3"
			echo_date "设置订阅服务器自动更新订阅服务器在星期 $ss_basic_node_update_day 的 $ss_basic_node_update_hr 点。"
		fi
	fi
}

kill_cron_job(){
	if [ -n "`cru l|grep ssupdate`" ];then
		echo_date 删除ss规则定时更新任务.
		sed -i '/ssupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
	if [ -n "`cru l|grep ssnodeupdate`" ];then
		echo_date 删除SSR定时订阅任务.
		sed -i '/ssnodeupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
}
#--------------------------------------nat part begin------------------------------------------------
load_tproxy(){
	#MODULES="nf_tproxy_core xt_TPROXY xt_socket xt_comment"
	MODULES="xt_TPROXY xt_socket xt_comment"
	OS=$(uname -r)
	# load Kernel Modules
	echo_date 加载TPROXY模块，用于udp转发...
	checkmoduleisloaded(){
		if lsmod | grep $MODULE &> /dev/null; then return 0; else return 1; fi;
	}
	
	for MODULE in $MODULES; do
		if ! checkmoduleisloaded; then
			insmod /lib/modules/${OS}/kernel/net/netfilter/${MODULE}.ko
		fi
	done
	
	modules_loaded=0
	
	for MODULE in $MODULES; do
		if checkmoduleisloaded; then
			modules_loaded=$(( j++ )); 
		fi
	done
	
	if [ $modules_loaded -ne 2 ]; then
		echo "One or more modules are missing, only $(( modules_loaded+1 )) are loaded. Can't start.";
		exit 1;
	fi
}

flush_nat(){
	echo_date 清除iptables规则...
	# flush rules and set if any
	iptables -t nat -D PREROUTING -p tcp -j SHADOWSOCKS >/dev/null 2>&1
	sleep 1
	iptables -t nat -F SHADOWSOCKS > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS > /dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_EXT > /dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_GFW > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_GFW > /dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_CHN > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_CHN > /dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_GAM > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_GAM > /dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_GLO > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_GLO > /dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_HOM > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_HOM > /dev/null 2>&1
	iptables -t mangle -D PREROUTING -p udp -j SHADOWSOCKS >/dev/null 2>&1
	iptables -t mangle -F SHADOWSOCKS >/dev/null 2>&1 && iptables -t mangle -X SHADOWSOCKS >/dev/null 2>&1
	iptables -t mangle -F SHADOWSOCKS_GAM > /dev/null 2>&1 && iptables -t mangle -X SHADOWSOCKS_GAM > /dev/null 2>&1
	iptables -t nat -D OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 3333 >/dev/null 2>&1
	iptables -t nat -F OUTPUT > /dev/null 2>&1
	iptables -t nat -X SHADOWSOCKS_EXT > /dev/null 2>&1
	iptables -t nat -D PREROUTING -p udp --dport 53 -j DNAT --to $lan_ipaddr >/dev/null 2>&1 
	iptables -t mangle -D QOSO0 -m mark --mark "$ip_prefix_hex" -j RETURN >/dev/null 2>&1
}

flush_ipset(){
	echo_date 清空ipset名单...
	ipset -F chnroute >/dev/null 2>&1 && ipset -X chnroute >/dev/null 2>&1
	ipset -F white_list >/dev/null 2>&1 && ipset -X white_list >/dev/null 2>&1
	ipset -F black_list >/dev/null 2>&1 && ipset -X black_list >/dev/null 2>&1
	ipset -F gfwlist >/dev/null 2>&1 && ipset -X gfwlist >/dev/null 2>&1
	ipset -F router >/dev/null 2>&1 && ipset -X router >/dev/null 2>&1
}

remove_redundant_rule(){
	ip_rule_exist=`ip rule show | grep "lookup 310" | grep -c 310`
	#ip_rule_exist=`ip rule show | grep "fwmark 0x07 lookup 310" | grep -c 300`
	if [ ! -z "ip_rule_exist" ];then
		echo_date 清除重复的ip rule规则.
		until [ "$ip_rule_exist" = 0 ]
		do 
			IP_ARG=`ip rule show | grep "lookup 310"|head -n 1|cut -d " " -f3,4,5,6`
			ip rule del $IP_ARG
			ip_rule_exist=`expr $ip_rule_exist - 1`
		done
	fi
}

remove_route_table(){
	echo_date 删除ip route规则.
	ip route del local 0.0.0.0/0 dev lo table 310 >/dev/null 2>&1
}

# creat ipset rules
creat_ipset(){
	echo_date 创建ipset名单
	ipset -! create white_list nethash && ipset flush white_list
	ipset -! create black_list nethash && ipset flush black_list
	ipset -! create gfwlist nethash && ipset flush gfwlist
	ipset -! create router nethash && ipset flush router
	ipset -! create chnroute nethash && ipset flush chnroute
	sed -e "s/^/add chnroute &/g" /koolshare/ss/rules/chnroute.txt | awk '{print $0} END{print "COMMIT"}' | ipset -R
}

add_white_black_ip(){
	# black ip/cidr
	ip_tg="149.154.0.0/16 91.108.4.0/22 91.108.56.0/24 109.239.140.0/24 67.198.55.0/24"
	for ip in $ip_tg
	do
		ipset -! add black_list $ip >/dev/null 2>&1
	done
	
	if [ ! -z $ss_wan_black_ip ];then
		ss_wan_black_ip=`dbus get ss_wan_black_ip|base64_decode|sed '/\#/d'`
		echo_date 应用IP/CIDR黑名单
		for ip in $ss_wan_black_ip
		do
			ipset -! add black_list $ip >/dev/null 2>&1
		done
	fi
	
	# white ip/cidr
	ip1=$(nvram get wan0_ipaddr | cut -d"." -f1,2)
	[ -n "$ss_basic_server_ip" ] && SERVER_IP=$ss_basic_server_ip || SERVER_IP=""
	ISP_DNS1=$(nvram get wan0_dns|sed 's/ /\n/g'|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 1p)
	ISP_DNS2=$(nvram get wan0_dns|sed 's/ /\n/g'|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 2p)
	ip_lan="0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4 $ip1.0.0/16 $SERVER_IP 223.5.5.5 223.6.6.6 114.114.114.114 114.114.115.115 1.2.4.8 210.2.4.8 112.124.47.27 114.215.126.16 180.76.76.76 119.29.29.29 $ISP_DNS1 $ISP_DNS2"
	for ip in $ip_lan
	do
		ipset -! add white_list $ip >/dev/null 2>&1
	done
	
	if [ ! -z $ss_wan_white_ip ];then
		ss_wan_white_ip=`echo $ss_wan_white_ip|base64_decode|sed '/\#/d'`
		echo_date 应用IP/CIDR白名单
		for ip in $ss_wan_white_ip
		do
			ipset -! add white_list $ip >/dev/null 2>&1
		done
	fi
}

get_action_chain() {
	case "$1" in
		0)
			echo "RETURN"
		;;
		1)
			echo "SHADOWSOCKS_GFW"
		;;
		2)
			echo "SHADOWSOCKS_CHN"
		;;
		3)
			echo "SHADOWSOCKS_GAM"
		;;
		5)
			echo "SHADOWSOCKS_GLO"
		;;
		6)
			echo "SHADOWSOCKS_HOM"
		;;
	esac
}

get_mode_name() {
	case "$1" in
		0)
			echo "不通过SS"
		;;
		1)
			echo "gfwlist模式"
		;;
		2)
			echo "大陆白名单模式"
		;;
		3)
			echo "游戏模式"
		;;
		5)
			echo "全局模式"
		;;
		6)
			echo "回国模式"
		;;
	esac
}

factor(){
	if [ -z "$1" ] || [ -z "$2" ]; then
		echo ""
	else
		echo "$2 $1"
	fi
}

get_jump_mode(){
	case "$1" in
		0)
			echo "j"
		;;
		*)
			echo "g"
		;;
	esac
}

lan_acess_control(){
	# lan access control
	acl_nu=`dbus list ss_acl_mode|sort -n -t "=" -k 2|cut -d "=" -f 1 | cut -d "_" -f 4`
	if [ -n "$acl_nu" ]; then
		for acl in $acl_nu
		do
			ipaddr=`dbus get ss_acl_ip_$acl`
			ipaddr_hex=`dbus get ss_acl_ip_$acl | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("%02x\n", $4)}'`
			ports=`dbus get ss_acl_port_$acl`
			proxy_mode=`dbus get ss_acl_mode_$acl`
			proxy_name=`dbus get ss_acl_name_$acl`
			if [ "$ports" == "all" ];then
				ports=""
				echo_date 加载ACL规则：【$ipaddr】【全部端口】模式为：$(get_mode_name $proxy_mode)
			else
				echo_date 加载ACL规则：【$ipaddr】【$ports】模式为：$(get_mode_name $proxy_mode)
			fi
			# 1 acl in SHADOWSOCKS for nat
			iptables -t nat -A SHADOWSOCKS $(factor $ipaddr "-s") -p tcp $(factor $ports "-m multiport --dport") -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
			# 2 acl in OUTPUT（used by koolproxy）
			iptables -t nat -A SHADOWSOCKS_EXT -p tcp  $(factor $ports "-m multiport --dport") -m mark --mark "$ipaddr_hex" -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
			# 3 acl in SHADOWSOCKS for mangle
			if [ "$proxy_mode" == "3" ];then
				iptables -t mangle -A SHADOWSOCKS $(factor $ipaddr "-s") -p udp $(factor $ports "-m multiport --dport") -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
			else
				[ "$mangle" == "1" ] && iptables -t mangle -A SHADOWSOCKS $(factor $ipaddr "-s") -p udp -j RETURN
			fi
		done

		if [ "$ss_acl_default_port" == "all" ];then
			ss_acl_default_port=""
			[ -z "$ss_acl_default_mode" ] && dbus set ss_acl_default_mode="$ss_basic_mode" && ss_acl_default_mode="$ss_basic_mode"
			echo_date 加载ACL规则：【剩余主机】【全部端口】模式为：$(get_mode_name $ss_acl_default_mode)
		else
			echo_date 加载ACL规则：【剩余主机】【$ss_acl_default_port】模式为：$(get_mode_name $ss_acl_default_mode)
		fi
	else
		ss_acl_default_mode="$ss_basic_mode"
		if [ "$ss_acl_default_port" == "all" ];then
			ss_acl_default_port="" 
			echo_date 加载ACL规则：【全部主机】【全部端口】模式为：$(get_mode_name $ss_acl_default_mode)
		else
			echo_date 加载ACL规则：【全部主机】【$ss_acl_default_port】模式为：$(get_mode_name $ss_acl_default_mode)
		fi
	fi
	dbus remove ss_acl_ip
	dbus remove ss_acl_name
	dbus remove ss_acl_mode
	dbus remove ss_acl_port
}

apply_nat_rules(){
	#----------------------BASIC RULES---------------------
	echo_date 写入iptables规则到nat表中...
	# 创建SHADOWSOCKS nat rule
	iptables -t nat -N SHADOWSOCKS
	# 扩展
	iptables -t nat -N SHADOWSOCKS_EXT
	# IP/cidr/白域名 白名单控制（不走ss）
	iptables -t nat -A SHADOWSOCKS -p tcp -m set --match-set white_list dst -j RETURN
	iptables -t nat -A SHADOWSOCKS_EXT -p tcp -m set --match-set white_list dst -j RETURN
	#-----------------------FOR GLOABLE---------------------
	# 创建gfwlist模式nat rule
	iptables -t nat -N SHADOWSOCKS_GLO
	# IP黑名单控制-gfwlist（走ss）
	iptables -t nat -A SHADOWSOCKS_GLO -p tcp -j REDIRECT --to-ports 3333
	#-----------------------FOR GFWLIST---------------------
	# 创建gfwlist模式nat rule
	iptables -t nat -N SHADOWSOCKS_GFW
	# IP/CIDR/黑域名 黑名单控制（走ss）
	iptables -t nat -A SHADOWSOCKS_GFW -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# IP黑名单控制-gfwlist（走ss）
	iptables -t nat -A SHADOWSOCKS_GFW -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-ports 3333
	#-----------------------FOR CHNMODE---------------------
	# 创建大陆白名单模式nat rule
	iptables -t nat -N SHADOWSOCKS_CHN
	# IP/CIDR/域名 黑名单控制（走ss）
	iptables -t nat -A SHADOWSOCKS_CHN -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# cidr黑名单控制-chnroute（走ss）
	iptables -t nat -A SHADOWSOCKS_CHN -p tcp -m set ! --match-set chnroute dst -j REDIRECT --to-ports 3333
	#-----------------------FOR GAMEMODE---------------------
	# 创建游戏模式nat rule
	iptables -t nat -N SHADOWSOCKS_GAM
	# IP/CIDR/域名 黑名单控制（走ss）
	iptables -t nat -A SHADOWSOCKS_GAM -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# cidr黑名单控制-chnroute（走ss）
	iptables -t nat -A SHADOWSOCKS_GAM -p tcp -m set ! --match-set chnroute dst -j REDIRECT --to-ports 3333
	#-----------------------FOR HOMEMODE---------------------
	# 创建回国模式nat rule
	 iptables -t nat -N SHADOWSOCKS_HOM
	# IP/CIDR/域名 黑名单控制（走ss）
	iptables -t nat -A SHADOWSOCKS_HOM -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# cidr黑名单控制-chnroute（走ss）
	iptables -t nat -A SHADOWSOCKS_HOM -p tcp -m set --match-set chnroute dst -j REDIRECT --to-ports 3333

	[ "$mangle" == "1" ] && load_tproxy
	[ "$mangle" == "1" ] && ip rule add fwmark 0x07 table 310
	[ "$mangle" == "1" ] && ip route add local 0.0.0.0/0 dev lo table 310
	# 创建游戏模式udp rule
	[ "$mangle" == "1" ] && iptables -t mangle -N SHADOWSOCKS
	# IP/cidr/白域名 白名单控制（不走ss）
	[ "$mangle" == "1" ] && iptables -t mangle -A SHADOWSOCKS -p udp -m set --match-set white_list dst -j RETURN
	# 创建游戏模式udp rule
	[ "$mangle" == "1" ] && iptables -t mangle -N SHADOWSOCKS_GAM
	# IP/CIDR/域名 黑名单控制（走ss）
	[ "$mangle" == "1" ] && iptables -t mangle -A SHADOWSOCKS_GAM -p udp -m set --match-set black_list dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
	# cidr黑名单控制-chnroute（走ss）
	[ "$mangle" == "1" ] && iptables -t mangle -A SHADOWSOCKS_GAM -p udp -m set ! --match-set chnroute dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
	#-------------------------------------------------------
	# 局域网黑名单（不走ss）/局域网黑名单（走ss）
	lan_acess_control
	#-----------------------FOR ROUTER---------------------
	# router itself
	[ "$ss_basic_mode" != "6" ] && iptables -t nat -A OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 3333
	iptables -t nat -A OUTPUT -p tcp -m mark --mark "$ip_prefix_hex" -j SHADOWSOCKS_EXT
	
	# 把最后剩余流量重定向到相应模式的nat表中对应的主模式的链
	iptables -t nat -A SHADOWSOCKS -p tcp $(factor $ss_acl_default_port "-m multiport --dport") -j $(get_action_chain $ss_acl_default_mode)
	iptables -t nat -A SHADOWSOCKS_EXT -p tcp $(factor $ss_acl_default_port "-m multiport --dport") -j $(get_action_chain $ss_acl_default_mode)
	
	# 如果是主模式游戏模式，则把SHADOWSOCKS链中剩余udp流量转发给SHADOWSOCKS_GAM链
	# 如果主模式不是游戏模式，则不需要把SHADOWSOCKS链中剩余udp流量转发给SHADOWSOCKS_GAM，不然会造成其他模式主机的udp也走游戏模式
	###[ "$mangle" == "1" ] && ss_acl_default_mode=3
	[ "$ss_acl_default_mode" != "0" ] && [ "$ss_acl_default_mode" != "3" ] && ss_acl_default_mode=0
	[ "$ss_basic_mode" == "3" ] && iptables -t mangle -A SHADOWSOCKS -p udp -j $(get_action_chain $ss_acl_default_mode)
	# 重定所有流量到 SHADOWSOCKS
	KP_NU=`iptables -nvL PREROUTING -t nat |sed 1,2d | sed -n '/KOOLPROXY/='|head -n1`
	[ "$KP_NU" == "" ] && KP_NU=0
	INSET_NU=`expr "$KP_NU" + 1`
	iptables -t nat -I PREROUTING "$INSET_NU" -p tcp -j SHADOWSOCKS
	#iptables -t nat -I PREROUTING 1 -p tcp -j SHADOWSOCKS
	[ "$mangle" == "1" ] && iptables -t mangle -A PREROUTING -p udp -j SHADOWSOCKS
	# QOS开启的情况下
	QOSO=`iptables -t mangle -S | grep -o QOSO | wc -l`
	RRULE=`iptables -t mangle -S | grep "A QOSO" | head -n1 | grep RETURN`
	if [ "$QOSO" -gt "1" ] && [ -z "$RRULE" ];then
		iptables -t mangle -I QOSO0 -m mark --mark "$ip_prefix_hex" -j RETURN
	fi
}

chromecast(){
	LOG1=开启chromecast功能（DNS劫持功能）
	LOG2=chromecast功能未开启，建议开启~
	kp_enable=`iptables -t nat -L PREROUTING | grep KOOLPROXY |wc -l`
	kp_mode=`dbus get koolproxy_policy`
	chromecast_nu=`iptables -t nat -L PREROUTING -v -n --line-numbers|grep "dpt:53"|awk '{print $1}'`
	if [ "$ss_basic_chromecast" == "1" ];then
		if [ -z "$chromecast_nu" ]; then
			IPT_ACTION="-A"
			echo_date $LOG1
		else
			echo_date DNS劫持规则已经添加，跳过~
		fi
	else
		if [ "$kp_mode" != 2 ] || [ "$kp_enable" -eq 0 ]; then
			if [ -n "$chromecast_nu" ]; then
				IPT_ACTION="-D"
				echo_date $LOG2
			fi
		else
			if [ -z "$chromecast_nu" ]; then
				IPT_ACTION="-A"
				echo_date $LOG1
			fi
		fi
	fi	
	iptables -t nat $IPT_ACTION PREROUTING -p udp --dport 53 -j DNAT --to $lan_ipaddr >/dev/null 2>&1
}
# -----------------------------------nat part end--------------------------------------------------------

restart_dnsmasq(){
	# Restart dnsmasq
	echo_date 重启dnsmasq服务...
	service restart_dnsmasq >/dev/null 2>&1
}

load_module(){
	xt=`lsmod | grep xt_set`
	OS=$(uname -r)
	if [ -f /lib/modules/${OS}/kernel/net/netfilter/xt_set.ko ] && [ -z "$xt" ];then
		echo_date "加载xt_set.ko内核模块！"
		insmod /lib/modules/${OS}/kernel/net/netfilter/xt_set.ko
	fi
}

restart_addon(){
	# for sleep walue in start up files
	old_sleep=`cat /jffs/scripts/nat-start | grep sleep | awk '{print $2}'`
	new_sleep="$ss_basic_sleep"
	if [ "$old_sleep" = "$new_sleep" ];then
		echo_date 开机延迟时间未改变，仍然是"$ss_basic_sleep"秒.
	else
		echo_date 设置"$ss_basic_sleep"秒开机延迟...
	fi
	
	if [ "$ss_basic_dnslookup" == "1" ];then
		echo_date 设置使用nslookup方式解析SS服务器的ip地址.
	else
		echo_date 设置使用resolveip方式解析SS服务器的ip地址.
	fi
}

# write number into nvram with no commit
write_numbers(){
	nvram set update_ipset="$(cat /koolshare/ss/rules/version | sed -n 1p | sed 's/#/\n/g'| sed -n 1p)"
	nvram set update_chnroute="$(cat /koolshare/ss/rules/version | sed -n 2p | sed 's/#/\n/g'| sed -n 1p)"
	nvram set update_cdn="$(cat /koolshare/ss/rules/version | sed -n 4p | sed 's/#/\n/g'| sed -n 1p)"
	nvram set update_Routing="$(cat /koolshare/ss/rules/version | sed -n 5p | sed 's/#/\n/g'| sed -n 1p)"
	nvram set update_WhiteList="$(cat /koolshare/ss/rules/version | sed -n 7p | sed 's/#/\n/g'| sed -n 1p)"
	nvram set ipset_numbers=$(cat /koolshare/ss/rules/gfwlist.conf | grep -c ipset)
	nvram set chnroute_numbers=$(cat /koolshare/ss/rules/chnroute.txt | grep -c .)
	nvram set cdn_numbers=$(cat /koolshare/ss/rules/cdn.txt | grep -c .)
	nvram set Routing_numbers=$(cat /koolshare/ss/dns/Routing.txt |grep -c /)
	nvram set WhiteList_numbers=$(cat /koolshare/ss/dns/WhiteList.txt |grep -Ec "Server=")
}

set_ulimit(){
	ulimit -n 16384
}

disable_ss(){
	echo_date =============== 梅林固件 - shadowsocks by sadoneli\&Xiaobao ===============
	echo_date
	echo_date -------------------------- 关闭Shadowsocks ------------------------------
	nvram set ss_mode=0
	dbus set dns2socks=0
	nvram commit
	restore_conf
	remove_conf_and_settings
	restart_dnsmasq
	flush_nat
	flush_ipset
	remove_redundant_rule
	remove_route_table
	kill_process
	kill_cron_job
	echo_date -------------------------- Shadowsocks已关闭 -----------------------------
}

load_nat(){
	nat_ready=$(iptables -t nat -L PREROUTING -v -n --line-numbers|grep -v PREROUTING|grep -v destination)
	i=120
	until [ -n "$nat_ready" ]
	do
	    i=$(($i-1))
	    if [ "$i" -lt 1 ];then
	        echo_date "错误：不能正确加载nat规则!"
	        disable_ss
	        exit
	    fi
	    sleep 2
	done
	echo_date "加载nat规则!"
	flush_nat
	flush_ipset
	remove_redundant_rule
	remove_route_table
	creat_ipset
	add_white_black_ip
	apply_nat_rules
	chromecast
}

apply_ss(){
	# router is on boot
	WAN_ACTION=`ps|grep /jffs/scripts/wan-start|grep -v grep`
	# now stop first
	echo_date =============== 梅林固件 - shadowsocks by sadoneli\&Xiaobao ===============
	echo_date
	echo_date -------------------------- 关闭Shadowsocks ------------------------------
	nvram set ss_mode=0
	dbus set dns2socks=0
	nvram commit
	restore_conf
	remove_conf_and_settings
	# restart dnsmasq when ss server is not ip or on router boot
	[ -z "$IFIP" ] && [ -z "$WAN_ACTION" ] && restart_dnsmasq
	flush_nat
	flush_ipset
	remove_redundant_rule
	remove_route_table
	kill_process
	kill_cron_job
	echo_date -------------------------- Shadowsocks已关闭 -----------------------------
	# pre-start
	echo_date ----------------------- shadowsocks 启动前触发脚本 -----------------------
	ss_pre_start
	# start
	echo_date ------------------------- 梅林固件 shadowsocks --------------------------
	resolv_server_ip
	# do not re generate json on router start, use old one
	[ -z "$WAN_ACTION" ] && creat_ss_json
	#creat_dnsmasq_basic_conf
	load_cdn_site
	custom_dnsmasq
	append_white_black_conf && ln_conf
	write_cron_job
	[ "$ss_basic_type" != "2" ] && start_dns
	[ "$ss_basic_type" != "2" ] && start_ss_redir || start_koolgame
	[ "$ss_basic_type" != "2" ] && start_kcp
	load_module
	#===load nat start===
	load_nat
	#===load nat end===
	restart_addon
	restart_dnsmasq
	echo_date ------------------------- shadowsocks 启动完毕 -------------------------
}
# =========================================================================

case $ACTION in
start)
	if [ "$ss_basic_enable" == "1" ];then
		logger "[软件中心]: 启动科学上网插件！"
		[ "$ss_basic_sleep" != "0" ] && sleep $ss_basic_sleep
		set_ulimit >> /tmp/syslog.log
		apply_ss >> /tmp/syslog.log
    	write_numbers >> /tmp/syslog.log
	else
		logger "[软件中心]: 科学上网插件未开启，不启动！"
	fi
	;;
stop)
	disable_ss
	echo_date
	echo_date 你已经成功关闭shadowsocks服务~
	echo_date See you again!
	echo_date
	echo_date =============== 梅林固件 - shadowsocks by sadoneli\&Xiaobao ===============
	;;
restart)
	set_ulimit
	apply_ss
	write_numbers
	echo_date
	echo_date "Across the Great Wall we can reach every corner in the world!"
	echo_date
	echo_date =============== 梅林固件 - shadowsocks by sadoneli\&Xiaobao ===============
	dbus fire onssstart
	# creat nat locker
	[ ! -f "/tmp/shadowsocks.nat_lock" ] && touch /tmp/shadowsocks.nat_lock
	return 0
	;;
update)
	update_ss
	;;
start_nat)
	if [ "$ss_basic_enable" == "1" ];then
		WAN_ACTION=`ps|grep /jffs/scripts/wan-start|grep -v grep`
		[ -n "$WAN_ACTION" ] && exit 0
		# detect nat locker,do not restart nat on reouter boot
		[ ! -f "/tmp/shadowsocks.nat_lock" ] && exit 0
		flush_nat
		flush_ipset
		remove_redundant_rule
		remove_route_table
		creat_ipset
		add_white_black_ip
		apply_nat_rules
		chromecast
	fi
	;;
esac
