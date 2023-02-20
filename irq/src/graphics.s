
.segment "CHR"

.incbin "Jroatch-chr-sheet.chr"

.segment "MAIN"

.export copy_screen
.proc copy_screen
.global screen_copy_offset, buf_vram_write

	ptr_screen_copy_dest = $0
	ptr_screen_data_src = $2
	
	screen_copy_length = 64
	
	lda screen_copy_offset
	sta ptr_screen_copy_dest               ; prepare screen copy dest ptr low byte
	clc
	adc #<base_screen                      ; add low byte of src ptr
	sta ptr_screen_data_src                ; prepare screen data src ptr low byte
	
	lda screen_copy_offset + 1
	tay
	adc #>base_screen                      ; add high byte of srcptr with carry from previous addition
	sta ptr_screen_data_src + 1            ; screen data src ptr high byte
	tya
	clc
	adc #$20                               ; offsetting screen copy dest by $2000
	sta ptr_screen_copy_dest + 1           ; screen copy dest ptr high byte
	
	ldy #screen_copy_length
	dey
	sty buf_vram_write + 2                 ; write stripe length - 1 to buffer
	;                                      ; (literal mode, right direction)
	
	lda #$ff
	sta buf_vram_write + 4, y              ; write buffer terminator
	
	@loop:
		lda (ptr_screen_data_src), y
		sta buf_vram_write + 3, y      ; write literals
		dey
		bpl @loop
	
	lda ptr_screen_copy_dest               ; write screen copy dest ptr to buffer
	sta buf_vram_write + 1
	lda ptr_screen_copy_dest + 1
	sta buf_vram_write
	
	lda screen_copy_offset
	clc
	adc #screen_copy_length                ; increment screen copy offset value
	sta screen_copy_offset
	bcc @nocarry
	
	inc screen_copy_offset + 1
	
@nocarry:
	lda screen_copy_offset + 1
	cmp #>base_screen_size                 ; check if we reached the end of the input buffer
	bmi @no_reset                          ; if not, skip ahead

	lda #$00
	sta screen_copy_offset                 ; reset screen copy offset value
	sta screen_copy_offset + 1

@no_reset:
	rts
	
.endproc

base_screen:
	.incbin "screen.nam"
base_screen_size = * - base_screen

