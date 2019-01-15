#!/usr/bin/bash
#---|
# id			tools.download/krakenDB-genus.sh
# creation		2019.01.14
# author 		Sean Aller | seandavid.a@gmail.com
# description 	Script for downloading and creating a custom database for a genus in Kraken 2
#---|
# Bash Settings
#set -o errexit   								# Abort on nonzero exitstatus
#set -o nounset   								# Abort on unbound variable
set -o pipefail  								# Don't hide errors within pipes
#---| START
# Setup Default Variables
DATE=`date +%y%m%d`
CORES=1
KEEP=0
OUTDIR=""
LEVEL="genome"
#---| Command Input Arguments
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -g|--genus) 								# Define the genus to download
    GENUS="$2"
    shift 										# > Past argument
    shift 										# > Past value
    ;;
    -j|--cores) 								# Define number of CPUs [default = 1]
    CORES="$2"
    shift 										# Past argument
    shift 										# Past value
    ;;
    -o|--outdir)								# Define the output directory [default = '.']
    OUTDIR="$2"
    shift 										# Past argument
    shift 										# Past value
    ;;
    -l|--level)                                 # Define the desired assembly_level to include [default = "genome"]
    LEVEL="$2"
    shift                                       # Past argument
    shift                                       # Past value
    ;;
    -k|--keep)									# Define the level of temporary file preservation [default = 0]
    OUTDIR="$2"
    shift 										# Past argument
    shift 										# Past value
    ;;
    -h|--help) 									# Help option
    HELP=1
    shift 										# Past argument
    shift 										# Past value
    ;;
    --default)
    DEFAULT=YES
    shift 										# Past argument
    ;;
    *)    										# Unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters
#---| Help Section
if [ "${HELP}" == 1 ] ; then
	printf "Usage: kraken2-genus-download [options] <genus>\n\n"
	printf "Options: \n\n"
	printf "\t-g | --genus\t\tGenus to download (case-sensitive) [required]\n"
	printf "\t-j | --cores\t\tNumber of cores to use [default: 1]\n"
	printf "\t-o | --outdir\t\tOutput directory for final database [default: '.']\n"
    printf "\t-l | --level\t\tDefine the desired assembly_level to include [default = 'genome']\n\t\t\t\t> genome = Complete genomes only\n\t\t\t\t> all = Complete genomes, chromosome, contigs and scaffolds\n"
	printf "\t-k | --keep\t\tLevel of temporary file preservation [default: 0]\n\t\t\t\t> 0 = Delete temporary files \n\t\t\t\t> 1 = Keep all temporary files\n"
	printf "\t-h | --help\t\tThis help message\n\n\n"
	exit 0
fi
#---| Download and Parsing of NCBI RefSeq Files
#-> Create temporary directory
mkdir tmp
#-> Download list of refseq genomes
curl -O ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/bacteria/assembly_summary.txt; mv assembly_summary.txt tmp/
#-> Extract the matching genus and generate FTP file paths
if [ ${LEVEL} == "genome" ]; then
    awk -F "\t" -v pat="$GENUS" '$12=="Complete Genome" && $8~pat {print $20}' tmp/assembly_summary.txt > tmp/ftpdirpaths
    PATHEND="completeonly"
    printf "\t> Generating kraken database for Complete Genomes only\n"
elif [ ${LEVEL} == "all" ]; then
    awk -F "\t" -v pat="$GENUS" '$8~pat {print $20}' tmp/assembly_summary.txt > tmp/ftpdirpaths
    PATHEND="all"
    printf "\t> Generating kraken database for all assembly levels\n"
else
    printf "ERROR: Unknown parameter for --level\n"
    exit 1
fi
awk 'BEGIN{FS=OFS="/";filesuffix="genomic.fna.gz"}{ftpdir=$0;asm=$10;file=asm"_"filesuffix;print ftpdir,file}'	tmp/ftpdirpaths > tmp/ftpfilepaths
#-> Convert FTP to rsync paths
sed -e 's/ftp\:\/\//rsync\:\/\//g' tmp/ftpfilepaths > tmp/rsync.links.list
#---| GNU Parallel + rsync for downloads of fna files [complete assemblies only]
SAMPLENUM=$(wc -l < tmp/rsync.links.list)
echo "Downloading ${SAMPLENUM} ${GENUS} genomes"
cat tmp/rsync.links.list | \
	parallel --eta --noswap --load 90% -j ${CORES} --max-args 1 'STRIP=$(basename {}); rsync -aqL {} tmp/fna/ ; echo "> $STRIP completed..."'
#---| Decompress Files
find tmp/fna/ -name '*.gz' -print0 | parallel --noswap --load 90% -j ${CORES} -q0 gunzip
#---| Create custome Kraken database
find tmp/fna/ -name '*.fna' -print0 | \
    xargs -0 -I{} -n1 kraken2-build --add-to-library {} --db ${GENUS}
#---| Build Kraken 2 Database
kraken2-build --download-taxonomy --threads ${CORES} --db ${GENUS}
kraken2-build --build --threads ${CORES} --minimizer-spaces 0 --db ${GENUS}
#-> Move database if output directory is supplied
if [ -n "${OUTDIR} " ] ; 
    then 
        mv ${GENUS} ${OUTDIR}/${GENUS}_${PATHEND}_${DATE}
    else
        mv ${GENUS} ${GENUS}_${PATHEND}_${DATE}
    fi
#---| Cleanup of temporary files
if [ ${KEEP} == 0 ]; then
    rm -rf tmp
fi
#---| END
