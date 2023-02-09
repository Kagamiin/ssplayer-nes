# ssplayer-nes

Sample player for **NES** using **SSDPCM** codec (originally designed by "Algorithm").

## Features

- Cycle-based **IRQ-driven** playback
- **Buffered decompression** driven by NMI for **easy integration** into games and demos
  - 256-byte buffer - fits all sample rates
  - Automatic predictive buffer filling - fills buffer with as many samples as needed for an entire frame
- **Variable sample rates**
  - 2-bit - up to 23.2 KHz
  - 1-bit - up to 26.3 KHz
  - Even higher sample rates possible via decompression without NMI-based buffering _(TODO: test how high it can go)_
- **SSDPCM** compression ratio of roughly 1:4 (2.13 bit/sample)
  - 1:8 compression ratio (1.06 bit/sample) also possible, with quality way superior to standard NES **DPCM**
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

## Supported mappers

Currently the following mappers are supported in the code (and selectable inside the makefile):

- **Konami VRC4** (easily portable to **VRC6**/**VRC7**)
- **Nintendo MMC5A***
- **Namco 163**

_*Emulation of MMC5A-exclusive features is currently not supported in any emulator to date._

Support for more mappers might be added in the future. If you wish for me to add support to a specific mapper, please open an issue - though the included mapper implementations should provide a good basis for porting to other mappers on your own.

Note that among all available mappers with support for cycle IRQs, the **Konami VRC** ones are considered ideal due to their capability of automatically retriggering the IRQ without any input from the CPU, which minimizes sample rate jitter and eliminates sample rate oscillation.

### Scanline-based mapper support

Support for scanline IRQ-based mappers is still on the way. They're a bit cumbersome to use and only provide a very limited set of sample rates.

_By the way, the most popular mapper with scanline IRQ, **MMC3**, isn't well-suited for playback over ~5.2 KHz (it will work on most emulators but real hardware behavior is unreliable and differs between revisions)_;

## Usage

If you wish to use the code in this repository, you will need to provide a few extra stuff:

- **Encoded audio** _(TODO: include royalty-free examples)_
  - A compatible encoder can be found at: <https://github.com/Kagamiin/ssdpcm>
  - The files should be placed inside `build/samples/` (or a subdirectory within)
- **Generated files**
  - Header containing scopes for binaries and superblock header declarations
  - A generator script is included in `tools/make-scopes.py`, which will generate both of these from the encoded audio and place them in the `build/codegen` folder
  - **NOTE:** The configuration variables need to be set in the Makefile to point to these generated files.

### Build tools

You'll also need the following tools:

- Python 3.7 or later (3.10 or later recommended)
- cc65/ca65
- GNU Make

## NROM folder

The `nrom` folder contains an older version of the decompression routine that does not use interrupts and is in fact built to be contained inside an **NROM** cartridge. It's fully cycle-counted and uses **1-bit SSDPCM** instead of **2-bit**, since that provides more storage space for samples.
