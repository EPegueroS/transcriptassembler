# nf-core/transcriptassembler: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.20.0dev - [2026-06-20]

### Added

- Added `TRINITY_BUSCO_ASSEMBLY` local subworkflow for de novo transcript assembly, bundling `TRINITY` and `BUSCO`.
- Added `GFFREAD` to `STAR_STRINGTIE_ASSEMBLY` to extract a spliced transcript FASTA from the merged GTF and reference genome, so reference-guided runs produce a transcript FASTA for downstream annotation steps to consume (same shape as de novo's Trinity output).

### Changed

- `reference_guided_assembly` now selects between two mutually exclusive assembly modes: reference-guided (`STAR_STRINGTIE_ASSEMBLY`) or de novo (`TRINITY_BUSCO_ASSEMBLY`), instead of running Trinity unconditionally with StringTie running additively alongside it.
- TransDecoder/BLAST/DeepSig/OrthoFinder/ColabFold now run for both assembly modes, since both now produce a transcript FASTA.

## v1.19.0dev - [2026-06-05]

### Added

- Added `STAR_STRINGTIE_ASSEMBLY` local subworkflow for reference-guided transcript aseembly. This subworkflow replaces `STAR` and `STRINGTIE` independent runs on `transcriptassembler.nf`.

## v1.18.0dev - [2026-04-24]

### Added

- Added `STRINGTIE/STRINGTIE` and `STRINGTIE/MERGE` modules as an alternative for de novo transcript assembly.

## v1.17.0dev - [2026-03-17]

### Added

- Added `SPLIT_CODING_NONCODING` module to separate TransDecoder output into coding and non-coding transcripts.
- Connected Infernal (`WGET_GUNZIP_INFERNAL` subworkflow) to annotate non-coding transcripts.
- Added `FILTER_BLASTP_CODING` module to subset existing LongORF BLASTP results to predicted coding ORFs, avoiding a redundant BLASTP run.

### Updated

- BLASTP now runs on `TRANSDECODER_LONGORF` peptide output to provide homology evidence to `TRANSDECODER_PREDICT` via `--retain_blastp_hits`.
- Updated pipeline diagram in README to reflect coding/non-coding split, Infernal integration, and `FILTER_BLASTP_CODING`.

## v1.16.0dev - [2026-02-14]

### Added

- Added OrthoFinder module for orthologous gene group inference.

### Notes

- Versioning corrected to follow Semantic Versioning (semver) properly. Previous versions incorrectly bumped PATCH instead of MINOR when adding new modules. This release reflects the true version based on the number of functional modules added since v1.0.0dev.

## v1.15.0dev - [2026-02-14]

### Updated

- Updated nf-core template to v3.5.2.
- Updated nf-core modules: multiqc (1.32), fastqc, utils_nfschema_plugin (nf-schema 2.5.1 with help system).
- Updated GitHub Actions workflows to latest versions.
- Updated nf-test.yml to test minimum Nextflow version (24.04.2).
- Removed obsolete workflow files (ci.yml, release-announcments.yml, template_version_comment.yml).

### Fixed

- Fixed `colabfold_alphafold2_params_tags` schema validation (object type, excluded from param validation).
- Fixed UTILS_NFSCHEMA_PLUGIN call signature (3 args to 9 args) to match updated subworkflow.
- Updated modules.json git_shas to match installed module/subworkflow versions.

## v1.14.0dev - [2026-01-21]

### Added

- Added BLASTP and BLASTN modules for functional annotation.

## v1.13.0dev - [2025-11-08]

### Added

- Added protein folding subworkflow (colabfold) based on nf-core/proteinfold.

## v1.12.0dev - [2025-09-06]

### Added

- Configured module `blast/blastp`

### Removed

- Removed module `blast/blastn`

## v1.11.2dev - [2025-03-30]

### Added

- Improvements to the pipeline documentation, including a basic diagram.

## v1.11.1dev - [2025-03-29]

### Fixed

- STAR module fixed to accept compressed files.

## v1.11.0dev - [2025-03-01]

### Added

- Added DeepSig to predict signal peptides.

## v1.10.1dev - [2025-02-19]

### Added

- Updated template.

### Removed

- STAR processes and WGET_GUNZIP_INFERNAL - need to investigate failures.

### Fixed

- Tests.

## v1.10.0dev - [2024-10-02]

### Added

- Added STAR mapping with the star-align subworkflow.

## v1.9.0dev - [2024-10-19]

### Added

- Implemented subworkflow to run Infernal search and classify RNAs.

## v1.8.0dev - [2024-10-02]

### Added

- Implemented diamond/blastp module.

## v1.7.1dev - [2024-08-06]

### Fixed

- Updated Transdecoder conda and container versions.

## v1.7.0dev - [2024-07-11]

### Added

- Implemented diamond_makedb module and added test dataset.

## v1.6.1dev - [2024-06-07]

### Added

- BUSCO test reduced dataset.
- Updated nf-core template with `nf-core lint --fix files_unchanged` and fixed lint errors.

## v1.6.0dev - [2024-02-23]

### Added

- Added BUSCO.
- Updated latest nf-core template.

## v1.5.0dev - [2023-10-10]

### Added

- Added Transdecoder predict.

## v1.4.0dev - [2023-09-07]

### Added

- Added Transdecoder longorf.

## v1.3.0dev - [2023-09-03]

### Added

- Added Trinity de-novo RNA assembler.

## v1.2.0dev - [2023-09-02]

### Added

- Added generation of MultiQC report.

## v1.1.0dev - [2023-08-26]

### Added

- Added subworkflow from nf-core `fastq_fastqc_umitools_fastp`.

### Deprecated

- Standalone FastQC and MultiQC as independent modules.

## v1.0.1dev - [2023-07-28]

### Added

- Additional test data.
- Updated FastQC.
- Sync nf-core.

## v1.0.0dev - [2023-06-17]

Initial release of nf-core/transcriptassembler, created with the [nf-core](https://nf-co.re/) template.

### Added

- Minimal test data.
- Custom samplesheet.
- Documentation.

### Fixed

- Removed requirement of a genome.
