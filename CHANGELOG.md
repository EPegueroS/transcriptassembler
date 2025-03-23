# nf-core/transcriptassembler: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v.1.0.16dev - [2025-03-23]

### `Added`

Improvements to the pipeline documentation, including a basic diagram.

## v.1.0.15dev - [2025-03-01]

### `Added`

Deepsig to predict signal peptides

## v.1.0.14dev - [2025-02-19]

### `Added`

Updated template

### `Removed`

STAR processes and WGET_GUNZIP_INFERNAL - need to investigate failures

### `Fixed`

Tests

## v.0.0.14dev - [2024-10-2]

### `Added`

Added STAR mapping with the star-align subworkflow

## v.0.0.13dev -[2024-10-19]

### `Added`

Implemented subworkflow to run infernal search and classify RNAs.

## v.0.0.12dev -[2024-10-2]

### `Added`

Implemented diamond/blastp module

## v.0.0.11dev - [2024-08-6]

### `Fixed`

Updated transdecoder conda and container versions.

## v.0.0.10dev - [2024-07-11]

### `Added`

Implemented diamond_makedb module and added test dataset

## v0.0.9dev - [2024-06-07]

### `Added`

BUSCO test reduced dataset
Updated nf-core template with `nf-core lint --fix files_unchanged` and fixed lint errors

## v0.0.8dev - [2024-02-23]

### `Added`

BUSCO
Updated latest nf-core template

## v0.0.7dev - [2023-10-10]

### `Added`

transdecoder predict

## v0.0.6dev - [2023-09-07]

### `Added`

transdecoder longorf

## v0.0.5dev - [2023-09-03]

### `Added`

Trinity de-novo RNA assembler

## v0.0.4dev - [2023-09-02]

### `Added`

Generation of multiqc report

## v0.0.3dev - [2023-08-26]

### `Added`

subworkflow from nf-core astq_fastqc_umitools_fastp

## `Deprecated`

fastqc and multiqc as independent modules

## v0.0.2dev - [2023-07-28]

### `Added`

Additional test data
Updated fastqc
sync nf-core

## v0.0.1dev - [2023-06-17]

Initial release of nf-core/transcriptassembler, created with the [nf-core](https://nf-co.re/) template.

### `Added`

Minimal test data
Custom samplesheet
Documentation

### `Fixed`

Removed requirement of a genome

### `Dependencies`

### `Deprecated`
