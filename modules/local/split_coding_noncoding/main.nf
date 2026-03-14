process SPLIT_CODING_NONCODING {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.9.0--h9ee0642_0' :
        'biocontainers/seqkit:2.9.0--h9ee0642_0' }"

    input:
    tuple val(meta), path(fasta), path(bed)

    output:
    tuple val(meta), path("*_coding.fa")    , emit: coding
    tuple val(meta), path("*_noncoding.fa") , emit: noncoding
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    tail -n +2 ${bed} | cut -f1 | sort -u > coding_ids.txt

    seqkit grep ${args} -f coding_ids.txt ${fasta} -o ${prefix}_coding.fa

    seqkit grep ${args} -v -f coding_ids.txt ${fasta} -o ${prefix}_noncoding.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$(seqkit version | sed 's/seqkit v//')
    END_VERSIONS
    """
}
