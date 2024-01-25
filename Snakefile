"""
Prototycal workflow for the analysis on data split into many files located in the paths
scratch/{data, mc}/{2011, 2012, 2016, 2017, 2018}/beauty2darkmatter_{i}.root
"""

__author__ = "Blaise Delaney"
__email__ = "blaise.delaney at cern.ch"

# global-scope config
configfile: "config/main.yml" # NOTE: colon synax 

# place necessary python imports here 

# global-scope variables, fetched from the config file in config/main.yml
years = config["years"] 

rule all:
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
        "touch {output}"

rule preselect:
    input:
        lambda wildcards: "scratch/{filetype}/{year}/truthmatched_mc/beauty2darkmatter_{i}.root".format(**wildcards) if wildcards.filetype == "mc"\
            else "scratch/{filetype}/{year}/beauty2darkmatter_{i}.root".format(**wildcards)
    output:
        "scratch/{filetype}/{year}/preselected/beauty2darkmatter_{i}.root"
    shell:
        "touch {output}"

rule select:
    input:
        "scratch/{filetype}/{year}/preselected/beauty2darkmatter_{i}.root"
    output:
        "scratch/{filetype}/{year}/full_sel/beauty2darkmatter_{i}.root"
    shell:
        "touch {output}"

rule post_process:
    input:
        "scratch/{filetype}/{year}/full_sel/beauty2darkmatter_{i}.root"
    output:
        "scratch/{filetype}/{year}/post_processed/beauty2darkmatter_{i}.root"
    shell:
        "touch {output}"

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
        shell("touch {output}")



rule merge_years:
    # aggregate the per-year samples into a single sample for the full integrated luminosity in data,
    # and the corresponding simulation sample set 
    input:
        lambda wildcards: [
            "scratch/{filetype}/{year}/sweighted/beauty2darkmatter.root".\
            format(filetype=wildcards.filetype, year=year)\
            for year in years
        ] if wildcards.filetype == "data" else [
            "scratch/{filetype}/{year}/subjob_merged/beauty2darkmatter.root".\
            format(filetype=wildcards.filetype, year=year)\
            for year in years
        ]
    output:
        "scratch/{filetype}/full_lumi/beauty2darkmatter.root"
    run:
        print("Reading in {input} and merging into {output}".format(input=input, output=output))
        shell("touch {output}")

rule train_neural_network:
    """
    Train the neural network on the aggregated data and simulation samples
    """
    input:
        data = "scratch/data/full_lumi/beauty2darkmatter.root",
        mc = "scratch/mc/full_lumi/beauty2darkmatter.root"
    output:
        "nn/tuned_neural_network.yml" # NOTE: dynamically generated output and directory
    run:
        print("Training the neural network on {input.data} and {input.mc}".format(input=input, output=output))
        shell("touch {output}")

rule nn_inference: 
    """
    Run the inference on the aggregated data and simulation samples
    """
            lambda wildcards: [
            "scratch/{filetype}/{year}/sweighted/beauty2darkmatter.root".\
            format(filetype=wildcards.filetype, year=year)\
            for year in years
        ] if wildcards.filetype == "data" else [
            "scratch/{filetype}/{year}/subjob_merged/beauty2darkmatter.root".\
            format(filetype=wildcards.filetype, year=year)\
            for year in years
        ]

rule sweight_data:
    # typically, one can expect some data-driven density estimation or data-mc correction task performed per-year
    input:
        mc = expand(
            "scratch/{filetype}/{year}/subjob_merged/beauty2darkmatter.root",
            filetype="mc", year=years
        ),
        data = expand(
            "scratch/{filetype}/{year}/subjob_merged/beauty2darkmatter.root",
            filetype="data", year=years
        )
    output:
        "scratch/{filetype}/{year}/sweighted/beauty2darkmatter.root"
    run:
        print("Sweighting {input.data} to with input from simulations: {input.mc}".format(input=input, output=output))
        shell("touch {output}")

rule fit:
    """
    Run the fit on the aggregated data and simulation samples
    """
    input:
        data = "scratch/data/full_lumi/beauty2darkmatter.root",
        mc = "scratch/mc/full_lumi/beauty2darkmatter.root"
    output:
        "results/fit_results.yml"
    run:
        print("Running the fit on {input.data} and {input.mc}".format(input=input, output=output))
        shell("touch {output}")