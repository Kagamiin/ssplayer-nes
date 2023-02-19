
.segment "INIT"


.export mapper_init
.proc mapper_init
	rts
.endproc

.export mapper_set_bank_8000
.proc mapper_set_bank_8000   ;    6
	tay                  ; 2  8
	sta bank_numbers, y  ; 5 13
	rts                  ; 6 19
.endproc

.export bank_numbers
bank_numbers:
.repeat 256, bank_num
	.byte bank_num
.endrepeat
