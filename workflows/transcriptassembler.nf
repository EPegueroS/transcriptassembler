/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

WorkflowTranscriptassembler.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// TODO used files for multi QC
ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check'
include { MULTIQC } from '../modules/local/multiqc'
include { TRANSDECODER_PREDICT  } from '../modules/local/transdecoder_predict'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { BUSCO } from '../modules/nf-core/busco/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { TRANSDECODER_LONGORF } from '../modules/nf-core/transdecoder/longorf/main'
include { TRINITY } from '../modules/nf-core/trinity/main'

//
// SUBWORKFLOW: Installed from nf-core/subworkflows
//

include { FASTQ_FASTQC_UMITOOLS_FASTP } from '../subworkflows/nf-core/fastq_fastqc_umitools_fastp/main'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []
def pass_trimmed_reads = [:]

workflow TRANSCRIPTASSEMBLER {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        file(params.input)
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    // TODO: OPTIONAL, you can use nf-validation plugin to create an input channel from the samplesheet with Channel.fromSamplesheet("input")
    // See the documentation https://nextflow-io.github.io/nf-validation/samplesheets/fromSamplesheet/
    // ! There is currently no tooling to help you write a sample sheet schema

    //
    // SUBWORKFLOW: Read QC, extract UMI and trim adapters with fastp
    //
    ch_filtered_reads      = Channel.empty()
    ch_fastqc_raw_multiqc  = Channel.empty()
    ch_fastqc_trim_multiqc = Channel.empty()
    ch_trim_log_multiqc    = Channel.empty()
    ch_trim_read_count     = Channel.empty()
    FASTQ_FASTQC_UMITOOLS_FASTP (
        INPUT_CHECK.out.reads,
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
    TRANSDECODER_LONGORF (
        ch_assembled_transcript_fasta
    )
    ch_longorf_pep                 = TRANSDECODER_LONGORF.out.pep
    ch_longorfs                    = TRANSDECODER_LONGORF.out.folder
    ch_versions                    = ch_versions.mix(TRANSDECODER_LONGORF.out.versions)

    TRANSDECODER_PREDICT (
        ch_assembled_transcript_fasta,
        ch_longorfs
    )
    ch_gff                         = TRANSDECODER_PREDICT.out.gff3
    ch_aa                          = TRANSDECODER_PREDICT.out.pep
    ch_versions                    = ch_versions.mix(TRANSDECODER_PREDICT.out.versions)
    


    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )


// MODULE: MultiQC
//
    if (!params.skip_multiqc) {
        workflow_summary    = WorkflowTranscriptassembler.paramsSummaryMultiqc(workflow, summary_params)
        ch_workflow_summary = Channel.value(workflow_summary)

        methods_description    = WorkflowTranscriptassembler.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description, summary_params)
        ch_methods_description = Channel.value(methods_description)

        MULTIQC (
            ch_multiqc_config,
            ch_multiqc_custom_config.collect().ifEmpty([]),
            CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect(),
            ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'),
            ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'),
            ch_multiqc_logo.collect().ifEmpty([]),
            ch_fail_trimming_multiqc.collectFile(name: 'fail_trimmed_samples_mqc.tsv').ifEmpty([]),
            ch_fastqc_raw_multiqc.collect{it[1]}.ifEmpty([]),
            ch_fastqc_trim_multiqc.collect{it[1]}.ifEmpty([]),
            ch_trim_log_multiqc.collect{it[1]}.ifEmpty([]),
        )
        multiqc_report = MULTIQC.out.report.toList()
    }

}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report, pass_trimmed_reads)
    }
    NfcoreTemplate.dump_parameters(workflow, params)
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
