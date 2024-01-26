"""
Prototycal workflow for the analysis on data split into many files located in the paths
scratch/{data, mc}/{2011, 2012, 2016, 2017, 2018}/beauty2darkmatter_{i}.root
"""

__author__ = "Blaise Delaney"
__email__ = "blaise.delaney at cern.ch"

# place necessary python imports here 
import shutil

# global-scope config
configfile: "config/main.yml" # NOTE: colon synax 
# global-scope variables, fetched from the config file in config/main.yml
years = config["years"] 


# end of execution: communicate the success or failure of the workflow and clean up the workspace
onsuccess:
    """
    This is a special directive that is executed when the workflow completes successfully
    """
    print("=== Workflow completed successfully. Congrats! Hopefully you got some interesting results. ===")
    # good practice: clean up the workspace metadata
    shutil.rmtree(".snakemake/metadata")
onerror:
    """
    This is a special directive that is executed when the workflow fails
    """
    print("=== ATTENTION! Workflow failed. Please refer to logging and debugging sections of the tutorial. ===")


rule all: # NOTE: the `all` rule is a special directive that is executed by default when the workflow is invoked
    """
    Target of the worflow; this sets up the direct acyclic graph (DAG) of the workflow
    """
    input:
        "results/fit_results.yml"

rule truthmatch_simulation:
    """Simulaion-specific preprocessing step before enacting any selection"""
    input:
        lambda wildcards: ["scratch/{filetype}/{year}/beauty2darkmatter_{i}.root".format(**wildcards)]\
            if wildcards.filetype == "mc" else []
    output:
        "scratch/{filetype}/{year}/truthmatched_mc/beauty2darkmatter_{i}.root"
    shell:
        "python src/process.py --input {input} --output {output}"

rule preselect:
    input:
        lambda wildcards: "scratch/{filetype}/{year}/truthmatched_mc/beauty2darkmatter_{i}.root".format(**wildcards) if wildcards.filetype == "mc"\
            else "scratch/{filetype}/{year}/beauty2darkmatter_{i}.root".format(**wildcards)
    output:
        "scratch/{filetype}/{year}/preselected/beauty2darkmatter_{i}.root"
    shell:
        "python src/process.py --input {input} --output {output}"

rule select:
    input:
        "scratch/{filetype}/{year}/preselected/beauty2darkmatter_{i}.root"
    output:
        "scratch/{filetype}/{year}/full_sel/beauty2darkmatter_{i}.root"
    shell:
        "python src/process.py --input {input} --output {output}"

rule post_process:
    input:
        "scratch/{filetype}/{year}/full_sel/beauty2darkmatter_{i}.root"
    output:
        "scratch/{filetype}/{year}/post_processed/beauty2darkmatter_{i}.root"
    shell:
        "python src/process.py --input {input} --output {output}"

rule merge_files_per_year:
    """
    Merge the per-year samples to accrue the full integrated luminosity collected by our favourite experiment
    NOTE: obviously, aggregation occurs on the data and mc samples separately
    """
    input:
        # decouple the aggregation of data and mc samples
        lambda wildcards: [
            "scratch/{filetype}/{year}/post_processed/beauty2darkmatter_{i}.root".\
            format(filetype=wildcards.filetype, year=wildcards.year, i=i)\
            for i in range(10) 
        ] if wildcards.filetype == "mc"\
        else [
            "scratch/{filetype}/{year}/post_processed/beauty2darkmatter_{i}.root".\
            format(filetype=wildcards.filetype, year=wildcards.year, i=i)\
            for i in range(10) 
        ]
    output:
        "scratch/{filetype}/{year}/subjob_merged/beauty2darkmatter.root"
    run:    
        print("Merging {input} into {output}".format(input=input, output=output))
        shell("python src/process.py --input {input} --output {output}")

rule merge_years:
    # aggregate the per-year samples into a single sample for the full integrated luminosity in data,
    # and the corresponding simulation sample set 
    input:
        lambda wildcards: [
            "scratch/{filetype}/{year}/subjob_merged/beauty2darkmatter.root".\
            format(filetype=wildcards.filetype, year=year)\
            for year in years
        ] if wildcards.filetype == "data" else [
            "scratch/{filetype}/{year}/subjob_merged/beauty2darkmatter.root".\
            format(filetype=wildcards.filetype, year=year)\
            for year in years
        ]
    output:
        "scratch/{filetype}/aggregated_pre_nn/beauty2darkmatter.root"
    run:
        print("Reading in {input} and merging into {output}".format(input=input, output=output))
        shell("python src/process.py --input {input} --output {output}")

rule train_neural_network:
    """
    Train the neural network on the aggregated data and simulation samples
    """
    input:
        # decouple the data and mc. Realistically one would have to provide both classes to a python NN training/inference executable
        data = "scratch/data/aggregated_pre_nn/beauty2darkmatter.root",
        mc = "scratch/mc/aggregated_pre_nn/beauty2darkmatter.root"
    output:
        "nn/tuned_neural_network.yml" # NOTE: dynamically generated output and directory
    run:
        # NOTE how the two inputs are individually provided as arguments to the python script
        print("Training the neural network on {input.data} and {input.mc}".format(input=input, output=output))
        shell("python src/process.py --input {input.data} {input.mc} --output {output}") # in the script, argparse has nargs=+ for the input to accept multiple inputs

rule nn_inference: 
    """
    Run the inference on the aggregated data and simulation samples
    """
    input:
        # fetch the tuned neural network from the previous rule
        nn = "nn/tuned_neural_network.yml",
        # samples on which we want to run the inference
        samples = "scratch/{filetype}/subjob_merged/beauty2darkmatter.root"
    output:
        "scratch/{filetype}/post_nn/beauty2darkmatter.root"
    run:
        print("Running the inference on {input}".format(input=input))
        shell("python src/process.py --input {input.samples} {input.nn} --output {output}")

rule sweight_data:
    # typically, one can expect some data-driven density estimation or data-mc correction task performed per-year
    # assume a sFit stage: https://inspirehep.net/literature/644725
    input:
        # decouple the input into the data and mc classes; 
        # assume an analysis executable would use the sig to fix fit parameters in the sFit to data
        data = lambda wildcards: [
            "scratch/{filetype}/{year}/post_nn/beauty2darkmatter.root".\
            format(filetype="data", year=wildcards.year)\
        ], 
        mc = lambda wildcards: [
            "scratch/{filetype}/{year}/post_nn/beauty2darkmatter.root".\
            format(filetype="mc", year=wildcards.year)\
        ],
    output:
        "scratch/{filetype}/{year}/sweighted/beauty2darkmatter.root",
    run:
        print("Sweighting {input.data} to with input from simulations: {input.mc}".format(input=input, output=output))
        shell("python src/process.py --input {input.data} {input.mc} --output {output}")

rule merge_years_pre_fit:
    # aggregate the per-year samples into a single sample for the full integrated luminosity in data,
    # and the corresponding simulation sample set 
    input:
        data = expand("scratch/{filetype}/{year}/sweighted/beauty2darkmatter.root", filetype="data", year=years),
        mc = expand("scratch/{filetype}/{year}/post_nn/beauty2darkmatter.root", filetype="mc", year=years),
    output:
        data = "scratch/data/full_lumi/beauty2darkmatter.root",
        mc = "scratch/mc/full_lumi/beauty2darkmatter.root"
    run:
        # decouple the aggregation of data and mc samples in python & bash. Not the most elegant solution, but it 
        # showcases the flexibility of the in-scope python operations
        print("Merging separately sweighted data and simulation samples into the appropriate output file")
        
        # data
        print("Start with data: merge {input_data} into {output_data}".format(input_data=input.data, output_data=output.data))
        shell("touch {output.data}") # you can think of this as placeholder for hadd -fk {output.data} {input.data}

        # simulation
        print("Now with simulation: merge {input_mc} into {output_mc}".format(input_mc=input.mc, output_mc=output.mc))
        shell("touch {output.mc}")

rule fit:
    """
    Run the fit on the aggregated data and simulation samples
    """
    input:
        data = "scratch/data/full_lumi/beauty2darkmatter.root",
        mc = "scratch/mc/full_lumi/beauty2darkmatter.root"
    output:
        "results/fit_results.yml" # NOTE: dynamically generated output and directory
    run:
        print("Running the fit on {input.data} and {input.mc}".format(input=input, output=output))
        
        # placecholder for, say, `python src/fit.py --input {input.data} {input.mc}`, where
        # the output file gets generated automatically and picked up by snakemake (it'll ley you know it doesn't find it!) 
        shell("python src/process.py --input {input} --output {output}") 