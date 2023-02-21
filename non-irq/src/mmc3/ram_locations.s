
.segment "ZEROPAGE"

.globalzp mmc3_bank_select_shadow, mmc3_mutex
	mmc3_bank_select_shadow: .res 1
	mmc3_mutex:              .res 1
