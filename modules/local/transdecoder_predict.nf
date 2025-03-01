process TRANSDECODER_PREDICT {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::transdecoder=5.7.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/transdecoder:5.7.1--pl5321hdfd78af_0':
        'quay.io/biocontainers/transdecoder:5.7.1--pl5321hdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)
    path(fold)

    output:
    tuple val(meta), path("*.pep")  , emit: pep, optional: true
    tuple val(meta), path("*.transdecoder.gff3") , emit: gff3, optional: true
    tuple val(meta), path("*.transdecoder.cds")  , emit: cds, optional: true
    tuple val(meta), path("*.transdecoder.bed")  , emit: bed, optional: true
    path "versions.yml"                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    TransDecoder.Predict \\
        $args \\
        -O ${prefix} \\
        -t \\
        $fasta
    mv ./synthetic_dataset/synthetic_dataset.fa.transdecoder_dir/longest_orfs.pep .
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        transdecoder_predict: \$(echo \$(TransDecoder.Predict --version) | sed -e "s/TransDecoder.Predict //g")
    END_VERSIONS
    """
}
