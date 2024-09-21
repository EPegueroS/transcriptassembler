// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { GUNZIP } from '../../modules/nf-core/gunzip/main'
include { WGET as WGET_CM } from '../../modules/local/wget/main'
include { WGET as WGET_CLANIN } from '../../modules/local/wget/main'

workflow WGET_GUNZIP_INFERNAL {


    main:

    ch_versions = Channel.empty()

    // TODO nf-core: substitute modules here for the modules of your subworkflow
    WGET_CM (
        params.rfam_cm_path,
        'Rfam.cm'
    )
    ch_versions = ch_versions.mix(WGET_CM.out.versions)
    

    WGET_CLANIN (
        params.rfam_clanin_path,
        'Rfam.clanin'
    )
    ch_versions = ch_versions.mix(WGET_CLANIN.out.versions)

    GUNZIP {
        WGET_CM.out.file
    }
    ch_versions = ch_versions.mix(GUNZIP.out.versions)

 
     
    

    //emit:
    // TODO nf-core: edit emitted channels
    //WGET_CM.out

    //versions = ch_versions                     // channel: [ versions.yml ]
}

