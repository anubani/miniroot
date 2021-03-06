# this package could be broken: TO TEST & FIX

PKG_DROPBEAR_SERVER ?= no
PKG_DROPBEAR_CLIENT ?= no
DROPBEAR_SRC ?= 0.52
DROPBEAR_PATCH_DIR ?=
DROPBEAR_DL_DIR ?= $(DL_DIR)
DROPBEAR_SRC_DIR ?= $(DROPBEAR_SRC_AUTODIR)
#DROPBEAR_BUILD_INSIDE = no
DROPBEAR_RC_SCRIPT ?= /etc/rc.dropbear

DROPBEAR_DEPS = zlib

DROPBEAR_DIR := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

DROPBEAR_URL = http://matt.ucc.asn.au/dropbear/releases
# if DROPBEAR_SRC is a version number
ifeq '$(call IS_SRC, $(DROPBEAR_SRC))' ''
override DROPBEAR_SRC := $(DROPBEAR_URL)/dropbear-$(strip $(DROPBEAR_SRC)).tar.bz2
endif

DROPBEAR_SRC_AUTODIR := $(shell $(TOOLS_DIR)/get_src_dir.sh '$(SRC_DIR)' '$(DROPBEAR_SRC)')
DROPBEAR_BUILD_DIR := $(if $(DROPBEAR_BUILD_INSIDE), $(DROPBEAR_SRC_DIR), $(TARGET_BUILD_DIR)/$(notdir $(DROPBEAR_SRC_DIR)))
DROPBEAR_BUILD_MAKEFILE := $(DROPBEAR_BUILD_DIR)/Makefile
DROPBEAR_BUILD_CONFIG := $(DROPBEAR_SRC_DIR)/options.h
DROPBEAR_BUILD_BIN := $(DROPBEAR_BUILD_DIR)/dropbearmulti
DROPBEAR_INSTALL_BIN := $(ROOT_BUILD_DIR)/sbin/$(notdir $(DROPBEAR_BUILD_BIN))
DROPBEAR_INSTALL_SERVER_ALIAS  = $(ROOT_BUILD_DIR)/sbin/dropbear
DROPBEAR_INSTALL_CLIENT1_ALIAS = $(ROOT_BUILD_DIR)/bin/dbclient
DROPBEAR_INSTALL_CLIENT2_ALIAS = $(ROOT_BUILD_DIR)/bin/ssh
DROPBEAR_INSTALL_KEYGEN_ALIAS  = $(ROOT_BUILD_DIR)/bin/dropbearkey

.PHONY : dropbear dropbear_init dropbear_clean dropbear_check_latest
$(eval $(call PKG_INCLUDE_RULE, $(PKG_DROPBEAR_SERVER) $(PKG_DROPBEAR_CLIENT), dropbear))

dropbear : $(DROPBEAR_DEPS) $(DROPBEAR_INSTALL_BIN)

dropbear_init : $(TOOLCHAIN_DEP)
	@ printf '\n=== DROPBEAR (package not tested) ===\n'

$(DROPBEAR_SRC_DIR) :
	@ $(TOOLS_DIR)/init_src.sh '$(DROPBEAR_SRC)' '$(DROPBEAR_DL_DIR)' '$@' '$(DROPBEAR_PATCH_DIR)'

define DROPBEAR_DISABLE_FEATURE
sed -i 's,^\(#define.*$1.*\),/*\1*/,' $(DROPBEAR_BUILD_CONFIG)
endef

$(DROPBEAR_BUILD_MAKEFILE) : | $(DROPBEAR_SRC_DIR)
	mkdir -p $(@D)
	cd $(@D) && \
		$(SET_PATH) $(SET_CC) $(SET_CFLAGS) $(SET_LDFLAGS) \
		$(abspath $|)/configure \
			$(CONFIGURE_HOST) \
			--srcdir='$(abspath $|)' \
			--with-zlib='$(abspath $(ZLIB_BUILD_DIR))' \
			--disable-lastlog \
			--disable-utmp \
			--disable-utmp \
			--disable-wtmpx \
			--disable-wtmpx \
			--disable-loginfunc \
			--disable-pututline \
			--disable-pututxline
	$(call DROPBEAR_DISABLE_FEATURE, DROPBEAR_BLOWFISH)
	$(call DROPBEAR_DISABLE_FEATURE, DROPBEAR_TWOFISH)
	$(call DROPBEAR_DISABLE_FEATURE, DROPBEAR_MD5_HMAC)
	$(call DROPBEAR_DISABLE_FEATURE, ENABLE_.*FWD)
	$(call DROPBEAR_DISABLE_FEATURE, DO_MOTD)

$(DROPBEAR_BUILD_BIN) : dropbear_init $(DROPBEAR_BUILD_MAKEFILE)
	$(SET_PATH) $(MAKE) -C $(@D) $(@F) \
	MULTI=1 PROGRAMS='$(strip \
		$(if $(call PKG_IS_SET, $(PKG_DROPBEAR_SERVER)), dropbear dropbearkey) \
		$(if $(call PKG_IS_SET, $(PKG_DROPBEAR_CLIENT)), dbclient) \
	)'

$(DROPBEAR_INSTALL_BIN) : $(DROPBEAR_BUILD_BIN)
	install -D $< $@
	$(if $(call PKG_IS_SET, $(PKG_DROPBEAR_SERVER)), \
		install -D $(DROPBEAR_DIR)/dropbear.sh $(ROOT_BUILD_DIR)$(DROPBEAR_RC_SCRIPT) && \
		ln -snf $(@F) $(DROPBEAR_INSTALL_SERVER_ALIAS) && \
		ln -snf ../sbin/$(@F) $(DROPBEAR_INSTALL_KEYGEN_ALIAS) \
	)
	$(if $(call PKG_IS_SET, $(PKG_DROPBEAR_CLIENT)), \
		ln -snf ../sbin/$(@F) $(DROPBEAR_INSTALL_CLIENT1_ALIAS) && \
		ln -snf ../sbin/$(@F) $(DROPBEAR_INSTALL_CLIENT2_ALIAS) \
	)

dropbear_clean :
	- $(if $(DROPBEAR_BUILD_INSIDE), \
		$(MAKE) -C $(DROPBEAR_BUILD_DIR) clean, \
		rm -rf $(DROPBEAR_BUILD_DIR) ) # make clean is broken in libtommath
	- rm -f $(DROPBEAR_INSTALL_BIN)
	- rm -f $(DROPBEAR_INSTALL_SERVER_ALIAS)
	- rm -f $(DROPBEAR_INSTALL_KEYGEN_ALIAS)
	- rm -f $(DROPBEAR_INSTALL_CLIENT1_ALIAS)
	- rm -f $(DROPBEAR_INSTALL_CLIENT2_ALIAS)

dropbear_check_latest :
	@ $(call CHECK_LATEST_ARCHIVE, head, http://matt.ucc.asn.au/dropbear/dropbear.html)
