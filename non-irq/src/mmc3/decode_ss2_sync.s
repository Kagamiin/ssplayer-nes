.include "smc.inc"
.include "nes_mmio.inc"
.include "checked_branches.inc"
.include "play_sample.inc"

.segment "DECODE"


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
	.globalzp tmp_playback_a, playback_delay_count
	.globalzp mmc3_bank_select_shadow, mmc3_mutex

	.import load_next_superblock
	
	.import bank_numbers

	.global buf_pcm

	dummy = $0
	jmp_dst1 = $0
	jmp_dst2 = $2
	slope0   = $4
	slope1   = $5
	tmp_sample_1 = $6
	tmp_sample_2 = $7
	tmp_sample_3 = $8
	tmp_sample_4 = $9

	MMC3_REG_BANK_SELECT = $8000
	MMC3_REG_BANK_DATA = $8001

.segment "DECODE"

prepare:
	lda #>decode_unroll_1
	sta jmp_dst1+1
	lda #>decode_unroll_2
	sta jmp_dst2+1

	inc mmc3_mutex
	lda mmc3_bank_select_shadow
	and #%11100000
	ora #%00000110
	sta MMC3_REG_BANK_SELECT

load_slopes:                        ;      3
	nop                         ;  2   5
	nop                         ;  2   7
	lda slopes_bank             ;  3  10
	sta MMC3_REG_BANK_DATA      ;  4  14

	ldy #$00                    ;  2  16
	lda (ptr_slopes), y         ;  5  21
	sta slope0                  ;  3  24
	iny                         ;  2  26  y = 1
	lda (ptr_slopes), y         ;  5  31
	sta slope1                  ;  3  34
	
	lda bits_bank               ;  3  37
	sta MMC3_REG_BANK_DATA      ;  4  41
	
	dey                         ;  2  43  y = 0
	jmp decode_byte_entry       ;  3  46
	

.include "decode/decode_loop_ss2_sync.inc"

cleanup:
	dec mmc3_mutex
	jmp load_next_superblock

.include "decode/decode_tables_ss2_sync.inc"

.endproc


