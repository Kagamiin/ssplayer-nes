# -------------------------------------------------------------
# Configuration variables

mapper_dir := vrc4
#mapper_dir := vrc7
#mapper_dir := mmc5a
#mapper_dir := n163
#mapper_dir := fme-7

#decode_routine := ss1_async
#decode_routine := ss1_async_fast
#decode_routine := ss1_async_fullunroll
#decode_routine := ss2_async
decode_routine := ss2_async_fast
#decode_routine := ss2_async_fullunroll

samples_subdir := 
#samples_subdir := the-little-things/
#samples_subdir := bad-apple/
#samples_subdir := bad-apple-ss1/

superblocks_file := superblocks.o
#superblocks_file := superblocks_thelittlethings-2par-14093-ss2.o
#superblocks_file := superblocks_bad-apple-22946-ss2.o
#superblocks_file := superblocks_bad-apple-22946-ss1.o

#cfgfile := $(mapper_dir)/ssplayer-64k.cfg
#cfgfile := $(mapper_dir)/ssplayer-128k.cfg
cfgfile := $(mapper_dir)/ssplayer-256k.cfg
#cfgfile := $(mapper_dir)/ssplayer-512k.cfg

# -------------------------------------------------------------

CA65 := ca65
LD65 := ld65
SRC_DIR := ./src
BUILD_DIR := ./build
CODEGEN_DIR := $(BUILD_DIR)/codegen
SAMPLES_DIR := $(BUILD_DIR)/samples

.PHONY: build_dirs all clean

MAPPER_DIRS := \
	vrc4 \
	vrc7 \
	mmc5 \
	n163 \
	fme-7


dirs := \
	$(mapper_dir) \
	decode

src_subdirs := $(patsubst %,$(SRC_DIR)/%,$(dirs))

obj_subdirs := $(patsubst %,$(BUILD_DIR)/%,$(dirs))

all_mapper_subdirs := $(patsubst %,$(BUILD_DIR)/%,$(MAPPER_DIRS))


make_dirs := \
	$(BUILD_DIR) \
	$(CODEGEN_DIR) \
	$(SAMPLES_DIR) \
	$(obj_subdirs)

objects := \
	$(superblocks_file) \
	delays.o \
	nmi.o \
	main.o \
	decode/buffer.o \
	decode/decode_$(decode_routine).o \
	decode/superblock_load.o \
	$(mapper_dir)/playback_irq.o \
	$(mapper_dir)/mapper_funcs.o \
	$(mapper_dir)/ram_locations.o

includes := \
	delays.inc \
	nes_mmio.inc \
	utils.inc


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

superblocks.o: superblocks.s $(includes) $(CODEGEN_DIR)/* $(SAMPLES_DIR)/$(samples_subdir)*.bin
	$(CA65) $< -g -o $(BUILD_DIR)/$@ --include-dir $(CODEGEN_DIR) --bin-include-dir $(SAMPLES_DIR)/$(samples_subdir) --include-dir $(SAMPLES_DIR)/$(samples_subdir)

superblocks_%.o: superblocks_%.s $(includes) $(CODEGEN_DIR)/* $(SAMPLES_DIR)/$(samples_subdir)*.bin
	$(CA65) $< -g -o $(BUILD_DIR)/$@ --include-dir $(CODEGEN_DIR) --bin-include-dir $(SAMPLES_DIR)/$(samples_subdir) --include-dir $(SAMPLES_DIR)/$(samples_subdir)
	
%.o: %.s $(includes)
	$(CA65) $< -g -o $(BUILD_DIR)/$@ --include-dir $(SRC_DIR)

build_dirs:
	@mkdir -p $(make_dirs) 2>/dev/null

clean:
	-rm $(BUILD_DIR)/*.o $(BUILD_DIR)/*.nes $(BUILD_DIR)/*.dbg 2> /dev/null || true
	-rm $(patsubst %,%/*,$(obj_subdirs)) 2> /dev/null || true
	-rm $(patsubst %,%/*,$(all_mapper_subdirs)) 2> /dev/null || true
