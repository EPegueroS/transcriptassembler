process TRANSDECODER_PREDICT {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/transdecoder:5.7.1--pl5321hdfd78af_0' :
    'biocontainers/transdecoder:5.7.1--pl5321hdfd78af_0' }"

    input:
    tuple val(meta), path(fasta), path("longorf_dir"), path(blastp_hits)

    output:
    tuple val(meta), path(fasta)                   , emit: fasta
    tuple val(meta), path("${meta.id}/*.pep")      , emit: pep
    tuple val(meta), path("${meta.id}/*.gff3")     , emit: gff
    tuple val(meta), path("${meta.id}/*.cds")      , emit: cds
    tuple val(meta), path("${meta.id}/*.bed")      , emit: bed
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def retain_blastp = blastp_hits ? "--retain_blastp_hits ${blastp_hits}" : ''

    """
    cp -rL longorf_dir ${prefix}

    TransDecoder.Predict \\
        $args \\
        -O $prefix \\
        -t $fasta \\
        $retain_blastp

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        transdecoder: \$(echo \$(TransDecoder.LongOrfs --version) | sed -e "s/TransDecoder.LongOrfs //g")
    END_VERSIONS
    """
}
