
; Register definitions
r0 = $F0
r1 = $F1
r2 = $F2
r3 = $F3
r4 = $F4
r5 = $F5
r6 = $F6
r7 = $F7
r8 = $F8
r9 = $F9
r10 = $FA
r11 = $FB
r12 = $FC
r13 = $FD
r14 = $FE
r15 = $FF
; Register aliases
al = r0
ah = r1
ax = al
sx = r2
dx = r4
cl = r6
ch = r7
cx = cl
il = r8
ih = r9
ix = il
bp = r10
sp = r12
pc = r14

; Temporaries
x2 = $0E
y2 = $0F


.macro inc_pc
.scope
	inc pc       ;  5  5
	bne delay    ;  3  8
	;            ; -1  7
	inc pc + 1   ;  5 12
	jmp continue ;  3 15

delay:               ;     8
	nop          ;  2 10
	inc $0       ;  5 15
continue:
.endscope
.endmacro

.macro inc_x2
.scope
	inc x2       ;  5  5
	bne delay    ;  3  8
	;            ; -1  7
	inc y2       ;  5 12
	jmp continue ;  3 15

delay:               ;     8
	nop          ;  2 10
	inc $0       ;  5 15
continue:
.endscope
.endmacro

.macro mov_reg_reg_8
	inc_pc       ; 15 15

	ldy #0       ;  2 17
	lda (pc), y  ;  5 22
	tax          ;  2 24

	and #$0F     ;  2 26
	tay          ;  3 28

	txa          ;  2 30
	lsr a        ;  2 32
	lsr a        ;  2 34
	lsr a        ;  2 36
	lsr a        ;  2 38
	tax          ;  2 40

	lda r0, y    ;  3 44
	sta r0, x    ;  3 48
.endmacro

.macro mov_reg_reg_16
	mov_reg_reg_8 ; 48 48
	lda r0 + 1, y ;  4 52
	sta r0 + 1, x ;  4 56
.endmacro

.macro mov_reg_mem_8
	ldy #0        ;  2  2
	lda (pc), y   ;  5  7
	and #$0F      ;  2  9
	tax           ;  2 11
	
	inc_pc        ; 15 26
	lda (pc), y   ;  5 31
	sta x2        ;  3 34
	inc_pc        ; 15 49
	lda (pc), y   ;  5 54
	sta y2        ;  3 57
	
	lda (x2), y   ;  5 62
	sta r0, x     ;  4 66
.endmacro

.macro mov_reg_mem_16
	mov_reg_mem_8 ; 66 66
	inc_x2        ; 15 81
	lda (x2), y   ;  5 86
	sta r0 + 1, x ;  4 90
.endmacro
