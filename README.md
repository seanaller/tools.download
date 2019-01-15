# tools.download
Collection of scripts for downloading, and processing, from various bioinformatic databases.
___

## bioproject_download.sh
Download all sample files for an associated BioProject 


USAGE:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`bioproject_download.sh BIOPROJECT_ID`  
  

Will parse the BioProject for the Sample URLs  
Output all sample files to 'samples' folder within the directory the script has been run in  

---

## kraken2-genus-download.sh
Download and create genus specific databases for use in Kraken2


USAGE:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`kraken2-genus-download.sh [options] <genus>`

| Option          | Description                                                                                                          |
| :-------------- | -------------------------------------------------------------------------------------------------------------------- |
| -g \| --genus   | Genus to download (case-sensitive) (required)                                                                        |
| -j \| --cores   | Number of cores to use (default: 1)                                                                                  |
| -o \| --outdir  | Output directory for final database (default: '.')                                                                   |
| -k \| --keep    | Level of temporary file preservation (default: 0)</br>- 0 = Delete temporary files</br>- 1 = Keep all temporary files|
| -h \| --help    | This help message                                                                                                    |

Will obtain all genomic FNA for the given Genus (complete assemblies from refseq only) and download, process and create kraken2 compatible database
