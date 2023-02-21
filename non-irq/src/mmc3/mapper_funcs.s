
.segment "INIT"


.export mapper_init
.proc mapper_init
.globalzp mmc3_bank_select_shadow, mmc3_mutex
	lda #$00                     ; PRG ROM bank mode 0, don't invert CHR A12
	sta mmc3_bank_select_shadow
	sta $e000                    ; disable interrupts
	sta mmc3_mutex
	rts
.endproc

.export mapper_set_bank_8000
.proc mapper_set_bank_8000
.globalzp mmc3_bank_select_shadow, mmc3_mutex
	tay
	inc mmc3_mutex
	lda mmc3_bank_select_shadow
	and #%11100000
	ora #%110
	sta $8000
	tya
	sta $8001
	dec mmc3_mutex
	rts
.endproc
