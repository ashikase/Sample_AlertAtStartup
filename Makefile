include theos/makefiles/common.mk

TWEAK_NAME = AlertAtStartup
AlertAtStartup_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

distclean: clean
	- rm -f $(THEOS_PROJECT_DIR)/$(APP_ID)*.deb
	- rm -f $(THEOS_PROJECT_DIR)/.theos/packages/*
