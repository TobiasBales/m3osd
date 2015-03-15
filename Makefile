ROOT          = $(dir $(lastword $(MAKEFILE_LIST)))
SRC_DIR       = $(ROOT)/src
CMSIS_DIR     = $(ROOT)/lib/CMSIS
STDPERIPH_DIR = $(ROOT)/lib/STM32F10x_StdPeriph_Driver
DEVICE_DIR    = $(ROOT)/lib/STM32_USB-FS-Device_Driver
COOS_DIR      = $(ROOT)/CoOS
OBJECT_DIR    = $(ROOT)/obj
BIN_DIR       = $(ROOT)/obj
TARGET        = M3OSD

.PRECIOUS: %.s

VPATH        := $(SRC_DIR):$(SRC_DIR)/startup
VPATH        := $(VPATH):$(CMSIS_DIR)/CM3/CoreSupport:$(CMSIS_DIR)/CM3/DeviceSupport/ST/STM32F10x
VPATH        := $(VPATH):$(STDPERIPH_DIR)/src
CMSIS_SRC     = $(notdir $(wildcard $(CMSIS_DIR)/CM3/CoreSupport/*.c $(CMSIS_DIR)/CM3/DeviceSupport/ST/STM32F10x/*.c))
STDPERIPH_SRC = $(notdir $(wildcard $(STDPERIPH_DIR)/src/*.c))
DEVICE_SRC    = $(notdir $(wildcard $(DEVICE_DIR)/src/*.c))
COOS_KERNEL_SRC = $(notdir $(wildcad $(COOS_DIR)/kernel/*.c))
COOS_PORTABLE_SRC = $(COOS_DIR)/portable/arch.c
COOS_PORTABLE_GCC_SRC = $(notdir $(wildcad $(COOS_DIR)/portable/GCC/*.c))

M3OSD_SRC     = multiwii.c \
                usb.c \
                usb_endp.c \
                usb_prop.c \
                osdcore.c \
                uart.c \
                sensors.c \
                fonts.c \
                gps.c \
                main.c \
                usb_pwr.c \
                usb_desc.c \
                usb_istr.c \
                rssi.c \
                startup_stm32f10x_md_gcc.s \
                $(CMSIS_SRC) \
                $(STDPERIPH_SRC) \
                $(DEVICE_SRC) \
                $(COOS_KERNEL_SRC) \
                $(COOS_PORTABLE_SRC) \
                $(COOS_PORTABLE_GCC_SRC)


CC           = arm-none-eabi-gcc
OBJCOPY      = arm-none-eabi-objcopy
INCLUDE_DIRS = $(SRC_DIR) \
               $(STDPERIPH_DIR)/inc \
               $(CMSIS_DIR)/CM3/CoreSupport \
               $(CMSIS_DIR)/CM3/DeviceSupport/ST/STM32F10x \
               $(COOS_DIR)/kernel \
               $(COOS_DIR)/portable \
               $(COOS_DIR)/portable/GCC \
               $(DEVICE_DIR)/inc
ARCH_FLAGS   = -mthumb -mcpu=cortex-m3
CFLAGS       = $(ARCH_FLAGS) \
               $(LTO_FLAGS) \
               $(addprefix -D,$(OPTIONS)) \
               $(addprefix -I,$(INCLUDE_DIRS)) \
               $(DEBUG_FLAGS) \
               -std=gnu99 \
               -Wall -pedantic -Wextra -Wshadow -Wunsafe-loop-optimizations \
               -ffunction-sections \
               -fdata-sections \
               -DSTM32F10X_MD \
               -DUSE_STDPERIPH_DRIVER

ASFLAGS      = $(ARCH_FLAGS) \
               -x assembler-with-cpp \
               $(addprefix -I,$(INCLUDE_DIRS))

LD_SCRIPT  = $(ROOT)/stm32_flash.ld
LDFLAGS     = -lm \
              -nostartfiles \
              --specs=nano.specs \
              -lc \
              -lnosys \
              $(ARCH_FLAGS) \
              $(LTO_FLAGS) \
              $(DEBUG_FLAGS) \
              -static \
              -Wl,-gc-sections,-Map,$(TARGET_MAP) \
              -T$(LD_SCRIPT)

TARGET_HEX   = $(BIN_DIR)/$(TARGET).hex
TARGET_ELF   = $(BIN_DIR)/$(TARGET).elf
TARGET_OBJS  = $(addsuffix .o,$(addprefix $(OBJECT_DIR)/$(TARGET)/,$(basename $($(TARGET)_SRC))))
TARGET_MAP   = $(OBJECT_DIR)/$(TARGET).map

$(TARGET_HEX): $(TARGET_ELF)
	$(OBJCOPY) -O ihex --set-start 0x8000000 $< $@

$(TARGET_ELF):  $(TARGET_OBJS)
	$(CC) -o $@ $^ $(LDFLAGS)

MKDIR_OBJDIR = @mkdir -p $(dir $@)

$(OBJECT_DIR)/$(TARGET)/%.o: %.c
	$(MKDIR_OBJDIR)
	@echo %% $<
	@$(CC) -c -o $@ $(CFLAGS) $<

$(OBJECT_DIR)/$(TARGET)/%.o: %.s
	$(MKDIR_OBJDIR)
	@echo %% $<
	@$(CC) -c -o $@ $(ASFLAGS) $< 

$(OBJECT_DIR)/$(TARGET)/%.o): %.S
	$(MKDIR_OBJDIR)
	@echo %% $<
	@$(CC) -c -o $@ $(ASFLAGS) $< 

clean:
	rm -f $(TARGET_HEX) $(TARGET_ELF) $(TARGET_OBJS) $(TARGET_MAP)
