install:
	install -D powersave $(DESTDIR)/usr/local/bin/powersave
	install -D -m 644 powersave.config $(DESTDIR)/usr/local/factory/powersave.config
	install -D -m 644 rules.d/50-powersave.rules $(DESTDIR)/etc/udev/rules.d/50-powersave.rules
