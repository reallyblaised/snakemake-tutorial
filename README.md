# snakemake-tutorial
Snakemake tutorial delivered at the _Workshop on Basic Computing Services in the Physics Department - subMIT_ at MIT in January 2024. 

Disclaimer: no LHCb data has been used to generate this tutorial. 

## Setup

Assuming you have a [conda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html) installation in your user area:

1. [**Optional**, but recommended] Install [mamba]():
   ```bash
   $ conda install -n base -c conda-forge mamba
   ```
   Mamba is a faster package manager than Conda. You can also directly install Mamba via its own [Mambaforge](https://github.com/conda-forge/miniforge#mambaforge) Python3 distribution, which is a direct replacement for Conda. You can use Mamba with virtually all Conda commands, using `mamba` as a drop-in replacement for `conda`;
2. Install a bespoke environment for this tutorial:
   ```bash
   $ mamba create -c conda-forge -c bioconda -n snakemake_tutorial snakemake
   ```
3. Activate the environment:
   ```
   $ mamba activate snakemake_tutorial
   ```
3. Verify the correct Snakemake installation:
   ```bash
   $ snakemake --help
   ```
## Overview

We'll develop a prototypical LHCb analysis workflow, using dummy empty `.root` files, which we'll simply `touch` at each analysis stage for simplicity. Realistically, in your amazing project, you will replace these steps with bash commands and Python executables. 

TLDR; the full pipeline is regulated by the `Snakefile` file, where rules are declared. The execution order is set by string pattern matching the respective per-rule `input` and `output` directives. You can read more about this design on the Snakemake [_Getting Started_](https://snakemake.github.io) page. In the interest of time, let's dive in; certain tools are best learnt by getting your hands dirty.

The power of Snakemake lies in processing several files via independent jobs. These, in turn, are regulated by user-defined _rules_, which can accommodate bash and Python commands for I/O, file processing, logging, benchmarking and alike. 

The tutorial is divided into several sections. First, we'll start with a basic implementation. I'll provide you with commands I typically use to ascertain the correctness of the implementation. We'll cover how to deploy Snakemake pipelines on the SubMIT cluster (on both CPU and GPU machines). Finally, I'll a few snippets that might come in handy in thornier scenarios.

## A prototypical pipeline

Typically, you'll find that the `.root` files you need to process in your anals

## Interfacing the Snakemake pipeline with the SubMIT cluster 

## Useful commands 

### Dry runs, forced runs 

### Visualising the pipeline

### Debugging

### Logging 

### Benchmarking 

### Clean up after yourself 

### Protected and temporary outputs

### Accessing eos 

## Advanced 

### Checkpoints

### Emails 

### Plotting 
