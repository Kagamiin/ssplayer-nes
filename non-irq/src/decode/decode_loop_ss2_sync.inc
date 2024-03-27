
	decode_byte_preamble:                       ;      7
		ldx #7                              ;  2   9
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 34  43
		ldx dummy                           ;  3  46  dummy
		play_sample_3                       ;     57 + 5n
		
		ldx #9                              ;  2   2
		:
			dex                         ;  2
			c_bne :-                    ;  3
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
	lda ptr_bitstream                    ;  3   9
	adc #31                              ;  2  11      HACK: carry is always set, so we're
	;                                                  actually adding 32
	sta ptr_bitstream                    ;  3  14
	c_bcc nocarry_ptr_bitstream          ;  3  ..  17
	;                                    ; -1  16  ..
	inc ptr_bitstream + 1                ;  5  21  ..
	dec idx_block                        ;  5  26  ..  check if we need to load the next superblock
	c_bne @slope_update                  ;  3  29  ..  ..
        ;                                    ; -1  ..  ..  28
	inc idx_superblock                   ;  5  ..  ..  33
	ldx #2                               ;  2  ..  ..  35
	:
		dex                          ;  2
		c_bne :-                     ;  3
		;                            ;  9  ..  ..  44
	nop                                  ;  2  ..  ..  46
	play_sample_3                        ;     ..  ..  57 + 5n
	jmp cleanup                          ;  3  ..  ..   3  get out of the loop
	; ---------------------------------- ;

@slope_update:                               ;     29  ..
	lda ptr_slopes                       ;  3  32  ..  update slope pointer
	adc #1                               ;  2  34  ..  HACK: carry is always set, so we're
	;                                                  actually adding 2
	sta ptr_slopes                       ;  3  37  ..
	c_bcc @nocarry                       ;  3  40  ..  ..
	;                                    ; -1  ..  ..  39
	inc ptr_slopes + 1                   ;  5  ..  ..  44
	ldy #$00                             ;  2  ..  ..  46
	play_sample_3                        ;     ..  ..  57 + 5n
	jmp load_slopes                      ;  3  ..  ..   3

@nocarry:                                    ;     40  ..
	nop                                  ;  2  42  ..
	nop                                  ;  2  44  ..
	ldy #$00                             ;  2  46  ..
	play_sample_3                        ;     57 + 5n
	jmp load_slopes                      ;  3   3  ..


nocarry_ptr_bitstream:                       ;         17
	dec idx_block                        ;  5  ..  22
	c_bne @slope_update                  ;  3  ..  25
        ;                                    ; -1  24  ..
	inc a:idx_superblock                 ;  6  30  ..
	ldx #3                               ;  2  32  ..
	:
		dex                          ;  2
		c_bne :-                     ;  3
		;                            ; 14  46  ..
	play_sample_3                        ;     57 + 5n
	jmp cleanup                          ;  3   3  get out of the loop
	; ---------------------------------- ;

@slope_update:                               ;         25
	clc                                  ;  2      27  NOTE: carry is always clear
	lda ptr_slopes                       ;  3      30  but we're clearing it to meet cycle count
	adc #2                               ;  2      32  update slope pointer
	sta ptr_slopes                       ;  3      35
	c_bcc @nocarry                       ;  3      38  ..
	;                                    ; -1      ..  37
	inc ptr_slopes + 1                   ;  5      ..  42
	nop                                  ;  2      ..  44
	ldy #$00                             ;  2      ..  46
	play_sample_3                        ;         ..  57 + 5n
	jmp load_slopes                      ;  3      ..   3

@nocarry:                                    ;     ..  38
	nop                                  ;  2  ..  40
	nop                                  ;  2  ..  42
	nop                                  ;  2  ..  44
	ldy #$00                             ;  2  ..  46
	play_sample_3                        ;         57 + 5n
	jmp load_slopes                      ;  3       3
