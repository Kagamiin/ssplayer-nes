
	decode_byte_preamble:                       ;     12
		ldx #5                              ;  2  14
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 24  38
		nop                                 ;  2  40
		nop                                 ;  2  42
		nop                                 ;  2  44
		play_sample_2_comb                  ; 13  57 + 5n
		
		ldx #8                              ;  2   2
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 39  41
		lda dummy                           ;  3  44  dummy
	decode_byte_entry:
		play_sample_3_comb                  ; 13  57 + 5n
			
	decode_byte:
		lda (ptr_bitstream), y              ;  5   5  load byte in bitstream
		tax                                 ;  2   7
		lda decode_byte_jump_tbl1_low, x    ;  4  11  fetch jump table address to decode nibble
		sta jmp_dst                         ;  3  14
		lda decode_byte_jump_tbl1_high, x   ;  4  18
		sta jmp_dst + 1                     ;  3  21
		ldx #2                              ;  2  23
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ;  9  32
		lda last_sample                     ;  3  35
		tax                                 ;  2  37  save last_sample in x
		nop                                 ;  2  39
		nop                                 ;  2  41
		play_sample_4_comb                  ; 16  57 + 5n
		
		txa                                 ;  2   2  load temporary regs
		jmp (jmp_dst)                       ;  5   7  jump to fetched address
		; --------------------------------- ; 35  42
	
	decode_byte_return_nibble1:
		tax                                 ;  2  44  save last_sample in x
		play_sample_1_comb                  ; 13  57 + 5n
		stx last_sample                     ;  3   3
		
		lda (ptr_bitstream), y              ;  5   8  load byte in bitstream
		and #$0f                            ;  2  10  extract upper nibble
		tax                                 ;  2  12
		lda decode_byte_jump_tbl2_low, x    ;  4  16  fetch jump table address to decode nibble
		sta jmp_dst                         ;  3  19
		lda decode_byte_jump_tbl2_high, x   ;  4  23  fetch jump table address to decode nibble
		sta jmp_dst + 1                     ;  3  26
		ldx #3                              ;  2  28
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 14  42
		nop                                 ;  2  44
		play_sample_2_comb                  ; 13  57 + 5n
		
		ldx #8                              ;  2   2
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 39  41
		lda dummy                           ;  3  44  dummy
		play_sample_3_comb                  ; 13  57 + 5n
		
		ldx #7                              ;  2   2
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 34  36
		lda last_sample                     ;  3  39
		tax                                 ;  2  41  save last_sample in x
		play_sample_4_comb                  ; 16  57 + 5n
		
		txa                                 ;  2   2  load temporary regs
		jmp (jmp_dst)                       ;  5   7  jump to fetched address
		; --------------------------------- ; 35  42
		
	decode_byte_return_nibble2:
		tax                                 ;  2  44  save last_sample in x
		play_sample_1_comb                  ; 13  57 + 5n
		stx last_sample                     ;  3   3
		
		iny                                 ;  2   5
		cpy #16                             ;  2   7
		c_beq after                         ;  3  10
		;                                   ; -1   9
		jmp decode_byte_preamble            ;  3  12

after:
	; Bitstream pointer update           ;     10
	lda ptr_bitstream                    ;  3  13
	adc #15                              ;  2  15      HACK: carry is always set, so we're
	;                                                  actually adding 16
	sta ptr_bitstream                    ;  3  18
	c_bcc nocarry_ptr_bitstream          ;  3  ..  21
	;                                    ; -1  20  ..
	inc ptr_bitstream + 1                ;  5  25  ..
	dec idx_block                        ;  5  30  ..  check if we need to load the next superblock
	c_bne @slope_update                  ;  3  33  ..  ..
        ;                                    ; -1  ..  ..  32
	inc idx_superblock                   ;  5  ..  ..  37
	inc dummy                            ;  5  ..  ..  42  dummy
        nop                                  ;  2  ..  ..  44
	play_sample_2_comb                   ; 13  ..  ..  57 + 5n
	jmp cleanup                          ;  3  ..  ..   3  get out of the loop
	; ---------------------------------- ;

@slope_update:                               ;     33  ..
	inc ptr_slopes                       ;  5  38  ..
	c_bne @nocarry                       ;  3  41  ..   ..
	;                                    ; -1  ..  ..   40
	nop                                  ;  2  ..  ..   42
        nop                                  ;  2  ..  ..   44
	play_sample_2_comb                   ; 13  ..  ..   57 + 5n
	inc ptr_slopes + 1                   ;  5  ..  ..    5
	jmp load_slopes                      ;  3  ..  ..    8

@nocarry:                                    ;     41  ..
	lda dummy                            ;  3  44  dummy
	play_sample_2_comb                   ; 13  57 + 5n
	inc dummy                            ;  5   5  dummy
	jmp load_slopes                      ;  3   8  ..

nocarry_ptr_bitstream:                       ;         21
	dec idx_block                        ;  5      26  check if we need to load the next superblock
	c_bne @slope_update                  ;  3      29  ..
        ;                                    ; -1      ..  28
	inc idx_superblock                   ;  5      ..  33
	ldx #2                               ;  2      ..  35
	:
		dex                          ;  2
		c_bne :-                     ;  3
		;                            ;  9      ..  44
	play_sample_2_comb                   ; 13      ..  57 + 5n
	jmp cleanup                          ;  3      ..   3  get out of the loop
	; ---------------------------------- ;

@slope_update:                               ;         29
	inc ptr_slopes                       ;  5      34
	inc dummy                            ;  5      39
	c_bne @nocarry                       ;  3  ..  42
	;                                    ; -1  41  ..
	lda dummy                            ;  3  44  ..  dummy
	play_sample_2_comb                   ; 13  57 + 5n ..
	inc ptr_slopes + 1                   ;  5   5  ..
	jmp load_slopes                      ;  3   8  ..

@nocarry:                                    ;         42
	nop                                  ;  2      44
	play_sample_2_comb                   ; 13      57 + 5n
	inc dummy                            ;  5       5  dummy
	jmp load_slopes                      ;  3       8
