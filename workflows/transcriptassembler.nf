/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQC                      } from '../modules/nf-core/fastqc/main'
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap            } from 'plugin/nf-schema'
include { paramsSummaryMultiqc        } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML      } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText      } from '../subworkflows/local/utils_nfcore_transcriptassembler_pipeline'
include { WGET_GUNZIP_INFERNAL        } from '../subworkflows/local/wget_gunzip_infernal'
include { BUSCO                       } from '../modules/nf-core/busco/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { TRANSDECODER                } from '../modules/local/transdecoder/main'
include { TRINITY                     } from '../modules/nf-core/trinity/main'
include { DIAMOND_MAKEDB              } from '../modules/nf-core/diamond/makedb/main'
include { STAR_GENOMEGENERATE         } from '../modules/nf-core/star/genomegenerate/main'
include { DIAMOND_BLASTP              } from '../modules/nf-core/diamond/blastp/main'
include { FASTQ_FASTQC_UMITOOLS_FASTP } from '../subworkflows/nf-core/fastq_fastqc_umitools_fastp'
include { DEEPSIG                     } from '../modules/local/deepsig/main'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow TRANSCRIPTASSEMBLER {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
    //
    ch_fastq = ch_samplesheet
        .branch {
            meta, fastqs ->
                single  : fastqs.size() == 1
                    return [ meta, fastqs.flatten() ]
                multiple: fastqs.size() > 1
                    return [ meta, fastqs.flatten() ]
        }

    FASTQ_FASTQC_UMITOOLS_FASTP (
        ch_fastq.multiple,
        params.skip_fastqc || params.skip_qc,
        params.with_umi,
        params.skip_umi_extract,
        params.umi_discard_read,
        params.skip_trimming,
        [],
        params.save_trimmed,
        params.save_trimmed,
        params.min_trimmed_reads
    )
    ch_filtered_reads      = FASTQ_FASTQC_UMITOOLS_FASTP.out.reads
    ch_fastqc_raw_multiqc  = FASTQ_FASTQC_UMITOOLS_FASTP.out.fastqc_raw_zip
    ch_fastqc_trim_multiqc = FASTQ_FASTQC_UMITOOLS_FASTP.out.fastqc_trim_zip
    ch_trim_log_multiqc    = FASTQ_FASTQC_UMITOOLS_FASTP.out.trim_json
    ch_trim_read_count     = FASTQ_FASTQC_UMITOOLS_FASTP.out.trim_read_count
    ch_versions = ch_versions.mix(FASTQ_FASTQC_UMITOOLS_FASTP.out.versions)

    //
    // Get list of samples that failed trimming threshold for MultiQC report
    //
    ch_trim_read_count
        .map {
            meta, num_reads ->
                pass_trimmed_reads[meta.id] = true
                if (num_reads <= params.min_trimmed_reads.toFloat()) {
                    pass_trimmed_reads[meta.id] = false
                    return [ "$meta.id\t$num_reads" ]
                }
        }
        .collect()
        .map {
            tsv_data ->
                def header = ["Sample", "Reads after trimming"]
                WorkflowTranscriptassembler.multiqcTsvFromList(tsv_data, header)
        }
        .set { ch_fail_trimming_multiqc }

    // MODULE: TRINITY
    //
    TRINITY (
        ch_filtered_reads
    )
    ch_assembled_transcript_fasta  = TRINITY.out.transcript_fasta
    ch_versions                    = ch_versions.mix(TRINITY.out.versions)

    // TODO nf-core: Investigate failure EPS 2025-03-19
    //WGET_GUNZIP_INFERNAL (
    //    ch_assembled_transcript_fasta
    //)
    //infernal_ch = WGET_GUNZIP_INFERNAL.out

    // MODULE: BUSCO
    if (!params.skip_busco) {
        BUSCO (
            ch_assembled_transcript_fasta,
            params.busco_mode,
            params.busco_lineage,
            params.busco_lineage_path,
            []
        )
        ch_versions                    = ch_versions.mix(BUSCO.out.versions)
    }

    // MODULE: TRANSDECODER
    TRANSDECODER (
        ch_assembled_transcript_fasta
    )
        ch_gff      = TRANSDECODER.out.gff
        ch_protein  = TRANSDECODER.out.pep
        ch_versions = ch_versions.mix(TRANSDECODER.out.versions)

    // MODULE: DEEPSIG
    DEEPSIG(
        ch_protein
    )
    ch_versions                    = ch_versions.mix(DEEPSIG.out.versions)

    // MODULE: DIAMOND_MAKEDB
    if (!params.skip_diamond){
        DIAMOND_MAKEDB(
            params.diamond_fasta
        )
        ch_versions                    = ch_versions.mix(DIAMOND_MAKEDB.out.versions)
    }


// MODULE: DIAMOND_BLASTP
    if (!params.skip_diamond_blastp){
        DIAMOND_BLASTP(
            [[id:'test', single_end:true],params.diamond_fasta], // generic meta data
            DIAMOND_MAKEDB.out.db,
            params.diamond_blastp_outext,
            params.diamond_blastp_columns
        )
        ch_versions                    = ch_versions.mix(DIAMOND_BLASTP.out.versions)
    }

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_'  +  'transcriptassembler_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
