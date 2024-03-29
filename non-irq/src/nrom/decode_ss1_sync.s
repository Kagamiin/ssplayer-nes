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

	jmp_dst  = $0
	slope0   = $2
	tmp_sample_1 = $3
	tmp_sample_2 = $4
	tmp_sample_3 = $5
	tmp_sample_4 = $6
	
.segment "DECODE"

prepare:

load_slopes:                      ;     30

	ldy #$00                  ;  2  32
	lda (ptr_slopes), y       ;  5  37
	sta a:slope0              ;  4  41
	
	ldy #$00                  ;  2  43
	jmp decode_byte_entry     ;  3  46
	
	decode_byte_preamble:                       ;      9
		ldx #6                              ;  2  11
		@delay_loop:
			dex                         ;  2
			c_bne @delay_loop           ;  3
			;                           ; 29  40
		nop                                 ;  2  42
		nop                                 ;  2  44
		nop                                 ;  2  46
		play_sample_2                       ;     57 + 5n
		
		ldx #9                              ;  2   2
		@delay_loop_:
			dex                         ;  2
			c_bne @delay_loop_          ;  3
			;                           ; 44  46
	decode_byte_entry:
		play_sample_3                       ;     57 + 5n
			
	decode_byte:
		lda (ptr_bitstream), y              ;  5   5  load byte in bitstream
		tax                                 ;  2   7
		lda decode_byte_jump_tbl1_low, x    ;  4  11  fetch jump table address to decode nibble
		sta jmp_dst                         ;  3  14
		lda decode_byte_jump_tbl1_high, x   ;  4  18
		sta jmp_dst + 1                     ;  3  21
		ldx #4                              ;  2  23
		@delay_loop:
			dex                         ;  2
			c_bne @delay_loop           ;  3
			;                           ; 19  42
		nop                                 ;  2  44
		nop                                 ;  2  46
		play_sample_4                       ;     57 + 5n
		
		lda last_sample                     ;  3   3  load temporary regs
		jmp (jmp_dst)                       ;  5   8  jump to fetched address
		; --------------------------------- ; 35  43
	
	decode_byte_return_nibble1:
		sta last_sample                     ;  3  46
		play_sample_1                       ;     57 + 5n
		
		lda (ptr_bitstream), y              ;  5   5  load byte in bitstream
		and #$0f                            ;  2   7  extract upper nibble
		tax                                 ;  2   9
		lda decode_byte_jump_tbl2_low, x    ;  4  13  fetch jump table address to decode nibble
		sta jmp_dst                         ;  3  16
		lda decode_byte_jump_tbl2_high, x   ;  4  20  fetch jump table address to decode nibble
		sta jmp_dst + 1                     ;  3  23
		ldx #4                              ;  2  25
		@delay_loop:
			dex                         ;  2
			c_bne @delay_loop           ;  3
			;                           ; 19  44
		nop                                 ;  2  46
		play_sample_2                       ;     57 + 5n
		
		ldx #9                              ;  2   2
		@delay_loop_:
			dex                         ;  2
			c_bne @delay_loop_          ;  3
			;                           ; 44  46
		play_sample_3                       ;     57 + 5n
		
		ldx #9                              ;  2   2
		@delay_loop__:
			dex                         ;  2
			c_bne @delay_loop__         ;  3
			;                           ; 44  46
		play_sample_4                       ;     57 + 5n
		
		lda last_sample                     ;  3   3  load temporary regs
		jmp (jmp_dst)                       ;  5   8  jump to fetched address
		; --------------------------------- ; 35  43
		
	decode_byte_return_nibble2:
		sta last_sample                     ;  3  46
		play_sample_1                       ;     57 + 5n
		
		iny                                 ;  2   2
		cpy #16                             ;  2   4
		c_beq after                         ;  3   7
		;                                   ; -1   6
		jmp decode_byte_preamble            ;  3   9

after:
	; Bitstream pointer update           ;      7
	clc                                  ;  2   9
	lda ptr_bitstream                    ;  3  12
	adc #16                              ;  2  14
	sta ptr_bitstream                    ;  3  17
	c_bcc @nocarry                       ;  3  ..  20
	;                                    ; -1  19  ..
	inc ptr_bitstream + 1                ;  5  24  ..

@nocarry:                                    ;     ..  20
	inc idx_block                        ;  5  ..  25
	lda superblock_length                ;  3  ..  28
	cmp idx_block                        ;  3  ..  31  check if we need to load the next superblock
	c_bne slope_update                   ;  3  ..  ..  34
        ;                                    ; -1  ..  33  ..
        inc idx_superblock                   ;  5
	jmp load_next_superblock             ;  3  ..   3  ..  load next superblock

slope_update:                                ;     ..  ..  34
	inc ptr_slopes                       ;  5  ..  ..  39
	c_bne nocarry_slope                  ;  3  ..  ..  42   ..
	;                                    ; -1  ..  ..       41
	inc ptr_slopes + 1                   ;  5  ..  ..       46

nocarry_slope:                               ;     ..  ..  42
	ldx #6                               ;  2  ..  ..  44
	play_sample_2                        ;     ..  ..  55 + 5n
	@delay_loop:
		dex                          ;  2
		c_bne @delay_loop              ;  3
		;                            ; 29  ..  ..  27
	jmp load_slopes                      ;  3  ..  ..  30

	.macro decode_internal    code, last_code
		
		.if code & $01
			sec
			sbc slope0
		.else
			clc
			adc slope0
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
		decode_code_offs0 (nib >> 3) & $01,                   ; 8  8
		decode_code_offs1 (nib >> 2) & $01, (nib >> 3) & $01  ; 8 16
		decode_code_offs2 (nib >> 1) & $01, (nib >> 2) & $01  ; 8 24
		decode_code_offs3 nib & $01,        (nib >> 1) & $01  ; 8 32
		jmp decode_byte_return_nibble1                        ; 3 35
	.endmacro
	
	.macro decode_nibble_ret2    nib
	.ident (.sprintf ("decode_nibble_ret2_%x", nib)):
		decode_code_offs0 (nib >> 3) & $01,                   ; 8  8
		decode_code_offs1 (nib >> 2) & $01, (nib >> 3) & $01  ; 8 16
		decode_code_offs2 (nib >> 1) & $01, (nib >> 2) & $01  ; 8 24
		decode_code_offs3 nib & $01,        (nib >> 1) & $01  ; 8 32
		jmp decode_byte_return_nibble2                        ; 3 35
	.endmacro

.segment "DECODE_TABLES"
	decode_unroll_1:
	.repeat 16, nib
		decode_nibble_ret1 nib
	.endrepeat

	decode_unroll_2:
	.repeat 16, nib
		decode_nibble_ret2 nib
	.endrepeat

	.align 32
	decode_byte_jump_tbl2_low:
	.repeat 16, nib
		.byte (.lobyte (.ident (.sprintf ("decode_nibble_ret2_%x", nib))))
	.endrepeat

	decode_byte_jump_tbl2_high:
	.repeat 16, nib
		.byte (.hibyte (.ident (.sprintf ("decode_nibble_ret2_%x", nib))))
	.endrepeat

	.align 256
	decode_byte_jump_tbl1_low:
	.repeat 256, by
		.byte (.lobyte (.ident (.sprintf ("decode_nibble_ret1_%x", by >> 4))))
	.endrepeat
	
	decode_byte_jump_tbl1_high:
	.repeat 256, by
		.byte (.hibyte (.ident (.sprintf ("decode_nibble_ret1_%x", by >> 4))))
	.endrepeat
	
.endproc


