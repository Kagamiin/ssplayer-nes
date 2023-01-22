.include "blocks-thelittlethings-2par-ss2.inc"

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
	.byte piece0::bits_bank       ; bits_bank
	.byte piece0::slopes_bank     ; slopes_bank
	.addr piece0::bits            ; bits
	.addr piece0::slopes          ; slopes
	.byte piece0::initial_sample  ; initial_sample
	.byte piece0::length          ; length

	.byte piece1::bits_bank       ; bits_bank
	.byte piece1::slopes_bank     ; slopes_bank
	.addr piece1::bits            ; bits
	.addr piece1::slopes          ; slopes
	.byte piece1::initial_sample  ; initial_sample
	.byte piece1::length          ; length

	.byte piece2::bits_bank       ; bits_bank
	.byte piece2::slopes_bank     ; slopes_bank
	.addr piece2::bits            ; bits
	.addr piece2::slopes          ; slopes
	.byte piece2::initial_sample  ; initial_sample
	.byte piece2::length          ; length

	.byte piece3::bits_bank       ; bits_bank
	.byte piece3::slopes_bank     ; slopes_bank
	.addr piece3::bits            ; bits
	.addr piece3::slopes          ; slopes
	.byte piece3::initial_sample  ; initial_sample
	.byte piece3::length          ; length

	.byte piece4::bits_bank       ; bits_bank
	.byte piece4::slopes_bank     ; slopes_bank
	.addr piece4::bits            ; bits
	.addr piece4::slopes          ; slopes
	.byte piece4::initial_sample  ; initial_sample
	.byte piece4::length          ; length

	.byte piece5::bits_bank       ; bits_bank
	.byte piece5::slopes_bank     ; slopes_bank
	.addr piece5::bits            ; bits
	.addr piece5::slopes          ; slopes
	.byte piece5::initial_sample  ; initial_sample
	.byte piece5::length          ; length

	.byte piece6::bits_bank       ; bits_bank
	.byte piece6::slopes_bank     ; slopes_bank
	.addr piece6::bits            ; bits
	.addr piece6::slopes          ; slopes
	.byte piece6::initial_sample  ; initial_sample
	.byte piece6::length          ; length

	.byte piece7::bits_bank       ; bits_bank
	.byte piece7::slopes_bank     ; slopes_bank
	.addr piece7::bits            ; bits
	.addr piece7::slopes          ; slopes
	.byte piece7::initial_sample  ; initial_sample
	.byte piece7::length          ; length

	.byte piece8::bits_bank       ; bits_bank
	.byte piece8::slopes_bank     ; slopes_bank
	.addr piece8::bits            ; bits
	.addr piece8::slopes          ; slopes
	.byte piece8::initial_sample  ; initial_sample
	.byte piece8::length          ; length

	.byte piece9::bits_bank       ; bits_bank
	.byte piece9::slopes_bank     ; slopes_bank
	.addr piece9::bits            ; bits
	.addr piece9::slopes          ; slopes
	.byte piece9::initial_sample  ; initial_sample
	.byte piece9::length          ; length

	.byte piece10::bits_bank       ; bits_bank
	.byte piece10::slopes_bank     ; slopes_bank
	.addr piece10::bits            ; bits
	.addr piece10::slopes          ; slopes
	.byte piece10::initial_sample  ; initial_sample
	.byte piece10::length          ; length

	.byte piece11::bits_bank       ; bits_bank
	.byte piece11::slopes_bank     ; slopes_bank
	.addr piece11::bits            ; bits
	.addr piece11::slopes          ; slopes
	.byte piece11::initial_sample  ; initial_sample
	.byte piece11::length          ; length

	.byte piece12::bits_bank       ; bits_bank
	.byte piece12::slopes_bank     ; slopes_bank
	.addr piece12::bits            ; bits
	.addr piece12::slopes          ; slopes
	.byte piece12::initial_sample  ; initial_sample
	.byte piece12::length          ; length

	.byte piece13::bits_bank       ; bits_bank
	.byte piece13::slopes_bank     ; slopes_bank
	.addr piece13::bits            ; bits
	.addr piece13::slopes          ; slopes
	.byte piece13::initial_sample  ; initial_sample
	.byte piece13::length          ; length



.export num_sblk_headers
num_sblk_headers:
	.byte 14
