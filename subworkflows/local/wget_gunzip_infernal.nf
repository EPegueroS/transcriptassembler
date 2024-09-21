// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { WGET as WGET_CM } from '../../../modules/local/wget/main'
include { WGET as WGET_CLANIN } from '../../../modules/local/wget/main'

workflow WGET_GUNZIP_INFERNAL {

    take:
    // TODO nf-core: edit input (take) channels
    rfam_cm_path = params.rfam_cm_path
    rfam_clanin_path = params.rfam_clanin_path

    main:

    ch_versions = Channel.empty()

    // TODO nf-core: substitute modules here for the modules of your subworkflow
    WGET_CM (
        rfam_cm_path,
        'Rfam.cm.gz'
    )
    

    emit:
    // TODO nf-core: edit emitted channels
    'Rfam.cm.gz'

    versions = ch_versions                     // channel: [ versions.yml ]
}

