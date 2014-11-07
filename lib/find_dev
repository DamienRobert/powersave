# vim: ft=zsh

find_disks() {
	local filter disk args mode
	while true;
	do
		case $1 in
			-- ) break ;;
			--usb ) shift;
				mode='usb'
				filter='ID_BUS=usb';;
			--sata ) shift;
				mode='sata'
				filter='ID_BUS=(ata|scsi|ide)';;
			--filter ) shift;
				filter=$1; shift ;;
			*) break;;
		esac
	done
	disks=()
	[[ -z $@ ]] && args=(/dev/sd?(N) /dev/hd?(N))
	[[ -z $filter ]] && filter=".*"
	for disk in $args; do
		if udevadm info -q all -n $disk | egrep $filter >/dev/null; then
			disks+=($disk)
		fi
	done
}

find_netdevs() {
	local dev sysdir args
	sysdir="/sys/class/net"
	netdevs=()
	netdevs_eth=()
	netdevs_wlan=()
	netdevs_lo=()
	args=($@)
	if [[ -z $args ]]; then
		args=()
		for dev in $sysdir/*(N); do
			args+=$(basename $dev)
		done
	fi
	for dev in $args; do
		netdevs+=($dev)
		[[ -e $sysdir/$dev/device ]] && [[ ! -e $sysdir/$dev/wireless ]] && netdevs_eth+=($dev)
		[[ -e $sysdir/$dev/wireless ]] && netdevs_wlan+=($dev)
		[[ ! -e $sysdir/$dev/device ]] && netdevs_lo+=($dev)
	done
}

find_labels() {
	local dev
	labels=()
	for dev in $@; do
		labels+=($(findfs $dev))
	done
}
