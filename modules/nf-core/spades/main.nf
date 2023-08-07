#!/usr/bin/env nextflow

/*
 * SPAdes Transcriptome Assembly
 * This pipeline runs SPAdes for transcriptome assembly
 */

params.pairedEndReads = "${baseDir}/data/*_[1-2].fq.gz"
params.singleEndReads = "${baseDir}/data/*.fq.gz"
params.outdir = "results"

log.info """\
    S P A D E S   T R A N S C R I P T O M E   A S S E M B L Y
    =========================================================
    pairedEndReads: ${params.pairedEndReads}
    singleEndReads: ${params.singleEndReads}
    outdir         : ${params.outdir}
    """
    .stripIndent()

process SPAdesTranscriptomePaired {
    container 'pegi3s/spades'

    input:
    tuple val(sample_id), path(reads)

    output:
    path "spades_${sample_id}_assembly"

    script:
    """
    spades.py --rna -o spades_${sample_id}_assembly -1 ${reads[0]} -2 
${reads[1]}
    """
}

process SPAdesTranscriptomeSingle {
    container 'pegi3s/spades'

    input:
    tuple val(sample_id), path(reads)

    output:
    path "spades_${sample_id}_assembly"

    script:
    """
    spades.py --rna -o spades_${sample_id}_assembly --pe-12 ${reads}
    """
}

workflow {
    pairedEndReads = Channel.fromFilePairs(params.pairedEndReads, 
checkIfExists: true)
                           .set { read_pairs_ch }

    singleEndReads = Channel.fromFilePairs(params.singleEndReads, 
checkIfExists: true)
                            .set { single_reads_ch }

    // Initialize empty channels in case one of them is empty
    def spades_paired_ch = null
    def spades_single_ch = null

    // Run SPAdes for paired-end reads if available
    if (pairedEndReads != null) {
        spades_paired_ch = pairedEndReads.map { sample_id, reads ->
            SPAdesTranscriptomePaired(sample_id: sample_id, reads: reads)
        }
    }

    // Run SPAdes for single-end reads if available
    if (singleEndReads != null) {
        spades_single_ch = singleEndReads.map { sample_id, reads ->
            SPAdesTranscriptomeSingle(sample_id: sample_id, reads: reads)
        }
    }

    // Merge the results from both channels
    def merged_assembly_ch = merge(spades_paired_ch ?: [], spades_single_ch 
?: [])

    // Final SPAdes process (single output for the assembly)
    process SPAdesFinal {
        input:
        path spades_assembly from merged_assembly_ch.flatMap { 
it.spades_${sample_id}_assembly }

        // Output directory for the final assembly
        output:
        path "final_spades_assembly"

        // Script to copy the assembly to the output directory
        script:
        """
        mkdir -p final_spades_assembly
        cp -r ${spades_assembly}/* final_spades_assembly/
        """
    }
}

workflow.onComplete {
    log.info ( workflow.success ? "\nDone! SPAdes assembly completed 
successfully.\n" : "Oops... Something went wrong with SPAdes assembly." )
}
