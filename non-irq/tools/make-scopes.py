
import argparse
from pathlib import Path
from typing import List, Dict, NamedTuple, TextIO


class Hunk(NamedTuple):
    name: str
    size: int


class RomBank(NamedTuple):
    size: int
    contents: List[Hunk]


class RomBankSet:
    def __init__(self, num_banks, bank_size):
        self.banks = [RomBank(size=bank_size, contents=[]) for i in range(num_banks)]

    def get_bank_capacity(self, bank_id) -> int:
        if bank_id < len(self.banks):
            bank = self.banks[bank_id]
            capacity = bank.size
            for hunk in bank.contents:
                capacity -= hunk.size
            if capacity < 0:
                raise RuntimeError(f"bank {bank_id} has negative capacity; size {bank.size}, contents {bank.contents}")
            return capacity

        raise IndexError(f"tried to access bank {bank_id} but there are only {len(self.banks)} banks")

    def find_hunk_bank(self, name) -> int:
        for bank_id, bank in enumerate(self.banks):
            if any([name == hunk.name for hunk in bank.contents]):
                return bank_id
        return None

    def add_hunk(self, name, size) -> None:
        if self.find_hunk_bank(name):
            return
        for bank_id, bank in enumerate(self.banks):
            if self.get_bank_capacity(bank_id) < size:
                continue
            bank.contents.append(Hunk(name = name, size = size))
            return

        raise Exception(f"no space left in any bank to add hunk '{name}' of size {size}")


def write_scope(outfile: TextIO, name_prefix: (Path | str), idx: int, allocator: RomBankSet) -> bool:
    params_name = f"{name_prefix}_{idx}_params.inc"
    bits_name = f"{name_prefix}_{idx}_bits.bin"
    slopes_name = f"{name_prefix}_{idx}_slopes.bin"
    bits_bank = allocator.find_hunk_bank(bits_name)
    slopes_bank = allocator.find_hunk_bank(slopes_name)

    if bits_bank is None or slopes_bank is None:
        return False

    outfile.write(f"""
.scope piece{idx:02x}
\t.include "{params_name}"
\tbits_bank := ${bits_bank:02x}
\tslopes_bank := ${slopes_bank:02x}
\t.segment "BANK_{bits_bank:02x}"
\tbits:
\t\t.incbin "{bits_name}"

\t.segment "BANK_{slopes_bank:02x}"
\tslopes:
\t\t.incbin "{slopes_name}"
.endscope
""")

    return True


def write_superblock_hdrs(outfile: TextIO, inc_outfile: Path, sblock_count: int):
    outfile.write(f""".include "{inc_outfile.name}"

.segment "HDRS"

;.export sblk_header_s
;.struct sblk_header_s
;\tbits_bank       .byte
;\tslopes_bank     .byte
;\tbits            .addr
;\tslopes          .addr
;\tinitial_sample  .byte
;\tlength          .byte
;.endstruct

.export sblk_table
sblk_table:
""")
    for sblock_idx in range(sblock_count):
        outfile.write(f"\t.byte piece{sblock_idx:02x}::bits_bank       ; bits_bank\n")
        outfile.write(f"\t.byte piece{sblock_idx:02x}::slopes_bank     ; slopes_bank\n")
        outfile.write(f"\t.addr piece{sblock_idx:02x}::bits            ; bits\n")
        outfile.write(f"\t.addr piece{sblock_idx:02x}::slopes          ; slopes\n")
        outfile.write(f"\t.byte piece{sblock_idx:02x}::initial_sample  ; initial_sample\n")
        outfile.write(f"\t.byte piece{sblock_idx:02x}::length          ; length\n")
        outfile.write("\n")

    outfile.write(".export num_sblk_headers\n")
    outfile.write("num_sblk_headers:\n")
    outfile.write(f"\t.byte {sblock_count}\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("name_prefix", help="filename prefix for the bin/inc files for the samples")
    parser.add_argument("--subdir", "-d", help="subdirectory inside the samples folder")
    parser.add_argument("--bank-count", "-c", help="number of available banks (default 32)", type=int, default=32)
    parser.add_argument("--bank-size", "--bs", help="size of each bank in bytes (default 8192)", type=int, default=8192)
    parser.add_argument("--decoder-reserve", "--dres", help="bytes of data to reserve for decoder in second-to-last bank (default 8192)", type=int, default=8192)
    parser.add_argument("--main-reserve", "--mres", help="bytes of data to reserve for init/main code in last bank (default 1024)", type=int, default=1024)
    args = parser.parse_args()

    build_path = Path(__file__).parent.parent / "build"
    inc_out_path = build_path / "codegen" / f"blocks_{args.name_prefix}.inc"
    superblocks_out_path = build_path / "codegen" / f"superblocks_{args.name_prefix}.s"
    samples_dir = build_path / "samples"
    if args.subdir:
        samples_dir /= args.subdir

    files = {}
    for fpath in samples_dir.glob(f"{args.name_prefix}*.bin"):
        files[str(fpath.relative_to(samples_dir))] = fpath.stat().st_size

    files_by_idx = sorted(files.items(), key=lambda x: int(x[0].split("_")[1]), reverse=False)
    files_by_size = sorted(files_by_idx, key=lambda x: x[1], reverse=True)

    allocator = RomBankSet(args.bank_count, args.bank_size)
    allocator.banks[args.bank_count - 2].contents.append(
        Hunk(name = "__decoder_reserve__", size = args.decoder_reserve))
    allocator.banks[args.bank_count - 1].contents.append(
        Hunk(name = "__main_reserve__", size = args.main_reserve))
    for name, size in files_by_size:
        allocator.add_hunk(name, size)

    scope_idx = 0
    with open(inc_out_path, "w") as outfile:
        while(write_scope(outfile, args.name_prefix, scope_idx, allocator)):
            scope_idx += 1

    with open(superblocks_out_path, "w") as outfile:
        write_superblock_hdrs(outfile, inc_out_path, scope_idx)


if __name__ == "__main__":
    main()
