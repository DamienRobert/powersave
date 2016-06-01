# Powersave

This is a fork of <https://github.com/Unia/Powersave> which was based on the
thread from <http://crunchbanglinux.org/forums/topic/11954> (but now
currently always enables powersaving via udev rules).

The inspiration for the integration with systemd comes from
<https://github.com/intelfx/power-management>.

For more informations on the udev rule disabling the polling, see also
<http://cgit.freedesktop.org/udisks/commit/?id=fb86ef144bad470b3d8ed761c7bdbe94886e5edd>.

See the directory `doc/ex-etc` for examples, and how one could
put everything into udev rules, so that the powersave configuration is always
enabled.

## Copyright

Copyright © 2014–2016 Damien Robert

MIT License. See {file:COPYING} for more details.
