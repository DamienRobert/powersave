lib_dir=$(prefix)/usr/local/lib/powersave
etc_dir=$(prefix)/etc

define munge_install
sed -e 's|@LIB_DIR@|$(lib_dir)|' \
    $(1) >$(2)
endef

install:
	install -D -m 644 etc/systemd/power-performance.target $(DESTDIR)/etc/systemd/system/power-performance.target
	install -D -m 644 etc/systemd/power-save.target $(DESTDIR)/etc/systemd/system/power-save.target
	$(call munge_install,etc/systemd/power-performance.service,$(DESTDIR)/$(etc_dir)/systemd/system/power-performance.service)
	$(call munge_install,etc/systemd/power-powersave.service,$(DESTDIR)/$(etc_dir)/systemd/system/power-powersave.service)
	install -D -m 644 etc/rules.d/50-powersave.rules $(DESTDIR)/etc/rules.d/50-powersave.rules
	install -D powersave $(DESTDIR)/usr/local/bin/powersave
	install -D -m 644 powersave.config $(DESTDIR)/usr/local/factory/powersave.config
	install -D -m 644 rules.d/50-powersave.rules $(DESTDIR)/etc/udev/rules.d/50-powersave.rules
