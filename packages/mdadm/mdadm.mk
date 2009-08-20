# options can be set in config.mk
PKG_MDADM ?= no
MDADM_SRC ?= 2.6.9
MDADM_PATCH_DIR ?= # [directory]
MDADM_SRC_DIR ?= $(shell $(TOOLS_DIR)/get_src_dir.sh '$(MDADM_DIR)' '$(MDADM_SRC)')
MDADM_BUILD_INSIDE = yes # cannot build mdadm outside

MDADM_DEPS =

MDADM_DIR := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

MDADM_URL = http://kernel.org/pub/linux/utils/raid/mdadm
# if MDADM_SRC is a version number
ifeq ($(strip $(shell $(TOOLS_DIR)/is_src.sh '$(MDADM_SRC)')),false)
override MDADM_SRC := $(MDADM_URL)/mdadm-$(strip $(MDADM_SRC)).tar.bz2
endif

MDADM_BUILD_DIR = $(if $(MDADM_BUILD_INSIDE), $(MDADM_SRC_DIR), $(BUILD_DIR)/$(notdir $(MDADM_SRC_DIR)))
MDADM_BUILD_BIN = $(MDADM_BUILD_DIR)/mdadm
MDADM_INSTALL_BIN = $(ROOT_BUILD_DIR)/sbin/$(notdir $(MDADM_BUILD_BIN))

.PHONY : mdadm_mkfs mdadm_init mdadm_clean mdadm_check_latest
$(eval $(call PKG_INCLUDE_RULE, $(PKG_MDADM), mdadm))

mdadm : $(MDADM_DEPS) $(MDADM_INSTALL_BIN)

mdadm_init : $(TOOLCHAIN_DEP)
	@ printf '\n=== MDADM ===\n'
	@ $(TOOLS_DIR)/init_src.sh '$(MDADM_DIR)' '$(MDADM_SRC)' '$(MDADM_SRC_DIR)' '$(MDADM_PATCH_DIR)'

$(MDADM_BUILD_BIN) : mdadm_init
	$(SET_PATH) $(MAKE) -C $(MDADM_SRC_DIR) mdadm \
		$(if $(MDADM_BUILD_INSIDE), , O='$(abspath $(MDADM_BUILD_DIR))') \
		$(SET_CC) $(SET_CPPFLAGS) $(SET_CFLAGS) $(SET_LDFLAGS)

$(MDADM_INSTALL_BIN) : $(MDADM_BUILD_BIN)
	install -D $(MDADM_BUILD_BIN) $(MDADM_INSTALL_BIN)

mdadm_clean :
	- $(MAKE) -C $(MDADM_SRC_DIR) clean \
		$(if $(MDADM_BUILD_INSIDE), , O='$(abspath $(MDADM_BUILD_DIR))')

mdadm_check_latest :
	@ $(call CHECK_LATEST_TARBALL, bz2, tail, $(MDADM_URL))
