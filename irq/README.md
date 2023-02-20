# ssplayer-nes/irq

This subfolder contains the IRQ-driven version of the sample player.

## Features

- Cycle-based **IRQ-driven** playback
- **Buffered decompression** driven by NMI for **easy integration** into games and demos
  - 256-byte buffer - fits all sample rates
  - Automatic predictive buffer filling - fills buffer with as many samples as needed for an entire frame
- **Variable sample rates**
  - 2-bit - up to 23.2 KHz
  - 1-bit - up to 26.3 KHz
  - Even higher sample rates possible via decompression without NMI-based buffering _(TODO: test how high it can go)_
- **NTSC** support only (for now)
  - **Dendy** support can be easily added with some hacking, but **PAL** support might need a different prediction table _(TODO verify)_

## Decompression routines

A few versions of the decompression routine are included. They provide various tradeoffs between code size and speed, as well as quality.

Note that for the code sizes listed, a further 192 bytes can be shaved off of these sizes by not including the entire prediction table for the buffer filling routine, if only a few known sample rates are going to be used.

### 2-bit SSDPCM

All 3 of these routines are made to work with the **2-bit SSDPCM** format. Their specifications are as follows:

| Name                          | Decode time @ ~14 KHz | Code size   |
|:------------------------------|:---------------------:|------------:|
| ss2_async_fullunroll          | 61-82 rasterlines     | 7680 bytes  |
| ss2_async_fast                | 79-106 rasterlines    | 1280 bytes  |
| ss2_async                     | 103-136 rasterlines   | 725 bytes   |

**NOTE:** Decode time measured with the Konami VRC mappers. Decode time will be larger for other mappers due to higher IRQ overhead.

### 1-bit SSDPCM

All 3 of these routines are made to work with the **1-bit SSDPCM** format. Their specifications are as follows:

| Name                          | Decode time @ ~14 KHz | Code size   |
|:------------------------------|:---------------------:|------------:|
| ss1_async_fullunroll          | 45-61 rasterlines     | 6400 bytes  |
| ss1_async_fast                | 63-84 rasterlines     | 1376 bytes  |
| ss1_async                     | 68-91 rasterlines     | 919 bytes   |

**NOTE:** Decode time measured with the Konami VRC mappers. Decode time will be larger for other mappers due to higher IRQ overhead.

### Future plans for more decompression routines

A hybrid format is planned that contains both 1-bit and 2-bit sample blocks to provide finer granularity in bitrate control.

I don't know if I'll explore other SSDPCM variants by Algorithm (such as SSDPCM1-Super and VF-SSDPCM1).
