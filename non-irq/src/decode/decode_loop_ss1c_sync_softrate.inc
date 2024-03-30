
	decode_byte_preamble:                       ;     13
		lda playback_delay_count            ;  3  16
		sec                                 ;  2  18
		sbc #2                              ;  2  20
		sta tmp_delay_count                 ;  3  23
		
		ldx #4                              ;  2  25
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 19  44
	continue_playing:
	patch_location_2_1:
		play_sample_2_comb_softrate         ;     57 + 5n
		
		ldx #8                              ;  2   2
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 39  41
		lda dummy                           ;  3  44
	decode_byte_entry:
	patch_location_3_0:
		play_sample_3_comb_softrate         ;     57 + 5n
		lda (ptr_bitstream), y              ;  5   5  load byte in bitstream
		tax                                 ;  2   7
		lda decode_byte_jump_tbl1_low, x    ;  4  11  fetch jump table address to decode nibble
		sta jmp_dst                         ;  3  14
		lda decode_byte_jump_tbl1_high, x   ;  4  18  fetch jump table address to decode nibble
		sta jmp_dst + 1                     ;  3  21
		php                                 ;  4  25
		plp                                 ;  3  28
		php                                 ;  4  32
		plp                                 ;  3  35
		lda a:last_sample                   ;  4  39
		tax                                 ;  2  41
	patch_location_4_0:
		play_sample_4_comb_softrate         ;     57 + 5n
		
		txa                                 ;  2   2  load temporary regs
		jmp (jmp_dst)                       ;  5   7  jump to fetched address
		; --------------------------------- ; 35  42
	
	decode_byte_return_nibble1:
		tax                                 ;  2  44
	patch_location_1_0:
		play_sample_1_comb_softrate         ;     57 + 5n
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
			dex                          ;  2
			c_bne :-                     ;  3
			;                           ; 14  42
		nop                                 ;  2  44
	patch_location_2_0:
		play_sample_2_comb_softrate              ;     57 + 5n

		ldx #8                              ;  2   2
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 39  41
		lda dummy                           ;  3  44
	patch_location_3_1:
		play_sample_3_comb_softrate         ;     57 + 5n
		
		ldx #7                              ;  2   2
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 34  36
		lda last_sample                     ;  3  39
		tax                                 ;  2  41
	patch_location_4_1:
		play_sample_4_comb_softrate         ;     57 + 5n
		
		txa                                 ;  2   2  load temporary regs
		jmp (jmp_dst)                       ;  5   7  jump to fetched address
		; --------------------------------- ; 35  42
	
	ladder:
		jmp decode_byte_preamble            ;  3  13

	decode_byte_return_nibble2:
		tax                                 ;  2  44
	patch_location_1_1:
		play_sample_1_comb_softrate         ;     57 + 5n
		stx last_sample                     ;  3   3
		
		iny                                 ;  2   5
		cpy #16                             ;  2   7
		c_bne ladder                        ;  3  10

after:
	; Bitstream pointer update           ; -1   9
	lda ptr_bitstream                    ;  3  12
	adc #15                              ;  2  14      HACK: carry is always set, so we're
	;                                                  actually adding 16
	sta ptr_bitstream                    ;  3  17
	c_bcc nocarry_ptr_bitstream          ;  3  ..  20
	;                                    ; -1  19  ..
	inc ptr_bitstream + 1                ;  5  24  ..
	dec idx_block                        ;  5  29  ..  check if we need to load the next superblock
	c_bne slope_update_1                 ;  3  32  ..  ..
        ;                                    ; -1  ..  ..  31
	inc a:idx_superblock                 ;  6  ..  ..  37
	pha                                  ;  4  ..  ..  41
	pla                                  ;  3  ..  ..  44
	play_sample_2_comb_softrate          ;     ..  ..  57 + 5n
	jmp cleanup                          ;  3  ..  ..   3  get out of the loop
	; ---------------------------------- ;

carry_1:                                     ;             42
	inc ptr_slopes + 1                   ;  5  ..  ..  47
	play_sample_2_comb_softrate          ;     ..  ..  60 + 5n  NOTE: misaligned by +3 cycles
	jmp load_slopes                      ;  3  ..  ..   6 NOTE: misaligned by +3 cycle

slope_update_1:                              ;     32  ..
	ldy #$00                             ;  2  34  ..
	inc ptr_slopes                       ;  5  39  ..
	c_beq carry_1                        ;  3  ..  ..  42
	;                                    ; -1  41  ..  ..
	lda dummy                            ;  3  44
patch_location_2_2:
	play_sample_2_comb_softrate          ;     57 + 5n
	jmp load_slopes                      ;  3   3  ..


nocarry_ptr_bitstream:                       ;         20
	dec idx_block                        ;  5  ..  25
	c_bne @slope_update                  ;  3  ..  28
        ;                                    ; -1  27  ..
	inc idx_superblock                   ;  5  32  ..
	php                                  ;  4  36  ..
	plp                                  ;  3  39  ..
	inc dummy                            ;  5  44  ..
	play_sample_2_comb_softrate          ;     57 + 5n
	jmp cleanup                          ;  3   3  get out of the loop
	; ---------------------------------- ;

@slope_update:                               ;         28
	inc a:ptr_slopes                     ;  6      34
	c_bne nocarry_2                      ;  3      37  ..
	;                                    ; -1      ..  36
	inc ptr_slopes + 1                   ;  6      ..  42
	ldy #$00                             ;  2      ..  44
	play_sample_2_comb_softrate          ;         ..  57 + 5n
	jmp load_slopes                      ;  3      ..   3

nocarry_2:                                   ;     ..  37
	nop                                  ;  2  ..  39
	ldy dummy                            ;  3  ..  42
	ldy #$00                             ;  2  ..  44
patch_location_2_3:
	play_sample_2_comb_softrate          ;         57 + 5n
	jmp load_slopes                      ;  3       3
