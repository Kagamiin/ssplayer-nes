
	.macro decode_and_store    code, store_location
		.if code = $02
			nop                        ; 2  2
			nop                        ; 2  4
			sta a:store_location       ; 4  8
		.elseif code = $01
			sec                        ; 2  2
			sbc slope0                 ; 3  5
			sta z:store_location       ; 3  8
		.else
			clc                        ; 2  2
			adc slope0                 ; 3  5
			sta z:store_location       ; 3  8
		.endif
	.endmacro

	.macro decode_codeword_part1   cw
	.ident (.sprintf ("decode_codeword_part1_%x", cw)):
	.scope
		w1 := cw .MOD 3
		cw1 := cw / 3
		w0 := cw1 .MOD 3
		decode_and_store  w0, tmp_sample_1  ; 8  8
		decode_and_store  w1, tmp_sample_2  ; 8 16
		jmp decode_byte_return_part1        ; 3 19
	.endscope
	.endmacro
	
	.macro decode_codeword_part2   cw
	.ident (.sprintf ("decode_codeword_part2_%x", cw)):
	.scope
		w4 := cw .MOD 3
		cw4 := cw / 3
		w3 := cw4 .MOD 3
		cw3 := cw4 / 3
		w2 := cw3 .MOD 3
		decode_and_store  w2, tmp_sample_3  ; 8  8
		decode_and_store  w3, tmp_sample_4  ; 8 16
		decode_and_store  w4, tmp_sample_5  ; 8 24
		jmp decode_byte_return_part2        ; 3 27
	.endscope
	.endmacro

.segment "DECODE"
	.repeat 9, bcw
		decode_codeword_part1 bcw
	.endrepeat

	.repeat 27, bcw
		decode_codeword_part2 bcw
	.endrepeat

.segment "DECODE_TABLES"
	.align 256
	decode_byte_jump_tbl1_low:
	.repeat 9, bcw
		.repeat 27
			.byte (.lobyte (.ident (.sprintf ("decode_codeword_part1_%x", bcw))))
		.endrepeat
	.endrepeat
	.repeat 13 ; failsafe
		.byte (.lobyte (.ident ("decode_codeword_part1_8")))
	.endrepeat

	.align 256
	decode_byte_jump_tbl1_high:
	.repeat 9, bcw
		.repeat 27
			.byte (.hibyte (.ident (.sprintf ("decode_codeword_part1_%x", bcw))))
		.endrepeat
	.endrepeat
	.repeat 13 ; failsafe
		.byte (.hibyte (.ident ("decode_codeword_part1_8")))
	.endrepeat

	.align 256
	decode_byte_jump_tbl2_low:
	.repeat 9
		.repeat 27, bcw
			.byte (.lobyte (.ident (.sprintf ("decode_codeword_part2_%x", bcw))))
		.endrepeat
	.endrepeat
	.repeat 13 ; failsafe
		.byte (.lobyte (.ident ("decode_codeword_part2_1a")))
	.endrepeat

	.align 256
	decode_byte_jump_tbl2_high:
	.repeat 9
		.repeat 27, bcw
			.byte (.hibyte (.ident (.sprintf ("decode_codeword_part2_%x", bcw))))
		.endrepeat
	.endrepeat
	.repeat 13 ; failsafe
		.byte (.hibyte (.ident ("decode_codeword_part2_1a")))
	.endrepeat
