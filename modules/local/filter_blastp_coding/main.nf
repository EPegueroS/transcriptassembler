process FILTER_BLASTP_CODING {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.9.0--h9ee0642_0' :
        'biocontainers/seqkit:2.9.0--h9ee0642_0' }"

    input:
    tuple val(meta), path(blastp_tsv), path(bed)

    output:
    tuple val(meta), path("*_coding_blastp.tsv"), emit: tsv
    path "versions.yml"                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Extract ORF IDs from BED col4 (format: ID=<orf_id>;...), skipping the track header
    tail -n +2 ${bed} | cut -f4 | sed 's/ID=\\([^;]*\\).*/\\1/' | sort -u > coding_orf_ids.txt

    # Retain only BLASTP rows whose query ID (col 1) is a predicted coding ORF
    awk 'NR==FNR { ids[\$1]=1; next } \$1 in ids' coding_orf_ids.txt ${blastp_tsv} \\
        > ${prefix}_coding_blastp.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$(seqkit version | sed 's/seqkit v//')
    END_VERSIONS
    """
}
