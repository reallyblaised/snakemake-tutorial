"""
Prototycal workflow for the analysis on data split into many files located in the paths
scratch/{data, mc}/{2011, 2012, 2016, 2017, 2018}/beauty2darkmatter_{i}.root
"""

__author__ = "Blaise Delaney"
__email__ = "blaise.delaney at cern.ch"

rule all:
    input:
        expand("scratch/{filetype}/{year}/post_processed/beauty2darkmatter_{i}.root", filetype=["data", "mc"], year=["2011", "2012", "2016", "2017", "2018"], i=range(10))

rule truthmatch_simulation:
    """Simulaion-specific preprocessing step before enacting any selection"""
    input:
        lambda wildcards: "scratch/{filetype}/{year}/beauty2darkmatter_{i}.root".format(**wildcards) if wildcards.filetype == "mc" else []
    output:
        "scratch/{filetype}/{year}/truthmatched_mc/beauty2darkmatter_{i}.root"
    shell:
        "touch {output}"

rule preselect:
    input:
        lambda wildcards: "scratch/{filetype}/{year}/truthmatched_mc/beauty2darkmatter_{i}.root".format(**wildcards) if wildcards.filetype == "mc"\
            else "scratch/{filetype}/{year}/truthmatched_mc/beauty2darkmatter_{i}.root".format(**wildcards)
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
