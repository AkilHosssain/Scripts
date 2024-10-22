#!/bin/bash

# Input file containing the list of target sites
TARGET_FILE=$1

# Output directory
OUTPUT_DIR="/home/kali/bug"

# Check if input file is provided
if [ -z "$TARGET_FILE" ]; then
    echo "Usage: $0 <target_file>"
    exit 1
fi

# Check if input file exists
if [ ! -f "$TARGET_FILE" ]; then
    echo "File $TARGET_FILE does not exist."
    exit 1
fi

# Check if naabu is installed
if ! command -v naabu &> /dev/null; then
    echo "Naabu could not be found. Please install Naabu and make sure it's in your PATH."
    exit 1
fi

# Extract base name from the input file name
BASE_NAME=$(basename "$TARGET_FILE" .txt)

# Output file names
NMAP_OUTPUT_FILE="$OUTPUT_DIR/${BASE_NAME}-nmap-scan.txt"
NAABU_OUTPUT_FILE="$OUTPUT_DIR/${BASE_NAME}-naabu-scan.txt"
DOWN_FILE="$OUTPUT_DIR/${BASE_NAME}-down.txt"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Clear output files if they exist
> "$NMAP_OUTPUT_FILE"
> "$NAABU_OUTPUT_FILE"
> "$DOWN_FILE"

# Prepare targets file for Nmap
NMAP_TARGETS="$OUTPUT_DIR/${BASE_NAME}-nmap-targets.txt"
grep -oP 'https?://\K[^/]*' "$TARGET_FILE" > "$NMAP_TARGETS"

# Run nmap scan
echo "Running Nmap scan on targets in $NMAP_TARGETS..."
nmap -sS -A -T4 -p 21,22,23,25,53,80,110,143,161,389,443,445,465,514,636,993,995,123,135,3306,5432,3389,8443,1433,1434,27017,6379,9200,5672,11211 -sV -iL "$NMAP_TARGETS" -oN "$NMAP_OUTPUT_FILE"

# Check for down sites during Nmap scan
echo "Checking for down sites in Nmap scan results..."
while IFS= read -r TARGET; do
    DOMAIN=$(echo "$TARGET" | sed -e 's|https://||' -e 's|http://||')
    if ! grep -q "$DOMAIN" "$NMAP_OUTPUT_FILE"; then
        echo "$TARGET" >> "$DOWN_FILE"
        echo "$TARGET is down (Nmap), added to $DOWN_FILE"
    fi
done < "$TARGET_FILE"

echo "Nmap scan complete. Results saved to $NMAP_OUTPUT_FILE"

# Perform naabu scan
echo "Starting Naabu scan..."
naabu -list "$NMAP_TARGETS" -p - -o "$NAABU_OUTPUT_FILE"

# Check for down sites during Naabu scan
echo "Checking for down sites in Naabu scan results..."
while IFS= read -r TARGET; do
    DOMAIN=$(echo "$TARGET" | sed -e 's|https://||' -e 's|http://||')
    if ! grep -q "$DOMAIN" "$NAABU_OUTPUT_FILE"; then
        echo "$TARGET" >> "$DOWN_FILE"
        echo "$TARGET was not found in Naabu scan, added to $DOWN_FILE"
    fi
done < "$TARGET_FILE"

echo "Naabu scan complete. Results saved to $NAABU_OUTPUT_FILE"
echo "Down targets saved to $DOWN_FILE"
