#
# Rules.mk
#
# Circle - A C++ bare metal environment for Raspberry Pi
# Copyright (C) 2014-2017  R. Stange <rsta2@o2online.de>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#


-include $(CIRCLE_PATH)/Config.mk

RASPPI	?= 3
PREFIX	?= arm-none-eabi-
SERIALPORT ?= /dev/ttyUSB0
DEFAULTBAUD ?= 115200
# see: doc/stdlib-support.txt
STDLIB_SUPPORT ?= 1

# set this to "softfp" if you want to link specific libraries
FLOAT_ABI ?= hard

CC	= $(PREFIX)gcc
CPP	= $(PREFIX)g++
AS	= $(CC)
LD	= $(PREFIX)ld
AR	= $(PREFIX)ar

ifeq ($(strip $(RASPPI)),1)
ARCH	?= -march=armv6k -mtune=arm1176jzf-s -marm -mfpu=vfp -mfloat-abi=$(FLOAT_ABI)
TARGET	?= kernel
else ifeq ($(strip $(RASPPI)),2)
ARCH	?= -march=armv7-a -marm -mfpu=neon-vfpv4 -mfloat-abi=$(FLOAT_ABI)
TARGET	?= kernel7
else
ARCH	?= -march=armv8-a -mtune=cortex-a53 -marm -mfpu=neon-fp-armv8 -mfloat-abi=$(FLOAT_ABI)
TARGET	?= kernel8-32
endif

ifeq ($(strip $(STDLIB_SUPPORT)),3)
LIBSTDCPP != $(CPP) $(ARCH) -print-file-name=libstdc++.a
EXTRALIBS += $(LIBSTDCPP)
LIBGCC_EH != $(CPP) $(ARCH) -print-file-name=libgcc_eh.a
ifneq ($(strip $(LIBGCC_EH)),libgcc_eh.a)
EXTRALIBS += $(LIBGCC_EH)
endif
else
CPPFLAGS  += -fno-exceptions -fno-rtti -nostdinc++
endif

ifeq ($(strip $(STDLIB_SUPPORT)),0)
CFLAGS	  += -nostdinc
else
LIBGCC	  != $(CPP) $(ARCH) -print-file-name=libgcc.a
EXTRALIBS += $(LIBGCC)
endif

OPTIMIZE ?= -O2

INCLUDE	+= -I $(CIRCLE_PATH)/include -I $(CIRCLE_PATH)/addon -I $(CIRCLE_PATH)/app/lib -I $(CIRCLE_PATH)/app/lib/core

AFLAGS	+= $(ARCH) -DRASPPI=$(RASPPI) -DSTDLIB_SUPPORT=$(STDLIB_SUPPORT) $(INCLUDE)
CFLAGS	+= $(ARCH) -Wall -fsigned-char -ffreestanding \
	   -D__circle__ -DRASPPI=$(RASPPI) -DSTDLIB_SUPPORT=$(STDLIB_SUPPORT) \
	   $(INCLUDE) $(OPTIMIZE) -g #-DNDEBUG

%.o: %.S
	$(AS) $(AFLAGS) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.cpp
	$(CPP) $(CPPFLAGS) -c -o $@ $<

clean:
	rm -f *.o *.a *.elf *.hex *.lst *.img *.cir *.map *~ $(EXTRACLEAN)

flash:

	make
	python $(CIRCLE_PATH)/tools/flasher.py $(TARGET).hex $(SERIALPORT)
	
monitor:

	putty -serial $(SERIALPORT) -sercfg $(DEFAULTBAUD)
	
