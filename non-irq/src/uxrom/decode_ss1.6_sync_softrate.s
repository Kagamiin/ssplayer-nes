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
	.globalzp tmp_playback_a, playback_delay_count, fine_pitch

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
	last_fine_pitch = $9
	patch_src = $a
	tmp_patch_id = $c

	.macro bankswitch
		tax                  ; 2  2
		sta bank_numbers, x  ; 5  7
	.endmacro

prepare:
	ldy #$00
	sty last_fine_pitch

	lda idx_block
	c_bne load_slopes
	lda superblock_length
	sta idx_block

load_slopes:                      ;      3  y = 0
	lda slopes_bank           ;  3   6
	bankswitch                ;  7  13

	lda (ptr_slopes), y       ;  5  18  y = 0
	sta slope0                ;  3  21
	
	lda last_fine_pitch       ;  3  24
	cmp fine_pitch            ;  3  27
	bne patch_trampoline      ;  2  29
	nop                       ;  2  31

continue_load_slopes:
	lda bits_bank             ;  3  34
	bankswitch                ;  7  41
	
	nop                       ;  2  43
	jmp decode_byte_entry     ;  3  46  y = 0

patch_trampoline:
	jmp patch_sample_playback

.segment "DECODE_RAMCODE"

.include "decode/decode_loop_ss1.6_sync_softrate.inc"

.segment "DECODE"

patch_sample_playback:
	lda fine_pitch
	cmp #(patch_table_2 - patch_table_1)
	bcc @not_oob
	lda #(patch_table_2 - patch_table_1 - 1)
	sta fine_pitch
@not_oob:
	tax

@patch1:
	lda patch_table_1, x
	sta tmp_patch_id
	ldy last_fine_pitch
	lda patch_table_1, y
	cmp tmp_patch_id
	beq @patch2

	ldy tmp_patch_id
	lda patches_low, y
	sta patch_src
	lda patches_high, y
	sta patch_src + 1
	
	ldy #(patch_2 - patch_1 - 1)
	:
		lda (patch_src), y
		sta patch_location_1, y
		dey
		bpl :-
	
@patch2:
	lda patch_table_2, x
	sta tmp_patch_id
	ldy last_fine_pitch
	lda patch_table_2, y
	cmp tmp_patch_id
	beq @patch3

	ldy tmp_patch_id
	lda patches_low, y
	sta patch_src
	lda patches_high, y
	sta patch_src + 1
	
	ldy #(patch_2 - patch_1 - 1)
	:
		lda (patch_src), y
		sta patch_location_2, y
		dey
		bpl :-
	
@patch3:
	lda patch_table_3, x
	sta tmp_patch_id
	ldy last_fine_pitch
	lda patch_table_3, y
	cmp tmp_patch_id
	beq @patch4

	ldy tmp_patch_id
	lda patches_low, y
	sta patch_src
	lda patches_high, y
	sta patch_src + 1
	
	ldy #(patch_2 - patch_1 - 1)
	:
		lda (patch_src), y
		sta patch_location_3_0, y
		sta patch_location_3_1, y
		sta patch_location_3_2, y
		sta patch_location_3_3, y
		sta patch_location_3_4, y
		dey
		bpl :-
	
@patch4:
	lda patch_table_4, x
	sta tmp_patch_id
	ldy last_fine_pitch
	lda patch_table_4, y
	cmp tmp_patch_id
	beq @patch5

	ldy tmp_patch_id
	lda patches_low, y
	sta patch_src
	lda patches_high, y
	sta patch_src + 1
	
	ldy #(patch_2 - patch_1 - 1)
	:
		lda (patch_src), y
		sta patch_location_4, y
		dey
		bpl :-
	
@patch5:
	lda patch_table_5, x
	sta tmp_patch_id
	ldy last_fine_pitch
	lda patch_table_5, y
	cmp tmp_patch_id
	beq @end_patch

	ldy tmp_patch_id
	lda patches_low, y
	sta patch_src
	lda patches_high, y
	sta patch_src + 1
	
	ldy #(patch_2 - patch_1 - 1)
	:
		lda (patch_src), y
		sta patch_location_5, y
		dey
		bpl :-

@end_patch:
	stx last_fine_pitch
	ldy #0
	jmp continue_load_slopes

patches_low:
	.byte <patch_0
	.byte <patch_1
	.byte <patch_2
	.byte <patch_3
	.byte <patch_4
	.byte <patch_5

patches_high:
	.byte >patch_0
	.byte >patch_1
	.byte >patch_2
	.byte >patch_3
	.byte >patch_4
	.byte >patch_5

patch_table_1:
	.byte 0,  0, 1, 1, 1, 1,  1, 2, 2, 2, 2,  2, 3, 3, 3, 3,  3, 4, 4, 4, 4,  4, 5, 5, 5, 5
patch_table_2:
	.byte 0,  0, 0, 0, 1, 1,  1, 1, 1, 2, 2,  2, 2, 2, 3, 3,  3, 3, 3, 4, 4,  4, 4, 4, 5, 5
patch_table_3:
	.byte 0,  1, 1, 1, 1, 1,  2, 2, 2, 2, 2,  3, 3, 3, 3, 3,  4, 4, 4, 4, 4,  5, 5, 5, 5, 5
patch_table_4:
	.byte 0,  0, 0, 0, 0, 1,  1, 1, 1, 1, 2,  2, 2, 2, 2, 3,  3, 3, 3, 3, 4,  4, 4, 4, 4, 5
patch_table_5:
	.byte 0,  0, 0, 1, 1, 1,  1, 1, 2, 2, 2,  2, 2, 3, 3, 3,  3, 3, 4, 4, 4,  4, 4, 5, 5, 5

patch_0:
	nop                         ;  2  2
	nop                         ;  2  4
	nop                         ;  2  6
	nop                         ;  2  8
	lda a:playback_delay_count  ;  4 12

patch_1:
	inc dummy                   ;  5  5
	nop                         ;  2  7
	nop                         ;  2  9
	lda a:playback_delay_count  ;  4 13

patch_2:
	inc dummy                   ;  5  5
	dec dummy                   ;  5 10
	lda a:playback_delay_count  ;  4 14

patch_3:
	inc dummy                   ;  5  5
	lda (dummy, x)              ;  6 11
	lda a:playback_delay_count  ;  4 15

patch_4:
	lda (dummy, x)              ;  6  6
	lda (dummy, x)              ;  6 12
	lda a:playback_delay_count  ;  4 16

patch_5:
	lda (dummy, x)              ;  6  6
	lda (dummy, x)              ;  6 12
	nop                         ;  2 14
	lda playback_delay_count    ;  3 17


cleanup:
	jmp load_next_superblock

.include "decode/decode_tables_ss1.6_sync.inc"

.endproc

.export load_decoder
.proc load_decoder
	.import __DECODE_RAMCODE_LOAD__, __DECODE_RAMCODE_RUN__, __DECODE_RAMCODE_SIZE__

	lda #<__DECODE_RAMCODE_LOAD__
	sta $00
	lda #>__DECODE_RAMCODE_LOAD__
	clc
	adc #>__DECODE_RAMCODE_SIZE__
	sta $01
	lda #<__DECODE_RAMCODE_RUN__
	sta $02
	lda #>__DECODE_RAMCODE_RUN__
	clc
	adc #>__DECODE_RAMCODE_SIZE__
	sta $03
	ldy #<__DECODE_RAMCODE_SIZE__
	ldx #>__DECODE_RAMCODE_SIZE__
	cpy #0
	beq after
	loop:
		inner:
			dey
			lda ($0000), y
			sta ($0002), y
			cpy #0
			bne inner
	after:  ; y = 0
		cpx #0
		beq end
		dex
		dec $01
		dec $03
		bpl loop  ; will always branch
end:
	rts
.endproc


