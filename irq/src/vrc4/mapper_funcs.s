
.segment "INIT"

.export mapper_init
.proc mapper_init
	lda #$00
	sta $f002             ; disable IRQ
	sta $9002             ; clear PRG swap bit, disable SRAM access
	lda #$00              ; initialize CHR bank registers
	sta $b000
	sta $b001
	sta $b003
	sta $c001
	sta $c003
	sta $d001
	sta $d003
	sta $e001
	sta $e003
	lda #$01
	sta $b002
	lda #$02
	sta $c000
	lda #$03
	sta $c002
	lda #$04
	sta $d000
	lda #$05
	sta $d002
	lda #$06
	sta $e000
	lda #$07
	sta $e002
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

; Sets up an 8KiB bank at $a000..$bfff
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

