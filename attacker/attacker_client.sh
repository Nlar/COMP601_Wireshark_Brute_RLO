#!/bin/bash
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi
if [ "$1" == "" ] || [ $# -gt 1 ]; then
    vuln_pid="Not Passed"
else
    vuln_pid=$1
fi
full_path=$(realpath $0)
full_path=$(dirname $full_path)
filename="$full_path/att_kali.raw"
snapfilename="$full_path/att_snapshot.cow"
kaliISOname=$(ls $full_path/kali*.iso)
echo $kaliISOname
if [ ! -f $snapfilename ]; then
    # Initial Setup.  Waiting until the vuln server is done
    echo "Initial Setup Detected"
    if [ "$vuln_pid" != "Not Passed" ]; then
        while kill -0 $vuln_pid 2> /dev/null; do
            sleep 10
        done
    fi
fi

qemu_initial_start="-name att_kali \
	-enable-kvm -cpu host \
	-m 4000 -realtime mlock=off -smp 2 \
	-boot menu=on,splash-time=5000 \
    -drive file=$filename,format=raw,index=0 \
    -drive file=$kaliISOname,index=1,media=cdrom \
	-vga std \
    -device virtio-net,netdev=network0 -netdev tap,id=network0,ifname=RLO_kal,script=no,downscript=no,vhost=on"
qemu_start=$qemu_initial_start
qemu_consistent_start="-name att_kali \
	-enable-kvm -cpu host \
	-m 4000 -realtime mlock=off -smp 2 \
	-boot menu=on,splash-time=5000 \
    -drive file=$snapfilename,format=qcow2,index=0 \
	-vga std \
    -device virtio-net,netdev=network0 -netdev tap,id=network0,ifname=RLO_kal,script=no,downscript=no,vhost=on"
if [ ! -f $filename ]; then
    qemu-img create -f raw $filename 25G
fi
if [ -f $snapfilename ]; then
    qemu_start=$qemu_consistent_start
fi

qemu-system-x86_64 $qemu_start

# Device is ideally setup.  Create an image so we can restore later
if [ ! -f $snapfilename ]; then
    qemu-img create -o backing_file=$filename,backing_fmt=raw -f qcow2 att_snapshot.cow
    mv ./att_snapshot.cow ./attacker/
fi

# Computer Name - attkali
# Username Kali Client - default - kali



