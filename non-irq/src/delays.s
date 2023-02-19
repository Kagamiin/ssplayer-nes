
; ---------------------------------------------------------------------------
.segment "MAIN"

; taken from github.com/Gumball2415/nes-scribbles
; > taken from bbbradsmith/nes-audio-tests
delay_frame:               ;       6
	jsr delay_24576    ;   24582
	jsr delay_3072     ;   27654
	jsr delay_1536     ;   29190
	jsr delay_384      ;   29574
	jsr delay_192      ;   29766
	nop                ; 2 29768
	nop                ; 2 29770
	nop                ; 2 29772
	nop                ; 2 29774
	rts                ; 6 29780

delay_24576: jsr delay_12288
delay_12288: jsr delay_6144
delay_6144:  jsr delay_3072
delay_3072:  jsr delay_1536
delay_1536:  jsr delay_768
delay_768:   jsr delay_384
delay_384:   jsr delay_192
delay_192:   jsr delay_96
delay_96:    jsr delay_48
delay_48:    jsr delay_24
delay_24:    jsr delay_12
delay_12:    rts

.export delay_frame
.export delay_24576, delay_12288, delay_6144, delay_3072
.export delay_1536, delay_768, delay_384, delay_192
.export delay_96, delay_48, delay_24, delay_12
