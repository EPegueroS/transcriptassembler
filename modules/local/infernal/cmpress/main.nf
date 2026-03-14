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
    tuple val(meta), path(cm_file), path("*.i1f"), path("*.i1i"), path("*.i1m"), path("*.i1p"), emit: cmpress
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    cmpress ${args} ${cm_file}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        infernal: \$(cmpress -h | grep '^# INFERNAL' | sed 's/^# INFERNAL //; s/ .*//')
    END_VERSIONS
    """

    stub:
    """
    touch ${cm_file}.i1f
    touch ${cm_file}.i1i
    touch ${cm_file}.i1m
    touch ${cm_file}.i1p

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        infernal: \$(cmpress -h | grep '^# INFERNAL' | sed 's/^# INFERNAL //; s/ .*//')
    END_VERSIONS
    """
}
