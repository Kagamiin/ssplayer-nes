.include "smc.inc"
.include "nes_mmio.inc"
.include "checked_branches.inc"
.include "play_sample.inc"

.segment "DECODE"

.res 9

; Decodes 32 bytes (128 samples) of 2-bit SSDPCM.
; If the end of the superblock is reached, triggers the next superblock to be loaded.
; uses:
;	bits_bank
;	slopes_bank
;	idx_block
;	idx_pcm_decode
;	idx_superblock
;	superblock_length
;	last_sample
;	ptr_bitstream
;	ptr_slopes
; updates:
;	idx_block
;	idx_pcm_decode
;	last_sample
;	ptr_bitstream
;	ptr_slopes
; clobbers:
;	a, x, y
;       zp $0..$5
.export decode_play_sync
.proc decode_play_sync

	.globalzp bits_bank, slopes_bank
	.globalzp idx_block, idx_pcm_decode, idx_superblock
	.globalzp superblock_length, last_sample, ptr_bitstream, ptr_slopes
	.globalzp tmp_playback_a, playback_delay_count, fine_pitch, last_fine_pitch

	.import load_next_superblock
	
	.import bank_numbers

	.global buf_pcm

	dummy = $0
	jmp_dst1 = $1
	jmp_dst2 = $3
	slope0   = $5
	slope1   = $6
	tmp_sample_1 = $7
	tmp_sample_2 = $8
	tmp_sample_3 = $9
	tmp_sample_4 = $A
	tmp_delay_count = $B

	.macro bankswitch
		tax                  ; 2  2
		sta bank_numbers, x  ; 5  7
	.endmacro

prepare:
	lda #>decode_unroll_1
	sta jmp_dst1+1
	lda #>decode_unroll_2
	sta jmp_dst2+1

	ldy #$00

	lda playback_delay_count
	sec
	sbc #1
	sta tmp_delay_count

	lda idx_block
	c_bne load_slopes
	lda superblock_length
	sta idx_block


load_slopes:                      ;      3  y = 0
	lda slopes_bank           ;  3   6
	bankswitch                ;  7  13

	lda (ptr_slopes), y       ;  5  18  y = 0
	sta slope0                ;  3  21
	iny                       ;  2  23
	lda (ptr_slopes), y       ;  5  28  y = 1
	sta slope1                ;  3  31
	dey                       ;  2  33  y = 0
	
	lda bits_bank             ;  3  36
	bankswitch                ;  7  43
	
	jmp decode_byte_entry     ;  3  46  y = 0

.segment "DECODE_RAMCODE"

.include "decode/decode_loop_ss2_sync_softrate.inc"

.segment "DECODE"

.include "decode/decode_tables_ss2_sync_softrate.inc"

.include "decode/decode_patch_ss2_sync_softrate.inc"

.segment "DECODE"

cleanup:
	jmp load_next_superblock

.endproc

.include "decode/decode_loader.inc"
