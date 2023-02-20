
.segment "INIT"

.export mapper_init
.proc mapper_init
	lda #3
	sta $5100                      ; PRG mode 3 - four 8K banks
	lda #$fe
	sta $5116                      ; map second-to-last bank to $c000-$dfff
	;                              ; to simulate the presence of a fixed bank
	rts
.endproc

; Sets up an 8KiB bank at $8000..$9fff
; uses:
;	a = bank number
.export mapper_set_bank_8000
.proc mapper_set_bank_8000
	ora #$80
	sta $5114
	rts
.endproc

; Sets the IRQ period register.
; uses:
;	a = IRQ cycle count
.export mapper_irq_set_period
.proc mapper_irq_set_period
.globalzp irq_period_holder
	eor #$ff              ; invert value because the MMC5 IRQ timer counts down
	sbc #20               ; compensate for software IRQ retrigger delay
	sta irq_period_holder
	rts
.endproc

.export mapper_irq_enable
.proc mapper_irq_enable
.globalzp irq_period_holder
	lda irq_period_holder
	sta $5209             ; enable IRQ by writing cycle count to timer register
	rts
.endproc

.export mapper_irq_disable
.proc mapper_irq_disable
	lda #$00              ; disable IRQ by stopping the timer register
	sta $5209
	rts
.endproc
