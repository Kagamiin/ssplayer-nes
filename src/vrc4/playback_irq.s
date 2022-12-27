.include "smc.inc"

.globalzp tmp_irq_a

.global buf_pcm

.segment "PLAYBACK_CODE"

; ---------------------------------------------------------------------------
.macro irq_ack
	sta $f003              ; 4
.endmacro

.if 1
.export irq_sample_selfmod
; ---------------------------------------------------------------------------
.proc irq_sample_selfmod              ;    7
	sta tmp_irq_a                 ; 3 10
	irq_ack                       ; 4 14
	SMC sample_addr_offset, { lda buf_pcm }
	;                             ; 4 18
	sta $4011                     ; 4 22
	SMC_OperateOnLowByte    inc, sample_addr_offset
	;                             ; 6 28
	lda tmp_irq_a                 ; 3 31
	rti                           ; 6 37
.endproc
SMC_Export idx_smc_pcm_playback, irq_sample_selfmod::sample_addr_offset

.endif



.if 0
; ---------------------------------------------------------------------------
irq_dispatch:                  ; 7  7
	jmp (irq_dispatch_ptr) ; 5  12


.macro save_ax_and_ack         ; 10 cycles
	sta tmp_irq_a          ;  3  3
	stx tmp_irq_x          ;  3  6
	irq_ack                ;  4 10
.endmacro

.macro play_sample_inline      ; 16 cycles
	ldx idx_pcm_playback   ;  3  3
	lda buf_pcm, x         ;  4  7
	sta $4011              ;  4 11
	inc idx_pcm_playback   ;  5 16
.endmacro

.macro play_sample_inline_comb ; 28 cycles
	ldx idx_pcm_playback   ;  3  3
	lda buf_pcm, x         ;  4  7
	tax                    ;  2  9
	clc                    ;  2 11
	adc sample_comb_buf    ;  3 14
	stx sample_comb_buf    ;  3 17
	lsr a                  ;  2 19
	sta $4011              ;  4 23
	inc idx_pcm_playback   ;  5 28
.endmacro
.endif

.if 0
; ---------------------------------------------------------------------------
.proc irq_sample
handler_buf1:                  ;    12
	save_ax_and_ack        ; 10 22
	play_sample_inline     ; 16 38
	beq @change_bank       ;  2 40 - 41

	ldx tmp_irq_x          ;  3 43   ..
	lda tmp_irq_a          ;  3 46   ..
	rti                    ;  6 52   ..

@change_bank:                  ;    ..   41
	ld_w irq_dispatch_ptr handler_buf2
	;                      ; 10 ..   51
	ldx tmp_irq_x          ;  3 ..   54
	lda tmp_irq_a          ;  3 ..   57
	rti                    ;  6 ..   63

handler_buf2:                  ;    12
	save_ax_and_ack        ; 10 22
	play_sample_inline     ; 16 38
	beq @change_bank       ;  2 40 - 41

	ldx tmp_irq_x          ;  3 43   ..
	lda tmp_irq_a          ;  3 46   ..
	rti                    ;  6 52   ..

@change_bank:                  ;    ..   41
	ld_w irq_dispatch_ptr handler_buf1
	;                      ; 10 ..   51
	ldx tmp_irq_x          ;  3 ..   54
	lda tmp_irq_a          ;  3 ..   57
	rti                    ;  6 ..   63
.endproc
.endif

.if 0
; ---------------------------------------------------------------------------
.proc irq_sample_comb
handler_buf1:                   ;    12
	save_ax_and_ack         ; 10 22
	play_sample_inline_comb ; 28 50
	beq @change_bank        ;  2 52 - 53

	ldx tmp_irq_x           ;  3 55   ..
	lda tmp_irq_a           ;  3 58   ..
	rti                     ;  6 64   ..

@change_bank:                   ;    ..   53
	ld_w irq_dispatch_ptr handler_buf2
	;                       ; 10 ..   63
	ldx tmp_irq_x           ;  3 ..   66
	lda tmp_irq_a           ;  3 ..   69
	rti                     ;  6 ..   75

handler_buf2:                   ;    12
	save_ax_and_ack         ; 10 22
	play_sample_inline_comb ; 28 50
	beq @change_bank        ;  2 52 - 53

	ldx tmp_irq_x           ;  3 55   ..
	lda tmp_irq_a           ;  3 58   ..
	rti                     ;  6 64   ..

@change_bank:                   ;    ..   53
	ld_w irq_dispatch_ptr handler_buf1
	;                       ; 10 ..   63
	ldx tmp_irq_x           ;  3 ..   66
	lda tmp_irq_a           ;  3 ..   69
	rti                     ;  6 ..   75
.endif

.if 0
; ---------------------------------------------------------------------------
.proc irq_sample_selfmod_banked       ;    7
	sta tmp_irq_a                 ; 3 10
	irq_ack                       ; 4 14
	SMC sample_addr_offset, { lda SMC_AbsAdr }
	;                             ; 4 18
	sta $4011                     ; 4 22
	SMC_OperateOnLowByte    inc, sample_addr_offset
	;                             ; 6 28
	SMC change_bank,        { beq @change_bank_1 }
	;                             ; 2 30 - 31
	lda tmp_irq_a                 ; 3 33   ..
	rti                           ; 6 39   ..

@change_bank_1:                       ;   ..   31
	SMC_TransferHighByte    sample_addr_offset, sample_bank_1, a
	;                             ; 6 ..   37
	SMC_ChangeBranch        change_bank, @change_bank_0, a
	;                             ; 6 ..   43
	lda tmp_irq_a                 ; 3 ..   51
	rti                           ; 6 ..   57

@change_bank_0:
	SMC_TransferHighByte    sample_addr_offset, sample_bank_0, a
	;                             ; 6 ..   42
	SMC_ChangeBranch        change_bank, @change_bank_1, a
	;                             ; 6 ..   48
	lda tmp_irq_a                 ; 3 ..   51
	rti                           ; 6 ..   57
.endproc
.endif

.if 0
; ---------------------------------------------------------------------------
.proc irq_sample_selfmod_comb_banked  ;    7
	sta tmp_irq_a                 ; 3 10
	stx tmp_irq_x                 ; 3 13
	irq_ack                       ; 4 17
	SMC sample_addr_offset, { lda SMC_AbsAdr }
	;                             ; 4 21
	tax                           ; 2 23
	clc                           ; 2 25
	SMC sample_comb_buf,    { adc #SMC_Value }
	;                             ; 2 27
	SMC_StoreValue          sample_comb_buf, x
	;                             ; 4 31
	lsr a                         ; 2 33
	sta $4011                     ; 4 37
	SMC_OperateOnLowByte    inc, sample_addr_offset
	;                             ; 6 43
	SMC change_bank,        { beq @change_bank_1 }
	;                             ; 2 45 - 46

@end:                                 ;   45   ..   61
	ldx tmp_irq_x                 ; 3 48   ..   64
	lda tmp_irq_a                 ; 3 51   ..   67
	rti                           ; 6 57   ..   73

@change_bank_1:                       ;   ..   46   ..
	SMC_TransferHighByte    sample_addr_offset, sample_bank_1, a
	;                             ; 6 ..   52   ..
	SMC_ChangeBranch        change_bank, @change_bank_0, a
	;                             ; 6 ..   58   ..
	bne @end                      ; 3 ..   61 - 61  ; always taken

@change_bank_0:                       ;   ..   42   ..
	SMC_TransferHighByte    sample_addr_offset, sample_bank_0, a
	;                             ; 6 ..   48   ..
	SMC_ChangeBranch        change_bank, @change_bank_1, a
	;                             ; 6 ..   54   ..
	bne @end                      ; 3 ..   57 - 57  ; always taken
.endproc
.endif

