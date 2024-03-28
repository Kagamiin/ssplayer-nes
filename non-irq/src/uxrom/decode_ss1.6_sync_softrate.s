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
	patch_src = $9
	tmp_patch_id = $b

	.macro bankswitch
		tax                  ; 2  2
		sta bank_numbers, x  ; 5  7
	.endmacro

prepare:
	ldy #$00

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
	lda a:bits_bank           ;  4  34
	bankswitch                ;  7  42
	
	jmp decode_byte_entry     ;  3  45  y = 0

patch_trampoline:
	jmp patch_sample_playback

.segment "DECODE_RAMCODE"

.include "decode/decode_loop_ss1.6_sync_softrate.inc"

.segment "DECODE"

.include "decode/decode_tables_ss1.6_sync.inc"

;---------------------------------------------------------------
	.proc patch_sample_playback

		.globalzp playback_delay_count, fine_pitch, last_fine_pitch

.segment "DECODE"

		lda #(patch_table_2 - patch_table_1)       ;  2    2 
		cmp fine_pitch                             ;  3    5 
		bcs @not_oob_fp                            ;  3   ..   8
		;                                            -1    7  ..
		lda #(patch_table_2 - patch_table_1 - 2)   ;  2    9  ..
		sta fine_pitch                             ;  3   12  ..
	@not_oob_fp:                                       ;
		lda #(patch_table_2 - patch_table_1)       ;  2   14  10
		cmp last_fine_pitch                        ;  3   17  13
		bcs @not_oob_lfp                           ;  3   ..  ..   20  16
		;                                            -1   19  15   ..  ..
		lda #(patch_table_2 - patch_table_1 - 1)   ;  2   21  17   ..  ..
		sta last_fine_pitch                        ;  3   24  20   ..  ..
	@not_oob_lfp:
		lda fine_pitch                             ;  3   27  23   23  19
		tax                                        ;  2   29  25   25  21

	@patch1:
		lda patch_table_1, x            ;  4   4    5   5 *
		sta tmp_patch_id                ;  3   7    3   8
		ldy last_fine_pitch             ;  3  10    3  11
		lda patch_table_1, y            ;  4  14    5  16 *
		cmp tmp_patch_id                ;  3  17    3  19
		beq @patch2                     ;  3  20    3  22

		;                                 -1  19   -1  21
		ldy tmp_patch_id                ;  3  22    3  24
		lda patches_low, y              ;  4  26    5  29 *
		sta patch_src                   ;  3  29    3  32
		lda patches_high, y             ;  3  32    3  35
		sta patch_src + 1               ;  3  35    3  38
		;
		ldy #(patch_2 - patch_1 - 1)    ;  2  37    2  40
		:
			lda (patch_src), y         ; 5  5   5  5
			sta patch_location_1, y    ; 4  9   5 10 *******
			dey                        ; 2 11   2 12
			bpl :-                     ; 3 14   3 15
		;                               ; -1       -1
		;                               ; 98 135  105 145
		
	@patch2:
		lda patch_table_2, x            ;  4   4    5   5 *
		sta tmp_patch_id                ;  3   7    3   8
		ldy last_fine_pitch             ;  3  10    3  11
		lda patch_table_2, y            ;  4  14    5  16 *
		cmp tmp_patch_id                ;  3  17    3  19
		beq @patch3                     ;  3  20    3  22

		;                                 -1  19   -1  21
		ldy tmp_patch_id                ;  3  22    3  24
		lda patches_low, y              ;  4  26    5  29 *
		sta patch_src                   ;  3  29    3  32
		lda patches_high, y             ;  3  32    3  35
		sta patch_src + 1               ;  3  35    3  38
		;
		ldy #(patch_2 - patch_1 - 1)    ;  2  37    2  40
		:
			lda (patch_src), y         ; 5  5   5  5
			sta patch_location_2, y    ; 4  9   5 10 *******
			dey                        ; 2 11   2 12
			bpl :-                     ; 3 14   3 15
		;                               ; -1       -1
		;                               ; 98 135  115 145
		
	@patch3:
		lda patch_table_3, x            ;  4   4    5   5 *
		sta tmp_patch_id                ;  3   7    3   8
		ldy last_fine_pitch             ;  3  10    3  11
		lda patch_table_3, y            ;  4  14    5  16 *
		cmp tmp_patch_id                ;  3  17    3  19
		beq @patch4                     ;  3  20    3  22

		;                                 -1  19   -1  21
		ldy tmp_patch_id                ;  3  22    3  24
		lda patches_low, y              ;  4  26    5  29 *
		sta patch_src                   ;  3  29    3  32
		lda patches_high, y             ;  3  32    3  35
		sta patch_src + 1               ;  3  35    3  38
		;
		ldy #(patch_2 - patch_1 - 1)    ;  2  37    2  40
		:
			lda (patch_src), y         ; 5  5   5  5
			sta patch_location_3_1, y  ; 4  9   5 10 *******
			sta patch_location_3_3, y  ; 4 13   5 15 *******
			sta patch_location_3_4, y  ; 4 17   5 20 *******
			dey                        ; 2 19   2 22
			bpl :-                     ; 3 22   3 25
		;                               ; -1       -1
		;                              ; 154 191  175 215
		
	@patch4:
		lda patch_table_4, x            ;  4   4    5   5 *
		sta tmp_patch_id                ;  3   7    3   8
		ldy last_fine_pitch             ;  3  10    3  11
		lda patch_table_4, y            ;  4  14    5  16 *
		cmp tmp_patch_id                ;  3  17    3  19
		beq @patch5                     ;  3  20    3  22

		;                                 -1  19   -1  21
		ldy tmp_patch_id                ;  3  22    3  24
		lda patches_low, y              ;  4  26    5  29 *
		sta patch_src                   ;  3  29    3  32
		lda patches_high, y             ;  3  32    3  35
		sta patch_src + 1               ;  3  35    3  38
		;
		ldy #(patch_2 - patch_1 - 1)    ;  2  37    2  40
		:
			lda (patch_src), y         ; 5  5   5  5
			sta patch_location_4, y    ; 4  9   5 10 *******
			dey                        ; 2 11   2 12
			bpl :-                     ; 3 14   3 15
		;                               ; -1       -1
		;                               ; 98 135  115 145
		
	@patch5:
		lda patch_table_5, x            ;  4   4    5   5 *
		sta tmp_patch_id                ;  3   7    3   8
		ldy last_fine_pitch             ;  3  10    3  11
		lda patch_table_5, y            ;  4  14    5  16 *
		cmp tmp_patch_id                ;  3  17    3  19
		beq @end_patch                  ;  3  20    3  22

		;                                 -1  19   -1  21
		ldy tmp_patch_id                ;  3  22    3  24
		lda patches_low, y              ;  4  26    5  29 *
		sta patch_src                   ;  3  29    3  32
		lda patches_high, y             ;  3  32    3  35
		sta patch_src + 1               ;  3  35    3  38
		;
		ldy #(patch_2 - patch_1 - 1)    ;  2  37    2  40
		:
			lda (patch_src), y         ; 5  5   5  5
			sta patch_location_5, y    ; 4  9   5 10 *******
			dey                        ; 2 11   2 12
			bpl :-                     ; 3 14   3 15
		;                               ; -1       -1
		;                               ; 98 135  115 145

	@end_patch:
		stx last_fine_pitch        ; 3  3
		ldy #0                     ; 2  5
		jmp continue_load_slopes   ; 3  8

	patches_low:
		.byte <patch_0
		.byte <patch_1
		.byte <patch_2
		.byte <patch_3
		.byte <patch_4
		.byte <patch_5
		.byte <patch_0

	patches_high:
		.byte >patch_0
		.byte >patch_1
		.byte >patch_2
		.byte >patch_3
		.byte >patch_4
		.byte >patch_5
		.byte >patch_0

.segment "DECODE_TABLES"

	.align 256
	patch_table_1:
		.byte 0,  0, 1, 1, 1, 1,  1, 2, 2, 2, 2,  2, 3, 3, 3, 3,  3, 4, 4, 4, 4,  4, 5, 5, 5, 5,  6
	patch_table_2:
		.byte 0,  0, 0, 0, 1, 1,  1, 1, 1, 2, 2,  2, 2, 2, 3, 3,  3, 3, 3, 4, 4,  4, 4, 4, 5, 5,  6
	patch_table_3:
		.byte 0,  1, 1, 1, 1, 1,  2, 2, 2, 2, 2,  3, 3, 3, 3, 3,  4, 4, 4, 4, 4,  5, 5, 5, 5, 5,  6
	patch_table_4:
		.byte 0,  0, 0, 0, 0, 1,  1, 1, 1, 1, 2,  2, 2, 2, 2, 3,  3, 3, 3, 3, 4,  4, 4, 4, 4, 5,  6
	patch_table_5:
		.byte 0,  0, 0, 1, 1, 1,  1, 1, 2, 2, 2,  2, 2, 3, 3, 3,  3, 3, 4, 4, 4,  4, 4, 5, 5, 5,  6

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
		lda a:playback_delay_count  ;  4 13 (12 + 1)

	patch_2:
		inc dummy                   ;  5  5
		dec dummy                   ;  5 10
		lda a:playback_delay_count  ;  4 14 (12 + 2)

	patch_3:
		inc dummy                   ;  5  5
		lda (dummy, x)              ;  6 11
		lda a:playback_delay_count  ;  4 15 (12 + 3)

	patch_4:
		lda (dummy, x)              ;  6  6
		lda (dummy, x)              ;  6 12
		lda a:playback_delay_count  ;  4 16 (12 + 4)

	patch_5:
		lda (dummy, x)              ;  6  6
		lda (dummy, x)              ;  6 12
		nop                         ;  2 14
		lda playback_delay_count    ;  3 17 (12 + 5)
	.endproc

.segment "DECODE"

cleanup:
	jmp load_next_superblock

.endproc

.export load_decoder
.proc load_decoder
	.import __DECODE_RAMCODE_LOAD__, __DECODE_RAMCODE_RUN__, __DECODE_RAMCODE_SIZE__

	addr_load = $00
	addr_run = $02
	
	lda #<__DECODE_RAMCODE_LOAD__
	sta addr_load
	lda #>__DECODE_RAMCODE_LOAD__
	clc
	adc #>__DECODE_RAMCODE_SIZE__
	sta addr_load + 1
	lda #<__DECODE_RAMCODE_RUN__
	sta addr_run
	lda #>__DECODE_RAMCODE_RUN__
	clc
	adc #>__DECODE_RAMCODE_SIZE__
	sta addr_run + 1
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
		dec addr_load + 1
		dec addr_run + 1
		bpl loop  ; will always branch
end:
	rts
.endproc


