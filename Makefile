CA65 := ca65
LD65 := ld65
SRC_DIR := ./src
BUILD_DIR := ./build
CODEGEN_DIR := $(BUILD_DIR)/codegen
SAMPLES_DIR := $(BUILD_DIR)/samples

.PHONY: build_dirs all clean

dirs := \
	vrc4 \
	decode

src_subdirs := $(patsubst %,$(SRC_DIR)/%,$(dirs))

obj_subdirs := $(patsubst %,$(BUILD_DIR)/%,$(dirs))

make_dirs := \
	$(BUILD_DIR) \
	$(CODEGEN_DIR) \
	$(SAMPLES_DIR) \
	$(obj_subdirs)

objects := \
	superblocks.o \
	delays.o \
	nmi.o \
	main.o \
	decode/buffer.o \
	decode/decode_ss2_async_fullunroll.o \
	vrc4/playback_irq.o \
	vrc4/mapper_funcs.o \
	vrc4/ram_locations.o

includes := \
	delays.inc \
	nes_mmio.inc \
	utils.inc

cfgfile := vrc4/ssplayer-128k.cfg


vpath %.o $(BUILD_DIR) $(obj_subdirs)
vpath %.nes $(BUILD_DIR)
vpath %.inc $(SRC_DIR) $(src_subdirs) $(CODEGEN_DIR)
vpath %.cfg $(SRC_DIR)
vpath %.s $(SRC_DIR) $(src_subdirs) $(CODEGEN_DIR)

all: build_dirs ssplayer.nes

ssplayer.nes: $(objects) $(cfgfile)
	$(LD65) -o $(BUILD_DIR)/ssplayer.nes \
	-C $(SRC_DIR)/$(cfgfile) \
	--dbgfile $(BUILD_DIR)/ssplayer.dbg \
	$(patsubst %,$(BUILD_DIR)/%,$(objects))

superblocks.o: superblocks.s $(includes)
	$(CA65) $< -g -o $(BUILD_DIR)/$@ --include-dir $(CODEGEN_DIR) --bin-include-dir $(SAMPLES_DIR) --include-dir $(SAMPLES_DIR)

%.o: %.s $(includes)
	$(CA65) $< -g -o $(BUILD_DIR)/$@ --include-dir $(SRC_DIR)

build_dirs:
	@mkdir -p $(make_dirs) 2>/dev/null

clean:
	-rm $(BUILD_DIR)/*.o $(BUILD_DIR)/*.nes $(BUILD_DIR)/*.dbg
	-rm $(patsubst %,%/*,$(obj_subdirs))
