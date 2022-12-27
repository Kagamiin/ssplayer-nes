CA65 := ./tools/ca65
LD65 := ./tools/ld65
SRC_DIR := ./src
BUILD_DIR := ./build
CODEGEN_DIR := $(BUILD_DIR)/codegen
SAMPLES_DIR := $(BUILD_DIR)/samples

vpath %.o $(BUILD_DIR)
vpath %.nes $(BUILD_DIR)
vpath %.inc $(SRC_DIR) $(CODEGEN_DIR)
vpath %.s $(SRC_DIR) $(SRC_DIR)/vrc4 $(CODEGEN_DIR)

.PHONY: build_dirs all clean

objects := \
	ssplayer.o \
	superblocks.o \
	playback_irq.o \
	decode_ss2_async.o \
	mapper_funcs.o \
	ram_locations.o

includes := \
	utils.inc


all: build_dirs ssplayer.nes

ssplayer.nes: $(objects) $(SRC_DIR)/vrc4/ssplayer.cfg
	$(LD65) -o $(BUILD_DIR)/ssplayer.nes -C $(SRC_DIR)/vrc4/ssplayer.cfg --dbgfile $(BUILD_DIR)/ssplayer.dbg $(patsubst %,$(BUILD_DIR)/%,$(objects))

superblocks.o: superblocks.s $(includes)
	$(CA65) $< -g -o $(BUILD_DIR)/$@ --include-dir $(CODEGEN_DIR) --bin-include-dir $(SAMPLES_DIR) --include-dir $(SAMPLES_DIR)

%.o: %.s $(includes)
	$(CA65) $< -g -o $(BUILD_DIR)/$@

build_dirs:
	@mkdir -p $(CODEGEN_DIR) $(SAMPLES_DIR) 2>/dev/null

clean:
	rm $(BUILD_DIR)/*.o $(BUILD_DIR)/*.nes $(BUILD_DIR)/*.dbg
