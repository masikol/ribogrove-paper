# -*- encoding: utf-8 -*-

import os
import sys
from io import StringIO
import subprocess as sp
import statistics as sts

import pandas as pd
from Bio import SeqIO


def _select_seqs(acc, seqs_fasta_fpath):

    cmd = f'cat {seqs_fasta_fpath} | seqkit grep -nrp {acc}'

    pipe = sp.Popen(cmd, shell=True, stdout=sp.PIPE, stderr=sp.PIPE)
    stdout_stderr = pipe.communicate()

    if pipe.returncode != 0:
        print('\nError while selectins genes')
        print(stdout_stderr[1].decode('utf-8'))
        print(f'Accession: {" ".join(acc)}')
        print(cmd)
        sys.exit(1)
    else:
        fasta_str = stdout_stderr[0].decode('ascii')
    # end if

    fasta_io = StringIO(fasta_str)
    seq_records = list(SeqIO.parse(fasta_io, 'fasta'))
    fasta_io.close()

    return seq_records
# end def _select_seqs


def _get_len(record):
    return len(record.seq)
# end def _get_len


def gene_seqs_2_stats(seqs_fasta_fpath, ass_acc_fpath, stats_outfpath):

    ass_acc_df = pd.read_csv(ass_acc_fpath, sep='\t')

    with open(stats_outfpath, 'wt') as stats_outfile:

        stats_outfile.write('ass_id\trefseq_id\tacc\ttitle\tnum_genes\tmin_len\tmax_len\tmean_len\tmedian_len\n')

        for i, row in ass_acc_df.iterrows():

            ass_id = row['ass_id']
            refseq_id = row['refseq_id']
            acc = row['acc']
            title = row['title']

            print(f'\rDoing {i+1}/{ass_acc_df.shape[0]}: {acc}', end=' '*10)

            seq_records = _select_seqs(acc, seqs_fasta_fpath)

            num_genes = len(seq_records)

            if num_genes != 0:
                gene_lengths = tuple(map(_get_len, seq_records))
                min_len = min(gene_lengths)
                max_len = max(gene_lengths)
                mean_len = sts.mean(gene_lengths)
                median_len = sts.median(gene_lengths)
            else:
                min_len = 'NA'
                max_len = 'NA'
                mean_len = 'NA'
                median_len = 'NA'
            # end if

            stats_outfile.write(f'{ass_id}\t{refseq_id}\t{acc}\t{title}\t{num_genes}\t')
            stats_outfile.write(f'{min_len}\t{max_len}\t{mean_len}\t{median_len}\n')

        # end for
    # end with
# end def gene_seqs_2_stats
