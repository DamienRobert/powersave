pkg_dir=$(prefix)/usr/local/lib/powersave
etc_dir=$(prefix)/etc
bin_dir=$(pkg_dir)/bin
factory_dir=$(pkg_dir)/factory
rsync=rsync -vcrlp

define munge
sed -i -e 's|@LIB_DIR@|$(lib_dir)|' \
    $(1)
endef

define install_dir
mkdir -p $(2)/
$(rsync) $(1)/ $(2)
endef

define uninstall_dir
$(foreach f,$(shell cd $(1)/; find . -type f), rm $(2)/$(f);)
$(foreach f,$(shell cd $(1)/; find . -depth -type d), rmdir --ignore-fail-on-non-empty $(2)/$(f);)
endef

install:
	$(call install_dir,etc,$(DESTDIR)/$(etc_dir))
	$(call install_dir,bin,$(DESTDIR)/$(bin_dir))
	$(call install_dir,factory,$(DESTDIR)/$(factory_dir))

uninstall:
	$(call uninstall_dir,etc,$(DESTDIR)/$(etc_dir))
	$(call uninstall_dir,bin,$(DESTDIR)/$(bin_dir))
	$(call uninstall_dir,factory,$(DESTDIR)/$(factory_dir))
