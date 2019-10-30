#!/bin/bash

#set -o xtrace

# Print this messge if the script fails for some reason
trap 'exit 1' ERR

# Function that shows help message
usage () {
	echo "Usage: $0 -p 10 -v variants.vcf"
	echo "-p, Percent of each chromosome that you want to keep"
	echo "-v, VCF file that you want to shrink"
	echo "-h, This help message"
	exit 1
}

while getopts 'v:p:h' flag; do
	case "${flag}" in
	v)
		vcf=${OPTARG}
		;;
	p)
		percentage=${OPTARG}
		;;
	h)
		usage
		;;
	esac
done

if [[ -z $percentage ]]; then
	echo "Must use use -p flag"
	usage
fi

if [[ -z $vcf ]]; then
	echo "Must use use -v flag"
	usage
fi

output=$(basename $vcf .vcf)-$percentage-percent.vcf

if [[ -f $output ]]; then
	echo "Removing already existing $output"
	rm $output
fi

grep "#" $vcf > $vcf-header

## Run loop that creates smaller vcf file
## Explanation for how each iteration object is created
# Begin by grepping the input vcf for all lines that start with "chr"
# Run awk to select the first column because it contains all chromosome names
# Run uniq to get a list of unique chromosome names

## Explanation for the "$chrlen" variable
# grep for exact matches, only return the match and count the matches

## Explanation for how the "$output" file is created
# "$chrlen" is multiplied by "$percentage/100"
# Adding 1 to every shrunk chromosome length is necessary if you happen to have a full chromosome that is so short that the length becomes less than 1 when it is shrunk
# head will select the $newlen first variants from each chromosome
# The chromosome lines are produced with "grep -w ^$chr $vcf" which is redirected as input to grep
for chr in $(grep ^chr $vcf | awk '{ print $1 }' | uniq); do
	echo "Shrinking $chr"
	chrlen=$(grep -woc ^$chr $vcf)
	echo "Full length is $chrlen lines"
	newlen=$(( 1 + ($chrlen*$percentage/100) ))
	head -n $newlen <(grep -w ^$chr $vcf) >> $output
	echo "$chr now has $newlen lines"
done

cat $output >> $vcf-header
mv $vcf-header $output

# All done!
echo "All done!"
