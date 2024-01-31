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

## A basic pipeline

Typically, you'll find that the `.root` files you need to process in your analysis are stored in a dedicated area. Let's emulate these conditions:

```bash
$ python src/utils/generate_data_mc_files.py 
```

This command will touch empty files in the path `scratch/{data, mc}/{2012, 2018}/beauty2darkmatter_{i}.root`, with $i$ in the range $[0, 3)$.

This will generate the file tree (containing empty ROOT files):

```
scratch
   ├── data
   │   ├── 2012
   │   │   ├── beauty2darkmatter_0.root
   │   │   ├── beauty2darkmatter_1.root
   │   │   └── beauty2darkmatter_2.root
   │   └── 2018
   │       ├── beauty2darkmatter_0.root
   │       ├── beauty2darkmatter_1.root
   │       └── beauty2darkmatter_2.root
   └── mc
       ├── 2012
       │   ├── beauty2darkmatter_0.root
       │   ├── beauty2darkmatter_1.root
       │   └── beauty2darkmatter_2.root
       └── 2018
           ├── beauty2darkmatter_0.root
           ├── beauty2darkmatter_1.root
           └── beauty2darkmatter_2.root
```
This setup emulates the typical split between data and Monte Carlo simulations typically used in an LHC(b) analysis. ROOT is the _de facto_ default format to store HEP events. We consider two years of data taking, `2012` and `2018`, as representative of the Run 1 and Run 2 data taking campaigns of the LHC.

**For LHC users**: if your files are store on `eos` and you need employ the `xrootd` protocol, see the section _Accessing eos_ below.

Now we have everything to get started. Let's start at the beginnig: in our `Snakefile`, we start by importing global-scope parameters:

```python

# ./Snakefile

# global-scope config
configfile: "config/main.yml" # NOTE: colon synax 
# global-scope variables, fetched from the config file in config/main.yml
years = config["years"] 
```

This imports the global parameters that condition the overall pipeline, as read in by `config/main.yml`. The path to the yaml config file is arbitrary; `configfile` is unmutable Snakemake syntax. By taking a look at `config/main.yml`,
you'll see that I have just specified a list of nominal years of data taking I wish to run on. I generally prefer specifying such global parameters in a dedicated config YAML file to keep things tidy and flexible (you may want to decouple data and MC runs, as well as the years you decide to run on). 

Ultimately, all we do is read in the `years: ["2012", "2018"]` entry into the Python list 

```python
years = ["2012", "2018"] 
```
during the execution of the pipeline. In fact, all typical python commands can be executed in-scope within the `Snakefile`. 

Pro tip: `breakpoint()` can be inserted whenever you need a quick-and-dirty check during the pipeline execution. 

Let's inspect the rest of the Snakefile: 

```python
"""
Prototycal workflow for the analysis on data split into many files located in the paths
scratch/{data, mc}/{2012, 2018}/beauty2darkmatter_{i}.root
"""

# global-scope config
configfile: "config/main.yml" # NOTE: colon synax 
# global-scope variables, fetched from the config file in config/main.yml
years = config["years"] 


rule all: # NOTE: the `all` rule is a special directive that is executed by default when the workflow is invoked
    """
    Target of the worflow; this sets up the direct acyclic graph (DAG) of the workflow
    """
    input:
        expand("scratch/{filetype}/{year}/post_processed/beauty2darkmatter_{i}.root", filetype=["data", "mc"], year=years, i=range(3))

rule select:
    input:
        "scratch/{filetype}/{year}/beauty2darkmatter_{i}.root"
    output:
        "scratch/{filetype}/{year}/selected/beauty2darkmatter_{i}.root"
    shell:
        "python src/process.py --input {input} --output {output}"

rule post_process:
    input:
        "scratch/{filetype}/{year}/selected/beauty2darkmatter_{i}.root"
    output:
        "scratch/{filetype}/{year}/post_processed/beauty2darkmatter_{i}.root"
    shell:
        "python src/process.py --input {input} --output {output}"
```

Rule `all` specifies the _target_ of the entire workflow. In this sense, Snakeamke is a _top-down_ pipelining tool: the workflow starts from the input specified in `rule all` and works its way down to the individual rules required to generate the files specifified in the `input` field in the scope of `rule all`. 

The rule dependency resolution in Snakemake is done string pattern matching the output paths of each rule with the input file paths of another, thereby constructing a directed acyclic graph (DAG) of tasks. This DAG is then traversed from the final outputs back to the initial inputs, following a top-down approach.


Let's take a closer look. In
```python
rule all:
    input:
        expand("scratch/{filetype}/{year}/post_processed/beauty2darkmatter_{i}.root", filetype=["data", "mc"], year=years, i=range(3))
```
we avail ourselves of the `expand` special function in Snakemake to generate the combinatorics defined by the `input` filed. The wildcard `{filetype}` is allowed to take on the values `data` and `mc`. By the same token, `{year}` takes on the values specified by reading in `config/main.yml`. The index `{i}` is allowed to take the values `[0, 1, 2]`, as per design. Combined, we instruct Snakemake to infer the DAG necessary to generate the target paths:

```python
[
   'scratch/data/2012/post_processed/beauty2darkmatter_0.root',
   'scratch/data/2012/post_processed/beauty2darkmatter_1.root',
   'scratch/data/2012/post_processed/beauty2darkmatter_2.root',
   'scratch/data/2018/post_processed/beauty2darkmatter_0.root',
   'scratch/data/2018/post_processed/beauty2darkmatter_1.root',
   'scratch/data/2018/post_processed/beauty2darkmatter_2.root',
   'scratch/mc/2012/post_processed/beauty2darkmatter_0.root',
   'scratch/mc/2012/post_processed/beauty2darkmatter_1.root',
   'scratch/mc/2012/post_processed/beauty2darkmatter_2.root',
   'scratch/mc/2018/post_processed/beauty2darkmatter_0.root',
   'scratch/mc/2018/post_processed/beauty2darkmatter_1.root',
   'scratch/mc/2018/post_processed/beauty2darkmatter_2.root'
] # a simple python list
```

The rest of the rules define the necessary rules necessary to generate the file paths above. Notice how we added a directory mid-path to specify the *stage* of the analysis, whilst effectively keeping the overall number and kind of dummy files generated at the beginning of this tutorial. We preserve the name of the individual files with each I/O operation, in each stage. The parent path is sufficient to map each file to the rule that generates it. 

Each ancestor rule to `all` has (at the very least - more on this later) the `input`, `output` and `shell` fields. These should be self explanatory. The name of the game is matching the wildcards in each path to enfore the desired dependency. 

In `shell` we spell out a string specifying the bash command each job must execute: 

```bash
"python src/process.py --input {input} --output {output}" # notice the quotes! 
```

where `{input}` and `{output}` are take on the values setup in the corresponding fields of each rule. The `src/process.py` file is a wrapper for the `touch` bash command. Typically, in my research I find myself writing a Python executable to perform a specific task in the analysis, and specify what the relevant input and output files via the `argparse` command-line interface available in Python:

```python
# from src/process.py
if __name__ == "__main__":
    # Parse the command-line arguments
    parser = ArgumentParser(description="Process the input data.")
    parser.add_argument(
        "-i",
        "--input",
        type=str,
        help="The input file to process.",
        required=True,
        nargs="+",
    )
    parser.add_argument(
        "-o", "--output", type=str, help="The output file to write.", required=True
    )
    args = parser.parse_args()
```
This is a nice way to interface Python executables with the wildcard syntax native to Snakemake.

### Running the pipelnie

Let's run. Type the command below, **in the same directory of `Snakefile`. 

```
$ snakemake --cores <number of cores; if none specified, use all available by default> 
```

The main command is `snakeamke`. The flag `--cores` is required, and asks you to specify the number of cores you want to allocate to the jobs. I am not 100% sure of what happens under the hood. I know, however, that the flags `--cores` and `--cores all` are equivalent, and allow you to make use of all the available cores in your machine. You can refer to the [Snakemake docs](https://snakemake.readthedocs.io/en/stable/executing/cli.html#) for more details on resource allocation for more info.

All going well, you should see a lot of green from the jobs completing.

### Visualising the pipeline

Upon successful completion of the pipeline, we can inspect the anatomy of the pipeline. That is, the overall DAG - showing the evolution of each input file - and the rule sequence, in order of execution. Notice how we introduced non-linearities in the workflow. Data-monte carlo comparisons, neural network training and evaluation, and similar other steps will force us to define complicated workflows.

```bash
$ snakemake --rulegraph | dot -Tpdf > rulegraph.pdf
```
should generate this plot:



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
