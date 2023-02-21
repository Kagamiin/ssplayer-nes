
.segment "INIT"

.export mapper_init
.proc mapper_init
	lda #$00
	sta $f000             ; disable IRQ
	lda #$3e
	sta $9000             ; map second-to-last bank to $c000-$dfff
	;                     ; to simulate the presence of a fixed bank
	lda #00
	sta $a000             ; map CHR banks linearly
	lda #01
	sta $a010
	lda #02
	sta $b000
	lda #03
	sta $b010
	lda #04
	sta $c000
	lda #05
	sta $c010
	lda #06
	sta $d000
	lda #07
	sta $d010
	rts
.endproc

; Sets up an 8KiB bank at $8000..$9fff
; uses:
;	a = bank number
.export mapper_set_bank_8000
.proc mapper_set_bank_8000
	sta $8000
	rts
.endproc

; Sets the IRQ period register.
; uses:
;	a = IRQ cycle count
.export mapper_irq_set_period
.proc mapper_irq_set_period
	sta $e010             ; write period
	rts
.endproc

.export mapper_irq_enable
.proc mapper_irq_enable
	lda #$07              ; enable IRQ, cycle mode, repeat mode
	sta $f000
	rts
.endproc

.export mapper_irq_disable
.proc mapper_irq_disable
	lda #$00              ; disable IRQ
	sta $f000
	rts
.endproc

