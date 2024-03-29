.include "smc.inc"
.include "nes_mmio.inc"
.include "checked_branches.inc"
.include "play_sample.inc"

.segment "DECODE"

.res 9

; Decodes 16 bytes (80 samples) of 1.6-bit SSDPCM.
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
	tmp_sample_5 = $8
	tmp_delay_count = $9

	.macro bankswitch
		tax                  ; 2  2
		sta bank_numbers, x  ; 5  7
	.endmacro

prepare:
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
	
	lda dummy                 ;  3  24
	
	lda last_fine_pitch       ;  3  27
	cmp fine_pitch            ;  3  30
	bne patch_trampoline      ;  2  32  ; expected to not be taken

continue_load_slopes:
	lda bits_bank             ;  3  35
	bankswitch                ;  7  42
	
	jmp decode_byte_entry     ;  3  45  y = 0

patch_trampoline:
	jmp patch_sample_playback

.include "decode/decode_loop_ss1.6_sync_softrate.inc"

.include "decode/decode_tables_ss1.6_sync.inc"

.include "decode/decode_patch_ss1.6_sync_softrate.inc"

.segment "DECODE"

cleanup:
	jmp load_next_superblock

.endproc

.include "decode/decode_loader.inc"
