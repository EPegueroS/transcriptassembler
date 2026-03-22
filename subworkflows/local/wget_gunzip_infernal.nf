include { GUNZIP as GUNZIPCM }    from '../../modules/nf-core/gunzip/main'
include { WGET as WGETCM }       from '../../modules/local/wget/main'
include { WGET as WGETCLANIN }   from '../../modules/local/wget/main'
include { CMPRESS }               from '../../modules/local/infernal/cmpress/main'
include { CMSCAN }                from '../../modules/local/infernal/cmscan/main'

workflow WGET_GUNZIP_INFERNAL {

    take:
    ch_fasta

    main:

    ch_versions = Channel.empty()

    WGETCM (
        params.rfam_cm_path,
        'Rfam.cm'
    )
    ch_versions = ch_versions.mix(WGETCM.out.versions)

    GUNZIPCM (
        WGETCM.out.file
    )
    ch_versions = ch_versions.mix(GUNZIPCM.out.versions)

    CMPRESS (
        GUNZIPCM.out.gunzip
    )
    ch_versions = ch_versions.mix(CMPRESS.out.versions)

    CMSCAN (
        ch_fasta,
        params.rfam_clanin_path,
        CMPRESS.out.cmpress.collect()
    )
    ch_versions = ch_versions.mix(CMSCAN.out.versions)

    emit:
    cmscan   = CMSCAN.out.output
    tblout   = CMSCAN.out.tblout
    versions = ch_versions
}
