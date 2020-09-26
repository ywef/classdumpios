GO_EASY_ON_ME=1
THEOS_DEVICE_IP=guest-room.local
DEBUG=1
#FINALPACKAGE=0
target = macosx:10.14:10.12
include $(THEOS)/makefiles/common.mk

TOOL_NAME = classdumpios
classdumpios_CFLAGS = -fobjc-arc -include ext.h
classdumpios_FILES = $(wildcard *.*m)

include $(THEOS_MAKE_PATH)/tool.mk
