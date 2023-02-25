
import argparse
import copy
from pathlib import Path
from typing import List, Tuple, NamedTuple

class Stripe(NamedTuple):
    start_addr: int
    is_run: bool
    data: bytearray

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input_file")
    parser.add_argument("output_file")
    args = parser.parse_args()

    input_path = Path(args.input_file)
    output_path = Path(args.output_file)

    data: bytes
    with open(input_path, "rb") as infile:
        data = infile.read()

    original_data = bytearray(copy.deepcopy(data))

    stripes: List[Stripe] = []
    current_stripe: Stripe = None
    address = 0x2000

    while data:
        if len(data) >= 4 and all((data[0] == x for x in data[1:4])):
            if current_stripe != None:
                stripes.append(current_stripe)
            current_stripe = Stripe(start_addr=address, is_run=True, data=bytearray())
            last_byte = data[0]
            while data and data[0] == last_byte and len(current_stripe.data) < 64:
                current_stripe.data.append(data[0])
                data = data[1:]
                address += 1
            stripes.append(current_stripe)
            current_stripe = None
        else:
            if current_stripe == None:
                current_stripe = Stripe(start_addr=address, is_run=False, data=bytearray())
            if not len(current_stripe.data) < 64:
                stripes.append(current_stripe)
                current_stripe = Stripe(start_addr=address, is_run=False, data=bytearray())
            current_stripe.data.append(data[0])
            data = data[1:]
            address += 1

    resulting_data = bytearray()
    for stripe in stripes:
        resulting_data.extend(stripe.data)

    with open(output_path, "wb") as outfile:
        for stripe in stripes:
            outfile.write(stripe.start_addr.to_bytes(2, "big", signed=False))
            length_byte = (len(stripe.data) - 1) | (0x40 if stripe.is_run else 0)
            outfile.write(length_byte.to_bytes(1, "little"))
            if stripe.is_run:
                outfile.write(stripe.data[0:1])
            else:
                outfile.write(stripe.data)
        outfile.write(b'\xff')

if __name__ == "__main__":
    main()
