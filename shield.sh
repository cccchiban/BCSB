#!/bin/bash

if ! command -v iptables &> /dev/null
then
    echo "iptables未安装，正在安装..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "debian" || "$ID" == "ubuntu" ]]; then
            sudo apt update && sudo apt install -y iptables
        elif [[ "$ID" == "centos" || "$ID" == "rhel" ]]; then
            sudo yum install -y iptables
        elif [[ "$ID" == "fedora" ]]; then
            sudo dnf install -y iptables
        else
            echo "未知的操作系统，无法自动安装iptables，请手动安装。"
            exit 1
        fi
    else
        echo "无法确定操作系统，请手动安装iptables。"
        exit 1
    fi
    echo "iptables安装完成。"
else
    echo "iptables已安装。"
fi

# 定义要屏蔽的网站
blocked_domains=(
    "rfa.org" "bbc.com" "theinitium.com" "tibet.net" "jw.org"
    "bannedbook.org" "dw.com" "storm.mg" "yam.com" "chinadigitaltimes"
    "ltn.com.tw" "mpweekly.com" "cup.com.hk" "thenewslens.com"
    "inside.com.tw" "everylittled.com" "cool3c.com" "taketla.zaiko.io"
    "news.agentm.tw" "sportsv.net" "research.tnlmedia.com" "ad2iction.com"
    "viad.com.tw" "tnlmedia.com" "becomingaces.com" "pincong.rocks"
    "flipboard.com" "soundofhope.org" "wenxuecity.com" "aboluowang.com"
    "2047.name" "shu.best" "shenyunperformingarts.org" "bbc.co.uk"
    "cirosantilli" "wsj.com" "rfi.fr" "chinapress.com.my" "hancel.org"
    "miraheze.org" "zhuichaguoji.org" "fawanghuihui.org" "hopto.org"
    "amnesty.org" "hrw.org" "irmct.org" "zhengjian.org" "wujieliulan.com"
    "dongtaiwang.com" "ultrasurf.us" "yibaochina.com" "roc-taiwan.org"
    "creaders.net" "upmedia.mg" "ydn.com.tw" "udn.com" "theaustralian.com.au"
    "voacantonese.com" "voanews.com" "bitterwinter.org" "christianstudy.com"
    "learnfalungong.com" "usembassy-china.org.cn" "master-li.qi-gong.me"
    "zhengwunet.org" "modernchinastudies.org" "ninecommentaries.com"
    "dafahao.com" "shenyuncreations.com" "tgcchinese.org" "botanwang.com"
    "falungong" "freedomhouse.org" "abc.net.au" "funmart.beanfun.com"
    "gashpoint.com" "alipay.com" "tenpay.com" "unionpay.com" "yunshanfu.cn"
    "icbc.com.cn" "ccb.com" "boc.cn" "bankcomm.com" "abchina.com"
    "cmbchina.com" "psbc.com" "cebbank.com" "cmbc.com.cn" "pingan.com"
    "spdb.com.cn" "bank.ecitic.com" "cib.com.cn" "hxb.com.cn" "cgbchina.com.cn"
    "jcbcard.cn" "pbccrc.org.cn" "adbc.com.cn" "gamepay.com.tw" "10099.com.cn"
    "10010.com" "189.cn" "10086.cn" "1688.com" "jd.com" "taobao.com"
    "pinduoduo.com" "cctv.com" "cntv.cn" "tianya.cn" "tieba.baidu.com"
    "xuexi.cn" "rednet.cn" "weibo.com" "zhihu.com" "douban.com" "tmall.com"
    "vip.com" "toutiao.com" "zijieapi.com" "xiaomi.cn" "oppo.cn"
    "oneplusbbs.com" "bbs.vivo.com.cn" "club.lenovo.com.cn" "bbs.iqoo.com"
    "realmebbs.com" "rogbbs.asus.com.cn" "bbs.myzte.cn" "club.huawei.com"
    "bbs.meizu.cn" "xiaohongshu.com" "coolapk.com" "bbsuc.cn" "tangdou.com"
    "oneniceapp.com" "izuiyou.com" "pipigx.com" "ixiaochuan.cn" "duitang.com"
    "renren.com" "netvi­ga­tor.com" "tor­pro­ject.org" ".esu.wiki" ".gov.cn"
)

# 定义BT的屏蔽规则
extra_blocked_strings=(
    "torrent" ".torrent" "peer_id=" "announce" "info_hash" "get_peers"
    "find_node" "BitTorrent" "announce_peer" "BitTorrent protocol"
    "announce.php?passkey=" "magnet:" "xunlei" "sandai" "Thunder" "XLLiveUD"
    "ethermine.com" "antpool.one" "antpool.com" "pool.bar" "get_peers"
    "announce_peer" "find_node" "seed_hash"
)

# 定义测速网站的屏蔽规则
speedtest_blocked_strings=(
    ".speed" "speed." ".speed." "fast.com" "speedtest.net" "speedtest.com"
    "speedtest.cn" "test.ustc.edu.cn" "10000.gd.cn" "db.laomoe.com"
    "jiyou.cloud" "ovo.speedtestcustom.com" "speed.cloudflare.com"
    "speedtest"
)

echo "请选择操作："
echo "1) 添加屏蔽规则"
echo "2) 删除屏蔽规则"
read -p "输入选项 (1/2): " action

if [ "$action" == "2" ]; then
    echo "请选择要删除屏蔽规则的类型："
else
    echo "请选择要屏蔽的类型："
fi

echo "1) 屏蔽金融、新闻和轮子等网站"
echo "2) 屏蔽BT和挖矿相关内容"
echo "3) 屏蔽测速网站"
read -p "输入选项 (1/2/3): " choice

case $choice in
    1)
        for domain in "${blocked_domains[@]}"
        do
            if [ "$action" == "2" ]; then
                iptables -D OUTPUT -m string --string "$domain" --algo bm -j DROP
                echo "Unblocked $domain"
            else
                iptables -A OUTPUT -m string --string "$domain" --algo bm -j DROP
                echo "Blocked $domain"
            fi
        done
        ;;
    2)
        for string in "${extra_blocked_strings[@]}"
        do
            if [ "$action" == "2" ]; then
                iptables -D OUTPUT -m string --string "$string" --algo bm -j DROP
                echo "Unblocked $string"
            else
                iptables -A OUTPUT -m string --string "$string" --algo bm -j DROP
                echo "Blocked $string"
            fi
        done
        ;;
    3)
        for string in "${speedtest_blocked_strings[@]}"
        do
            if [ "$action" == "2" ]; then
                iptables -D OUTPUT -m string --string "$string" --algo bm -j DROP
                echo "Unblocked $string"
            else
                iptables -A OUTPUT -m string --string "$string" --algo bm -j DROP
                echo "Blocked $string"
            fi
        done
        ;;
    *)
        echo "无效选项"
        exit 1
        ;;
esac

# 持久化规则
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "debian" || "$ID" == "ubuntu" ]]; then
        if ! command -v netfilter-persistent &> /dev/null
        then
            echo "netfilter-persistent未安装，正在安装..."
            sudo apt update && sudo apt install -y netfilter-persistent
            echo "netfilter-persistent安装完成。"
        fi
        sudo sh -c "iptables-save > /etc/iptables/rules.v4"
        sudo systemctl enable netfilter-persistent
        sudo systemctl restart netfilter-persistent
    elif [[ "$ID" == "centos" || "$ID" == "rhel" || "$ID" == "fedora" ]]; then
        sudo service iptables save
        sudo systemctl restart iptables
    else
        echo "请手动保存iptables规则。"
    fi
else
    echo "无法确定操作系统，请手动保存iptables规则。"
fi

if [ "$action" == "1" ]; then
    echo "所有屏蔽规则已成功添加并生效！"
else
    echo "所有屏蔽规则已成功删除并持久化！"
fi
