GO_EASY_ON_ME=1
THEOS_DEVICE_IP=guest-room.local
DEBUG=1
#FINALPACKAGE=0
ARCH=arm64
export ARCH=arm64
ARCHS=arm64

target = iphone
include $(THEOS)/makefiles/common.mk

TOOL_NAME = classdumpios
classdumpios_CFLAGS = -fobjc-arc -I. -include Classes/Extensions/ext.h -include ../class-dump-Prefix.pch -I$(wildcard *.*h) -I$(wildcard "Classes/**") -IClasses/Extensions -IClasses/Core
classdumpios_CFLAGS += -IClasses/Cursors -IClasses/Extras -IClasses/Extensions -IClasses/FileManagement -IClasses/LoadCommands
classdumpios_CFLAGS += -IClasses/OC -IClasses/ObjC -IClasses/Structure -IClasses/Type -IClasses/Visitors
classdumpios_FILES = $(wildcard *.*m) $(wildcard Classes/*.m) $(wildcard Classes/Core/*.m)
classdumpios_FILES += $(wildcard Classes/Cursors/*.m) $(wildcard Classes/Extensions/*.m)
classdumpios_FILES += $(wildcard Classes/Extras/*.m) $(wildcard Classes/FileManagement/*.m)
classdumpios_FILES += $(wildcard Classes/OC/*.m) $(wildcard Classes/LoadCommands/*.m)
classdumpios_FILES += $(wildcard Classes/ObjC/*.m) $(wildcard Classes/Structure/*.m)
classdumpios_FILES += $(wildcard Classes/Type/*.m) $(wildcard Classes/Visitors/*.m)
include $(THEOS_MAKE_PATH)/tool.mk
