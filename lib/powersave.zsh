# vim: ft=zsh

powersave_status() {
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
			print_status() {
				for file in $@; do
					echo "$file: $(cat $file)" 
				done
			}
			echo "*** DEVICES POWER CONTROL ***"
			print_status /sys/bus/*/devices/*/power/control
			echo "*** USB POWER AUTOSUSPEND ***"
			print_status /sys/bus/usb/devices/*/power/autosuspend
			echo "*** MISC ***"
			print_status /proc/sys/kernel/nmi_watchdog
			print_status /sys/module/pcie_aspm/parameters/policy
			echo "*** SOUND ***"
			print_status /sys/module/snd_*/parameters/power_save /sys/module/snd_*/parameters/power_save_controller
			echo "*** KERNEL WRITE MODE ***"
			# kernel write mode
			sysctl vm.laptop_mode vm.dirty_writeback_centisecs vm.dirty_expire_centisecs vm.dirty_ratio vm.dirty_background_ratio
			echo "*** DISK POWERSAVE ***"
			sudo hdparm -B $disks
			print_status /sys/class/scsi_host/host*/link_power_management_policy
			echo "*** MONITOR, CPU, WIRELESS ***"
			# screen powersave
			print_status /sys/class/backlight/*/brightness
			cpupower frequency-info -g # cpu
			for dev in $netdevs_wlan; do
				echo "- $dev power save:"
				iw dev $dev get power_save
			done
			;;
	esac
}

#return $brightness setting to apply to backlight
#and $cur_brightness
#apply_brightness can be a math expression like '$max_brightness/3'
get_brightness() { #{{{2
	local backlight max_brightness apply_brigthness change_mode
	while true;
	do
		case $1 in
			-- ) break ;;
			--increase ) shift; change_mode="increase" ;; #only increase brightness
			--decrease ) shift; change_mode="decrease" ;;
			*) break;;
		esac
	done
	apply_brightness=$1; shift
	backlight=$1;
	brightness=
	[[ -e $backlight/brightness ]] || return 1
	max_brightness=9
	[[ -r "$backlight/max_brightness" ]] && max_brightness=$(cat "$backlight/max_brightness")
	[[ -r "$backlight/brightness" ]] && cur_brightness=$(cat "$backlight/brightness")
	[[ -r "$backlight/actual_brightness" ]] && cur_brightness=$(cat "$backlight/actual_brightness")
	eval "(( brightness = $apply_brightness ))"
	case $change_mode in
		increase)
			[[ -n $cur_brightness && $cur_brightness -gt $brightness ]] && brightness=
		;;
		decrase)
			[[ -n $cur_brightness && $cur_brightness -lt $brightness ]] && brightness=
		;;
	esac
}
