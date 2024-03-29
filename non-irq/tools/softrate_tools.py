import sys
import math

freq = lambda coarse, fine, steps: 315/88/2 * 1000000 / (67 + fine/steps + ((coarse - 2) & 0xff) * 5)

def freq_to_coarsefine(desired_freq, steps):
    period = (315/88/2 * 1000000) / desired_freq
    coarse = math.floor((period + (1/steps)/2) / 5 - 67/5 + 2)
    coarse = min(max(2, coarse), 255)
    fine = math.floor(steps * (period - 67 - ((coarse - 2) * 5) + (1/steps)/2.1))
    fine = min(max(0, fine), steps * 5)
    actual_freq = freq(coarse, fine, steps)
    return (coarse, fine, actual_freq)

def calc_difference_cents(desired, obtained):
    return round(math.log(obtained / desired, 2**(1/12)) * 100, 3)

def generate_freq_table(base_freq, semitones_down, semitones_up, mode_steps):
    desired_freqs = [base_freq * 2**(st/12) for st in range(-semitones_down, semitones_up + 1)]
    calc_results = map(lambda x: freq_to_coarsefine(x, mode_steps), desired_freqs)
    result = map(lambda res, desired: ((res[0], res[1]), calc_difference_cents(res[2], desired)), calc_results, desired_freqs)
    return list(result)

def codegen_table(freq_table, segment_name, label_prefix, file=sys.stdout):
    print(f'.segment "{segment_name}"', file=file)
    print(file=file)
    print(f'{label_prefix}_coarse:', file=file)
    for l in range(0, len(freq_table), 16):
        print(f"\t.byte ", end='', file=file)
        print(", ".join(list(map(lambda x: f"${x[0][0]:02X}", freq_table[l:min(l + 16, len(freq_table))]))), file=file)
    print(file=file)
    print(f'{label_prefix}_fine:', file=file)
    for l in range(0, len(freq_table), 16):
        print(f"\t.byte ", end='', file=file)
        print(", ".join(list(map(lambda x: f"${x[0][1]:02X}", freq_table[l:min(l + 16, len(freq_table))]))), file=file)
    print(file=file)

