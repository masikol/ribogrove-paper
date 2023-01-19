
set -e

# Load configuration file
CONF_FILE="$1"
if [[ ! -f "${CONF_FILE}" ]]; then
  echo -e "\nError: file ${CONF_FILE} does not exist!"
  exit 1
fi

source "${CONF_FILE}"

# Get directory where scripts are located
SCRIPT_ABSPATH=`realpath $0`
SCRIPT_DIR=`dirname "${SCRIPT_ABSPATH}"`


# Directories for different sorts of data
LOGS_DIR="${WORKDIR}/logs"
CATEGORIES_DIR="${WORKDIR}/categories"
TAXONOMY_DIR="${WORKDIR}/taxonomy"
GENES_DIR="${WORKDIR}/gene_seqs"
ABERRATIONS_AND_HETEROGENEITY_DIR="${WORKDIR}/aberrations_and_heterogeneity"

for some_dir in "${WORKDIR}" "${LOGS_DIR}" "${CATEGORIES_DIR}" \
                "${TAXONOMY_DIR}" "${GENOMES_GBK_DIR}" "${GENES_DIR}" \
                "${ABERRATIONS_AND_HETEROGENEITY_DIR}";
do
  mkdir -pv "${some_dir}"
done

if [[ "${CALC_PRIMERS_COVERAGE}" == 1 ]]; then
  PRIMERS_DIRPATH="${WORKDIR}/primers_coverage"
  mkdir -pv "${PRIMERS_DIRPATH}"
fi


# |=== Configure all paths to intermediate and result files ===|

FILTERED_REFSEQ_CATALOG_FILE="${REFSEQ_CATALOG_FILE/.catalog.gz/_filtered.catalog.gz}"

ASS_ID_TO_GI_FPATH="${WORKDIR}/${PREFIX}_assembly_2_GI.tsv"

ACC_BLACKLIST_FPATH="${SCRIPT_DIR}/ad_hoc/accession_blacklist.tsv"
GI_ACC_TITLES_FPATH="${WORKDIR}/${PREFIX}_refseq_accs.tsv"

RAW_ASS_ACC_MERGED_FPATH="${WORKDIR}/${PREFIX}_raw_refseq_accs_merged.tsv"
ASS_ACC_MERGED_FPATH="${WORKDIR}/${PREFIX}_refseq_accs_merged.tsv"

ALL_GENES_FASTA="${GENES_DIR}/${PREFIX}_all_collected.fasta"
ALL_GENES_STATS="${GENES_DIR}/${PREFIX}_all_collected_stats.tsv"

CATEGORIES_FPATH="${CATEGORIES_DIR}/${PREFIX}_categories.tsv"
SEQTECH_LOGFILE="${LOGS_DIR}/${PREFIX}_seqtech_log.log"

PER_GENOME_TAXID_FPATH="${TAXONOMY_DIR}/${PREFIX}_per_genome_taxIDs.tsv"
PER_GENE_TAXID_FPATH="${TAXONOMY_DIR}/${PREFIX}_per_gene_taxIDs.tsv"

PER_GENOME_TAXONOMY_FPATH="${TAXONOMY_DIR}/${PREFIX}_per_genome_taxonomy.tsv"
PER_GENE_TAXONOMY_FPATH="${TAXONOMY_DIR}/${PREFIX}_per_gene_taxonomy.tsv"

NNN_FAIL_SEQIDS_FPATH="${ABERRATIONS_AND_HETEROGENEITY_DIR}/${PREFIX}_NNN_fail_seqIDs.txt"

REPEATS_FPATH="${ABERRATIONS_AND_HETEROGENEITY_DIR}/${PREFIX}_repeats.tsv"
REPEAT_FAIL_SEQIDS_FPATH="${ABERRATIONS_AND_HETEROGENEITY_DIR}/${PREFIX}_repeats_fail_seqIDs.txt"

CMSCAN_TBLOUT_FPATH="${ABERRATIONS_AND_HETEROGENEITY_DIR}/cmscan_output_table.tblout"

ABERRANT_SEQIDS_FPATH="${ABERRATIONS_AND_HETEROGENEITY_DIR}/aberrant_seqIDs.txt"

BLACKLIST_SEQIDS_FILE="${SCRIPT_DIR}/ad_hoc/blacklist_seqIDs.tsv"
WHITELIST_SEQIDS_FILE="${SCRIPT_DIR}/ad_hoc/whitelist_seqIDs.tsv"

FINAL_GENES_FASTA="${GENES_DIR}/${PREFIX}_final_gene_seqs.fasta"
FINAL_GENES_STATS="${GENES_DIR}/${PREFIX}_final_gene_stats.tsv"

ANNOTATED_RESULT_FASTA="${GENES_DIR}/${PREFIX}_final_gene_seqs_annotated.fasta"
DISCARDED_SEQIDS="${GENES_DIR}/discarded_seqIDs.txt"
DISCARDED_FASTA="${GENES_DIR}/${PREFIX}_discarded_gene_seqs.fasta"
ANNOTATED_DISCARDED_FASTA="${GENES_DIR}/${PREFIX}_discarded_gene_seqs_annotated.fasta"

RFAM_DIR_FOR_EXTRACT_16S=`dirname "${RFAM_FOR_EXTRACT_16S}"`
RFAM_FAMILY_FOR_EXTRACT_16S="${RFAM_DIR_FOR_EXTRACT_16S}/${PREFIX}_${RFAM_FAMILY_ID}_for_extract_16S.cm"

RFAM_DIR_FOR_FILTERING=`dirname "${RFAM_FOR_EXTRACT_16S}"`
RFAM_FAMILY_FOR_FILTERING="${RFAM_DIR_FOR_FILTERING}/${PREFIX}_${RFAM_FAMILY_ID}_for_filtering.cm"

COUNT_BASES_TABLE="${WORKDIR}/bases_count.tsv"
DISCARDED_COUNT_BASES_TABLE="${WORKDIR}/discarded_bases_count.tsv"

PER_GENE_STATS="${WORKDIR}/${PREFIX}_per_gene_stats.tsv"
DISCARDED_PER_GENE_STATS="${WORKDIR}/${PREFIX}_discarded_per_gene_stats.tsv"

ENTROPY_FILE="${ABERRATIONS_AND_HETEROGENEITY_DIR}/${PREFIX}_entropy.tsv"

if [[ ! -z "${PREV_WORKDIR}" ]]; then
  PREV_ALL_GENES_FASTA="${PREV_WORKDIR}/gene_seqs/${PREFIX}_all_collected.fasta"
  PREV_ALL_GENES_STATS="${PREV_WORKDIR}/gene_seqs/${PREFIX}_all_collected_stats.tsv"
  PREV_ASS_ACC_MERGED_FILE="${PREV_WORKDIR}/${PREFIX}_refseq_accs_merged.tsv"
  PREV_CATEGORY_FILE="${PREV_WORKDIR}/categories/${PREFIX}_categories.tsv"
  PREV_TBLOUT_FILE="${PREV_WORKDIR}/aberrations_and_heterogeneity/cmscan_output_table.tblout"
  PREV_PERBASE_ENTROPY_FILE="${PREV_WORKDIR}/aberrations_and_heterogeneity/per_base_${PREFIX}_entropy.tsv.gz"
  PREV_FINAL_GENES_FASTA="${PREV_WORKDIR}/gene_seqs/${PREFIX}_final_gene_seqs_annotated.fasta"
  PREV_PRIMERS_DIRPATH="${PREV_WORKDIR}/primers_coverage"
fi


# |=== Proceed ===|


# == Filter RefSeq .catalog file ==
python3 "${SCRIPT_DIR}/filter_refseq_catalog.py" \
  --raw-refseq-catalog "${REFSEQ_CATALOG_FILE}" \
  --outfile "${FILTERED_REFSEQ_CATALOG_FILE}"


# == Translate Assembly UIDs to RefSeq GI numbers ==

python3 "${SCRIPT_DIR}/assembly2gi_numbers.py" \
  --assm-id-file "${ASSEMBLY_IDS_FPATH}" \
  --outfile "${ASS_ID_TO_GI_FPATH}"


# == Translate RefSeq GI numbers to corresponding ACCESSION.VERSION's and titles ==

python3 "${SCRIPT_DIR}/gis_to_accs.py" \
  --gi-file "${ASS_ID_TO_GI_FPATH}" \
  --outfile "${GI_ACC_TITLES_FPATH}"


# == Merge Assembly IDs to ACCESSION.VERSION's and titles ==

python3 "${SCRIPT_DIR}/merge_assIDs_and_accs.py" \
  --assm-2-gi-file "${ASS_ID_TO_GI_FPATH}" \
  --gi-2-acc-file "${GI_ACC_TITLES_FPATH}" \
  --outfile "${RAW_ASS_ACC_MERGED_FPATH}"


# == Remove unreliable and irrelevant genomic sequences ==
# 1. Remove "whole genome shotgun" sequences.
# 2. Remove sequences added to RefSeq after the current release.
# 3. Remove sequences from the blacklist.

python3 "${SCRIPT_DIR}/remove_unwanted_refseq_seqs.py" \
  --raw-merged-file "${RAW_ASS_ACC_MERGED_FPATH}" \
  --refseq-catalog "${FILTERED_REFSEQ_CATALOG_FILE}" \
  --acc-blacklist "${ACC_BLACKLIST_FPATH}" \
  --outfile "${ASS_ACC_MERGED_FPATH}"


# == Download genomes ==

python3 "${SCRIPT_DIR}/download_genomes.py" \
  --assm-acc-file "${ASS_ACC_MERGED_FPATH}" \
  --outdir "${GENOMES_GBK_DIR}" \
  --log-file "${LOGS_DIR}/${PREFIX}_download_genomes.log"


# == Extract Rfam covariance model for 16S rRNA genes extraction ==

"${CMFETCH}" "${RFAM_FOR_EXTRACT_16S}" "${RFAM_FAMILY_ID}" > "${RFAM_FAMILY_FOR_EXTRACT_16S}"
if [[ $? != 0 ]]; then
  echo 'Error!'
  echo "Cannot extract model for family ${RFAM_FAMILY_ID} from file ${RFAM_FOR_EXTRACT_16S}"
  exit 1
fi


# == Extract 16S genes from downloaded genomes ==
if [[ ! -z "${PREV_WORKDIR}" ]]; then
  python3 "${SCRIPT_DIR}/extract_16S.py" \
    --assm-acc-file "${ASS_ACC_MERGED_FPATH}" \
    --gbk-dir "${GENOMES_GBK_DIR}" \
    --out-fasta "${ALL_GENES_FASTA}" \
    --out-stats "${ALL_GENES_STATS}" \
    --cmsearch "${CMSEARCH_FOR_EXTRACT_16S}" \
    --rfam-family-cm "${RFAM_FAMILY_FOR_EXTRACT_16S}" \
    --prev-all-genes-fasta "${PREV_ALL_GENES_FASTA}" \
    --prev-all-genes-stats "${PREV_ALL_GENES_STATS}" \
    --seqkit "${SEQKIT}"
else
  python3 "${SCRIPT_DIR}/extract_16S.py" \
    --assm-acc-file "${ASS_ACC_MERGED_FPATH}" \
    --gbk-dir "${GENOMES_GBK_DIR}" \
    --out-fasta "${ALL_GENES_FASTA}" \
    --out-stats "${ALL_GENES_STATS}" \
    --cmsearch "${CMSEARCH_FOR_EXTRACT_16S}" \
    --rfam-family-cm "${RFAM_FAMILY_FOR_EXTRACT_16S}" \
    --seqkit "${SEQKIT}"
fi


# === Taxonomy section ===

# == Get taxIDs for our genomes ==

python3 "${SCRIPT_DIR}/get_taxIDs_from_catalog.py" \
  --assm-acc-file "${ASS_ACC_MERGED_FPATH}" \
  --refseq-catalog-file "${FILTERED_REFSEQ_CATALOG_FILE}" \
  --per-genome-outfile "${PER_GENOME_TAXID_FPATH}"

# == Map seqIDs to taxIDs ==

python3 "${SCRIPT_DIR}/pergenome_2_pergene_taxIDs.py" \
  --assm-acc-file "${ASS_ACC_MERGED_FPATH}" \
  --all-fasta-file "${ALL_GENES_FASTA}" \
  --per-genome-taxID-file "${PER_GENOME_TAXID_FPATH}" \
  --per-gene-outfile "${PER_GENE_TAXID_FPATH}" \


# == Map our Aseembly IDs (and seqIDs) to full taxonomy using our taxIDs ==

python3 "${SCRIPT_DIR}/add_taxonomy_names.py" \
  --assm-acc-file "${ASS_ACC_MERGED_FPATH}" \
  --per-genome-taxid-file "${PER_GENOME_TAXID_FPATH}" \
  --per-gene-taxid-file "${PER_GENE_TAXID_FPATH}" \
  --ranked-lineage "${RANKEDLINEAGE_FPATH}" \
  --per-genome-outfile "${PER_GENOME_TAXONOMY_FPATH}" \
  --per-gene-outfile "${PER_GENE_TAXONOMY_FPATH}"

#  End of the taxonomy section
# =========================


# == Assign categories to downloaded genomes ==

if [[ ! -z "${PREV_WORKDIR}" ]]; then
  python3 "${SCRIPT_DIR}/assign_genome_categories.py" \
    --all-fasta-file "${ALL_GENES_FASTA}" \
    --all-stats-file "${ALL_GENES_STATS}" \
    --gbk-dir "${GENOMES_GBK_DIR}" \
    --outfile "${CATEGORIES_FPATH}" \
    --seqtech-logfile "${SEQTECH_LOGFILE}" \
    --prev-categories "${PREV_CATEGORY_FILE}" \
    --prev-assm-acc-file "${PREV_ASS_ACC_MERGED_FILE}" \
    --seqkit "${SEQKIT}"
else
  python3 "${SCRIPT_DIR}/assign_genome_categories.py" \
    --all-fasta-file "${ALL_GENES_FASTA}" \
    --all-stats-file "${ALL_GENES_STATS}" \
    --gbk-dir "${GENOMES_GBK_DIR}" \
    --outfile "${CATEGORIES_FPATH}" \
    --seqtech-logfile "${SEQTECH_LOGFILE}" \
    --seqkit "${SEQKIT}"
fi


# == Drop genes from genomes containing at least 3 N's in a row ==

python3 "${SCRIPT_DIR}/find_NNN.py" \
  --assm-acc-file "${ASS_ACC_MERGED_FPATH}" \
  --all-fasta-file "${ALL_GENES_FASTA}" \
  --categories-file "${CATEGORIES_FPATH}" \
  --out-fail-file "${NNN_FAIL_SEQIDS_FPATH}"


# == Extract Rfam covariance model for 16S rRNA genes exttaction ==

"${CMFETCH}" "${RFAM_FOR_FILTERING}" "${RFAM_FAMILY_ID}" > "${RFAM_FAMILY_FOR_FILTERING}"
if [[ $? != 0 ]]; then
  echo 'Error!'
  echo "Cannot extract model for family ${RFAM_FAMILY_ID} from file ${RFAM_FOR_FILTERING}"
  exit 1
fi


# == Compare all remainig genes to Rfam covariance model (cm) ==

if [[ ! -z "${PREV_WORKDIR}" ]]; then
  python3 "${SCRIPT_DIR}/compare_all_seqs_to_cm.py" \
    --in-fasta-file "${ALL_GENES_FASTA}" \
    --NNN-fail-seqIDs "${NNN_FAIL_SEQIDS_FPATH}" \
    --outdir "${ABERRATIONS_AND_HETEROGENEITY_DIR}" \
    --cmscan "${CMSCAN_FOR_FILTERING}" \
    --cmpress "${CMPRESS_FOR_FILTERING}" \
    --prev-tblout "${PREV_TBLOUT_FILE}" \
    --rfam-family-cm "${RFAM_FAMILY_FOR_FILTERING}"
else 
  python3 "${SCRIPT_DIR}/compare_all_seqs_to_cm.py" \
    --in-fasta-file "${ALL_GENES_FASTA}" \
    --NNN-fail-seqIDs "${NNN_FAIL_SEQIDS_FPATH}" \
    --outdir "${ABERRATIONS_AND_HETEROGENEITY_DIR}" \
    --cmscan "${CMSCAN_FOR_FILTERING}" \
    --cmpress "${CMPRESS_FOR_FILTERING}" \
    --rfam-family-cm "${RFAM_FAMILY_FOR_FILTERING}"
fi


# == Find aberrant genes and record long indels ==

if [[ "${CHECK_CONSERV_REGIONS}" == 1 ]]; then
  python3 "${SCRIPT_DIR}/find_aberrant_genes.py" \
    --fasta-seqs-file "${ALL_GENES_FASTA}" \
    --NNN-fail-seqIDs "${NNN_FAIL_SEQIDS_FPATH}" \
    --assm-acc-file "${ASS_ACC_MERGED_FPATH}" \
    --cmscan-tblout "${CMSCAN_TBLOUT_FPATH}" \
    --conserved-regions-fasta "${CONSERVED_REGIONS_FASTA}" \
    --outdir "${ABERRATIONS_AND_HETEROGENEITY_DIR}" \
    --muscle "${MUSCLE}" \
    --deletion-len-threshold 10
else
  python3 "${SCRIPT_DIR}/find_aberrant_genes.py" \
    --fasta-seqs-file "${ALL_GENES_FASTA}" \
    --NNN-fail-seqIDs "${NNN_FAIL_SEQIDS_FPATH}" \
    --assm-acc-file "${ASS_ACC_MERGED_FPATH}" \
    --cmscan-tblout "${CMSCAN_TBLOUT_FPATH}" \
    --outdir "${ABERRATIONS_AND_HETEROGENEITY_DIR}" \
    --muscle "${MUSCLE}" \
    --deletion-len-threshold 10
fi


# == Find repeats in genes sequences ==

python3 "${SCRIPT_DIR}/find_repeats.py" \
  --in-fasta-file "${ALL_GENES_FASTA}" \
  --NNN-fail-seqIDs "${NNN_FAIL_SEQIDS_FPATH}" \
  --aberrant-seqIDs "${ABERRANT_SEQIDS_FPATH}" \
  --repeat-len-threshold 25 \
  --out-fail-file "${REPEAT_FAIL_SEQIDS_FPATH}" \
  --out-repeats-log "${REPEATS_FPATH}"


# == Drop sequences which didn't pass filters ==
python3 "${SCRIPT_DIR}/make_final_seqs.py" \
  --all-seqs-file "${ALL_GENES_FASTA}" \
  --NNN-fail-seqIDs "${NNN_FAIL_SEQIDS_FPATH}" \
  --aberrant-seqIDs "${ABERRANT_SEQIDS_FPATH}" \
  --repeats-fail-seqIDs "${REPEAT_FAIL_SEQIDS_FPATH}" \
  --blacklist-seqIDs "${BLACKLIST_SEQIDS_FILE}" \
  --whitelist-seqIDs "${WHITELIST_SEQIDS_FILE}" \
  --assm-acc-file "${ASS_ACC_MERGED_FPATH}" \
  --out-fasta-file "${FINAL_GENES_FASTA}" \
  --out-stats-file "${FINAL_GENES_STATS}"


# == Annotate sequences: add taxonomy and categories to their headers ==
python3 "${SCRIPT_DIR}/annotate_seq_names.py" \
  --fasta-seqs-file "${FINAL_GENES_FASTA}" \
  --per-gene-taxonomy-file "${PER_GENE_TAXONOMY_FPATH}" \
  --categories-file "${CATEGORIES_FPATH}" \
  --outfile "${ANNOTATED_RESULT_FASTA}"


# == Make result sequences pretty: 60 bp per line ==
tmp_fasta='/tmp/tmp.fasta'
cat "${ANNOTATED_RESULT_FASTA}" | "${SEQKIT}" seq -uw 60 > "${tmp_fasta}"
cat "${tmp_fasta}" > "${ANNOTATED_RESULT_FASTA}"
rm "${tmp_fasta}"


# == Make a fasta file of discarded sequences ==

cat "${NNN_FAIL_SEQIDS_FPATH}" "${ABERRANT_SEQIDS_FPATH}" "${REPEAT_FAIL_SEQIDS_FPATH}" > \
  "${DISCARDED_SEQIDS}"
cat "${ALL_GENES_FASTA}" \
  | seqkit grep -f "${DISCARDED_SEQIDS}" \
  | seqkit sort -s > "${DISCARDED_FASTA}"

if [[ -f "${FINAL_SEQIDS}" ]]; then
  rm -v "${FINAL_SEQIDS}"
fi
if [[ -f "${DISCARDED_SEQIDS}" ]]; then
  rm -v "${DISCARDED_SEQIDS}"
fi


# == Annotate discarded sequences: add taxonomy and categories to their headers ==
python3 "${SCRIPT_DIR}/annotate_seq_names.py" \
  --fasta-seqs-file "${DISCARDED_FASTA}" \
  --per-gene-taxonomy-file "${PER_GENE_TAXONOMY_FPATH}" \
  --categories-file "${CATEGORIES_FPATH}" \
  --outfile "${ANNOTATED_DISCARDED_FASTA}"


# == Make result sequences pretty: 60 bp per line ==
tmp_fasta='/tmp/tmp.fasta'
cat "${ANNOTATED_DISCARDED_FASTA}" | "${SEQKIT}" seq -uw 60 > "${tmp_fasta}"
cat "${tmp_fasta}" > "${ANNOTATED_DISCARDED_FASTA}"
rm "${tmp_fasta}"


# == Make per-gene statistics file (final) ==

python3 "${SCRIPT_DIR}/count_bases.py" \
  --input-fasta "${ANNOTATED_RESULT_FASTA}" \
  --outfile "${COUNT_BASES_TABLE}"

python3 "${SCRIPT_DIR}/merge_bases_categories_taxonomy.py" \
  --bases-file "${COUNT_BASES_TABLE}" \
  --categories-file "${CATEGORIES_FPATH}" \
  --taxonomy-file "${PER_GENE_TAXONOMY_FPATH}" \
  --outfile "${PER_GENE_STATS}"


# == Make per-gene statistics file for discarded sequences ==

python3 "${SCRIPT_DIR}/count_bases.py" \
  --input-fasta "${ANNOTATED_DISCARDED_FASTA}" \
  --outfile "${DISCARDED_COUNT_BASES_TABLE}"

python3 "${SCRIPT_DIR}/merge_bases_categories_taxonomy.py" \
  --bases-file "${DISCARDED_COUNT_BASES_TABLE}" \
  --categories-file "${CATEGORIES_FPATH}" \
  --taxonomy-file "${PER_GENE_TAXONOMY_FPATH}" \
  --outfile "${DISCARDED_PER_GENE_STATS}"


# == Calculate entropy -- intragenomic variability ==

if [[ ! -z "${PREV_WORKDIR}" ]]; then
  python3 "${SCRIPT_DIR}/calculate_entropy.py" \
    --fasta-seqs-file "${ANNOTATED_RESULT_FASTA}" \
    --genes-stats-file "${FINAL_GENES_STATS}" \
    --categories-file "${CATEGORIES_FPATH}" \
    --outfile "${ENTROPY_FILE}" \
    --prev-per-base-entropy-file "${PREV_PERBASE_ENTROPY_FILE}" \
    --prev-assm-acc-file "${PREV_ASS_ACC_MERGED_FILE}" \
    --muscle "${MUSCLE}"
else
  python3 "${SCRIPT_DIR}/calculate_entropy.py" \
    --fasta-seqs-file "${ANNOTATED_RESULT_FASTA}" \
    --genes-stats-file "${FINAL_GENES_STATS}" \
    --categories-file "${CATEGORIES_FPATH}" \
    --outfile "${ENTROPY_FILE}" \
    --muscle "${MUSCLE}"
fi


# == Calculate PCR primer coverage ==

if [[ "${CALC_PRIMERS_COVERAGE}" == 1 ]]; then
  if [[ ! -z "${PREV_WORKDIR}" && -f "${PREV_FINAL_GENES_FASTA}" && -d "${PREV_PRIMERS_DIRPATH}" ]]; then
    python3 "${SCRIPT_DIR}/check_primers_mfeprimer.py" \
      --fasta-seqs-file "${ANNOTATED_RESULT_FASTA}" \
      --categories-file "${CATEGORIES_FPATH}" \
      --outdir "${PRIMERS_DIRPATH}" \
      --mfeprimer "${MFEPRIMER}" \
      --prev-final-fasta "${PREV_FINAL_GENES_FASTA}" \
      --prev-primers-outdir "${PREV_PRIMERS_DIRPATH}"
  else
    python3 "${SCRIPT_DIR}/check_primers_mfeprimer.py" \
      --fasta-seqs-file "${ANNOTATED_RESULT_FASTA}" \
      --categories-file "${CATEGORIES_FPATH}" \
      --outdir "${PRIMERS_DIRPATH}" \
      --mfeprimer "${MFEPRIMER}"
  fi
fi
