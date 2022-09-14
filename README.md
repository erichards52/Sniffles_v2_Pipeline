# Sniffles_v2_Pipeline

## How to use:

This LSF compatible Nextflow DSL2 pipeline runs much like the research/rare disease pipeline/has the same framework. It will create an experiment ID for whichever project/experiment id/flowcell (or run) ID it is aimed at.

This pipeline is ONLY meant to be used to produce a sniffles output for datasets/cohorts which have already been processed by the research/rare disease pipeline, as it will create a(n) SV_sniffles2 directory within any SV_workflow directory that exists within the sub-directory's run/flowcell IDs.

This pipeline can potentially be updated to adapt to newer versions of Sniffles and/or truvari by specifying a container within the Sniffles process (https://www.nextflow.io/docs/latest/singularity.html) or specifying the full path of a conda installation of either of these softwares. The publish directory for each process will also need to be updated (`publishDir "$dir_string/SV_sniffles2/"`).

To run this pipeline, do the following:
`./submit_sniffles_pipe.sh ${path/to/project/experiment/flowcell/run/id} ${SV_truth_set}`

The output and error logs will be located in wherever this pipeline is run and will be named after the experiment ID and run/flowcell ID of each affected run.
