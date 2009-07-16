.PHONY : check_latest

check_latest : linux_check_latest busybox_check_latest \
	zlib_check_latest dropbear_check_latest \
	e2fsprogs_check_latest mdadm_check_latest \
	libroxml_check_latest

# CHECK_LATEST <package> <PACKAGE> <latest version>
# print default and latest version
define CHECK_LATEST
	echo "default $(strip $1): $(strip $(call GET_DEFAULT_VERSION, $1, $2))"
	echo " latest $(strip $1): $(strip $3)"
endef

# GET_DEFAULT_VERSION <package> <PACKAGE>
# print default version
define GET_DEFAULT_VERSION
	$(shell \
		sed -n 's,^$(strip $2)_SRC *?= *\([^ ]*\).*,\1,p' \
		$($(strip $2)_DIR)/$(strip $1).mk \
	)
endef

# GET_TARBALL_VERSION <package> <extension> <head|tail> <www>
# print version of a tarball from the web page
define GET_TARBALL_VERSION
	$(shell \
		$(call WWW_DUMP, http://$(strip $4)) | \
		sed -n 's,.*http://.*/$(strip $1)-\(.*\).tar.$(strip $2).*,\1,p' | \
		$3 -n1 \
	)
endef
define WWW_DUMP
	$(if $(shell which elinks 2>/dev/null), \
		elinks -dump $1, \
		$(if $(shell which lynx 2>/dev/null), \
			lynx -dump $1 \
		) \
	)
endef

# CHECK_LATEST_TARBALL_FOR <package> <extension> <head|tail> <www>
# print default and latest version from the web page for the package
# extension should be gz or bz2
# filter first or last tarball with head or tail
define CHECK_LATEST_TARBALL_FOR
	$(call CHECK_LATEST, \
		$1, \
		$(shell echo $1 | tr '[:lower:]' '[:upper:]'), \
		$(call GET_TARBALL_VERSION, $1, $2, $3, $4) \
	)
endef

# CHECK_LATEST_TARBALL <extension> <head|tail> <www>
# print default and latest version from the web page for the implicit package
# extension should be gz or bz2
# filter first or last tarball with head or tail
define CHECK_LATEST_TARBALL
	$(call CHECK_LATEST_TARBALL_FOR, $(@:_check_latest=), $1, $2, $3)
endef
