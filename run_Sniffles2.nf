/*
 * Enable DSL 2 syntax
 */
nextflow.enable.dsl = 2

params.bamfile = ''

bam_file = "$params.bamfile"
params.dirstring = ''
params.runstring = ''
params.svSet = ''
run_string = "$params.runstring"
dir_string = "$params.dirstring"

//Run Sniffles to detect structural variants within the alignment
process SNIFFLES {
	publishDir "$dir_string/SV_sniffles2/", mode: 'copy', overwrite: 'false'
        errorStrategy 'retry'
        cache 'deep'
        maxRetries 3
	maxForks 10
        memory { 6.GB * task.attempt }
	clusterOptions = '-P bio -n 8 -R "span[hosts=1]"'

	input:
	val bam_file

	output:
	path "${run_string}_mapped_sniffles_robust.vcf", emit: vcf_file

	script:
	"""
	/home/erichards/.conda/envs/sniff2Env/bin/sniffles -t 16 -i ${bam_file} -v ${run_string}_mapped_sniffles_robust.vcf
	"""
}

//Run bcftools and bgzip to sort and compress the resulting VCF from Sniffles
process BCFTOOLS_BGZIP {
        publishDir "$dir_string/SV_sniffles2/", mode: 'copy', overwrite: 'false'
        errorStrategy 'retry'
        maxRetries 3
        maxForks 10
        memory { 100.MB * task.attempt }
        clusterOptions = '-P bio -n 2'

        input:
	path vcf_file

        output:
        path "**", emit: vcf_file_sorted

        script:
        """
	/resources/tools/apps/software/bio/BCFtools/1.9-foss-2019b/bin/bcftools sort -T . -o ${run_string}_mapped_sniffles_robust_sorted.vcf ${vcf_file}
        sed -i 's/^##INFO=<ID=REF_strand,Number=2,/##INFO=<ID=REF_strand,Number=.,/' ${run_string}_mapped_sniffles_robust_sorted.vcf
        /hpc/tools/apps/software/bio/HTSlib/1.9-GCC-6.4.0-2.28/bin/bgzip ${run_string}_mapped_sniffles_robust_sorted.vcf
        """
}

//Index the compressed VCF with tabix
process TABIX {
        publishDir "$dir_string/SV_sniffles2/", mode: 'copy', overwrite: 'false'
        errorStrategy 'retry'
        maxRetries 3
        memory { 100.MB * task.attempt }
        clusterOptions = '-P bio -n 2'

        input:
	path vcf_file_sorted

        output:
        path "**", emit: vcf_file_sorted_index

        script:
        """
	/hpc/tools/apps/software/bio/HTSlib/1.9-GCC-6.4.0-2.28/bin/tabix ${vcf_file_sorted}
        """
}

//Run truvari to benchmark the resulting VCF against a truth set of SVs
process TRUVARI {
        publishDir "$dir_string/SV_sniffles2", mode: 'copy', overwrite: 'false'
        cache 'deep'
        errorStrategy 'retry'
        maxRetries 3
	maxForks 10
        memory { 1.GB * task.attempt }
        clusterOptions = '-P bio -n 2'
        conda '/home/erichards/.conda/envs/ontVarPipeEnvTruHla'

        input:
	path vcf_file_sorted_index
        path vcf_file_sorted

        output:
        path "**"

        script:
        """
	/home/erichards/.local/bin/truvari --pctsize 0 --pctsim 0 -t -c ${run_string}_mapped_sniffles_robust_sorted.vcf.gz -b $params.svSet -o SV_truvari
        """
}

//Use Adam's perl script to pull out desired stats from pipeline files/results
process VCF_STATS_SCRIPT {
        errorStrategy 'retry'
        maxRetries 3
        memory { 300.MB * task.attempt }
        clusterOptions = '-P bio -n 2'
        conda '/home/erichards/.conda/envs/bio-perl'

        input:
	path vcf_file

        output:
        stdout emit: vcf_stats

        script:
        """
	/home/erichards/.conda/envs/bio-perl/bin/perl /genomes/analysis/research_and_dev/ed_working/ontPipeline/stagingDir/v2.2/scripts/vcf_script.pl ${vcf_file}
        """
}

//Forward the results printed by VCF_STATS_SCRIPT into a text file that will be produced in the final results directory
process VCF_STATS_FW {
        publishDir "$dir_string/perlStatsFiles_sniffles2/", mode: 'copy', overwrite: 'false'
        errorStrategy 'retry'
        maxRetries 3
        memory { 300.MB * task.attempt }
        clusterOptions = '-P bio'

        input:
	stdin vcf_stats

        output:
        path "${run_string}_mapped_sniffles2_robust.vcf.stats"

        script:
        """
	tee ${run_string}_mapped_sniffles2_robust.vcf.stats
        """
}


workflow {
    SNIFFLES(bam_file)
    BCFTOOLS_BGZIP(SNIFFLES.out)
    TABIX(BCFTOOLS_BGZIP.out)
    TRUVARI(BCFTOOLS_BGZIP.out, TABIX.out)
    VCF_STATS_SCRIPT(SNIFFLES.out)
    VCF_STATS_FW(VCF_STATS_SCRIPT.out)
}
