
.segment "INIT"

.export mapper_init
.proc mapper_init
	lda #$40
	sta $e000             ; disable expansion sound; also sets $8000-$9fff to bank 0
	lda #$3e
	sta $f000             ; map second-to-last bank to $c000-$dfff
	;                     ; to simulate the presence of a fixed bank
	lda #$7f
	sta $5800
	lda #$ff
	sta $5000             ; initialize IRQ timer to stable state
	
	lda #$00
	sta $8000             ; map CHR banks linearly
	lda #$01
	sta $8800
	lda #$02
	sta $9000
	lda #$03
	sta $9800
	lda #$04
	sta $a000
	lda #$05
	sta $a800
	lda #$06
	sta $b000
	lda #$07
	sta $b800
	rts
.endproc

; Sets up an 8KiB bank at $8000..$9fff
; uses:
;	a = bank number
.export mapper_set_bank_8000
.proc mapper_set_bank_8000
	ora #$40              ; keep expansion sound disabled
	sta $e000
	rts
.endproc

; Sets the IRQ period register.
; uses:
;	a = IRQ cycle count
.export mapper_irq_set_period
.proc mapper_irq_set_period
.globalzp irq_period_holder
	adc #17               ; compensate for software IRQ retrigger delay
	adc #2                ; compensate IRQ entrance delay/jitter
	sta irq_period_holder
	rts
.endproc

.export mapper_irq_enable
.proc mapper_irq_enable
.globalzp irq_period_holder
	lda irq_period_holder
	sta $5000             ; write cycle count to timer register
	lda #$ff
	sta $5800             ; enable IRQ by setting the IRQ enable bit in $5800
	rts
.endproc

.export mapper_irq_disable
.proc mapper_irq_disable
	lda #$7f
	sta $5800             ; disable IRQ by clearing the IRQ enable bit in $5800
	rts
.endproc
