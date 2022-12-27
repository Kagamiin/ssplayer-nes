
.import mapper_init, mapper_irq_set_period, mapper_irq_disable, mapper_irq_enable
.import decode_ss2_async, fill_buffer, load_next_superblock
.import irq_sample_selfmod

.import __PLAYBACK_CODE_LOAD__
.import __PLAYBACK_CODE_RUN__
.import __PLAYBACK_CODE_SIZE__
.import INES_MAPPER, INES_SRAM, INES_MIRROR, INES_CHR_BANKS, INES_PRG_BANKS

.segment "HEADER"

	.byte 'N', 'E', 'S', $1A ; ID
	.byte <INES_PRG_BANKS ; 16k PRG chunk count
	.byte <INES_CHR_BANKS ; 8k CHR chunk count
	.byte <INES_MIRROR | (<INES_SRAM << 1) | ((<INES_MAPPER & $f) << 4)
	.byte (INES_MAPPER & %11110000)
	.byte $0, $0, $0, $0, $0, $0, $0, $0 ; padding

.globalzp tmp_addr, idx_pcm_playback, block_slope, tmp_shortbuf
.global buf_pcm

; ---------------------------------------------------------------------------
.segment "MAIN"

; ---------------------------------------------------------------------------
.proc main_loop
	jsr fill_buffer
	jmp main_loop
.endproc

; ---------------------------------------------------------------------------
.segment "INIT"

; ---------------------------------------------------------------------------
.proc load_playback_code
	ldx #<__PLAYBACK_CODE_SIZE__
	@loop:
		dex
		lda __PLAYBACK_CODE_LOAD__, x
		sta __PLAYBACK_CODE_RUN__, x
		cpx #00
		bne @loop
	rts

.assert __PLAYBACK_CODE_SIZE__ <= 256, error, "playback code is bigger than 256 bytes"
.endproc

; ---------------------------------------------------------------------------
.proc reset
	jsr mapper_init
	ldx #$ff
	stx $4017                    ; disable frame counter IRQ
	txs
	; clear memory
	ldx #7
	lda #0
	sta $0
	tay
	@loop:
		stx $1
		@inner:
			dey
			sta ($0), y
			bne @inner
		dex
		bpl @loop
	jsr load_playback_code       ; copy playback code into RAM
	jsr load_next_superblock     ; load first superblock
	jsr decode_ss2_async         ; pre-fill the buffer with some samples
	lda #(256 - 114)
	jsr mapper_irq_set_period
	jsr mapper_irq_enable
	lda #0
	pha
	plp                          ; enable interrupts
	jmp main_loop
.endproc

; ---------------------------------------------------------------------------
.segment "VECTORS"

	.addr 0                  ; nmi
	.addr reset              ; reset
	.addr irq_sample_selfmod ; irq

