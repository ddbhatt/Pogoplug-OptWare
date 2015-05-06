#!/bin/sh
# for BusyBox v1.16.1 (Pogoplug Series 4)
# Place this script in /root/

# Mount RootFS as readonly
# ========================
mount -o ro,remount /

# Wait till dmesg says LED -> Connected or LED -> MESSAGE or filesystems are mounted
waited=0
while [ "$(dmesg | grep 'LED -> CONNECTED')" == "" ]; do
    #while [ "$(ls /tmp/.cemnt/ | grep mnt)" == "" ]; do
        sleep 1
        waited=$((waited+1))
        if [ ${waited} -ge 300 ]; then
                break
        fi
done

# Mount OptWare USB - Manually
# ============================
# mount -o exec,suid,dev,remount /tmp/.cemnt/mnt_sda1
# mount -o bind /tmp/.cemnt/mnt_sda1/opt /opt

optware_found=false
# Mount OptWare USB
# =================
for f in $(ls /tmp/.cemnt/sd?)
do
    LinuxPart=$(fdisk -l ${f} | grep "Linux" | cut -d" " -f1)
    if [ "${LinuxPart}" != "" ]; then
        mnt_sdx=/tmp/.cemnt/mnt_${LinuxPart##*/tmp/.cemnt/}
        if [ -d ${mnt_sdx}/opt/bin ]; then
            # Defaults rw, suid, dev, exec, auto, nouser, async, and relatime.
            mount -o rw,exec,suid,dev,remount ${mnt_sdx}
            # Bind the opt found on usb to internal
            mount -o bind ${mnt_sdx}/opt /opt
            optware_found=true
        fi
    fi
done

# If OptWare Disk is found and Mounted to /opt then
if [ ${optware_found} == true ];

    # Setup Running of this script on each boot up
    # ============================================
    # Add to /etc/init.d/rcS
    # mount -o ro,remount /

# Check if optware.sh exists in /etc/init.d/rcS or Add if it doesnt
if [ "$(cat /etc/init.d/rcS | grep -o optware.sh)" != "optware.sh" ]; then
mv /etc/nsswitch.conf /etc/nsswitch.conf.original
echo "hosts: files mdns4_minimal [NOTFOUND=return] wins dns mdns4" > /etc/nsswitch.conf
cp /etc/init.d/rcS /etc/init.d/rcS.original
cat << EOF >> /etc/init.d/rcS
nohup /root/optware.sh > /dev/null 2>&1 &
EOF
fi

    # Setup Path to include /opt/bin:/opt/sbin: first
    # ===============================================
    # Modify path in /etc/profile to include /opt/bin and /opt/sbin first or can Export from this script
    # export PATH=/opt/bin:/opt/sbin:/bin:/sbin:/usr/bin:/usr/sbin:/opt/share/pear
    PATH=/opt/bin:/opt/sbin:${PATH}

    # Create rcS file if not existing
    # ===============================
    if [ ! -f /opt/etc/init.d/rcS ]; then
        mkdir -p /opt/etc/init.d/

cat << EOF > /opt/etc/init.d/rcS
#!/bin/sh
mount -o ro,remount /

# Log DateTime of this rcS run
# echo OptWare init.d/rcS Run on $(date) >> /opt/log.txt

# Wait 5 Seconds
sleep 5

# Mount Swap file if it exists
if [ -f /tmp/.cemnt/mnt_sda1/swapfile.img ];then
    # To Make swapfile.img
    # 1) /opt/bin/ipkg install e2fslibs
    # 2) dd if=/dev/zero of=/tmp/.cemnt/mnt_sda1/swapfile.img bs=1M count=512 #for a 1GB swapfile, use count=1024
    # /opt/sbin/mkswap /tmp/.cemnt/mnt_sda1/swapfile.img

    /opt/sbin/swapon /tmp/.cemnt/mnt_sda1/swapfile.img
fi

# Starting Services manually (since I don't need all services all the time)
# ==========================
# /opt/etc/init.d/S80samba start
# /opt/bin/transmission-daemon --config-dir /opt/etc/transmission
# /opt/etc/init.d/S20dbus start 

# Update IP Every 600 Seconds - https://github.com/ddbhatt/Alternative-for-DynDns
# (while true;do curl --silent "http://www.webserver.com/pogoplug/?Password&SET-MY-IP"; sleep 600; done;) > /dev/null 2>&1 &

EOF

    fi

    # Run Init for OptWare
    # ====================
    if [ -f /opt/etc/init.d/rcS ]; then
            /opt/etc/init.d/rcS
    fi

    # Misc Commands
    # =============
    rmdir /opt/ipkg-*
    sync

fi
# For Installing ipkg
# Follow: http://aaronrandall.com/blog/customising-your-pogoplug/
