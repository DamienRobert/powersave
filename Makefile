install:
	install -D powersave $(DESTDIR)/usr/local/bin/powersave
	install -D 50-powersave.rules $(DESTDIR)/etc/udev/rules.d/50-powersave.rules
