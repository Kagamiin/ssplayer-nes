.include "smc.inc"
.include "nes_mmio.inc"
.include "checked_branches.inc"
.include "play_sample.inc"

.segment "DECODE"



; Decodes 16 bytes (128 samples) of 1-bit SSDPCM.
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
	.globalzp tmp_playback_a, playback_delay_count

	.import load_next_superblock
	
	.import bank_numbers

	.global buf_pcm

	dummy    = $0
	jmp_dst  = $0
	slope0   = $2
	tmp_sample_1 = $3
	tmp_sample_2 = $4
	tmp_sample_3 = $5
	tmp_sample_4 = $6
	tmp_sample_4_last = $7

	.macro bankswitch
		tax                  ; 2  2
		sta bank_numbers, x  ; 5  7
	.endmacro
	
.segment "DECODE"

prepare:
	lda idx_block
	c_bne load_slopes
	lda superblock_length
	sta idx_block

load_slopes:                      ;      8
	lda slopes_bank           ;  3  11
	bankswitch                ;  7  18

	ldy #$00                  ;  2  20
	lda (ptr_slopes), y       ;  5  25
	sta slope0                ;  3  28
	
	lda a:bits_bank           ;  4  32
	bankswitch                ;  7  39
	
	nop                       ;  2  41
	jmp decode_byte_entry     ;  3  44

.include "decode/decode_loop_ss1c_sync.inc"

cleanup:
	jmp load_next_superblock

.include "decode/decode_tables_ss1c_sync.inc"

.endproc


