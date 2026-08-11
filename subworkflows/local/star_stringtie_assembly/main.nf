include { STAR_GENOMEGENERATE     } from '../../../modules/nf-core/star/genomegenerate/main'
include { STAR_ALIGN              } from '../../../modules/nf-core/star/align/main'
include { STRINGTIE_STRINGTIE     } from '../../../modules/nf-core/stringtie/stringtie/main'
include { STRINGTIE_MERGE         } from '../../../modules/nf-core/stringtie/merge/main'
include { GFFREAD                 } from '../../../modules/nf-core/gffread/main'
include { STAR_STRINGTIE_UNGUIDED } from '../star_stringtie_unguided/main'

workflow STAR_STRINGTIE_ASSEMBLY {

    take:
    ch_reads         // channel: [ val(meta), path(reads) ]
    ch_fasta         // channel: [ val(meta), path(fasta) ]
    ch_gtf           // channel: [ val(meta2), path(gtf) ]
    val_seq_platform // val: string - sequencing platform (e.g. ILLUMINA)
    val_seq_center   // val: string - sequencing center

    main:

    ch_versions = Channel.empty()

    // Build genome index with reference GTF so known splice sites are embedded in the index
    STAR_GENOMEGENERATE ( ch_fasta, ch_gtf )
    ch_versions = ch_versions.mix(STAR_GENOMEGENERATE.out.versions)

    // Pass 1: align without GTF guide to discover splice junctions from read evidence alone
    STAR_STRINGTIE_UNGUIDED (
        ch_reads,
        STAR_GENOMEGENERATE.out.index,
        val_seq_platform,
        val_seq_center
    )
    ch_versions = ch_versions.mix(STAR_STRINGTIE_UNGUIDED.out.versions)

    // Pass 2: realign reads using StringTie-derived splice junctions as annotation guide.
    // The merged GTF from pass 1 tells STAR exactly where splice sites are.
    ch_merged_gtf_pass1 = STAR_STRINGTIE_UNGUIDED.out.merged_gtf
        .map { gtf -> [[id: 'merged_pass1'], gtf] }

    STAR_ALIGN (
        ch_reads,
        STAR_GENOMEGENERATE.out.index.first(),  // broadcast single index to all samples
        ch_merged_gtf_pass1.first(),            // broadcast single merged GTF to all samples
        false,                                   // star_ignore_sjdbgtf = false → --sjdbGTFfile used
        val_seq_platform,
        val_seq_center
    )
    ch_versions = ch_versions.mix(STAR_ALIGN.out.versions.first())

    // Second StringTie pass on improved alignments — produces higher-quality transcript models
    STRINGTIE_STRINGTIE (
        STAR_ALIGN.out.bam_sorted,
        []  // no guide GTF: improved alignments drive the second-pass assembly
    )
    ch_versions = ch_versions.mix(STRINGTIE_STRINGTIE.out.versions.first())

    ch_stringtie_gtfs_pass2 = STRINGTIE_STRINGTIE.out.transcript_gtf
        .map { _meta, gtf -> gtf }
        .collect()

    STRINGTIE_MERGE (
        ch_stringtie_gtfs_pass2,
        []  // no reference GTF
    )
    ch_versions = ch_versions.mix(STRINGTIE_MERGE.out.versions)

    // Extract spliced transcript FASTA from the final annotation for downstream annotation steps
    ch_merged_gtf_final = STRINGTIE_MERGE.out.gtf
        .map { gtf -> [[id: 'merged_final'], gtf] }

    GFFREAD (
        ch_merged_gtf_final,
        ch_fasta.map { _meta, fasta -> fasta }
    )
    // Note: GFFREAD uses topic-channel versioning (versions_gffread) incompatible with
    // the classic versions.yml path expected by softwareVersionsToYAML; skipped for now.

    emit:
    star_index           = STAR_GENOMEGENERATE.out.index               // channel: [ val(meta), path(index) ]
    bam_pass1            = STAR_STRINGTIE_UNGUIDED.out.bam_sorted      // channel: [ val(meta), path(bam) ]
    per_sample_gtf_pass1 = STAR_STRINGTIE_UNGUIDED.out.per_sample_gtf // channel: [ val(meta), path(gtf) ]
    merged_gtf_pass1     = STAR_STRINGTIE_UNGUIDED.out.merged_gtf      // channel: [ path(gtf) ]
    bam                  = STAR_ALIGN.out.bam_sorted                   // channel: [ val(meta), path(bam) ]
    log_final            = STAR_ALIGN.out.log_final                    // channel: [ val(meta), path(log) ]
    log_out              = STAR_ALIGN.out.log_out                      // channel: [ val(meta), path(log) ]
    per_sample_gtf       = STRINGTIE_STRINGTIE.out.transcript_gtf      // channel: [ val(meta), path(gtf) ]
    abundance            = STRINGTIE_STRINGTIE.out.abundance           // channel: [ val(meta), path(txt) ]
    merged_gtf           = STRINGTIE_MERGE.out.gtf                     // channel: [ path(gtf) ]
    transcript_fasta     = GFFREAD.out.gffread_fasta                   // channel: [ val(meta), path(fasta) ]
    versions             = ch_versions                                 // channel: [ path(versions.yml) ]
}
