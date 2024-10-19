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
    tuple val(meta2), path(cm_file),path(i1f),path(i1i),path(i1m),path(i1p)

    output:
    tuple val(meta), path("mrum*"), emit: cmscan
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    cmscan --rfam --cut_ga --nohmmonly --tblout mrum-genome.tblout --fmt 2 --clanin ${clanin_file} ${cm_file} ${fasta_file} > mrum-genome.cmscan

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cmpress: \$(echo \$(cmspress -h) | head -n2 | tail -n1 | cut -f3 -d " " ))
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch mrum-genome.cmscan
    touch mrum-genome.tblout

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cmpress: \$(echo \$(cmspress -h) | head -n2 | tail -n1 | cut -f3 -d " " ))
    END_VERSIONS
    """
}
