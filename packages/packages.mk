PKG_DIR := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

.PHONY : packages packages_clean
clean : packages_clean

define PKG_IS_SET
$(strip $(or \
	$(findstring y, $1), \
	$(findstring Y, $1), \
))
endef

define PKG_INCLUDE_RULE
ifneq '$(call PKG_IS_SET, $1)' ''
packages : $2
packages_clean : $2_clean
endif
check_latest : $2_check_latest
endef

include $(PKG_DIR)/mtd-utils/mtd-utils.mk
include $(PKG_DIR)/mdadm/mdadm.mk
include $(PKG_DIR)/e2fsprogs/e2fsprogs.mk
include $(PKG_DIR)/zlib/zlib.mk
include $(PKG_DIR)/dropbear/dropbear.mk
include $(PKG_DIR)/libroxml/libroxml.mk
