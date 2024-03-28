
	decode_byte_preamble:                       ;     10
		ldx #6                              ;  2  12
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 29  41
		nop                                 ;  2  43
		nop                                 ;  2  45
	patch_location_3_4:
		play_sample_3_softrate              ;     57 + 5n
		
		ldx #8                              ;  2   2
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 39  41
		nop                                 ;  2  43
		nop                                 ;  2  45
	decode_byte_entry:
	patch_location_4:
		play_sample_4_softrate              ;     57 + 5n
			
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
		lda dummy                           ;  3  45
	patch_location_5:
		play_sample_5_softrate              ;     57 + 5n
		
		lda last_sample                     ;  3   3  load temporary regs
		jmp (jmp_dst)                       ;  5   8  jump to fetched address
		; --------------------------------- ; 19  27
	
	ladder:
		jmp decode_byte_preamble            ;  3  10
	
	decode_byte_return_part1:
		sta last_sample                     ;  3  30
		lda (ptr_bitstream), y              ;  5  35  load byte in bitstream
		tax                                 ;  2  37
		lda decode_byte_jump_tbl2_low, x    ;  4  41  fetch jump table address to decode nibble
		sta a:jmp_dst                       ;  4  45
	patch_location_1:
		play_sample_1_softrate              ;     57 + 5n
		
		lda decode_byte_jump_tbl2_high, x   ;  4   4
		sta jmp_dst + 1                     ;  3   7
		lda last_sample                     ;  3  10  load temporary regs
		jmp (jmp_dst)                       ;  5  15  jump to fetched address
		; --------------------------------- ; 27  42
		
	decode_byte_return_part2:
		sta last_sample                     ;  3  45
	patch_location_2:
		play_sample_2_softrate              ;     57 + 5n
		
		iny                                 ;  2   2
		cpy #16                             ;  2   4
		c_bne ladder                        ;  3   7

after:
	; Bitstream pointer update           ; -1   6
	lda ptr_bitstream                    ;  3   9
	adc #15                              ;  2  11      HACK: carry is always set, so we're
	;                                                  actually adding 16
	sta ptr_bitstream                    ;  3  14
	x_bcc nocarry_ptr_bitstream          ;  4  ..  18  HACK: branch crosses page boundary
	;                                    ; -2  16  ..
	inc ptr_bitstream + 1                ;  5  21  ..
	dec idx_block                        ;  5  26  ..  check if we need to load the next superblock
	c_bne @slope_update                  ;  3  29  ..  ..
        ;                                    ; -1  ..  ..  28
	inc idx_superblock                   ;  5  ..  ..  33
	inc dummy                            ;  5  ..  ..  38
	dec dummy                            ;  5  ..  ..  43
	nop                                  ;  2  ..  ..  45
	play_sample_3_softrate               ;     ..  ..  57 + 5n
	jmp cleanup                          ;  3  ..  ..   3  get out of the loop
	; ---------------------------------- ;

@slope_update:                               ;     29  ..
	inc ptr_slopes                       ;  5  34  ..  update slope pointer
	nop                                  ;  2  36
	c_bne nocarry_1                      ;  3  39  ..  ..
	;                                    ; -1  ..  ..  38
	inc ptr_slopes + 1                   ;  5  ..  ..  43
	ldy #$00                             ;  2  ..  ..  45
	play_sample_3_softrate               ;     ..  ..  57 + 5n
	jmp load_slopes                      ;  3  ..  ..   3

nocarry_1:                                   ;     39  ..
	nop                                  ;  2  41  ..
	nop                                  ;  2  43  ..
	ldy #$00                             ;  2  45  ..
patch_location_3_1:
	play_sample_3_softrate               ;     57 + 5n
	jmp load_slopes                      ;  3   3  ..


nocarry_ptr_bitstream:                       ;         18
	dec idx_block                        ;  5  ..  23
	c_bne @slope_update                  ;  3  ..  26
        ;                                    ; -1  25  ..
	inc idx_superblock                   ;  5  30  ..
	ldx #2                               ;  2  32  ..
	:
		dex                          ;  2
		c_bne :-                     ;  3
		;                            ;  9  41  ..
	nop                                  ;  2  43
	nop                                  ;  2  45
	play_sample_3_softrate               ;     57 + 5n
	jmp cleanup                          ;  3   3  get out of the loop
	; ---------------------------------- ;

@slope_update:                               ;         26
	clc                                  ;  2      28  NOTE: carry is always clear
	lda ptr_slopes                       ;  3      31  but we're clearing it to meet cycle count
	adc #1                               ;  2      33  update slope pointer
	sta ptr_slopes                       ;  3      36
	c_bcc nocarry_2                      ;  3      39  ..
	;                                    ; -1      ..  38
	inc ptr_slopes + 1                   ;  6      ..  43
	ldy #$00                             ;  2      ..  45
	play_sample_3_softrate               ;         ..  57 + 5n
	jmp load_slopes                      ;  3      ..   3

nocarry_2:                                   ;     ..  39
	nop                                  ;  2  ..  41
	nop                                  ;  2  ..  43
	ldy #$00                             ;  2  ..  45
patch_location_3_3:
	play_sample_3_softrate               ;         57 + 5n
	jmp load_slopes                      ;  3       3
