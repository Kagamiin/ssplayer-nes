# -------------------------------------------------------------
# Configuration variables

#mapper_dir := nrom
mapper_dir := uxrom
#mapper_dir := mmc3

#decode_routine := ss1_sync
#decode_routine := ss1_sync_softrate
#decode_routine := ss1c_sync
#decode_routine := ss1c_sync_softrate
#decode_routine := ss1.6_sync
decode_routine := ss1.6_sync_softrate
#decode_routine := ss2_sync
#decode_routine := ss2_sync_fast
#decode_routine := ss2_sync_fixedrate
#decode_routine := ss2_sync_softrate

options := -D SOFTRATE=1

#samples_subdir := cuba-baion-32k/
#samples_subdir := cuba-baion-32k-ss1c/
#samples_subdir := cuba-baion-ss1/
#samples_subdir := cuba-baion-ss1c/
#samples_subdir := cuba-baion/
#samples_subdir := soad-35094/
samples_subdir := hyperprism-15980-ss1.6/
#samples_subdir := balancetogether-short-ss1/
#samples_subdir := balancetogether-short-ss1c/
#samples_subdir := balancetogether-short-ss2/

#superblocks_file := superblocks_cuba-baion-14093-ss1.o
#superblocks_file := superblocks_cuba-baion-19454-ss1.o
#superblocks_file := superblocks_cuba-baion-19454-ss1-8kbank.o
#superblocks_file := superblocks_cuba-baion-19454-ss2.o
#superblocks_file := superblocks_cuba-baion-19454-ss2-8kbank.o
#superblocks_file := superblocks_soad-35094-ss2.o
superblocks_file := superblocks_hyperprism-15980-ss1.6.o
#superblocks_file := superblocks_balancetogether-19454-ss1.o
#superblocks_file := superblocks_balancetogether-19454-ss1c.o
#superblocks_file := superblocks_balancetogether-19454-ss2.o

#cfgfile := $(mapper_dir)/ssplayer-32k.cfg
#cfgfile := $(mapper_dir)/ssplayer-64k.cfg
#cfgfile := $(mapper_dir)/ssplayer-128k.cfg
#cfgfile := $(mapper_dir)/ssplayer-256k.cfg
#cfgfile := $(mapper_dir)/ssplayer-512k.cfg
cfgfile := $(mapper_dir)/ssplayer-1024k.cfg

# -------------------------------------------------------------

CA65 := ca65
LD65 := ld65
SRC_DIR := ./src
BUILD_DIR := ./build
ASSETS_DIR := ./assets
CODEGEN_DIR := $(BUILD_DIR)/codegen
SAMPLES_DIR := $(BUILD_DIR)/samples

.PHONY: build_dirs all clean

MAPPER_DIRS := \
	nrom \
	uxrom \
	mmc3 \

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
	delays.o \
	nmi.o \
	main.o \
	ram_locations_common.o \
	$(mapper_dir)/decode_$(decode_routine).o \
	$(mapper_dir)/mapper_funcs.o \
	$(mapper_dir)/ram_locations.o \
	decode/superblock_load.o \
	$(superblocks_file) \

includes := \
	delays.inc \
	nes_mmio.inc \
	$(SRC_DIR)/decode/*


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
	$(CA65) $< -g -o $(BUILD_DIR)/$@ --include-dir $(SRC_DIR) --bin-include-dir $(ASSETS_DIR) $(options)

build_dirs:
	@mkdir -p $(make_dirs) 2>/dev/null

clean:
	-rm $(BUILD_DIR)/*.o $(BUILD_DIR)/*.nes $(BUILD_DIR)/*.dbg 2> /dev/null || true
	-rm $(patsubst %,%/*,$(obj_subdirs)) 2> /dev/null || true
	-rm $(patsubst %,%/*,$(all_mapper_subdirs)) 2> /dev/null || true
