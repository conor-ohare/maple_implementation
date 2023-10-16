#!/bin/sh

# Phylogenetic tree construction using MAPLE

# ------------------------------------------------------------
## INPUTS
# ------------------------------------------------------------

# $1: input_fasta - sequences to be used in the phylogeny
# $2: reference - reference tree
# $3: data_path - path where input_fasta and reference are saved

input_fasta="$1"
reference="$2"
data_path="$3"

input_basename="${1%.fasta}"

# ------------------------------------------------------------
## PACKAGE INSTALLATION
# ------------------------------------------------------------

# REQUIREMENTS: mafft

# Define the name of your Conda environment
conda_env="alignment"

# Check if Conda is available
if command -v conda &> /dev/null; then
    # Check if the Conda environment exists
    if conda env list | grep -q "$conda_env"; then
        # Activate the Conda environment
        source activate "$conda_env"

        # Check if mafft is installed in the environment
        if ! conda list | grep -q "^mafft "; then
            # Install mafft from the Bioconda channel
            conda install -c bioconda mafft
        else
            echo "mafft is already installed."
        fi

        # Deactivate the Conda environment
        conda deactivate
    else
        echo "Conda environment '$conda_env' does not exist."
    fi
else
    echo "Conda is not installed. Please install Conda first."
fi


# ------------------------------------------------------------
## PREPROSSESSING 
# ------------------------------------------------------------

cd $data_path

# Use a temporary file
temp_file=$(mktemp)

# Process the file
while IFS= read -r line; do
  if [[ "$line" == "<"* ]]; then
    # Remove everything after the first space
    modified_line="${line%% *}"
    echo "$modified_line" >> "$temp_file"
  else
    echo "$line" >> "$temp_file"
  fi
done < $input_fasta

# Overwrite the original file with the modified content
mv "$temp_file" $file_path

echo "File has been modified in-place."


# ------------------------------------------------------------
## ALIGN SEQUENCES TO REFERENCE
# ------------------------------------------------------------

# If the sequences are shorter than the reference genome, then
# this will incorporate gaps, ensuring that all sequences in 
# input_fasta are of the same length as the reference, which
# is crucial when comparing base-by-base

# cd $data_path

mafft --6merpair --thread -1 --keeplength --addfragments $input_fasta $reference > "$input_basename.aligned.fasta"

sed '/^>/s/ .*$//' "$input_basename.aligned.fasta" > temporary_file
mv temporary_file "$input_basename.aligned.fasta"


# ------------------------------------------------------------
## CREATE MAPLE INPUT FILE
# ------------------------------------------------------------

python3 ../createMapleFile.py --path ./ --reference $reference --fasta "$input_basename.aligned.fasta"  --output "$input_basename.MAPLE_input.txt" --overwrite


# ------------------------------------------------------------
## CREATE NEWICK TREE USING MAPLE
# ------------------------------------------------------------

python3 ../MAPLEv0.3.4.py  --input "$input_basename.MAPLE_input.txt" --output "./$input_basename.MAPLE_output" --overwrite

cd ../

# Plot the Newick tree and save as PDF
Rscript plotTree.R