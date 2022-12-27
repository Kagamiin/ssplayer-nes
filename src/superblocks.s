.include "blocks-thelittlethings-ss2.inc"

.segment "HDRS"

;.export sblk_header_s
;.struct sblk_header_s
;	bits_bank       .byte
;	slopes_bank     .byte
;	bits            .addr
;	slopes          .addr
;	initial_sample  .byte
;	length          .byte
;.endstruct

.export sblk_table
sblk_table:
	.byte $00                     ; bits_bank
	.byte $07                     ; slopes_bank
	.addr piece0::bits            ; bits
	.addr piece0::slopes          ; slopes
	.byte piece0::initial_sample  ; initial_sample
	.byte piece0::length          ; length

	.byte $01                     ; bits_bank
	.byte $07                     ; slopes_bank
	.addr piece1::bits            ; bits
	.addr piece1::slopes          ; slopes
	.byte piece1::initial_sample  ; initial_sample
	.byte piece1::length          ; length

	.byte $02                     ; bits_bank
	.byte $07                     ; slopes_bank
	.addr piece2::bits            ; bits
	.addr piece2::slopes          ; slopes
	.byte piece2::initial_sample  ; initial_sample
	.byte piece2::length          ; length

	.byte $03                     ; bits_bank
	.byte $07                     ; slopes_bank
	.addr piece3::bits            ; bits
	.addr piece3::slopes          ; slopes
	.byte piece3::initial_sample  ; initial_sample
	.byte piece3::length          ; length

	.byte $04                     ; bits_bank
	.byte $07                     ; slopes_bank
	.addr piece4::bits            ; bits
	.addr piece4::slopes          ; slopes
	.byte piece4::initial_sample  ; initial_sample
	.byte piece4::length          ; length

	.byte $05                     ; bits_bank
	.byte $07                     ; slopes_bank
	.addr piece5::bits            ; bits
	.addr piece5::slopes          ; slopes
	.byte piece5::initial_sample  ; initial_sample
	.byte piece5::length          ; length

	.byte $06                     ; bits_bank
	.byte $07                     ; slopes_bank
	.addr piece6::bits            ; bits
	.addr piece6::slopes          ; slopes
	.byte piece6::initial_sample  ; initial_sample
	.byte piece6::length          ; length

	.byte $07                     ; bits_bank
	.byte $07                     ; slopes_bank
	.addr piece7::bits            ; bits
	.addr piece7::slopes          ; slopes
	.byte piece7::initial_sample  ; initial_sample
	.byte piece7::length          ; length

.export num_sblk_headers
num_sblk_headers:
	.byte 8
