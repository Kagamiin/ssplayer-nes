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
	.globalzp mmc3_bank_select_shadow, mmc3_mutex

	.import load_next_superblock
	
	.import bank_numbers

	.global buf_pcm

	dummy = $0
	jmp_dst  = $0
	slope0   = $2
	tmp_sample_1 = $3
	tmp_sample_2 = $4
	tmp_sample_3 = $5
	tmp_sample_4 = $6

	MMC3_REG_BANK_SELECT = $8000
	MMC3_REG_BANK_DATA = $8001

.segment "DECODE"

prepare:
	inc mmc3_mutex
	lda mmc3_bank_select_shadow
	and #%11100000
	ora #%00000110
	sta MMC3_REG_BANK_SELECT

load_slopes:                        ;      8
	inc dummy                   ;  5  13  dummy
	nop                         ;  2  15
	nop                         ;  2  17
	nop                         ;  2  19

	lda slopes_bank             ;  3  22
	sta MMC3_REG_BANK_DATA      ;  4  26

	ldy #$00                    ;  2  28
	lda (ptr_slopes), y         ;  5  33
	sta slope0                  ;  3  36
	
	lda bits_bank               ;  3  39
	sta MMC3_REG_BANK_DATA      ;  4  43
	
	jmp decode_byte_entry       ;  3  46

.include "decode/decode_loop_ss1_sync.inc"

cleanup:
	dec mmc3_mutex
	jmp load_next_superblock

.include "decode/decode_tables_ss1_sync.inc"

.endproc


