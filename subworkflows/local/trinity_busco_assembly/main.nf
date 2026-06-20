include { TRINITY } from '../../../modules/nf-core/trinity/main'
include { BUSCO   } from '../../../modules/nf-core/busco/main'

workflow TRINITY_BUSCO_ASSEMBLY {

    take:
    ch_reads             // channel: [ val(meta), path(reads) ]
    val_skip_busco       // val: boolean - skip BUSCO completeness assessment
    val_busco_mode       // val: string  - BUSCO mode (genome, proteins, or transcriptome)
    val_busco_lineage    // val: string  - BUSCO lineage dataset, or 'auto' for auto-lineage
    busco_lineage_path   // path: path to BUSCO lineages - downloads if not set
    busco_config         // path: BUSCO configuration file (optional)

    main:

    ch_versions = Channel.empty()

    TRINITY (
        ch_reads
    )
    ch_versions = ch_versions.mix(TRINITY.out.versions)

    ch_busco_batch_summary        = Channel.empty()
    ch_busco_short_summaries_txt  = Channel.empty()
    ch_busco_short_summaries_json = Channel.empty()
    ch_busco_dir                  = Channel.empty()

    if (!val_skip_busco) {
        BUSCO (
            TRINITY.out.transcript_fasta,
            val_busco_mode,
            val_busco_lineage,
            busco_lineage_path,
            busco_config
        )
        ch_busco_batch_summary        = BUSCO.out.batch_summary
        ch_busco_short_summaries_txt  = BUSCO.out.short_summaries_txt
        ch_busco_short_summaries_json = BUSCO.out.short_summaries_json
        ch_busco_dir                  = BUSCO.out.busco_dir
        ch_versions                   = ch_versions.mix(BUSCO.out.versions)
    }

    emit:
    transcript_fasta            = TRINITY.out.transcript_fasta    // channel: [ val(meta), path(fasta) ]
    busco_batch_summary          = ch_busco_batch_summary         // channel: [ val(meta), path(txt) ]
    busco_short_summaries_txt    = ch_busco_short_summaries_txt   // channel: [ val(meta), path(txt) ]
    busco_short_summaries_json   = ch_busco_short_summaries_json  // channel: [ val(meta), path(json) ]
    busco_dir                    = ch_busco_dir                   // channel: [ val(meta), path(dir) ]
    versions                     = ch_versions                    // channel: [ path(versions.yml) ]
}
