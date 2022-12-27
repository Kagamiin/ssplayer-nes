
.segment "INIT"

.export mapper_init
.proc mapper_init
	lda #$00
	sta $f002             ; disable IRQ
	sta $9002             ; clear PRG swap bit, disable SRAM access
	rts
.endproc

; Sets up an 8KiB bank at $8000..$9FFF
; uses:
;	a = bank number
.export mapper_set_bank_8000
.proc mapper_set_bank_8000
	sta $8000
	rts
.endproc

; Sets up an 8KiB bank at $A000..$BFFF
; uses:
;	a = bank number
.export mapper_set_bank_a000
.proc mapper_set_bank_a000
	sta $a000
	rts
.endproc

; Sets the IRQ period register.
; uses:
;	a = IRQ cycle count
; clobbers:
;	x
.export mapper_irq_set_period
.proc mapper_irq_set_period
	tax
	and #$0f
	sta $f000             ; write 4 low bits of period
	txa
	lsr a
	lsr a
	lsr a
	lsr a
	sta $f001             ; write 4 high bits of period
	rts
.endproc

.export mapper_irq_enable
.proc mapper_irq_enable
	lda #$07              ; enable IRQ, cycle mode, repeat mode
	sta $f002
	rts
.endproc

.export mapper_irq_disable
.proc mapper_irq_disable
	lda #$00              ; disable IRQ
	sta $f002
	rts
.endproc

