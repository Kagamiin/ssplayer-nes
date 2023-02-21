# ssplayer-nes

Sample player for **NES** using **SSDPCM** codec (originally designed by "Algorithm").

## Features

- Support for mappers with **cycle-based IRQ**
  - Runs in the background, leaving free CPU time for your application
  - OAM DMA and PPU uploads are supported, with minimal audio quality degradation
  - **Buffered decompression** driven by NMI for **easy integration** into games and demos
  - 256-byte buffer - fits all sample rates
  - Automatic predictive buffer filling - fills buffer with as many samples as needed for an entire frame
- Support for simpler mappers **without IRQ**
  - Trigger one-shot samples at any time
  - No RAM buffer required
  - NMI handler can be used for concurrent code execution (with some audio quality degradation)
  - On supported mappers: scanline IRQs can be used for triggering raster effects (with some audio quality degradation)
- **SSDPCM** compression ratio of roughly 1:4 (2.13 bit/sample)
  - 1:8 compression ratio (1.06 bit/sample) also possible, with quality way superior to standard NES **DPCM**

## Supported mappers

Currently the following mappers are supported:

### IRQ-driven version

- **Konami VRC4**
- **Konami VRC7**
- **Nintendo MMC5A***
- **Namco 163**
- **Sunsoft FME-7** (also Sunsoft 5B/5A)

_*Emulation of MMC5A-exclusive features is currently not supported in any emulator to date._

Note that among all available mappers with support for cycle IRQs, the **Konami VRC** ones are considered ideal due to their capability of automatically retriggering the IRQ without any input from the CPU, which minimizes sample rate jitter and eliminates sample rate oscillation.

### Non-IRQ-driven version

- **NROM**
- **UxROM** (UNROM/UOROM/UNROM-512 etc.)
- **MMC3**

Support for more mappers might be added in the future. If you wish for me to add support to a specific mapper, please open an issue - though the included mapper implementations should provide a good basis for porting to other mappers on your own.

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

## NROM-legacy folder

The `nrom-legacy` folder contains an older version of the playback routine that does not use interrupts and is in fact built to be contained inside an **NROM** cartridge. It's fully cycle-counted and uses **1-bit SSDPCM** instead of **2-bit**, since that provides more storage space for samples.

Note that a newer, better version is available inside the `non-irq` folder.
