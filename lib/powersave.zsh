# vim: ft=zsh

powersave_status() {
	local dev

	print_status() {
		for file in $@; do
			[[ -r $file ]] && echo "$file: $(cat $file)"
		done
	}
	case $1 in
		usb)
			#-power/control: on means no suspend, auto mean autosuspend, suspend mean suspend now.
			#- power/autosuspend: give the delay in second for device suspension
			#  (-1 is the same as setting control to on)
			for i in /sys/bus/usb/devices/*/power/; do
				if [[ -e $i/control ]]; then
					echo "$i: control=$(cat $i/control), autosuspend=$(cat $i/autosuspend)"
				fi
			done
			;;
		*)
			get_devices
			echo "*** DEVICES POWER CONTROL ***"
			print_status $buses
			echo "\n*** USB POWER AUTOSUSPEND ***"
			print_status /sys/bus/usb/devices/*/power/autosuspend
			echo "\n*** MISC ***"
			print_status /proc/sys/kernel/nmi_watchdog
			echo "\n*** SOUND ***"
			print_status /sys/module/snd_*/parameters/power_save /sys/module/snd_*/parameters/power_save_controller
			echo "\n*** VIDEO ***"
			print_status /sys/module/pcie_aspm/parameters/policy
			print_status /sys/module/i915/parameters/{powersave,enable_rc6,enable_fbc,lvds_downclock}
			echo "\n*** KERNEL WRITE MODE ***"
			# kernel write mode
			sysctl vm.laptop_mode vm.dirty_writeback_centisecs vm.dirty_expire_centisecs vm.dirty_ratio vm.dirty_background_ratio
			echo "\n*** DISK POWERSAVE ***"
			[[ -n $disks ]] && sudo hdparm -aB $disks
			print_status /sys/class/scsi_host/host*/link_power_management_policy
			echo "\n*** MONITOR, CPU, WIRELESS ***"
			# screen powersave
			print_status /sys/class/backlight/*/brightness
			cpupower frequency-info # cpu
			cpupower info # cpu perf bias
			for dev in $netdevs_wlan; do
				echo -n "- $dev power save:"
				iw dev $dev get power_save
			done
			;;
	esac
}

#return $brightness setting to apply to backlight
#and $cur_brightness
#apply_brightness can be a math expression like '$max_brightness/3'
get_brightness() { #{{{2
	local backlight max_brightness apply_brightness change_mode
	while true;
	do
		case $1 in
			-- ) break ;;
			--auto ) shift
				case $mode in
					powersave) change_mode="decrease" ;; #only decrease brightness
					performance) change_mode="increase" ;; #only increase brightness
				esac ;;
			--increase ) shift; change_mode="increase" ;; #only increase brightness
			--decrease ) shift; change_mode="decrease" ;; #only decrease brightness
			*) break;;
		esac
	done
	if [[ $# -ge 2 ]]; then
		apply_brightness=$1
		backlight=$2
	else
		backlight=$1
	fi
	brightness=
	[[ -e $backlight/brightness ]] || return 1
	max_brightness=9
	[[ -r "$backlight/max_brightness" ]] && max_brightness=$(cat "$backlight/max_brightness")
	[[ -r "$backlight/brightness" ]] && cur_brightness=$(cat "$backlight/brightness")
	[[ -r "$backlight/actual_brightness" ]] && cur_brightness=$(cat "$backlight/actual_brightness")
	if [[ -n $apply_brightness ]]; then
		case $apply_brightness in
			max) apply_brightness='$max_brightness' ;;
			low) apply_brightness='$max_brightness/3' ;;
			min) apply_brightness='$max_brightness/10' ;;
		esac
		eval "(( brightness = $apply_brightness ))"
		case $change_mode in
			increase)
				[[ -n $cur_brightness && $cur_brightness -gt $brightness ]] && brightness=
			;;
			decrease)
				[[ -n $cur_brightness && $cur_brightness -lt $brightness ]] && brightness=
			;;
		esac
	fi
}

set_brightness() {
	local bright light opt
	while true;
	do
		case $1 in
			-- ) break ;;
			--auto|--increase|--decrease ) opt="$1"; shift ;;
			*) break;;
		esac
	done
	bright=$1; shift
	echo "- brigthness: $bright"
	if [[ -n $bright ]]; then
		for light in $@; do
			get_brightness $opt $bright $light
			echo "-> $(basename $light)/brightness: $brightness ($cur_brightness)"
			write_files $brightness "$light/brightness"
		done
	fi
}

write_files() {
	local file value rvalue
	echo "# write_files $@"
	value=$1
	if [[ -n $value ]]; then
		shift
		for file in $@; do
			if [[ -r $file ]]; then
				rvalue=$(<$file)
				[[ $rvalue = $value ]] && return
			fi
			if [[ -n $SUDO_WRITE && $UID -ne 0 ]]; then
				sudo sh -c "echo -n $value > $file"
			else
				if [[ -w $file ]]; then
					echo "echo $value > $file"
					echo -n $value > $file
				fi
			fi
		done
	fi
}

test_connection() {
	ip addr show dev $1 | grep "state UP" >/dev/null 2>&1
}
is_connected() {
	local dev
	connected=
	for dev in $netdevs; do
		test_connection $dev && connected=t
	done
}

test_bt_connection() {
	hciconfig | grep 'UP' >/dev/null 2>&1
}

#from tlp-functions.in:
get_sys_power_supply() { # get current power source
	# rc: 0=ac, 1=battery, 2=unknown
	local psrc
	local rc=
	for psrc in /sys/class/power_supply/*; do
		# -f $psrc/type not necessary - cat 2>.. handles this
		case "$(cat $psrc/type 2> /dev/null)" in
			Mains)
				# AC detected, check if online
				if [ "$(cat $psrc/online 2> /dev/null)" = "1" ]; then
					rc=0
					break
				fi
				# else AC not online => keep $rc as-is
				;;
			Battery)
				# set rc to battery, but don't stop looking for AC
				rc=1
				;;
			*)
				echo "unknown power supply: ${psrc##*/}"
				;;
		esac
	done
	# set rc to unknown if we haven't seen any AC/battery power source so far
	: ${rc:=2}
	return $rc
}

get_systemd_users() {
	local i
	systemd_users=()
	systemd_users_bus=()
	for i in /run/user/*/systemd; do
		systemd_users+=($(id -un ${${i#/run/user/}%/systemd}))
		systemd_users_bus+=("unix:path=${i%/systemd}/bus")
	done
}

run_global_service() {
	local user service bus i
	service=$1
	get_systemd_users
	for ((i=1; i<=$#systemd_users; i++)); do
		user=$systemd_users[i]
		bus=$systemd_users_bus[i]
		echo "Running $service for $user"
		sudo -u $user sh -c "DBUS_SESSION_BUS_ADDRESS='$bus' systemctl --user is-enabled '$service' && systemctl --user --no-block start '$service'"
	done
}
