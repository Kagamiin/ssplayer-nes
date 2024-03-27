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

	.import load_next_superblock
	
	.import bank_numbers

	.global buf_pcm

	jmp_dst1 = $0
	jmp_dst2 = $2
	slope0   = $4
	slope1   = $5
	tmp_sample_1 = $6
	tmp_sample_2 = $7
	tmp_sample_3 = $8
	tmp_sample_4 = $9

	.macro bankswitch
		tay                  ; 2  2
		sta bank_numbers, y  ; 5  7
	.endmacro
	
.segment "DECODE"

prepare:
	lda #>decode_unroll_1
	sta jmp_dst1+1
	lda #>decode_unroll_2
	sta jmp_dst2+1
	
	lda idx_block
	bne load_slopes
	
	lda superblock_length
	sta idx_block

load_slopes:
	lda slopes_bank           ;  3   2
	bankswitch                ;  7   9

	ldy #$00                  ;  2  11
	lda (ptr_slopes), y       ;  5  16
	sta slope0                ;  3  19
	iny                       ;  2  21  y = 1
	lda (ptr_slopes), y       ;  5  26
	sta slope1                ;  3  29
	
	lda bits_bank             ;  3  32
	bankswitch                ;  7  39
	
	ldy #$00                  ;  2  41
	jmp decode_byte_entry     ;  3  44
	
	decode_byte_preamble:                       ;      7
		ldx #6                              ;  2   9
		@delay_loop:
			dex                         ;  2
			c_bne @delay_loop           ;  3
			;                           ; 29  38
		nop                                 ;  2  40
		nop                                 ;  2  42
		nop                                 ;  2  44
		play_sample_3                       ;     55 + 5n
		
		ldx #8                              ;  2   2
		@delay_loop_:
			dex                         ;  2
			c_bne @delay_loop_          ;  3
			;                           ; 39  41
		ldx $00                             ;  3  44  dummy
	decode_byte_entry:
		play_sample_4                       ;     55 + 5n
			
	decode_byte:
		lda (ptr_bitstream), y              ;  5   5  load byte in bitstream
		tax                                 ;  2   7
		lda decode_byte_jump_tbl1_low, x    ;  4  11  fetch jump table address to decode nibble
		sta jmp_dst1                        ;  3  14
		
		lda last_sample                     ;  3  17  load temporary regs
		jmp (jmp_dst1)                      ;  5  22  jump to fetched address
		; --------------------------------- ; 19  41
	
	decode_byte_return_nibble1:
		sta last_sample                     ;  3  44
		play_sample_1                       ;     55 + 5n
		
		lda (ptr_bitstream), y              ;  5   5  load byte in bitstream
		tax                                 ;  2   7
		lda decode_byte_jump_tbl2_low, x    ;  4  11  fetch jump table address to decode nibble
		sta jmp_dst2                        ;  3  14
		
		lda last_sample                     ;  3  17  load temporary regs
		jmp (jmp_dst2)                      ;  5  22  jump to fetched address
		; --------------------------------- ; 19  41
		
	decode_byte_return_nibble2:
		sta last_sample                     ;  3  44
		play_sample_2                       ;     55 + 5n
		
		iny                                 ;  2   2
		cpy #32                             ;  2   4
		c_bne decode_byte_preamble          ;  3   7

after:
	; Bitstream pointer update           ; -1   6
	lda ptr_bitstream                    ;  3   9
	adc #31                              ;  2  11      HACK: carry is always set, so we're actually adding 32
	sta ptr_bitstream                    ;  3  14
	c_bcc @nocarry                       ;  3  ..  17
	;                                    ; -1  16  ..
	inc ptr_bitstream + 1                ;  5  21  ..
	jmp carry_ptr_bitstream              ;  3  24  ..

@nocarry:
	dec idx_block                        ;  5  ..  22
	c_bne slope_update                   ;  3  ..  25
        ;                                    ; -1  ..  24
	inc a:idx_superblock                 ;  6  ..  30
	nop                                  ;  2  ..  32
	nop                                  ;  2  ..  34
	nop                                  ;  2  ..  36
	nop                                  ;  2  ..  38
	nop                                  ;  2  ..  40
	nop                                  ;  2  ..  42
	nop                                  ;  2  ..  44
	play_sample_3                        ;         55 + 5n
	jmp load_next_superblock             ;  3  ..   3  load next superblock

slope_update:                                ;     ..  25
	lda ptr_slopes                       ;  3  ..  28  update slope pointer
	adc #2                               ;  2  ..  30  HACK: carry is always clear
	sta ptr_slopes                       ;  3  ..  33
	c_bcc nocarry_slope                  ;  3  ..  36       ..
	;                                    ; -1  ..  ..       35
	inc ptr_slopes + 1                   ;  5  ..  ..       40
	play_sample_3                        ;                  51 + 5n
	jmp load_slopes                      ;  3               -1

nocarry_slope:                                    ;     ..  36
	nop                                  ;  2  ..  38
	nop                                  ;  2  ..  40
	play_sample_3                        ;         51 + 5n
	jmp load_slopes                      ;  3      -1
	
	
carry_ptr_bitstream:                         ;     24
	dec idx_block                        ;  5  29
	c_bne slope_update_2                 ;  3  32
        ;                                    ; -1  31
	inc idx_superblock                   ;  5  36
	nop                                  ;  2  38
	nop                                  ;  2  40
	nop                                  ;  2  42
	nop                                  ;  2  44
	play_sample_3                        ;     55 + 5n
	jmp load_next_superblock             ;  3   3  load next superblock

slope_update_2:                              ;     32
	lda ptr_slopes                       ;  3  35  update slope pointer
	adc #1                               ;  2  37  HACK: carry is always set, so we're actually adding 2
	sta ptr_slopes                       ;  3  40
	c_bcc @nocarry                       ;  3  43       ..
	;                                    ; -1  ..       42
	inc ptr_slopes + 1                   ;  5  ..       47

@nocarry:
	play_sample_3                        ;     54 + 5n  58 + 5n
	;                                    ;     -1     -- 3
	; ---------------------------------- ; misaligned ^ should be -1
load_slopes_inline:
	lda slopes_bank                      ;  3   2
	bankswitch                           ;  7   9

	ldy #$00                             ;  2  11
	lda (ptr_slopes), y                  ;  5  16
	sta slope0                           ;  3  19
	iny                                  ;  2  21  y = 1
	lda (ptr_slopes), y                  ;  5  26
	sta slope1                           ;  3  29
	
	lda bits_bank                        ;  3  32
	bankswitch                           ;  7  39
	
	ldy #$00                             ;  2  41
	jmp decode_byte_entry                ;  3  44

	.macro adc_slope_id    idx
		adc .ident (.sprintf ("slope%x", (idx)))
	.endmacro

	.macro sbc_slope_id    idx
		sbc .ident (.sprintf ("slope%x", (idx)))
	.endmacro

	.macro decode_internal    code, last_code
		
		.if code & $02
			sec                        ; 2  2
			sbc_slope_id (code & $01)  ; 3  5
		.else
			clc                        ; 2  2
			adc_slope_id (code & $01)  ; 3  5
		.endif
	.endmacro

	.macro decode_code_offs0    code, last_code
		decode_internal code, last_code     ; 5  5
		sta tmp_sample_1                    ; 3  8
	.endmacro
	
	.macro decode_code_offs1    code, last_code
		decode_internal code, last_code     ; 5  5
		sta tmp_sample_2                    ; 3  8
	.endmacro
	
	.macro decode_code_offs2    code, last_code
		decode_internal code, last_code     ; 5  5
		sta tmp_sample_3                    ; 3  8
	.endmacro
	
	.macro decode_code_offs3    code, last_code
		decode_internal code, last_code     ; 5  5
		sta tmp_sample_4                    ; 3  8
	.endmacro

	.macro decode_nibble_ret1    nib
	.ident (.sprintf ("decode_nibble_ret1_%x", nib)):
		decode_code_offs0 (nib >> 2) & $03,                   ; 8  8
		decode_code_offs1 nib & $03,        (nib >> 2) & $03  ; 8 16
		jmp decode_byte_return_nibble1                        ; 3 19
	.endmacro
	
	.macro decode_nibble_ret2    nib
	.ident (.sprintf ("decode_nibble_ret2_%x", nib)):
		decode_code_offs2 (nib >> 2) & $03,                   ; 8  8
		decode_code_offs3 nib & $03,        (nib >> 2) & $03  ; 8 16
		jmp decode_byte_return_nibble2                        ; 3 19
	.endmacro

.segment "DECODE_TABLES"
	.align 256
	decode_unroll_1:
	.repeat 16, nib
		decode_nibble_ret1 nib
	.endrepeat

	.align 256
	decode_unroll_2:
	.repeat 16, nib
		decode_nibble_ret2 nib
	.endrepeat

	.align 256
	decode_byte_jump_tbl1_low:
	.repeat 256, by
		.byte (.lobyte (.ident (.sprintf ("decode_nibble_ret1_%x", by >> 4))))
	.endrepeat
	
	decode_byte_jump_tbl2_low:
	.repeat 256, nib
		.byte (.lobyte (.ident (.sprintf ("decode_nibble_ret2_%x", nib & $f))))
	.endrepeat
	
	
.endproc


