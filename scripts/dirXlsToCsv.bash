#!/usr/bin/env bash

arg1=${1:-''}

if [[ $arg1 == '--help' || $arg1 == '-h' || -z "$arg1" ]]; then
    echo "For use mainly with Elections Ontario data"
    echo "Specify the dir to convert xlsx to csv"
    echo "$0 \$dir"
    exit 0
fi

#exit when command fails (use || true when a command can fail)
set -o errexit

#exit when your script tries to use undeclared variables
set -o nounset

# in scripts to catch mysqldump fails
set -o pipefail

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # Dir of the script
__root="$(cd "$(dirname "${__dir}")" && pwd)"           # Dir of the dir of the script
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"       # Full path of the script
__base="$(basename ${__file})"                          # Name of the script
ts=`date +'%Y%m%d-%H%M%S'`
ds=`date +'%Y%m%d'`
pid=`ps -ef | grep ${__base} | grep -v 'vi ' | head -n1 |  awk ' {print $2;} '`
formerDir=`pwd`

# If you require named arguments, see
# http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash

export DISPLAY=:0

echo Begin `date`  .....

echo; echo; echo;

### BEGIN SCRIPT ###############################################################

#(a.k.a set -x) to trace what gets executed

if ! which ssconvert > /dev/null; then
    echo "This program requires ssconvert.  On debian package systems, do"
    echo "sudo apt-get install gnumeric"
    exit 1
fi

if ! which sponge > /dev/null; then
    echo "This program uses sponge.  On debian systems, do:"
    echo "sudo apt-get install moreutils"
    exit 1
fi

dirToConvert=$arg1

set -x
cd $dirToConvert
pwd


#First, replace spaces with underscores
echo Replacing spaces with underscores in file names
set -x
if $dirToConvert/*\ *.xls; then
    for file in $dirToConvert/*\ *.xls; do mv -v "$file"  `echo $file | tr ' ' '_'` ; done
fi

# Then using ssconvert, convert from XLS to CSV
echo 'Convert using ssconvert'
for file in $dirToConvert/*.xls; do
    #chop the suffix
    baseName=`echo $file  | rev | cut -d '.' -f 2- | rev | tr -d '\n'`

    rm -f $baseName.csv

    set -x
    ssconvert "$file" "$baseName.csv" 2> /dev/null
    set +x
done


#Remove first line of instruction for ontario files
echo -n 'Removing weird line and normalizing data'
for file in $dirToConvert/*.csv; do
    echo -n '.'
    if grep 'The column titles for this worksheet' $file > /dev/null; then
        tail -n +2 $file > $file.2
        mv -f $file.2 $file
        ls -lh $file
    fi


    # Could probably refactor below and above into one function
    string='COMBINED WITH POLL'
    if grep "$string" $file > /dev/null; then
        grep -v "COMBINED WITH POLL" $file > $file.2
        mv $file.2 $file
    fi

    tail -n +2 $file | grep '^[0-9]' > $file.2

    head -n 1 $file | cat - $file.2 > $file.3

    rm $file.2

    mv -f $file.3 $file
done
echo





set +x

cd -

### END SCIPT ##################################################################

cd $formerDir
