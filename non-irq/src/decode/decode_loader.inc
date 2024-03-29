.export load_decoder
.proc load_decoder
	.import __DECODE_RAMCODE_LOAD__, __DECODE_RAMCODE_RUN__, __DECODE_RAMCODE_SIZE__
	.globalzp last_fine_pitch

	addr_load = $00
	addr_run = $02
	
	lda #<__DECODE_RAMCODE_LOAD__
	sta addr_load
	lda #>__DECODE_RAMCODE_LOAD__
	clc
	adc #>__DECODE_RAMCODE_SIZE__
	sta addr_load + 1
	lda #<__DECODE_RAMCODE_RUN__
	sta addr_run
	lda #>__DECODE_RAMCODE_RUN__
	clc
	adc #>__DECODE_RAMCODE_SIZE__
	sta addr_run + 1
	ldy #<__DECODE_RAMCODE_SIZE__
	ldx #>__DECODE_RAMCODE_SIZE__
	cpy #0
	beq after
	loop:
		inner:
			dey
			lda ($0000), y
			sta ($0002), y
			cpy #0
			bne inner
	after:  ; y = 0
		cpx #0
		beq end
		dex
		dec addr_load + 1
		dec addr_run + 1
		bpl loop  ; will always branch
end:
	stx last_fine_pitch  ; x = 0
	rts
.endproc
