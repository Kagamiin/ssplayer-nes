
	patch_trampoline:
		jmp patch_sample_playback

	decode_byte_preamble:                       ;     10
		lda playback_delay_count            ;  3  13
		sec                                 ;  2  15
		sbc #1                              ;  2  17
		sta tmp_delay_count                 ;  3  20
		
		lda fine_pitch                      ;  3  23
		cmp last_fine_pitch                 ;  3  26
		bne patch_trampoline                ;  2  28  ; expected to not branch
		
		ldx #3                              ;  2  30
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 14  44
		nop                                 ;  2  46
	continue_playing:
	patch_location_3_4:
		play_sample_3_softrate              ;     57 + 5n
		
		ldx #9                              ;  2   2
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 44  46
	decode_byte_entry:
	patch_location_4:
		play_sample_4_softrate              ;     57 + 5n
		lda (ptr_bitstream), y              ;  5   5  load byte in bitstream
		tax                                 ;  2   7
		lda decode_byte_jump_tbl1_low, x    ;  4  11  fetch jump table address to decode nibble
		sta jmp_dst1                        ;  3  14
		
		lda last_sample                     ;  3  17  load temporary regs
		jmp (jmp_dst1)                      ;  5  22  jump to fetched address
		; --------------------------------- ; 19  41
	
	decode_byte_return_nibble1:
		sta last_sample                     ;  3  44
		nop                                 ;  2  46
	patch_location_1:
		play_sample_1_softrate              ;     57 + 5n

		lda (ptr_bitstream), y              ;  5   5  load byte in bitstream
		tax                                 ;  2   7
		lda decode_byte_jump_tbl2_low, x    ;  4  11  fetch jump table address to decode nibble
		sta jmp_dst2                        ;  3  14
		
		lda last_sample                     ;  3  17  load temporary regs
		jmp (jmp_dst2)                      ;  5  22  jump to fetched address
		; --------------------------------- ; 19  41

	ladder:
		jmp decode_byte_preamble            ;  3  10

	decode_byte_return_nibble2:
		sta last_sample                     ;  3  44
		nop                                 ;  2  46
	patch_location_2:
		play_sample_2_softrate              ;     57 + 5n
		
		iny                                 ;  2   2
		cpy #32                             ;  2   4
		c_bne ladder                        ;  3   7

after:
	; Bitstream pointer update           ; -1   6
	lda ptr_bitstream                    ;  3   9
	adc #31                              ;  2  11      HACK: carry is always set, so we're
	;                                                  actually adding 16
	sta ptr_bitstream                    ;  3  14
	c_bcc nocarry_ptr_bitstream          ;  4  ..  17
	;                                    ; -2  16  ..
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
	play_sample_3_softrate               ;     ..  ..  57 + 5n
	jmp cleanup                          ;  3  ..  ..   3  get out of the loop
	; ---------------------------------- ;

carry_1:                                     ;             42
	inc ptr_slopes + 1                   ;  5  ..  ..  47
	play_sample_3_softrate               ;     ..  ..  58 + 5n  NOTE: misaligned by +1 cycle
	jmp load_slopes                      ;  3  ..  ..   7 NOTE: misaligned by +1 cycle

slope_update_1:                              ;     29  ..
	ldy #$00                             ;  2  31  ..
	lda ptr_slopes                       ;  3  34  ..
	adc #1                               ;  2  36  ..  HACK: carry is always set, so we're actually adding 2
	sta ptr_slopes                       ;  3  39  ..
	c_beq carry_1                        ;  3  ..  ..  42

nocarry_1:                                   ; -1  41  ..
	inc dummy                            ;  5  46  ..
patch_location_3_1:
	play_sample_3_softrate               ;     57 + 5n
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
	play_sample_3_softrate               ;     57 + 5n
	jmp cleanup                          ;  3   3  get out of the loop
	; ---------------------------------- ;

@slope_update:                               ;         25
	clc                                  ;  2      27  NOTE: carry is always clear
	lda ptr_slopes                       ;  3      30  but we're clearing it to meet cycle count
	adc #2                               ;  2      32  update slope pointer
	sta ptr_slopes                       ;  3      35
	nop                                  ;  2      37
	c_bcc nocarry_2                      ;  3      40  ..
	;                                    ; -1      ..  39
	inc ptr_slopes + 1                   ;  6      ..  44
	ldy #$00                             ;  2      ..  46
	play_sample_3_softrate               ;         ..  57 + 5n
	jmp load_slopes                      ;  3      ..   3

nocarry_2:                                   ;     ..  40
	nop                                  ;  2  ..  42
	nop                                  ;  2  ..  44
	ldy #$00                             ;  2  ..  46
patch_location_3_3:
	play_sample_3_softrate               ;         57 + 5n
	jmp load_slopes                      ;  3       3
