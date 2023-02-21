
.segment "INIT"

.export mapper_init
.proc mapper_init
	lda #$b
	sta $8000             ; command $b - PRG bank at $c000-$dfff
	lda #$3e
	sta $a000             ; map second-to-last bank to $c000-$dfff
	;                     ; to simulate the presence of a fixed bank
	lda #$d
	sta $8000             ; command $d - IRQ control
	lda #$00
	sta $a000             ; disable IRQ counter decrement and IRQ generation
	
	ldx #$7
	@loop:
		stx $8000     ; command $0-$7 - CHR banking
		stx $a000     ; map CHR banks linearly
		dex
		bpl @loop
	
	rts
.endproc

; Sets up an 8KiB bank at $8000..$9fff
; uses:
;	a = bank number
.export mapper_set_bank_8000
.proc mapper_set_bank_8000
	php
	sei
	pha
	lda #$9
	sta $8000             ; command $9 - PRG bank at $8000-$9fff
	pla
	sta $a000
	plp
	rts
.endproc

; Sets the IRQ period register.
; uses:
;	a = IRQ cycle count
.export mapper_irq_set_period
.proc mapper_irq_set_period
.globalzp irq_period_holder
	adc #35 + 3           ; compensate for software IRQ retrigger delay and jitter
	eor #$ff              ; invert value because the FME-7 IRQ timer counts down
	sta irq_period_holder
	rts
.endproc

.export mapper_irq_enable
.proc mapper_irq_enable
.globalzp irq_period_holder
	lda #$e
	sta $8000             ; command $e - IRQ counter low byte
	lda irq_period_holder
	sta $a000             ; write cycle count to timer register
	
	lda #$f
	sta $8000             ; command $f - IRQ counter high byte
	lda #$00
	sta $a000
	
	lda #$d
	sta $8000             ; command $d - IRQ control
	lda #$81
	sta $a000             ; enable IRQ counter decrement and IRQ generation
	rts
.endproc

.export mapper_irq_disable
.proc mapper_irq_disable
	php
	sei
	lda #$d
	sta $8000             ; command $d - IRQ control
	lda #$00
	sta $a000             ; disable IRQ counter decrement and IRQ generation
	plp
	rts
.endproc
