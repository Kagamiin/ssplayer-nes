
	decode_byte_preamble:                       ;      9
		ldx #6                              ;  2  11
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 29  40
		nop                                 ;  2  42
		nop                                 ;  2  44
		nop                                 ;  2  46
		play_sample_2                       ;     57 + 5n
		
		ldx #9                              ;  2   2
		:
			dex                         ;  2
			c_bne :-                    ;  3
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
		:
			dex                         ;  2
			c_bne :-                    ;  3
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
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 19  44
		nop                                 ;  2  46
		play_sample_2                       ;     57 + 5n
		
		ldx #9                              ;  2   2
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 44  46
		play_sample_3                       ;     57 + 5n
		
		ldx #9                              ;  2   2
		:
			dex                         ;  2
			c_bne :-                    ;  3
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
	lda ptr_bitstream                    ;  3  10
	adc #15                              ;  2  12      HACK: carry is always set, so we're
	;                                                  actually adding 16
	sta ptr_bitstream                    ;  3  15
	c_bcc nocarry_ptr_bitstream          ;  3  ..  18
	;                                    ; -1  17  ..
	inc ptr_bitstream + 1                ;  5  22  ..
	dec idx_block                        ;  5  27  check if we need to load the next superblock
	c_bne @slope_update                  ;  3  30  ..
        ;                                    ; -1  29  ..
	inc idx_superblock                   ;  5  34  ..
	inc dummy                            ;  5  39  ..
	inc dummy                            ;  5  44  ..
	nop                                  ;  2  46  ..
	play_sample_2                        ;     57 + 5n
	jmp cleanup                          ;  3   3  get out of the loop
	; ---------------------------------- ;

@slope_update:                               ;     30  ..
	inc ptr_slopes                       ;  5  35  ..
	c_bne @nocarry                       ;  3  38  ..  ..
	;                                    ; -1  ..  ..  37
	inc ptr_slopes + 1                   ;  5  ..  ..  42
	nop                                  ;  2  ..  ..  44
	nop                                  ;  2  ..  ..  46
	play_sample_2                        ;         ..  57 + 5n
	inc dummy                            ;  5  ..  ..   5  dummy
	jmp load_slopes                      ;  3  ..  ..   8

@nocarry:                                    ;     38  ..
	nop                                  ;  2  40  ..
	nop                                  ;  2  42  ..
	nop                                  ;  2  44  ..
	nop                                  ;  2  46  ..
	play_sample_2                        ;     57 + 5n
	inc dummy                            ;  5   5  .. dummy
	jmp load_slopes                      ;  3   8  ..

nocarry_ptr_bitstream:                       ;         18
	dec idx_block                        ;  5      23  check if we need to load the next superblock
	c_bne @slope_update                  ;  3      26  ..
        ;                                    ; -1      ..  25
	inc idx_superblock                   ;  5      ..  30
	ldx #3                               ;  2      ..  32
	:
		dex                          ;  2
		c_bne :-                     ;  3
		;                            ; 14      ..  46
	play_sample_2                        ;         ..  57 + 5n
	jmp cleanup                          ;  3      ..   3  get out of the loop
	; ---------------------------------- ;

@slope_update:                               ;         26
	inc ptr_slopes                       ;  5      31
	c_bne @nocarry                       ;  3      34  ..
	;                                    ; -1      ..  33
	ldx #2                               ;  2      ..  35
	:
		dex                          ;  2
		c_bne :-                     ;  3
		;                            ;  9      ..  44
	nop                                  ;  2      ..  46
	play_sample_2                        ;         ..  57 + 5n
	inc ptr_slopes + 1                   ;  5      ..   5
	jmp load_slopes                      ;  3      ..   8

@nocarry:                                    ;  1      34
	inc dummy                            ;  5      39  dummy
	inc dummy                            ;  5      44  dummy
	nop                                  ;  2      46
	play_sample_2                        ; 13      57 + 5n
	inc dummy                            ;  5       5  dummy
	jmp load_slopes                      ;  3       8

