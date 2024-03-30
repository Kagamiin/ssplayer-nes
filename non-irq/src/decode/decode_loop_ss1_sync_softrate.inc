
	decode_byte_preamble:                       ;     11
		lda playback_delay_count            ;  3  14
		sec                                 ;  2  16
		sbc #1                              ;  2  18
		sta tmp_delay_count                 ;  3  21
		
		ldx #4                              ;  2  23
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 19  42
		nop                                 ;  2  44
		nop                                 ;  2  46
	continue_playing:
	patch_location_2_1:
		play_sample_2_softrate              ;     57 + 5n
		
		ldx #9                              ;  2   2
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 44  46
	decode_byte_entry:
	patch_location_3_0:
		play_sample_3_softrate              ;     57 + 5n
		lda (ptr_bitstream), y              ;  5   5  load byte in bitstream
		tax                                 ;  2   7
		lda decode_byte_jump_tbl1_low, x    ;  4  11  fetch jump table address to decode nibble
		sta jmp_dst                         ;  3  14
		lda decode_byte_jump_tbl1_high, x   ;  4  18  fetch jump table address to decode nibble
		sta jmp_dst + 1                     ;  3  21
		ldx #4                              ;  2  23
		:
			dex                          ;  2
			c_bne :-                     ;  3
			;                           ; 19  42
		nop                                 ;  2  44
		nop                                 ;  2  46
	patch_location_4_0:
		play_sample_4_softrate              ;     57 + 5n
		
		lda last_sample                     ;  3   3  load temporary regs
		jmp (jmp_dst)                       ;  5   8  jump to fetched address
		; --------------------------------- ; 35  43
	
	decode_byte_return_nibble1:
		sta last_sample                     ;  3  46
	patch_location_1_0:
		play_sample_1_softrate              ;     57 + 5n

		lda (ptr_bitstream), y              ;  5   5  load byte in bitstream
		and #$0f                            ;  2   7  extract upper nibble
		tax                                 ;  2   9
		lda decode_byte_jump_tbl2_low, x    ;  4  13  fetch jump table address to decode nibble
		sta jmp_dst                         ;  3  16
		lda decode_byte_jump_tbl2_high, x   ;  4  20  fetch jump table address to decode nibble
		sta jmp_dst + 1                     ;  3  23
		ldx #4                              ;  2  25
		:
			dex                          ;  2
			c_bne :-                     ;  3
			;                           ; 19  44
		nop                                 ;  2  46
	patch_location_2_0:
		play_sample_2_softrate              ;     57 + 5n

		ldx #9                              ;  2   2
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 44  46
	patch_location_3_1:
		play_sample_3_softrate              ;     57 + 5n
		
		ldx #9                              ;  2   2
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 44  46
	patch_location_4_1:
		play_sample_4_softrate              ;     57 + 5n
		
		lda last_sample                     ;  3   3  load temporary regs
		jmp (jmp_dst)                       ;  5   8  jump to fetched address
		; --------------------------------- ; 35  43
	
	ladder:
		jmp decode_byte_preamble            ;  3  11
		
	.res 4
	
	decode_byte_return_nibble2:
		sta last_sample                     ;  3  46
	patch_location_1_1:
		play_sample_1_softrate              ;     57 + 5n
		
		iny                                 ;  2   2
		cpy #16                             ;  2   4
		x_bne ladder                        ;  4   8  HACK: branch crosses a page boundary

after:
	; Bitstream pointer update           ; -2   6
	lda ptr_bitstream                    ;  3   9
	adc #15                              ;  2  11      HACK: carry is always set, so we're
	;                                                  actually adding 16
	sta ptr_bitstream                    ;  3  14
	c_bcc nocarry_ptr_bitstream          ;  3  ..  17  HACK: branch crosses page boundary
	;                                    ; -1  16  ..
	inc ptr_bitstream + 1                ;  5  21  ..
	dec idx_block                        ;  5  26  ..  check if we need to load the next superblock
	c_bne slope_update_1                 ;  3  29  ..  ..
        ;                                    ; -1  ..  ..  28
	inc idx_superblock                   ;  5  ..  ..  33
	ldx #2                               ;  2  ..  ..  35
	:
		dex                           ;  2
		c_bne :-                      ;  3
		;                            ;  9  ..  ..  44
	nop                                  ;  2  ..  ..  46
	play_sample_2_softrate               ;     ..  ..  57 + 5n
	jmp cleanup                          ;  3  ..  ..   3  get out of the loop
	; ---------------------------------- ;

carry_1:                                     ;             40
	inc a:ptr_slopes + 1                 ;  6  ..  ..  46
	play_sample_2_softrate               ;     ..  ..  57 + 5n
	jmp load_slopes                      ;  3  ..  ..   3

slope_update_1:                              ;     29  ..
	ldy #$00                             ;  2  31  ..
	inc a:ptr_slopes                     ;  6  37  ..
	c_beq carry_1                        ;  3  ..  ..  40
	;                                    ; -1  39  ..
	pha                                  ;  4  43  ..
	pla                                  ;  3  46
patch_location_2_2:
	play_sample_2_softrate               ;     57 + 5n
	jmp load_slopes                      ;  3   3  ..


nocarry_ptr_bitstream:                       ;         17
	dec a:idx_block                      ;  6  ..  23
	c_bne @slope_update                  ;  3  ..  26
        ;                                    ; -1  25  ..
	inc idx_superblock                   ;  5  30  ..
	ldx #3                               ;  2  32  ..
	:
		dex                          ;  2
		c_bne :-                     ;  3
		;                            ; 14  46  ..
	play_sample_2_softrate               ;     57 + 5n
	jmp cleanup                          ;  3   3  get out of the loop
	; ---------------------------------- ;

@slope_update:                               ;         26
	clc                                  ;  2      28  NOTE: carry is always clear
	lda a:ptr_slopes                     ;  4      32  but we're clearing it to meet cycle count
	adc #1                               ;  2      34  update slope pointer
	sta ptr_slopes                       ;  3      37
	c_bcc nocarry_2                      ;  3      40  ..
	;                                    ; -1      ..  39
	inc ptr_slopes + 1                   ;  6      ..  44
	ldy #$00                             ;  2      ..  46
	play_sample_2_softrate               ;         ..  57 + 5n
	jmp load_slopes                      ;  3      ..   3

nocarry_2:                                   ;     ..  40
	nop                                  ;  2  ..  42
	nop                                  ;  2  ..  44
	ldy #$00                             ;  2  ..  46
patch_location_2_3:
	play_sample_2_softrate               ;         57 + 5n
	jmp load_slopes                      ;  3       3
