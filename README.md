# snakemake-tutorial
Snakemake tutorial delivered at the _Workshop on Basic Computing Services in the Physics Department - subMIT_ at MIT in January 2024. 

Disclaimer: no LHCb data has been used to generate this tutorial. 

## Setup

Assuming you have a [conda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html) installation in your user area:

1. **Preliminary step**: install [Mamba](https://github.com/mamba-org/mamba), essentially an accelerated version of the [Conda](https://docs.conda.io/en/latest/) package manager. 
The best thing of Mamba is that you can using `mamba` as a drop-in replacement for virtually all `conda` commands.
Installing Mamba can be enacted in two ways: 

   (a) [The way I wrote this set up this tutorial] If you want to operate within a Conda installation, you can proceed to create a new environment, `snakemake_tutorial`, in which you can install Mamba: 
   ```bash
   $ conda create -c conda-forge -n snakemake_tutorial mamba
   $ conda activate snakemake_tutorial
   ```
   Test the correct installation of Mamba by typing in the terminal
   ```bash
   $ mamba
   ```
   after which you should see a familiar `conda` blurb of all possible commands and flags.

   (b) Alternatively, you can also directly install Mamba via its own [Mambaforge](https://github.com/conda-forge/miniforge#mambaforge) Python3 distribution, which is a direct replacement for Conda as a whole. After completing this step, you have access to the full `mamba` command suite. Let's setup a bespoke environment for this tutorial:

   ```bash
   $ mamba create -n snakemake_tutorial 
   $ mamba activate snakemake_tutorial
   ``` 
   In both cases, you should end up with a `snakemake_tutorial` environment containing a Mamba installation. *N.B.*: one should be able to install Snakemake using solely Conda, but last I check Mamba was the preferred option.

2. Install Snakemake in the env:
   ```bash
   $ mamba install -c conda-forge -c bioconda snakemake
   ```

3. Verify the correct Snakemake installation:
   ```bash
   $ snakemake --help
   ```
   
## Overview

The power of Snakemake lies in processing several files via independent jobs. These, in turn, are regulated by user-defined _rules_, which can accommodate bash and Python commands for I/O, file processing, logging, benchmarking and alike. 

We'll develop a prototypical LHCb analysis workflow, using dummy empty `.root` files, which we'll simply `touch` at each analysis stage for simplicity. Realistically, in your amazing project, you will replace these simplistic I/O steps with bash commands and Python executables. 

The key point is that Snakemake orchestrates the job dependency, *irrespectively of the exact command executed in each job*. The full pipeline is specified by the `Snakefile` file, where rules are declared. In this tutorial we enforce a one-to-one correspondence between the stages of this dummy analysis and the rules of the workflow. That is, each rule specifies a stage (selection, postprocessing, fitting, etc.) in the analsysis.

The rule execution order is set by string pattern matching the respective per-rule `input` and `output` directives. You can read more about this design on the Snakemake [_Getting Started_](https://snakemake.github.io) page. In the interest of time, let's dive in; certain tools are best learnt by getting your hands dirty.


[**Fixme**] The tutorial is divided into several sections. First, we'll start with a basic implementation. I'll provide you with commands I typically use to ascertain the correctness of the implementation. We'll cover how to deploy Snakemake pipelines on the SubMIT cluster (on both CPU and GPU machines). Finally, I'll a few snippets that might come in handy in thornier scenarios.

## A prototypical pipeline

Typically, you'll find that the `.root` files you need to process in your analysis are stored in a dedicated area. Let's emulate these conditions:

```bash
$ python src/utils/generate_data_mc_files.py 
```

This command will touch empty files in the path `scratch/{data, mc}/{2012, 2018}/beauty2darkmatter_{i}.root`, with $i$ in the range $[0, 10)$.

**For LHC users**: if your files are store on `eos` and you need employ the `xrootd` protocol, see the section _Accessing eos_ below.

Now we have everything to get started. Let's inspect the `Snakefile`: **text goes here**.

### Running the pipeline

In the same directory where the `Snakefile` lives, execute the command

```bash
$ snakemake --cores <number of cores; if none specified, use all available by default> 
```

### Visualising the pipeline

Upon successful completion of the pipeline, we can inspect the anatomy of the pipeline. That is, the overall DAG - showing the evolution of each input file - and the rule sequence, in order of execution. Notice how we introduced non-linearities in the workflow. Data-monte carlo comparisons, neural network training and evaluation, and similar other steps will force us to define complicated workflows.

```bash
$ snakemake --rulegraph | dot -Tpdf > rulegraph.pdf
```

```bash
$ snakemake --dag | dot -Tpdf > dag.pdf
```

Inspect the `dag.pdf` and `rulegraph.pdf` visualisations. Following the evolution of each file through the rules, can you convince yourself the job flow matches the analysis design? 

## Interfacing the Snakemake pipeline with the SubMIT cluster 

## Useful commands 

### Dry runs, forced runs 

### Debugging

### Logging 

### Benchmarking 

### Clean up after yourself

Notice the snippet at the beginning of the `Snakefile`: 

```python
onsuccess:
    """
    This is a special directive that is executed when the workflow completes successfully
    """
    print("=== Workflow completed successfully. Congrats! Hopefully you got some interesting results. ===")
    # good practice: clean up the workspace metadata
    shutil.rmtree(".snakemake/metadata")
```
Upon completing the pipeline successfully, unwanted metadata files (which might blow up your local area if left unchecked over LHC-sized datasets and jobs) will be automatically deleted. I suggest you extend this practice to any log files you may not want to inspect after running the worflow successfully. _Note_: deletion will occur if and only if the pipeline has run successfully.

### Protected and temporary outputs

One has the option to enforce two special output-file status conditions:

1. **Temporary files**: these are 

### Accessing eos

## Advanced 

### Checkpoints

### Emails 

### Plotting 
