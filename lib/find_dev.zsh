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

find_backlights() {
	backlights=(/sys/class/backlight/*(N))
}

find_displays() {
	local x
	displays=()
	for x in /tmp/.X11-unix/X*(N); do
		displays+=":${$(basename $x)#X}"
	done
}

find_labels() {
	local dev
	labels=()
	for dev in $@; do
		labels+=($(findfs $dev))
	done
}

find_pci_buses() {
	#only go to 2 levels to find pci buses
	pci_buses=(/sys/bus/pci/devices/*/power/control(N) /sys/bus/pci/devices/*/????:??:??.?/power/control(N))
}
find_ahci_buses() {
	#only go to 2 levels to find pci buses
	ahci_buses=(/sys/bus/pci/devices/**/ata*/power/control(N))
}
find_usb_buses() {
	#only go to 2 levels to find pci buses
	usb_buses=(/sys/bus/usb/devices/*/power/control(N))
}
find_buses() {
	find_pci_buses
	find_usb_buses
	find_ahci_buses
	buses=($bci_buses $usb_buses $ahci_buses)
}

find_devices() {
	#only run if disks is not defined
	#to have empty disks just set disks=() in pre_vars
	if [[ -z ${disks+defined} ]]; then
		find_disks --sata
	fi
	if [[ -z ${netdevs+defined} ]]; then
		find_netdevs
	fi
	if [[ -z ${backlights+defined} ]]; then
		find_backlights
	fi
	if [[ -z ${displays+defined} ]]; then
		find_displays
	fi
	if [[ -z ${buses+defined} ]]; then
		find_buses
	fi
}
