process CMSCAN {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/infernal:1.1.5--pl5321h031d066_2':
        'biocontainers/infernal:1.1.5--pl5321h031d066_2' }"

    input:
    tuple val(meta), path(fasta_file)
    path(clanin_file)
    tuple val(meta2), path(cm_file), path(i1f), path(i1i), path(i1m), path(i1p)

    output:
    tuple val(meta), path("${prefix}.cmscan")  , emit: output
    tuple val(meta), path("${prefix}.tblout")   , emit: tblout
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '--rfam --cut_ga --nohmmonly --fmt 2'
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    cmscan \\
        ${args} \\
        --tblout ${prefix}.tblout \\
        --clanin ${clanin_file} \\
        ${cm_file} \\
        ${fasta_file} \\
        > ${prefix}.cmscan

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        infernal: \$(cmscan -h | grep '^# INFERNAL' | sed 's/^# INFERNAL //; s/ .*//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.cmscan
    touch ${prefix}.tblout

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        infernal: \$(cmscan -h | grep '^# INFERNAL' | sed 's/^# INFERNAL //; s/ .*//')
    END_VERSIONS
    """
}
