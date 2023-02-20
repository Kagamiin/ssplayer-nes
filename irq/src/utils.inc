
.macro ld_w dest word          ; 10 cycles
	lda <word              ;  2  2
	sta dest               ;  3  5
	lda >word              ;  2  7
	sta dest + 1           ;  3 10
.endmacro
