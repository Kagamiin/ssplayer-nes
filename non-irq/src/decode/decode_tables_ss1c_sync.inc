
	.macro decode_internal    code, last_code
		
		.if code & $01
			sec
			sbc slope0
		.else
			clc
			adc slope0
		.endif
	.endmacro

	.macro decode_code_offs0    code, last_code
		decode_internal code, last_code     ; 5  5
		sta tmp_sample_1                    ; 3  8
	.endmacro
	
	.macro decode_code_offs1    code, last_code
		decode_internal code, last_code     ; 5  5
		sta tmp_sample_2                    ; 3  8
	.endmacro
	
	.macro decode_code_offs2    code, last_code
		decode_internal code, last_code     ; 5  5
		sta tmp_sample_3                    ; 3  8
	.endmacro
	
	.macro decode_code_offs3    code, last_code
		decode_internal code, last_code     ; 5  5
		sta tmp_sample_4                    ; 3  8
	.endmacro

	.macro decode_nibble_ret1    nib
	.ident (.sprintf ("decode_nibble_ret1_%x", nib)):
		decode_code_offs0 (nib >> 3) & $01,                   ; 8  8
		decode_code_offs1 (nib >> 2) & $01, (nib >> 3) & $01  ; 8 16
		decode_code_offs2 (nib >> 1) & $01, (nib >> 2) & $01  ; 8 24
		decode_code_offs3 nib & $01,        (nib >> 1) & $01  ; 8 32
		jmp decode_byte_return_nibble1                        ; 3 35
	.endmacro
	
	.macro decode_nibble_ret2    nib
	.ident (.sprintf ("decode_nibble_ret2_%x", nib)):
		decode_code_offs0 (nib >> 3) & $01,                   ; 8  8
		decode_code_offs1 (nib >> 2) & $01, (nib >> 3) & $01  ; 8 16
		decode_code_offs2 (nib >> 1) & $01, (nib >> 2) & $01  ; 8 24
		decode_code_offs3 nib & $01,        (nib >> 1) & $01  ; 8 32
		jmp decode_byte_return_nibble2                        ; 3 35
	.endmacro

.segment "DECODE_TABLES"
	decode_unroll_1:
	.repeat 16, nib
		decode_nibble_ret1 nib
	.endrepeat

	decode_unroll_2:
	.repeat 16, nib
		decode_nibble_ret2 nib
	.endrepeat

	.align 32
	decode_byte_jump_tbl2_low:
	.repeat 16, nib
		.byte (.lobyte (.ident (.sprintf ("decode_nibble_ret2_%x", nib))))
	.endrepeat

	decode_byte_jump_tbl2_high:
	.repeat 16, nib
		.byte (.hibyte (.ident (.sprintf ("decode_nibble_ret2_%x", nib))))
	.endrepeat

	.align 256
	decode_byte_jump_tbl1_low:
	.repeat 256, by
		.byte (.lobyte (.ident (.sprintf ("decode_nibble_ret1_%x", by >> 4))))
	.endrepeat
	
	decode_byte_jump_tbl1_high:
	.repeat 256, by
		.byte (.hibyte (.ident (.sprintf ("decode_nibble_ret1_%x", by >> 4))))
	.endrepeat
