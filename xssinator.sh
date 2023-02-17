#!/bin/bash

# Validate the user inputs
if [[ ! "$1" =~ ^(https?|ftp)://.*$ ]]; then
  echo "Error: Invalid URL."
  exit 1
fi

if [ ! -f "$2" ]; then
  echo "Error: Payload file not found."
  exit 1
fi

# Set the default options for wget and xargs
WGET_OPTS="-r -np -k -l 10 -p -E -o /dev/null"
XARGS_OPTS="-P 8"

# Set the default output format and destination
OUTPUT_FORMAT="console"
OUTPUT_DEST=""

# Parse the command line options
while getopts ":d:c:u:o:v" opt; do
  case $opt in
    d)
      WGET_OPTS="$WGET_OPTS -l $OPTARG"
      ;;
    c)
      XARGS_OPTS="$XARGS_OPTS -P $OPTARG"
      ;;
    u)
      WGET_OPTS="$WGET_OPTS -U $OPTARG"
      ;;
    o)
      OUTPUT_FORMAT=$(echo "$OPTARG" | cut -d ":" -f 1)
      OUTPUT_DEST=$(echo "$OPTARG" | cut -d ":" -f 2-)
      ;;
    v)
      WGET_OPTS="$WGET_OPTS -v"
      XARGS_OPTS="$XARGS_OPTS --verbose"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

# Download the website recursively and extract all URLs
echo "Crawling $1..."
if ! wget "$WGET_OPTS" "$1" 2>&1 | pv -t >/dev/null; then
  echo "Error: Unable to crawl website."
  exit 1
fi
urls=$(grep -Eo "(http|https)://[a-zA-Z0-9./?=_-]*" -r "$1" | cut -d "#" -f 1 | sort -u)

# Launch the XSS assessment script on each URL in parallel
echo "$urls" | pv -t | xargs "$XARGS_OPTS" -I{} sh -c "/path/to/xss_assessment_script.sh '{}''$2'" | tee "$OUTPUT_DEST" | if [[ "$OUTPUT_FORMAT" == "json" ]]; then jq -s '.'; elif [[ "$OUTPUT_FORMAT" == "csv" ]]; then csvtool col -u ',' -t - transpose; fi



