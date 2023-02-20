
.include "nes_mmio.inc"

.segment "MAIN"

.macro get_byte
	pla
.endmacro

.export write_palettes
.proc write_palettes
	lda PPUSTATUS
	lda #$3f
	sta PPUADDR
	lda #$00
	sta PPUADDR
	
	lda #$0f
	sta PPUDATA
	lda #$15
	sta PPUDATA
	lda #$26
	sta PPUDATA
	lda #$30
	sta PPUDATA
	
	rts
.endproc

; Copies data from the write buffer in the stack page into VRAM.
; The buffer follows the NES Stripe Image format, but does not support RLE.
; After finishing, writes FF to the start of the buffer, terminating it and signaling that the copy
; operation has been performed.
; Uses: a, x, y, sp, $0f
; Clobbers: a, x, y, $0f
.export vram_copy_stripes
.proc vram_copy_stripes

.global ppuctrl_shadow, ppumask_shadow, buf_vram_write

peel_jump_location := $d
popslide_sp_buf := $f

popslide_buf_slack = .lobyte(buf_vram_write)

setup:
	clv                           ; clear overflow flag
	tsx
	stx popslide_sp_buf           ; save sp
	ldx #popslide_buf_slack - 1
	txs                           ; put sp at the start of the buffer
	ldx PPUSTATUS                 ; reset PPU address latch

read_dest_or_end:
	get_byte
	bmi restore_and_finish        ; if bit 7 of the high addr byte is set, end of stripe buffer
	sta PPUADDR                   ; write high addr
	get_byte
	sta PPUADDR                   ; write low addr
	
decode_direction:
	get_byte                      ; get length/mode byte
	bpl right                     ; if bit 7 is clear, direction is right
	; fall through                ; if set, direction is down
down:
	and #$7f                      ; decode length
	tay                           ; y = length
	lda ppuctrl_shadow
	ora #%00000100                ; set PPUCTRL bit 2
	sta PPUCTRL
	bvc write_loop                ; branch always

right:
	and #$7f                      ; decode length
	tay                           ; y = length
	lda ppuctrl_shadow
	and #%11111011                ; clear PPUCTRL bit 2
	sta PPUCTRL
	bvc write_loop                ; branch always

write_loop:
	tya
	sec
	sbc #8
	bmi finish_writes             ; less than 8 bytes to write
	tay
	bvc unrolled_write_hunk
	
restore_and_finish:
	ldx popslide_sp_buf
	txs                           ; restore sp
	lda #$ff                      ; terminate start of the buffer
	sta $0100 + popslide_buf_slack

	rts

finish_writes:
	;                             ; carry clear here
	adc #8 + 1                    ; reverse sbc #8 + add 1 to compensate
	tay
	beq read_dest_or_end
	@loop:
		get_byte
		sta PPUDATA
		dey
		bne @loop
	bvc read_dest_or_end

unrolled_write_hunk:
	.repeat 8
		get_byte
		sta PPUDATA
	.endrepeat
unrolled_hunk_end:
	bvc write_loop



.endproc
