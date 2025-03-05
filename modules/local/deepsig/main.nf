process DEEPSIG {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deepsig:1.2.5--pyhca03a8a_1':
        'biocontainers/deepsig:1.2.5--pyhca03a8a_1' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.out"), emit: signalpreds
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    deepsig -f ${fasta} -o ${prefix}.out -k euk

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deepsig: \$(deepsig --version)
    END_VERSIONS
    """
}
