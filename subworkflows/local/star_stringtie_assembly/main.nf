include { STAR_GENOMEGENERATE } from '../../../modules/nf-core/star/genomegenerate/main'
include { STAR_ALIGN          } from '../../../modules/nf-core/star/align/main'
include { STRINGTIE_STRINGTIE } from '../../../modules/nf-core/stringtie/stringtie/main'
include { STRINGTIE_MERGE     } from '../../../modules/nf-core/stringtie/merge/main'
include { GFFREAD             } from '../../../modules/nf-core/gffread/main'

workflow STAR_STRINGTIE_ASSEMBLY {

    take:
    ch_reads                // channel: [ val(meta), path(reads) ]
    ch_fasta                // channel: [ val(meta), path(fasta) ]
    ch_gtf                  // channel: [ val(meta2), path(gtf) ]
    val_star_ignore_sjdbgtf // val: boolean - skip re-extracting splice junctions from GTF when using pre-built index
    val_seq_platform        // val: string  - sequencing platform (e.g. ILLUMINA)
    val_seq_center          // val: string  - sequencing center

    main:

    ch_versions = Channel.empty()

    STAR_GENOMEGENERATE (
        ch_fasta,
        ch_gtf
        )
    ch_versions = ch_versions.mix(STAR_GENOMEGENERATE.out.versions)

    STAR_ALIGN (
        ch_reads,
        STAR_GENOMEGENERATE.out.index,
        ch_gtf,
        val_star_ignore_sjdbgtf,
        val_seq_platform,
        val_seq_center
    )
    ch_versions = ch_versions.mix(STAR_ALIGN.out.versions.first())

    // bam_sorted requires --outSAMtype BAM SortedByCoordinate set in STAR_ALIGN ext.args
    ch_annotation_gtf = ch_gtf.map { _meta, gtf -> gtf }

    STRINGTIE_STRINGTIE (
        STAR_ALIGN.out.bam_sorted,
        ch_annotation_gtf.first()
        )
    ch_versions = ch_versions.mix(STRINGTIE_STRINGTIE.out.versions.first())

    ch_stringtie_gtfs = STRINGTIE_STRINGTIE.out.transcript_gtf
        .map { _meta, gtf -> gtf }
        .collect()

    STRINGTIE_MERGE (
        ch_stringtie_gtfs,
        ch_annotation_gtf.first()
        )
    ch_versions = ch_versions.mix(STRINGTIE_MERGE.out.versions)

    // MODULE: GFFREAD - extract spliced transcript FASTA from the merged annotation
    // so downstream coding/non-coding annotation steps have a transcript FASTA to consume,
    // mirroring de novo assembly's output.
    ch_merged_gtf = STRINGTIE_MERGE.out.gtf.map { gtf -> [ [id: 'merged'], gtf ] }

    GFFREAD (
        ch_merged_gtf,
        ch_fasta.map { _meta, fasta -> fasta }
    )
    // Note: GFFREAD reports its version via a topic channel (`versions_gffread`), not the
    // classic versions.yml path emitted by the other modules here, so it isn't mixed into
    // ch_versions yet.

    emit:
    star_index       = STAR_GENOMEGENERATE.out.index          // channel: [ val(meta), path(index) ]
    bam              = STAR_ALIGN.out.bam                     // channel: [ val(meta), path(bam) ]
    bam_sorted       = STAR_ALIGN.out.bam_sorted              // channel: [ val(meta), path(bam) ]
    log_final        = STAR_ALIGN.out.log_final               // channel: [ val(meta), path(log_final) ]
    log_out          = STAR_ALIGN.out.log_out                 // channel: [ val(meta), path(log_out) ]
    transcript_gtf   = STRINGTIE_STRINGTIE.out.transcript_gtf // channel: [ val(meta), path(gtf) ]
    abundance        = STRINGTIE_STRINGTIE.out.abundance      // channel: [ val(meta), path(abundance) ]
    merged_gtf       = STRINGTIE_MERGE.out.gtf                // channel: [ path(gtf) ]
    transcript_fasta = GFFREAD.out.gffread_fasta               // channel: [ val(meta), path(fasta) ]
    versions         = ch_versions                            // channel: [ path(versions.yml) ]
}
