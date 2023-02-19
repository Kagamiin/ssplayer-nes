
.segment "ZEROPAGE"

.globalzp irq_period_holder
	irq_period_holder:    .res 1  ; N163 requires the IRQ period to be written on every retrigg
