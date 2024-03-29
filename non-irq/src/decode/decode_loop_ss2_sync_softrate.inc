
	decode_byte_preamble:                       ;     10
		lda playback_delay_count            ;  3  13
		sec                                 ;  2  15
		sbc #1                              ;  2  17
		sta tmp_delay_count                 ;  3  20
		
		lda a:fine_pitch                    ;  4  24
		cmp last_fine_pitch                 ;  3  27
		bne patch_trampoline                ;  2  29  ; expected to not branch
		
		ldx #3                              ;  2  31
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 14  45
	continue_playing:
	patch_location_3_4:
		play_sample_3_softrate              ;     57 + 5n
		
		ldx #7                              ;  2   2
		:
			dex                         ;  2
			c_bne :-                    ;  3
			;                           ; 34  36
		nop                                 ;  2  38
		nop                                 ;  2  40
		nop                                 ;  2  42
		c_beq patch_location_4              ;  3  45

	patch_trampoline:
		jmp patch_sample_playback

	decode_byte_entry:
	patch_location_4_m1:
		play_sample_4_softrate_m1cyc        ;     57 + 5n
		lda (ptr_bitstream), y              ;  5   7  load byte in bitstream
		tax                                 ;  2   7
		lda decode_byte_jump_tbl1_low, x    ;  4  11  fetch jump table address to decode nibble
		sta jmp_dst1                        ;  3  14
		
		lda last_sample                     ;  3  17  load temporary regs
		jmp (jmp_dst1)                      ;  5  22  jump to fetched address
		; --------------------------------- ; 19  41

	patch_location_4:
		play_sample_4_softrate              ;     57 + 5n
		lda (ptr_bitstream), y              ;  5   5  load byte in bitstream
		tax                                 ;  2   7
		lda decode_byte_jump_tbl1_low, x    ;  4  11  fetch jump table address to decode nibble
		sta jmp_dst1                        ;  3  14
		
		lda last_sample                     ;  3  17  load temporary regs
		jmp (jmp_dst1)                      ;  5  22  jump to fetched address
		; --------------------------------- ; 19  41
	
	ladder:
		jmp decode_byte_preamble            ;  3  10
	
	decode_byte_return_nibble1:
		sta a:last_sample                   ;  3  45
	patch_location_1:
		play_sample_1_softrate              ;     57 + 5n

		lda (ptr_bitstream), y              ;  5   5  load byte in bitstream
		tax                                 ;  2   7
		lda decode_byte_jump_tbl2_low, x    ;  4  11  fetch jump table address to decode nibble
		sta jmp_dst2                        ;  3  14
		
		lda last_sample                     ;  3  17  load temporary regs
		jmp (jmp_dst2)                      ;  5  22  jump to fetched address
		; --------------------------------- ; 19  41
		
	decode_byte_return_nibble2:
		sta a:last_sample                   ;  4  45
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
	lda ptr_slopes                       ;  3  32  ..
	adc #1                               ;  2  34  ..  HACK: carry is always set, so we're actually adding 2
	sta ptr_slopes                       ;  3  37  ..
	c_bne nocarry_1                      ;  3  40  ..  ..
	;                                    ; -1  ..  ..  39
	inc ptr_slopes + 1                   ;  5  ..  ..  44
	jmp hopover_page_boundary            ;  3  ..  ..  47 ; HACK

nocarry_1:                                   ;     40  ..
	ldy dummy                            ;  3  43  ..
	ldy #$00                             ;  2  45  ..
patch_location_3_1:
	play_sample_3_softrate               ;     57 + 5n
	jmp load_slopes                      ;  3   3  ..

hopover_page_boundary:
	play_sample_3_softrate               ;     ..  ..  59 + 5n  NOTE: misaligned by +2 cycles
	ldy #$00                             ;  2  ..  ..   4
	jmp load_slopes                      ;  3  ..  ..   7 NOTE: misaligned by +4 cycles


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
	adc #2                               ;  2      33  update slope pointer
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
