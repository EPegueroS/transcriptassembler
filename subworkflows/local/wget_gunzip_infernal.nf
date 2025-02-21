// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { GUNZIP as GUNZIPCM } from '../../modules/nf-core/gunzip/main'
include { GUNZIP as GUNZIPFASTA } from '../../modules/nf-core/gunzip/main'
include { WGET as WGETCM } from '../../modules/local/wget/main'
include { WGET as WGETCLANIN } from '../../modules/local/wget/main'
include { CMPRESS } from '../../modules/local/infernal/cmpress/cmpress'
include { CMSCAN } from '../../modules/local/infernal/cmscan/cmscan'

workflow WGET_GUNZIP_INFERNAL {

    take:
    ch_assembled_transcript_fasta

    main:

    ch_versions = Channel.empty()

    // TODO nf-core: substitute modules here for the modules of your subworkflow
    WGETCM (
        params.rfam_cm_path,
        'Rfam.cm'
    )
    ch_versions = ch_versions.mix(WGETCM.out.versions)
    GUNZIPCM {
        WGETCM.out.file
    }
    ch_versions = ch_versions.mix(GUNZIPCM.out.versions)

    GUNZIPFASTA {
        ch_assembled_transcript_fasta
    }
    ch_versions = ch_versions.mix(GUNZIPFASTA.out.versions)

    CMPRESS (
        GUNZIPCM.out.gunzip
    )
    ch_versions = ch_versions.mix(CMPRESS.out.versions)

    CMSCAN (
        GUNZIPFASTA.out.gunzip,
        params.rfam_clanin_path,
        CMPRESS.out.cmpress.collect()
    )
    ch_versions = ch_versions.mix(CMSCAN.out.versions)
    

    //emit:
    // TODO nf-core: edit emitted channels
    //WGET_CM.out

    //versions = ch_versions                     // channel: [ versions.yml ]
}

