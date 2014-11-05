pkg_dir=$(prefix)/usr/local/lib/powersave
bin_dir=$(pkg_dir)/bin
factory_dir=$(pkg_dir)/factory
etc_dir=$(prefix)/etc
rsync=rsync -vcrlp

install_pattern=\
  etc:$(DESTDIR)/$(etc_dir) \
  bin:$(DESTDIR)/$(bin_dir) \
  factory:$(DESTDIR)/$(factory_dir)

munge_files=\
  $(DESTDIR)/$(etc_dir)/systemd/system/power-performance.service \
  $(DESTDIR)/$(etc_dir)/systemd/system/power-save.service \
  $(DESTDIR)/$(etc_dir)/rules.d/50-powersave.rules \
  $(DESTDIR)/$(bin_dir)/powersave

define munge
sed -i -e \
  's|@PKG_DIR@|$(pkg_dir)|' \
  's|@FACTORY_DIR@|$(factory_dir)|' \
  's|@BIN_DIR@|$(bin_dir)|' \
  's|@ETC_DIR@|$(etc_dir)|' \
    $(1)
endef

define install_dir
mkdir -p $(2)/
$(rsync) $(1)/ $(2)
endef

define list_in_dir
$(patsubst $(1)%,%,$(shell find $(1) $(2)))
endef

define rm_dirs
rmdir --ignore-fail-on-non-empty $(1)
endef

define uninstall_dir
$(foreach f,$(call list_in_dir,$(1),-not -type d), rm $(2)/$(f);)
$(foreach f,$(call list_in_dir,$(1),-depth -type d), rmdir --ignore-fail-on-non-empty $(2)/$(f);)
endef

install:
	$(foreach inout,$(install_pattern), \
	  $(eval in = $(word 1,$(subst :, ,$(inout)))) \
	  $(eval out = $(word 2,$(subst :, ,$(inout)))) \
	  $(call install_dir,$(in),$(out));)
	$(foreach f,$(munge_files),$(call munge,$(f));)

uninstall:
	$(foreach inout,$(install_pattern), \
	  $(eval in = $(word 1,$(subst :, ,$(inout)))) \
	  $(eval out = $(word 2,$(subst :, ,$(inout)))) \
	  $(call uninstall_dir,$(in),$(out));)
	$(call rm_dirs,$(DESTDIR)/$(factory_dir) $(DESTDIR)/$(bin_dir) $(DESTDIR)/$(etc_dir) $(DESTDIR)/$(pkg_dir))
