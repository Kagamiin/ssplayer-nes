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
	
.segment "DECODE"

prepare:
	lda #>decode_unroll_1
	sta jmp_dst1+1
	lda #>decode_unroll_2
	sta jmp_dst2+1

load_slopes:                      ;     21

	ldy #$00                  ;  2  23
	lda (ptr_slopes), y       ;  5  28
	sta slope0                ;  3  31
	iny                       ;  2  33  y = 1
	lda (ptr_slopes), y       ;  5  38
	sta slope1                ;  3  41
	
	ldy #$00                  ;  2  43
	jmp decode_byte_entry     ;  3  46
	
	decode_byte_preamble:                       ;      7
		ldx #7                              ;  2   9
		@delay_loop:
			dex                         ;  2
			c_bne @delay_loop           ;  3
			;                           ; 34  43
		ldx $00                             ;  3  46  dummy
		play_sample_3                       ;     57 + 5n
		
		ldx #9                              ;  2   2
		@delay_loop_:
			dex                         ;  2
			c_bne @delay_loop_          ;  3
			;                           ; 44  46
	decode_byte_entry:
		play_sample_4                       ;     57 + 5n
			
	decode_byte:
		lda (ptr_bitstream), y              ;  5   5  load byte in bitstream
		tax                                 ;  2   7
		lda decode_byte_jump_tbl1_low, x    ;  4  11  fetch jump table address to decode nibble
		sta jmp_dst1                        ;  3  14
		
		lda last_sample                     ;  3  17  load temporary regs
		jmp (jmp_dst1)                      ;  5  22  jump to fetched address
		; --------------------------------- ; 19  41
	
	decode_byte_return_nibble1:
		nop                                 ;  2  43
		sta last_sample                     ;  3  46
		play_sample_1                       ;     57 + 5n
		
		lda (ptr_bitstream), y              ;  5   5  load byte in bitstream
		and #$0f                            ;  2   7  extract upper nibble
		tax                                 ;  2   9
		lda decode_byte_jump_tbl2_low, x    ;  4  13  fetch jump table address to decode nibble
		sta jmp_dst2                        ;  3  16
		
		lda last_sample                     ;  3  19  load temporary regs
		jmp (jmp_dst2)                      ;  5  24  jump to fetched address
		; --------------------------------- ; 19  43
		
	decode_byte_return_nibble2:
		sta last_sample                     ;  3  46
		play_sample_2                       ;     57 + 5n
		
		iny                                 ;  2   2
		cpy #32                             ;  2   4
		c_bne decode_byte_preamble          ;  3   7

after:
	; Bitstream pointer update           ; -1   6
	clc                                  ;  2   8
	lda ptr_bitstream                    ;  3  11
	adc #32                              ;  2  13
	sta ptr_bitstream                    ;  3  16
	c_bcc @nocarry                       ;  3  ..  19
	;                                    ; -1  18  ..
	inc ptr_bitstream + 1                ;  5  23  ..

@nocarry:
	inc idx_block                        ;  5  ..  24
	lda superblock_length                ;  3  ..  27
	cmp idx_block                        ;  3  ..  30  check if we need to load the next superblock
	c_bne slope_update                   ;  3  ..  33
        ;                                    ; -1  ..  32
        inc idx_superblock                   ;  5
	jmp load_next_superblock             ;  3  ..   3  load next superblock

slope_update:                                ;     ..  33
	clc                                  ;  2  ..  35
	lda ptr_slopes                       ;  3  ..  38  update slope pointer
	adc #2                               ;  2  ..  40
	sta ptr_slopes                       ;  3  ..  43
	c_bcc @nocarry                       ;  3  ..  46       ..
	;                                    ; -1  ..  ..       45
	inc ptr_slopes + 1                   ;  5  ..  ..       50

@nocarry:                                    ;     ..  46       50
	play_sample_3                        ;         57 + 5n  61 + 5n
	;                                    ;          0        4
	ldx #3                               ;  2  ..   2        6
	@delay_loop_:
		dex                          ;  2
		c_bne @delay_loop_           ;  3
		;                            ; 14      16       20
	nop                                  ;  2      18       22
	jmp load_slopes                      ;  3      21    -- 25
	; ---------------------------------- ; misaligned ---^ should be 21

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

	decode_byte_jump_tbl2_low:
	.repeat 16, nib
		.byte (.lobyte (.ident (.sprintf ("decode_nibble_ret2_%x", nib))))
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
	
	
.endproc


