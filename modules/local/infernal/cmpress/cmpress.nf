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
    path("Rfam.cm*"), emit: rfam
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
    cmpress ${cm_file}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cmpress: \$(echo \$(cmpress -h) | head -n2 | tail -n1 | cut -f3 -d " " ))
    END_VERSIONS
    """
}
