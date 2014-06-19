install:
	install -D powersave $(DESTDIR)/usr/local/bin/powersave
	install -D powersave.config $(DESTDIR)/etc/powersave.config
	install -D -m 644 50-powersave.rules $(DESTDIR)/etc/udev/rules.d/50-powersave.rules
