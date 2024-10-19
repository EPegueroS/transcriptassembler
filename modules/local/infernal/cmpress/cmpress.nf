process CMPRESS {
    tag "$meta.id"
    label "process_medium"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/infernal:1.1.5--pl5321h031d066_2':
        'biocontainers/infernal:1.1.5--pl5321h031d066_2' }"

    input:
    tuple val(meta), path(cm_file)

    output:
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    tuple val(meta), path(cm_file),path("*.i1f"),path("*.i1i"),path("*.i1m"),path("*.i1p"), emit: cmpress
    // TODO nf-core: List additional required output channels/values here
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
    """
    cmpress ${cm_file}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cmpress: \$(echo \$(cmspress -h) | head -n2 | tail -n1 | cut -f3 -d " " ))
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
   
    """
    touch ${cm_file}
    touch ${cm_file}.i1f
    touch ${cm_file}.i1i
    touch ${cm_file}.i1m
    touch ${cm_file}.i1p

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cmpress: \$(echo \$(cmpress -h) | head -n2 | tail -n1 | cut -f3 -d " " ))
    END_VERSIONS
    """
}
