#!/usr/bin/env python3

# TODO: add description

import os

print(f'\n|=== STARTING SCRIPT `{os.path.basename(__file__)}` ===|\n')


import sys
import gzip
import argparse

import pandas as pd

import src.rg_tools_IO as rgIO
from src.file_navigation import get_asm_report_fpath


# == Parse arguments ==

parser = argparse.ArgumentParser()

parser.add_argument(
    '-i',
    '--asm-sum',
    help="""TODO: add help""",
    required=True
)

parser.add_argument(
    '-o',
    '--out',
    help='TODO: add help',
    required=True
)

parser.add_argument(
    '-g',
    '--genomes-dir',
    help='TODO: add help',
    required=True
)


args = parser.parse_args()


asm_sum_fpath = os.path.realpath(args.asm_sum)
outfpath = os.path.realpath(args.out)
genomes_dirpath = os.path.realpath(args.genomes_dir)


# Check existance of input file -c/--gi-2-acc-fpath
if not os.path.exists(asm_sum_fpath):
    print(f'Error: file `{asm_sum_fpath}` does not exist')
    sys.exit(1)
# end if

if not os.path.isdir(genomes_dirpath):
    print(f'Error: directory `{genomes_dirpath}` does not exist')
    sys.exit(1)
# end if


if not os.path.isdir(os.path.dirname(outfpath)):
    try:
        os.makedirs(os.path.dirname(outfpath))
    except OSError as err:
        print(f'Error: cannot create directory `{os.path.dirname(outfpath)}`')
        sys.exit(1)
    # end try
# end if

print(asm_sum_fpath)
print(genomes_dirpath)
print()


def make_replicon_map(asm_sum_fpath, genomes_dirpath):
    asm_sum_df = rgIO.read_ass_sum_file(asm_sum_fpath)
    all_accs = set(asm_sum_df['asm_acc'])
    asm_accs, seq_accs = list(), list()
    for i, asm_acc in enumerate(all_accs):
        seq_accessions = get_sequence_accessions(asm_acc, genomes_dirpath)
        for seq_acc in seq_accessions:
            asm_accs.append(asm_acc)
            seq_accs.append(seq_acc)
        # end for
    # end for

    replicon_map_df = pd.DataFrame(
        {
            'asm_acc': asm_accs,
            'seq_acc': seq_accs
        }
    )
    return replicon_map_df
# end def

def get_sequence_accessions(asm_acc, genomes_dirpath):
    asm_report_fpath = get_asm_report_fpath(asm_acc, genomes_dirpath)
    with open(asm_report_fpath, 'rt') as infile:
        lines = remove_comment_lines(infile.readlines())
        accessions = tuple(map(get_refseq_accession, lines))
    # end with
    return accessions
# end def

def remove_comment_lines(lines):
    return tuple(
        filter(
            doesnt_start_with_num_sign,
            lines
        )
    )
# end def

def doesnt_start_with_num_sign(line):
    return line[0] != '#'
# end def

def get_refseq_accession(line):
    return line.split('\t')[6]
# end def


def write_output(replicon_map_df, outfpath):
    with gzip.open(outfpath, 'wt') as outfile:
        replicon_map_df.to_csv(
            outfile,
            sep='\t',
            encoding='utf-8',
            index=False,
            header=True,
            na_rep='NA'
        )
    # end with
# end def



# == Proceed ==

replicon_map_df = make_replicon_map(asm_sum_fpath, genomes_dirpath)
write_output(replicon_map_df, outfpath)


print(outfpath)
print(f'\n|=== EXITTING SCRIPT `{os.path.basename(__file__)}` ===|\n')
