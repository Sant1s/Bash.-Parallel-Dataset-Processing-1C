#!/usr/bin/bash

function file_path_valdation() {
    if [ -f "$1" ]; then
        if [ "${1##*.}" != "csv" ]; then
            echo "wrong file extension"
            exit
        fi
    else
        echo ""$1" file does not exists or it is not file"
        exit
    fi
}

process_lines() {
    local start=$1
    local end=$2
    while read -r line; do
        wget -P "$3" "$line" > /dev/null 2>&1
    done < <(sed -n "${start},${end}p" links.txt)
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --num_workers)
            num_workers="$2"
            shift 2
            ;;
        --input_file)
            input_file="$2"
            shift 2
            ;;
        --links_index)
            links_index="$2"
            shift 2
            ;;
        --output_folder)
            output_folder="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$input_file" || -z "$links_index" || -z "$output_folder" || -z "$num_workers" ]]; then
    echo "Usage: ./run.sh --num_workers <num> --input_file <file> --links_index <index> --output_folder <folder>"
    exit 1
fi

if ! [[ "$num_workers" =~ ^[0-9]+$ ]]; then
    echo "Error: Number of workers '$num_workers' is not a valid number."
    exit 1
fi

if ! [[ "$links_index" =~ ^[0-9]+$ ]]; then
    echo "Error: Number of workers '$links_index' is not a valid number."
    exit 1
fi

if [[ ! -d "$output_folder" ]]; then
    echo "Error: Output folder '$output_folder' is not a valid directory."
    exit 1
fi

file_path_valdation "$input_file"
awk -F ';' -v idx="$links_index" '{print $idx}' "$input_file" > links.txt
sed -i '1d' links.txt


lines_count=$(wc -l < links.txt)
lines_per_worker=$((lines_count / num_workers))
remainder=$((lines_count % num_workers))

start=1
for ((i = 0; i < num_workers; i++)); do
    if [[ $i -eq $((num_workers - 1)) ]]; then
        end=$((start + lines_per_worker + remainder - 1))
    else
        end=$((start + lines_per_worker - 1))
    fi
    process_lines $start $end "$output_folder" &
    start=$((end + 1))
done

wait
echo "All processes have completed."