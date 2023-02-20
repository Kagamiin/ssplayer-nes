.include "binaries.inc"

.segment "CODE"
.export num_sblk_headers
num_sblk_headers:
	.byte 14

.segment "HDRS"
.export sblk_headers
sblk_headers:
.align 8
	.byte $00              ; superblock bank (unused for now)
	.byte piece0::length   ; superblock length in 128-sample blocks ($00 is equivalent to 256)
	.addr piece0::bits     ; pointer to bitstream start
	.addr piece0::slopes   ; pointer to slope array start
	.byte piece0::initial_sample

.align 8
	.byte $00              ; superblock bank (unused for now)
	.byte piece1::length   ; superblock length in 128-sample blocks ($00 is equivalent to 256)
	.addr piece1::bits     ; pointer to bitstream start
	.addr piece1::slopes   ; pointer to slope array start
	.byte piece1::initial_sample

.align 8
	.byte $00              ; superblock bank (unused for now)
	.byte piece2::length   ; superblock length in 128-sample blocks ($00 is equivalent to 256)
	.addr piece2::bits     ; pointer to bitstream start
	.addr piece2::slopes   ; pointer to slope array start
	.byte piece2::initial_sample

.align 8
	.byte $00              ; superblock bank (unused for now)
	.byte piece3::length   ; superblock length in 128-sample blocks ($00 is equivalent to 256)
	.addr piece3::bits     ; pointer to bitstream start
	.addr piece3::slopes   ; pointer to slope array start
	.byte piece3::initial_sample

.align 8
	.byte $00              ; superblock bank (unused for now)
	.byte piece4::length   ; superblock length in 128-sample blocks ($00 is equivalent to 256)
	.addr piece4::bits     ; pointer to bitstream start
	.addr piece4::slopes   ; pointer to slope array start
	.byte piece4::initial_sample

.align 8
	.byte $00              ; superblock bank (unused for now)
	.byte piece5::length   ; superblock length in 128-sample blocks ($00 is equivalent to 256)
	.addr piece5::bits     ; pointer to bitstream start
	.addr piece5::slopes   ; pointer to slope array start
	.byte piece5::initial_sample

.align 8
	.byte $00              ; superblock bank (unused for now)
	.byte piece0::length   ; superblock length in 128-sample blocks ($00 is equivalent to 256)
	.addr piece0::bits     ; pointer to bitstream start
	.addr piece0::slopes   ; pointer to slope array start
	.byte piece0::initial_sample

.align 8
	.byte $00              ; superblock bank (unused for now)
	.byte piece1::length   ; superblock length in 128-sample blocks ($00 is equivalent to 256)
	.addr piece1::bits     ; pointer to bitstream start
	.addr piece1::slopes   ; pointer to slope array start
	.byte piece1::initial_sample

.align 8
	.byte $00              ; superblock bank (unused for now)
	.byte piece6::length   ; superblock length in 128-sample blocks ($00 is equivalent to 256)
	.addr piece6::bits     ; pointer to bitstream start
	.addr piece6::slopes   ; pointer to slope array start
	.byte piece6::initial_sample

.align 8
	.byte $00              ; superblock bank (unused for now)
	.byte piece3::length   ; superblock length in 128-sample blocks ($00 is equivalent to 256)
	.addr piece3::bits     ; pointer to bitstream start
	.addr piece3::slopes   ; pointer to slope array start
	.byte piece3::initial_sample

.align 8
	.byte $00              ; superblock bank (unused for now)
	.byte piece4::length   ; superblock length in 128-sample blocks ($00 is equivalent to 256)
	.addr piece4::bits     ; pointer to bitstream start
	.addr piece4::slopes   ; pointer to slope array start
	.byte piece4::initial_sample
	
.align 8
	.byte $00              ; superblock bank (unused for now)
	.byte piece7::length   ; superblock length in 128-sample blocks ($00 is equivalent to 256)
	.addr piece7::bits     ; pointer to bitstream start
	.addr piece7::slopes   ; pointer to slope array start
	.byte piece7::initial_sample

.align 8
	.byte $00              ; superblock bank (unused for now)
	.byte piece8::length   ; superblock length in 128-sample blocks ($00 is equivalent to 256)
	.addr piece8::bits     ; pointer to bitstream start
	.addr piece8::slopes   ; pointer to slope array start
	.byte piece8::initial_sample

.align 8
	.byte $00              ; superblock bank (unused for now)
	.byte piece9::length   ; superblock length in 128-sample blocks ($00 is equivalent to 256)
	.addr piece9::bits     ; pointer to bitstream start
	.addr piece9::slopes   ; pointer to slope array start
	.byte piece9::initial_sample

