#!/bin/bash

# Function to filter duplicate subdomains
filter_duplicate_subdomains() {
  input_file=$1
  output_file=$2
  subdomains=()
  echo "Filtering subdomains from $input_file to $output_file"
  while IFS= read -r url; do
    subdomain=$(echo $url | awk -F/ '{print $3}' | cut -d. -f1)
    if [[ ! " ${subdomains[@]} " =~ " ${subdomain} " ]]; then
      subdomains+=("$subdomain")
      echo $url >> "$output_file"
    fi
  done < "$input_file"
}

# Check if a URL argument was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <url>"
  exit 1
fi

url=$1

# Base directory for output
output_dir="/home/mr_10sion/bugs/$url"

# Create the main directory if it doesn't exist
if [ ! -d "$output_dir" ]; then
  mkdir -p "$output_dir"
fi

# Create the recon directory if it doesn't exist
if [ ! -d "$output_dir/recon" ]; then
  mkdir -p "$output_dir/recon"
fi

# Subdomain hunting with assetfinder
echo "[+] Hunting Subdomains with assetfinder..."
/home/mr_10sion/tools/assetfinder/assetfinder $url >> "$output_dir/recon/assets.txt"
grep $1 "$output_dir/recon/assets.txt" >> "$output_dir/recon/subdomain.txt"
rm "$output_dir/recon/assets.txt"

# Finding alive domains with httprobe
echo "[+] Finding Alive Domains with httprobe..."
cat "$output_dir/recon/subdomain.txt" | /home/mr_10sion/tools/httprobe/httprobe >> "$output_dir/recon/alive.txt"

# Filter duplicate subdomains from the alive.txt file
filtered_subdomains_file="$output_dir/recon/filtered_alive.txt"
echo "[+] Filtering duplicate subdomains from alive domains..."
filter_duplicate_subdomains "$output_dir/recon/alive.txt" "$filtered_subdomains_file"

# Check if the filtered_alive.txt file was created
if [ ! -f "$filtered_subdomains_file" ]; then
  echo "Error: Failed to create $filtered_subdomains_file"
  exit 1
fi

echo "[+] Scan complete. Results are in $output_dir/recon/"
