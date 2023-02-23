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
	tmp_sample_4_last = $7

	.macro bankswitch
		tay                  ; 2  2
		sta bank_numbers, y  ; 5  7
	.endmacro

	.macro play_sample_2_comb_minus5
		lda playback_delay_count   ;  3  3
		sec                        ;  2  5
		sbc #2                     ;  2  7
		@delay_loop_2:
			sbc #1              ;  2
			c_bne @delay_loop_2 ;  3
		;                          ;-11 -4 + 5n

		lda tmp_sample_2           ;  3 -1 + 5n
		adc tmp_sample_1           ;  3  2 + 5n
		lsr a                      ;  2  4 + 5n
		sta $4011                  ;  4  8 + 5n
	.endmacro
	
	.macro play_sample_2_comb_minus4
		lda playback_delay_count   ;  3  3
		sec                        ;  2  5
		sbc #2                     ;  2  7
		@delay_loop_2:
			sbc #1              ;  2
			c_bne @delay_loop_2 ;  3
		;                          ;-11 -4 + 5n

		lda a:tmp_sample_2         ;  4  0 + 5n
		adc tmp_sample_1           ;  3  3 + 5n
		lsr a                      ;  2  5 + 5n
		sta $4011                  ;  4  9 + 5n
	.endmacro
	
.segment "DECODE"

prepare:

load_slopes:                      ;      8
	lda slopes_bank           ;  3  11
	bankswitch                ;  7  18

	ldy #$00                  ;  2  20
	lda (ptr_slopes), y       ;  5  25
	sta slope0                ;  3  28
	
	lda a:bits_bank           ;  4  32
	bankswitch                ;  7  39
	
	ldy #$00                  ;  2  41
	jmp decode_byte_entry     ;  3  44
	
	decode_byte_preamble:                       ;     11
		ldx #6                              ;  2  13
		@delay_loop:
			dex                         ;  2
			c_bne @delay_loop           ;  3
			;                           ; 29  42
		nop                                 ;  2  44
		play_sample_2_comb                  ; 13  57 + 5n
		
		ldx #8                              ;  2   2
		@delay_loop_:
			dex                         ;  2
			c_bne @delay_loop_          ;  3
			;                           ; 39  41
		lda $0                              ;  3  44  dummy
	decode_byte_entry:
		play_sample_3_comb                  ; 13  57 + 5n
			
	decode_byte:
		lda (ptr_bitstream), y              ;  5   5  load byte in bitstream
		tax                                 ;  2   7
		lda decode_byte_jump_tbl1_low, x    ;  4  11  fetch jump table address to decode nibble
		sta jmp_dst                         ;  3  14
		lda decode_byte_jump_tbl1_high, x   ;  4  18
		sta jmp_dst + 1                     ;  3  21
		ldx #3                              ;  2  23
		@delay_loop:
			dex                         ;  2
			c_bne @delay_loop           ;  3
			;                           ; 14  37
		nop                                 ;  2  39
		nop                                 ;  2  41
		play_sample_4_comb                  ; 16  57 + 5n
		
		lda last_sample                     ;  3   3  load temporary regs
		jmp (jmp_dst)                       ;  5   8  jump to fetched address
		; --------------------------------- ; 35  43
	
	decode_byte_return_nibble1:
		sta last_sample                     ;  3   2
		play_sample_1_comb                  ; 13  59 + 5n
		
		lda (ptr_bitstream), y              ;  5   7  load byte in bitstream
		and #$0f                            ;  2   9  extract upper nibble
		tax                                 ;  2  11
		lda decode_byte_jump_tbl2_low, x    ;  4  15  fetch jump table address to decode nibble
		sta jmp_dst                         ;  3  18
		lda decode_byte_jump_tbl2_high, x   ;  4  22  fetch jump table address to decode nibble
		sta jmp_dst + 1                     ;  3  25
		ldx #3                              ;  2  27
		@delay_loop:
			dex                         ;  2
			c_bne @delay_loop           ;  3
			;                           ; 14  41
		lda $0                              ;  3  44  dummy
		play_sample_2_comb                  ; 13  57 + 5n
		
		ldx #8                              ;  2   2
		@delay_loop_:
			dex                         ;  2
			c_bne @delay_loop_          ;  3
			;                           ; 39  41
		lda $0                              ;  3  44  dummy
		play_sample_3_comb                  ; 13  57 + 5n
		
		ldx #8                              ;  2   2
		@delay_loop__:
			dex                         ;  2
			c_bne @delay_loop__         ;  3
			;                           ; 39  41
		play_sample_4_comb                  ; 16  57 + 5n
		
		lda last_sample                     ;  3   3  load temporary regs
		jmp (jmp_dst)                       ;  5   8  jump to fetched address
		; --------------------------------- ; 35  43
		
	decode_byte_return_nibble2:
		sta last_sample                     ;  3  46
		play_sample_1_comb                  ; 13  59 + 5n
		
		iny                                 ;  2   4
		cpy #16                             ;  2   6
		c_beq after                         ;  3   9
		;                                   ; -1   8
		jmp decode_byte_preamble            ;  3  11

after:
	; Bitstream pointer update           ;      9
	clc                                  ;  2  11
	lda ptr_bitstream                    ;  3  14
	adc #16                              ;  2  16
	sta ptr_bitstream                    ;  3  19
	c_bcc @nocarry                       ;  3  ..  22
	;                                    ; -1  21  ..
	inc ptr_bitstream + 1                ;  5  26  ..
	jmp carry_ptr_bitstream              ;  3  29  ..

@nocarry:                                    ;     ..  22
	inc idx_block                        ;  5  ..  27
	lda superblock_length                ;  3  ..  30
	cmp idx_block                        ;  3  ..  33  check if we need to load the next superblock
	c_bne slope_update                   ;  3  ..  ..  36
        ;                                    ; -1  ..  35  ..
	inc idx_superblock                   ;  5  ..  40  ..
	nop                                  ;  2  ..  42  ..
	nop                                  ;  2  ..  44  ..
	play_sample_2_comb                   ; 13      57 + 5n
	jmp load_next_superblock             ;  3  ..   3  ..  load next superblock

slope_update:                                ;     ..  ..  36
	inc ptr_slopes                       ;  5  ..  ..  41
	c_bne nocarry_slope                  ;  3  ..  ..  44   ..
	;                                    ; -1  ..  ..       43
	play_sample_2_comb                   ; 13               56 + 5n
	inc a:ptr_slopes + 1                 ;  6  ..  ..        5
	jmp load_slopes                      ;  3  ..  ..        8

nocarry_slope:                               ;     ..  ..  44
	play_sample_2_comb                   ; 13  ..  ..  57 + 5n
	inc $0                               ;  5  ..  ..   5  dummy
	jmp load_slopes                      ;  3  ..  ..   8
	
carry_ptr_bitstream:                         ;     29
	inc idx_block                        ;  5  34
	lda superblock_length                ;  3  37
	cmp idx_block                        ;  3  40  check if we need to load the next superblock
	c_bne slope_update_2                 ;  3  43
        ;                                    ; -1  42
        nop                                  ;  2  44
	play_sample_2_comb                   ; 13  57 + 5n
	inc idx_superblock                   ;  5   5
	jmp load_next_superblock             ;  3   8  load next superblock

slope_update_2:                              ;     43
	inc ptr_slopes                       ;  5  48
	c_bne nocarry_slopes_2               ;  3  51       ..
	;                                    ; -1  ..       50
	play_sample_2_comb_minus5            ;  8           58 + 5n
	inc ptr_slopes + 1                   ;  5  ..        6
	jmp load_slopes                      ;  3  ..        9
	;                                    ; misaligned ---^ should be 8

nocarry_slopes_2:                            ;     51
	play_sample_2_comb_minus5            ;  8  59 + 5n
	lda $0                               ;  3   5  dummy
	jmp load_slopes                      ;  3   8

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


