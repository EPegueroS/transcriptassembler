include { STAR_ALIGN          } from '../../../modules/nf-core/star/align/main'
include { STRINGTIE_STRINGTIE } from '../../../modules/nf-core/stringtie/stringtie/main'
include { STRINGTIE_MERGE     } from '../../../modules/nf-core/stringtie/merge/main'

workflow STAR_STRINGTIE_UNGUIDED {

    take:
    ch_reads          // channel: [ val(meta), path(reads) ]
    ch_star_index     // channel: [ val(meta), path(index) ]
    val_seq_platform  // val: string - sequencing platform (e.g. ILLUMINA)
    val_seq_center    // val: string - sequencing center

    main:

    ch_versions = Channel.empty()

    // Align reads without annotation GTF — splice junctions discovered from read evidence alone.
    // ch_star_index.first() broadcasts a single index to all samples.
    STAR_ALIGN (
        ch_reads,
        ch_star_index.first(),
        Channel.value([[id: 'no_gtf'], []]),  // no annotation GTF
        true,                                  // star_ignore_sjdbgtf: omit --sjdbGTFfile
        val_seq_platform,
        val_seq_center
    )
    ch_versions = ch_versions.mix(STAR_ALIGN.out.versions.first())

    STRINGTIE_STRINGTIE (
        STAR_ALIGN.out.bam_sorted,
        []  // no guide GTF
    )
    ch_versions = ch_versions.mix(STRINGTIE_STRINGTIE.out.versions.first())

    ch_stringtie_gtfs = STRINGTIE_STRINGTIE.out.transcript_gtf
        .map { _meta, gtf -> gtf }
        .collect()

    STRINGTIE_MERGE (
        ch_stringtie_gtfs,
        []  // no reference GTF
    )
    ch_versions = ch_versions.mix(STRINGTIE_MERGE.out.versions)

    emit:
    bam_sorted     = STAR_ALIGN.out.bam_sorted              // channel: [ val(meta), path(bam) ]
    log_final      = STAR_ALIGN.out.log_final               // channel: [ val(meta), path(log) ]
    log_out        = STAR_ALIGN.out.log_out                 // channel: [ val(meta), path(log) ]
    per_sample_gtf = STRINGTIE_STRINGTIE.out.transcript_gtf // channel: [ val(meta), path(gtf) ]
    merged_gtf     = STRINGTIE_MERGE.out.gtf                // channel: [ path(gtf) ]
    versions       = ch_versions                            // channel: [ path(versions.yml) ]
}
