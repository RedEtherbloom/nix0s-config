#!/usr/bin/env python3
import random

# Alchemical symbols in Unicode, for decoration
possible_symbols = list(range(0x1F700, 0x1F776 + 1)) + list(range(0x1F77B, 0x1F77F+1))
random_symbol = random.choice(possible_symbols)
print(chr(random_symbol))
