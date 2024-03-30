.segment "DECODE"
	patch_sample_playback:
		lda fine_pitch                             ;  2    2
		tax                                        ;  2    4
		cmp #(patch_table_2 - patch_table_1 - 1)   ;  3    7
		bcc @not_oob_fp                            ;  3   10
		;                                            -1   ..   9
		lda #(patch_table_2 - patch_table_1 - 2)   ;  2   ..  11
		tax                                        ;  2   ..  13
		sta fine_pitch                             ;  3   ..  16
	@not_oob_fp:                                       ;
		lda #(patch_table_2 - patch_table_1 - 1)   ;  2   12  18
		cmp last_fine_pitch                        ;  3   15  21
		bcs @not_oob_lfp                           ;  3   18  24
		;                                            -1   ..  ..   17  23
		lda #(patch_table_2 - patch_table_1 - 1)   ;  2   ..  ..   19  25
		sta last_fine_pitch                        ;  3   ..  ..   22  28
	@not_oob_lfp:                                      ;
		;                                          ;      18  24   22  28
		

		lda patch_table_1, x            ;  4   4    5   5 *
		sta patch_location_1_0 + 8      ;  4   8    4   9
		sta patch_location_1_1 + 8      ;  4  12    4  13

		lda patch_table_2, x            ;  4  16    5  18 *
		sta patch_location_2_0 + 8      ;  4  20    4  22
		sta patch_location_2_1 + 8      ;  4  24    4  26
		sta patch_location_2_2 + 8      ;  4  28    4  30
		sta patch_location_2_3 + 8      ;  4  32    4  34

		lda patch_table_3, x            ;  4  36    5  39 *
		sta patch_location_3_0 + 8      ;  4  40    4  43
		sta patch_location_3_1 + 8      ;  4  44    4  47

		lda patch_table_4, x            ;  4  48    5  52 *
		sta patch_location_4_0 + 8      ;  4  52    4  56
		sta patch_location_4_1 + 8      ;  4  56    4  60

		stx last_fine_pitch        ; 3  3
		jmp continue_load_slopes   ; 3  6

.segment "DECODE_TABLES"

	.align 256
	patch_table_1:
		.byte 5,  5, 4, 4, 4,  4, 3, 3, 3,  3, 2, 2, 2,  2, 1, 1, 1,  1, 0, 0, 0,  6
	patch_table_2:
		.byte 5,  5, 5, 4, 4,  4, 4, 3, 3,  3, 3, 2, 2,  2, 2, 1, 1,  1, 1, 0, 0,  6
	patch_table_3:
		.byte 5,  4, 4, 4, 4,  3, 3, 3, 3,  2, 2, 2, 2,  1, 1, 1, 1,  0, 0, 0, 0,  6
	patch_table_4:
		.byte 5,  5, 5, 5, 4,  4, 4, 4, 3,  3, 3, 3, 2,  2, 2, 2, 1,  1, 1, 1, 0,  6
