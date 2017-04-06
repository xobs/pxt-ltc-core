VERSION    = v1.0

TRGT      ?= /opt/codebender/codebender-arduino-core-files/v167/packages/arduino/tools/arm-none-eabi-gcc/gcc-arm-none-eabi-4.8.3-2014q1/bin/arm-none-eabi-
CC         = $(TRGT)gcc
CXX        = $(TRGT)g++
OBJCOPY    = $(TRGT)objcopy

PACKAGE    = pxt-ltc-core
LDSCRIPT   = ld/KL02Z32-app.ld
DBG_CFLAGS = -ggdb -g -DDEBUG -Wall
DBG_LFLAGS = -ggdb -g -Wall
CFLAGS     = $(ADD_CFLAGS) \
             -DVERSION=\"$(VERSION)\" \
             -DARDUINO=160 \
             -I. -Iinc -Isrc -Isrc/core \
             -fsingle-precision-constant -Wall -Wextra \
             -mcpu=cortex-m0plus -mfloat-abi=soft -mthumb \
             -DARDUINO_APP -fno-builtin \
             -ffunction-sections -fdata-sections -fno-common \
             -fomit-frame-pointer -falign-functions=16 -nostdlib -Os
CXXFLAGS   = $(CFLAGS) -std=c++11 -fno-rtti -fno-exceptions
LFLAGS     = $(ADD_LFLAGS) $(PKG_LFLAGS) $(CFLAGS) \
             -nostartfiles -nostdlib -nodefaultlibs \
             -Wl,-Map=$(PROJECT).map,--gc-sections \
             -Wl,--cref,--no-warn-mismatch,--script=$(LDSCRIPT),--build-id=none

OBJ_DIR    = .obj/

CSOURCES   = $(shell find src -name '*.c')
CPPSOURCES = $(shell find src -name '*.cpp')
ASOURCES   = $(wildcard src/*.s)
COBJS      = $(addprefix $(OBJ_DIR)/, $(CSOURCES:.c=.o))
CXXOBJS    = $(addprefix $(OBJ_DIR)/, $(CPPSOURCES:.cpp=.o))
AOBJS      = $(addprefix $(OBJ_DIR)/, $(ASOURCES:.s=.o))
OBJECTS    = $(COBJS) $(CXXOBJS) $(AOBJS)
VPATH = . ../common

QUIET      = @

ALL        = all
TARGET     = $(PACKAGE).elf
DEBUG      = debug
REBUILD    = rebuild
DREBUILD   = drebuild
CLEAN      = clean
CHANGELOG  = ChangeLog.txt
DISTCLEAN  = distclean
DIST       = dist
DDIST      = dailydist
INSTALL    = install
INIT       = init

$(ALL): $(TARGET)

$(OBJECTS): | $(OBJ_DIR)

$(TARGET): $(OBJECTS) $(LDSCRIPT)
	$(QUIET) echo "  LD       $@"
	$(QUIET) $(CXX) $(OBJECTS) $(LFLAGS) -o $@
	$(QUIET) echo "  OBJCOPY  $(PACKAGE).bin"
	$(QUIET) $(OBJCOPY) -O binary $@ $(PACKAGE).bin
	$(QUIET) echo "  OBJCOPY  $(PACKAGE).hex"
	$(QUIET) $(OBJCOPY) -O ihex $@ $(PACKAGE).hex
	$(QUIET) echo "  SYMBOL   $(PACKAGE).symbol"
	$(QUIET) $(OBJCOPY) --only-keep-debug $< $(PACKAGE).symbol 2> /dev/null



$(DEBUG): CFLAGS += $(DBG_CFLAGS)
$(DEBUG): LFLAGS += $(DBG_LFLAGS)
CFLAGS += $(DBG_CFLAGS)
LFLAGS += $(DBG_LFLAGS)
$(DEBUG): $(TARGET)

$(OBJ_DIR):
	$(QUIET) mkdir -p $(OBJ_DIR) $(OBJ_DIR)/src
	$(QUIET) for i in `find src`; do mkdir -p $(OBJ_DIR)/$$i; done

$(COBJS) : $(OBJ_DIR)/%.o : %.c Makefile
	$(QUIET) echo "  CC       $<	$(notdir $@)"
	$(QUIET) $(CC) -c $< $(CFLAGS) -o $@ -MMD

$(OBJ_DIR)/%.o: %.cpp
	$(QUIET) echo "  CXX      $<	$(notdir $@)"
	$(QUIET) $(CXX) -c $< $(CXXFLAGS) -o $@ -MMD

$(OBJ_DIR)/%.o: %.s
	$(QUIET) echo "  AS       $<	$(notdir $@)"
	$(QUIET) $(CC) -x assembler-with-cpp -c $< $(CFLAGS) -o $@ -MMD

.PHONY: $(CLEAN) $(DISTCLEAN) $(DIST) $(REBUILD) $(DREBUILD) $(INSTALL) \
        $(CHANGELOG) $(INIT)

$(CLEAN):
	$(QUIET) rm -f $(wildcard $(OBJ_DIR)/*.d)
	$(QUIET) rm -f $(wildcard $(OBJ_DIR)/*.o)
	$(QUIET) rm -f $(TARGET) $(PACKAGE).bin $(PACKAGE).symbol

$(DISTCLEAN): $(CLEAN)
	$(QUIET) rm -rf $(OBJ_DIR) $(wildcard $(TARGET)-*.tar.gz)
	$(QUIET) rm -f $(CHANGELOG)

$(CHANGELOG):
	$(QUIET) if [ -d .git ] ; then \
		git log `git tag`.. --pretty=format:"* %ad | %s%d [%an]" \
		--date=short > $@ ; \
	fi
	$(QUIET) echo "" >> $@

include $(wildcard $(OBJ_DIR)/*.d)
