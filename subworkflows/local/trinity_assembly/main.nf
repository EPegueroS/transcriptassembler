include { TRINITY                 } from '../../../modules/nf-core/trinity/main'
include { GUNZIP                  } from '../../../modules/nf-core/gunzip/main'
include { STAR_GENOMEGENERATE     } from '../../../modules/nf-core/star/genomegenerate/main'
include { STAR_STRINGTIE_UNGUIDED } from '../star_stringtie_unguided/main'

workflow TRINITY_ASSEMBLY {

    take:
    ch_reads          // channel: [ val(meta), path(reads) ]
    val_seq_platform  // val: string - sequencing platform (e.g. ILLUMINA)
    val_seq_center    // val: string - sequencing center

    main:

    ch_versions = Channel.empty()

    // De novo transcript assembly from raw reads
    TRINITY ( ch_reads )
    ch_versions = ch_versions.mix(TRINITY.out.versions)

    // STAR_GENOMEGENERATE requires an uncompressed FASTA; decompress Trinity's .fa.gz first
    GUNZIP ( TRINITY.out.transcript_fasta )
    ch_versions = ch_versions.mix(GUNZIP.out.versions)

    // Build STAR index from Trinity assembly — treated as the reference "genome".
    // No GTF available; STAR_GENOMEGENERATE auto-scales --genomeSAindexNbases from assembly size.
    STAR_GENOMEGENERATE (
        GUNZIP.out.gunzip,
        Channel.value([[id: 'no_gtf'], []])  // no annotation GTF for de novo
    )
    ch_versions = ch_versions.mix(STAR_GENOMEGENERATE.out.versions)

    // Realign reads to Trinity assembly without GTF guide to build an annotation GTF.
    // Produces the merged_gtf that describes transcript structure on Trinity contig coordinates.
    STAR_STRINGTIE_UNGUIDED (
        ch_reads,
        STAR_GENOMEGENERATE.out.index,
        val_seq_platform,
        val_seq_center
    )
    ch_versions = ch_versions.mix(STAR_STRINGTIE_UNGUIDED.out.versions)

    emit:
    transcript_fasta = TRINITY.out.transcript_fasta             // channel: [ val(meta), path(fasta) ]
    merged_gtf       = STAR_STRINGTIE_UNGUIDED.out.merged_gtf  // channel: [ path(gtf) ]
    versions         = ch_versions                              // channel: [ path(versions.yml) ]
}
