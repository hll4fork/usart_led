# Makefile skeleton adapted from Peter Harrison's - www.micromouse.com
# edit by huanglilong for stm32f103c8 -- 2016/2/29

# MCU name and submodel
MCU      = cortex-m3#Cortex-M3 Core
SUBMDL   = stm32f103

# toolchain (using code sourcery now)
TCHAIN 	 = arm-none-eabi
THUMB    = -mthumb#select between generating code that executes in ARM and Thumb states
THUMB_IW = -mthumb-interwork#generate code that supports calling betweem the ARM and Thumb instruction sets

# Target file name (without extension).
BUILDDIR = build
TARGET = $(BUILDDIR)/fimware

ST_START = stm32_startcode
ST_USART = usart_lib

# Optimization level [0,1,2,3,s]
OPT ?= 0
DEBUG = 
#DEBUG = dwarf-2

# lib's path
INCDIRS = ./$(ST_START) ./$(ST_USART)

CFLAGS = $(DEBUG)
CFLAGS += -O$(OPT)
CFLAGS += -ffunction-sections -fdata-sections#place each function or data data item into its own section in the output file
CFLAGS += -Wall -Wimplicit#-Wall: turn on all optional warnings, -Wimplicit: warn when a declaration does not specify a type
CFLAGS += -Wcast-align#warn whenever a pointer is cast such that the required alignment of target is increased.
CFLAGS += -Wpointer-arith -Wswitch#-Wswitch: warn for switch statement
CFLAGS += -Wredundant-decls -Wreturn-type -Wshadow -Wunused#warn if anything is declared more than once in the same scope
														   #return type
														   #variable or function is shadowed
														   #defined but not used
# add predefinitions STM32F10X_MD and USE_STDPERIPH_DRIVER for using stm's lib
CFLAGS += -DSTM32F10X_MD -DUSE_STDPERIPH_DRIVER
CFLAGS += -Wa,-adhlns=$(BUILDDIR)/$(subst $(suffix $<),.lst,$<)#-Wa: pass option to assember
CFLAGS += $(patsubst %,-I%,$(INCDIRS))

# Aeembler Flags
ASFLAGS = -Wa,-adhlns=$(BUILDDIR)/$(<:.s=.lst)#,--g$(DEBUG)

LDFLAGS = -nostartfiles -Wl,-Map=$(TARGET).map,--cref,--gc-sections#-Wl: pass option to the linker
																   #--cref: output a cross reference table
																   #--gc-sections: enable garbage collection
LDFLAGS += -lc -lgcc#link libc.a and libgcc.a

# Set the linker script
LDFLAGS +=-T$(ST_START)/c_only_md.ld#use c_only_md.ld for linker script

# Define programs and commands.
SHELL = sh
CC = $(TCHAIN)-gcc
CPP = $(TCHAIN)-g++
AR = $(TCHAIN)-ar
OBJCOPY = $(TCHAIN)-objcopy
OBJDUMP = $(TCHAIN)-objdump
SIZE = $(TCHAIN)-size
NM = $(TCHAIN)-nm
REMOVE = rm -f
REMOVEDIR = rm -r
COPY = cp

# Define Messages
# English
MSG_ERRORS_NONE = Errors: none
MSG_BEGIN = "-------- begin --------"
MSG_ETAGS = Created TAGS File
MSG_END = --------  end  --------
MSG_SIZE_BEFORE = Size before:
MSG_SIZE_AFTER = Size after:
MSG_FLASH = Creating load file for Flash:
MSG_EXTENDED_LISTING = Creating Extended Listing:
MSG_SYMBOL_TABLE = Creating Symbol Table:
MSG_LINKING = Linking:
MSG_COMPILING = Compiling C:
MSG_ASSEMBLING = Assembling:
MSG_CLEANING = Cleaning project:

# Combine all necessary flags and optional flags.
# Add target processor to flags.
GENDEPFLAGS = -MD -MP -MF .dep/$(@F).d#generate depedencies
ALL_CFLAGS  = -mcpu=$(MCU) $(THUMB_IW) -I. $(CFLAGS) $(GENDEPFLAGS)
ALL_ASFLAGS = -mcpu=$(MCU) $(THUMB_IW) -I. -x assembler-with-cpp $(ASFLAGS)

# --------------------------------------------- #
# file management
ASRC = $(ST_START)/c_only_startup.s

STM32SRCS =

_STM32USARTSRCS = stm32f10x_gpio.c \
				  stm32f10x_rcc.c \
				  stm32f10x_usart.c \
				  system_stm32f10x.c
				  
# get usart_lib dir source code's path
STM32USARTSRCS = $(patsubst %, $(ST_USART)/%,$(_STM32USARTSRCS))

SRCS = stm32f10x_it.c usart.c main.c


SRC = $(SRCS) $(STM32SRCS) $(STM32USARTSRCS)

# Define all object files.
_COBJ =  $(SRC:.c=.o)
_AOBJ =  $(ASRC:.s=.o)
COBJ = $(patsubst %, $(BUILDDIR)/%,$(_COBJ))
AOBJ = $(patsubst %, $(BUILDDIR)/%,$(_AOBJ))

# Define all listing files.
_LST  =  $(ASRC:.s=.lst)
_LST +=  $(SRC:.c=.lst)
LST = $(patsubst %, $(BUILDDIR)/%,$(_LST))

# Display size of file.
HEXSIZE = $(SIZE) --target=binary $(TARGET).hex
ELFSIZE = $(SIZE) -A $(TARGET).elf

# go!
all: begin build finished end
build: elf bin lss sym

bin: $(TARGET).bin
elf: $(TARGET).elf
lss: $(TARGET).lss
sym: $(TARGET).sym
dfu: $(TARGET).bin
	sudo dfu-util -d 0110:1001 -a 0 -D $(TARGET).bin

begin:
	mkdir -p build/stm32_startcode
	mkdir -p build/usart_lib
	@echo --
	@echo $(MSG_BEGIN)
	@echo $(COBJ)

finished:
	@echo $(MSG_ERRORS_NONE)
tags:
	etags `find . -name "*.c" -o -name "*.cpp" -o -name "*.h"`
	@echo $(MSG_ETAGS)
end:
	@echo $(MSG_END)
	@echo

# Create final output file (.hex) from ELF output file.
%.hex: %.elf
	@echo
	@echo $(MSG_FLASH) $@
	$(OBJCOPY) -O binary $< $@

# Create final output file (.bin) from ELF output file.
%.bin: %.elf
	@echo
	@echo $(MSG_FLASH) $@
	$(OBJCOPY) -O binary $< $@


# Create extended listing file from ELF output file.
# testing: option -C
%.lss: %.elf
	@echo
	@echo $(MSG_EXTENDED_LISTING) $@
	$(OBJDUMP) -h -S -D $< > $@


# Create a symbol table from ELF output file.
%.sym: %.elf
	@echo
	@echo $(MSG_SYMBOL_TABLE) $@
	$(NM) -n $< > $@


# Link: create ELF output file from object files.
.SECONDARY : $(TARGET).elf
.PRECIOUS : $(COBJ) $(AOBJ)

%.elf:  $(COBJ) $(AOBJ)
	@echo
	@echo $(MSG_LINKING) $@
	$(CC) $(THUMB) $(ALL_CFLAGS) $(AOBJ) $(COBJ) --output $@ $(LDFLAGS)

# Compile: create object files from C source files. ARM/Thumb
$(COBJ) : $(BUILDDIR)/%.o : %.c
	@echo
	@echo $(MSG_COMPILING) $<
	$(CC) -c $(THUMB) $(ALL_CFLAGS) $< -o $@

# Assemble: create object files from assembler source files. ARM/Thumb
$(AOBJ) : $(BUILDDIR)/%.o : %.s
	@echo
	@echo $(MSG_ASSEMBLING) $<
	$(CC) -c $(THUMB) $(ALL_ASFLAGS) $< -o $@

clean: begin clean_list finished end

clean_list :
	@echo
	@echo $(MSG_CLEANING)
	$(REMOVE) $(TARGET).hex
	$(REMOVE) $(TARGET).bin
	$(REMOVE) $(TARGET).obj
	$(REMOVE) $(TARGET).elf
	$(REMOVE) $(TARGET).map
	$(REMOVE) $(TARGET).obj
	$(REMOVE) $(TARGET).a90
	$(REMOVE) $(TARGET).sym
	$(REMOVE) $(TARGET).lnk
	$(REMOVE) $(TARGET).lss
	$(REMOVE) $(COBJ)
	$(REMOVE) $(AOBJ)
	$(REMOVE) $(LST)
	$(REMOVE) flash/tmpflash.bin
#	$(REMOVE) $(SRC:.c=.s)
#	$(REMOVE) $(SRC:.c=.d)
	$(REMOVE) .dep/*

# Include the dependency files.
-include $(shell mkdir .dep 2>/dev/null) $(wildcard .dep/*)


# Listing of phony targets.
.PHONY : all begin finish tags end   \
build elf hex bin lss sym clean clean_list  cscope

cscope:
	rm -rf *.cscope
	find . -iname "*.[hcs]" | grep -v examples | xargs cscope -R -b

