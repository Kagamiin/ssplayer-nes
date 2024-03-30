.include "smc.inc"
.include "nes_mmio.inc"
.include "checked_branches.inc"
.include "play_sample.inc"

.segment "DECODE"

.res 9

; Decodes 16 bytes (128 samples) of 1-bit SSDPCM with comb filter.
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
	jmp_dst  = $1
	slope0   = $3
	tmp_sample_1 = $4
	tmp_sample_2 = $5
	tmp_sample_3 = $6
	tmp_sample_4 = $7
	tmp_sample_4_last = $8
	tmp_delay_count = $9

	.macro bankswitch
		tax                  ; 2  2
		sta bank_numbers, x  ; 5  7
	.endmacro

prepare:
	ldy #$00

	lda playback_delay_count
	sec
	sbc #2
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

	nop                       ;  2  23

	lda last_fine_pitch       ;  3  26
	cmp fine_pitch            ;  3  29
	bne patch_trampoline      ;  2  31  ; expected to not be taken

continue_load_slopes:
	lda bits_bank             ;  3  34
	bankswitch                ;  7  41
	
	jmp decode_byte_entry     ;  3  44  y = 0

patch_trampoline:
	jmp patch_sample_playback

.segment "DECODE_RAMCODE"

.include "decode/decode_loop_ss1c_sync_softrate.inc"

.segment "DECODE"

.include "decode/decode_tables_ss1c_sync.inc"

.include "decode/decode_patch_ss1c_sync_softrate.inc"

.segment "DECODE"

cleanup:
	jmp load_next_superblock

.endproc

.include "decode/decode_loader.inc"
