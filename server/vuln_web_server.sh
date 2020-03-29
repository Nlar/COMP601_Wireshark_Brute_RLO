#!/bin/bash
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

full_path=$(realpath $0)
full_path=$(dirname $full_path)
filename="$full_path/vuln_web.raw"
snapfilename="$full_path/vuln_snapshot.cow"
ubuntuISOname=$(ls $full_path/ubuntu*.iso)

qemu_initial_start="-name vuln_web \
	-enable-kvm -cpu host \
	-m 2000 -realtime mlock=off -smp 2 \
	-boot menu=on,splash-time=5000 \
    -drive file=$filename,format=raw,index=0 \
    -drive file=$ubuntuISOname,index=1,media=cdrom \
	-vga std \
    -device virtio-net,netdev=network0 -netdev tap,id=network0,ifname=RLO_vul,script=no,downscript=no,vhost=on"
qemu_start=$qemu_initial_start
qemu_consistent_start="-name vuln_web \
	-enable-kvm -cpu host \
	-m 2000 -realtime mlock=off -smp 2 \
	-boot menu=on,splash-time=5000 \
    -drive file=$snapfilename,format=qcow2,index=0 \
	-vga std \
    -device virtio-net,netdev=network0 -netdev tap,id=network0,ifname=RLO_vul,script=no,downscript=no,vhost=on"
if [ ! -f $filename ]; then
    qemu-img create -f raw $filename 3G
fi
if [ -f $snapfilename ]; then
    qemu_start=$qemu_consistent_start
fi

qemu-system-x86_64 $qemu_start

# Device is ideally setup.  Create an image so we can restore later
if [ ! -f $snapfilename ]; then
    qemu-img create -o backing_file=$filename,backing_fmt=raw -f qcow2 vuln_snapshot.cow
    mv ./vuln_snapshot.cow ./server/
fi

# Username Ubuntu Server - vuln
# Ubuntu Server Name - vuln_web


