cohort=$1
svSet=$2
for file in $(find ${cohort} -name aligned_minimap) 
do 
    for bam in $(ls ${file}/*.bam) 
    do 
        echo ${bam}
        minimapdir="$(dirname ${bam})"
        workflowdir="$(dirname ${minimapdir})"
        flowcelldir="$(dirname ${workflowdir})"
        sampdir="$(dirname ${flowcelldir})"
        basesamp="$(basename ${sampdir})"
        baseflowcell="$(basename ${flowcelldir})"

        mkdir -p ${basesamp}
        mkdir ${basesamp}/${baseflowcell}

        cp snifflesPipe-wrapper.sh run_Sniffles2.nf nextflow.config ${basesamp}/${baseflowcell}

        cd ${basesamp}/${baseflowcell}

        bsub -o ./sniffles_output_${basesamp}_${baseflowcell}_%J.out -e ./sniffles_output_${basesamp}_${baseflowcell}_%J.err -J snifflesPipeGE_${baseflowcell} -q pipeline -P bio -n 2 -R "span[hosts=1]" -R "select[mem>7000] rusage[mem=7000]" -M 7000 sh snifflesPipe-wrapper.sh ${bam} ${workflowdir} ${flowcelldir} ${baseflowcell} ${svSet}
        cd ../..
    done
done
