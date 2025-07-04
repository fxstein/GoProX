#!/bin/zsh
#
# generate-firmware-wiki-table.zsh: Generate a Markdown firmware table for the GoProX wiki
#
# Copyright (c) 2021-2025 by Oliver Ratzesberger
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Usage: ./generate-firmware-wiki-table.zsh [--debug]
#
# FINALIZED PRODUCTION VERSION WITH DEBUG OUTPUT ENABLED
#
# This version is validated to:
# - Output all models in the exact custom order (MODEL_ORDERED_LIST)
# - Include all firmware versions for each model, sorted newest-to-oldest
# - Add red-flag rows only for models with no firmware in a section
# - Be robust to zsh quirks and macOS/BSD sort
# - Retain debug output for troubleshooting

# NOTE: Whenever you add, remove, or update firmware, update firmware/README.md to keep the summary current.

set -uo pipefail

# Parse --debug option
DEBUG=0
for arg in "$@"; do
  if [[ "$arg" == "--debug" ]]; then
    DEBUG=1
  fi
done

# Only print these if DEBUG=1
if (( DEBUG )); then
  print "[DEBUG] PATH: $PATH"
  print "[DEBUG] SHELL: $SHELL"
  print "[DEBUG] Script: $0"
  print "[DEBUG] command -v find: $(command -v find)"
  print "[DEBUG] command -v cut: $(command -v cut)"
fi

FIRMWARE_DIRS=(firmware/official firmware/labs)
WIKI_PAGE="GoProX.wiki/firmware-tracker.md"

CURRENT_YEAR=$(date +'%Y')
TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S %z')
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo 'N/A')
SCRIPT_NAME=$(basename "$0")
LEGEND="**Legend:**  \n🚩: Missing URL or missing firmware directory  \n⚠️: Version does not match Hnn.nn.nn.nn.nn or HDn.nn.nn.nn.nn schema  \n\n*Model list as of $CURRENT_YEAR*  \n"

TABLE_HEADER="| Status | Model | Version String | URL | Path | Notes |\n|--------|-------|----------------|-----|------|-------|\n"

# List of all known GoPro camera models as of 2025 (add more as needed)
ALL_MODELS=(
  "GoPro Max"
  "HERO (2024)"
  "HERO8 Black"
  "HERO9 Black"
  "HERO10 Black"
  "HERO11 Black"
  "HERO11 Black Mini"
  "HERO12 Black"
  "HERO13 Black"
  "The Remote"
)

# Define custom model order (highest index = newest)
typeset -A MODEL_ORDER
MODEL_ORDER=(
  "HERO13 Black" 10
  "HERO12 Black" 9
  "HERO11 Black" 8
  "HERO11 Black Mini" 7
  "HERO10 Black" 6
  "HERO9 Black" 5
  "HERO8 Black" 4
  "GoPro Max" 3
  "HERO (2024)" 2
  "The Remote" 1
)

# Define the explicit model order for output
MODEL_ORDERED_LIST=(
  "HERO13 Black"
  "HERO12 Black"
  "HERO11 Black"
  "HERO11 Black Mini"
  "HERO10 Black"
  "HERO9 Black"
  "HERO8 Black"
  "GoPro Max"
  "HERO (2024)"
  "The Remote"
)

# Helper function to check if a model has any non-🚩 row in a given array
has_non_flag_row() {
  local model="$1"
  local -a arr
  arr=("${(@P)2}")
  for row in "${arr[@]}"; do
    # Extract model and status columns
    local row_status model_col
    row_status=$(echo "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $3); print $3}')
    model_col=$(echo "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $4); print $4}')
    if [[ "$model_col" == "$model" && "$row_status" != "🚩" ]]; then
      return 0  # found non-flag row
    fi
  done
  return 1  # no non-flag row found
}

# Instead of building official_rows and labs_rows as strings, build as arrays
official_rows_arr=()
labs_rows_arr=()

# Arrays to collect redflags and warnings for summary
redflag_summary=()
warning_summary=()

GITHUB_REPO_URL="https://github.com/fxstein/GoProX"

for dir in $FIRMWARE_DIRS; do
  if [[ -d $dir ]]; then
    while IFS= read -r -d '' file; do
      # Always use path relative to workspace root
      relpath=${file#./}
      relpath=${relpath#${PWD}/}
      # Determine type by path prefix
      if [[ $relpath == firmware/labs/* ]]; then
        type="Labs"
        model="${relpath#firmware/labs/}"
        model="${model%%/*}"
        version="${relpath#firmware/labs/$model/}"
        version="${version%%/*}"
      elif [[ $relpath == firmware/official/* ]]; then
        type="Official"
        model="${relpath#firmware/official/}"
        model="${model%%/*}"
        version="${relpath#firmware/official/$model/}"
        version="${version%%/*}"
      else
        continue  # skip files not in expected dirs
      fi
      [[ -z $version || $version == "$model" ]] && version="-"
      url="-"
      while IFS= read -r line; do
        [[ $line =~ ^#.*$ ]] && continue
        [[ -z $line ]] && continue
        url=$line
        break
      done < "$file"
      fw_path="$file"
      notes=""
      row_status=""
      if [[ "$url" == "-" ]]; then
        row_status="🚩"
      elif ! [[ "$version" =~ ^H[0-9]{2}(\.[0-9]{2}){4}([a-z][0-9]*)?$ ]] && ! [[ "$version" =~ ^HD[0-9]{1}(\.[0-9]{2}){4}([a-z][0-9]*)?$ ]]; then
        row_status="⚠️"
      fi
      model_index=${MODEL_ORDER[$model]:-0}
      row="| $model_index | $row_status | $model | $version | $url | $fw_path | $notes |"
      if [[ $type == "Official" ]]; then
        official_rows_arr+=("$row")
      else
        labs_rows_arr+=("$row")
      fi
    done < <(/usr/bin/find "$dir" -type f -name '*.url' -print0)
  fi

done

# Debug: print the sort command and raw output
if (( DEBUG )); then
  print "[DEBUG] Sort command for official: sort -t'|' -k5,5r" >&2
fi
if (( ${#official_rows_arr[@]} )); then
  if (( DEBUG )); then
    print "[DEBUG] Raw official rows before sort:" >&2
    for row in "${official_rows_arr[@]}"; do
      print -- "$row" >&2
    done
  fi
  IFS=$'\n' sorted_official_rows=($(printf '%s\n' "${official_rows_arr[@]}" | sort -t'|' -k5,5r))
  if (( DEBUG )); then
    print "[DEBUG] Sorted official rows after sort:" >&2
    for row in "${sorted_official_rows[@]}"; do
      version=$(echo "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $5); print $5}')
      model=$(echo "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $4); print $4}')
      print -- "[DEBUG] [model:$model][version:$version] $row" >&2
    done
  fi
else
  sorted_official_rows=()
fi
if (( DEBUG )); then
  print "[DEBUG] Sort command for labs: sort -t'|' -k5,5r" >&2
fi
if (( ${#labs_rows_arr[@]} )); then
  if (( DEBUG )); then
    print "[DEBUG] Raw labs rows before sort:" >&2
    for row in "${labs_rows_arr[@]}"; do
      print -- "$row" >&2
    done
  fi
  IFS=$'\n' sorted_labs_rows=($(printf '%s\n' "${labs_rows_arr[@]}" | sort -t'|' -k5,5r))
  if (( DEBUG )); then
    print "[DEBUG] Sorted labs rows after sort:" >&2
    for row in "${sorted_labs_rows[@]}"; do
      version=$(echo "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $5); print $5}')
      model=$(echo "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $4); print $4}')
      print -- "[DEBUG] [model:$model][version:$version] $row" >&2
    done
  fi
else
  sorted_labs_rows=()
fi

# Output tables using only MODEL_ORDERED_LIST
{
  echo "<!--"
  echo "  This file is generated by $SCRIPT_NAME."
  echo "  Do NOT manually edit this file."
  echo "  Generated: $TIMESTAMP"
  echo "  Commit: $COMMIT_HASH"
  echo "-->"
  echo
  echo "# GoProX Firmware Tracker"
  echo
  echo "> **NOTE:** This markdown file is automatically generated by the \`$SCRIPT_NAME\` tool. Do NOT manually edit this file. Any changes will be overwritten."
  echo
  if [[ "$COMMIT_HASH" != "N/A" ]]; then
    echo "Created by: \`$SCRIPT_NAME\` on: $TIMESTAMP ([\`$COMMIT_HASH\`](https://github.com/fxstein/GoProX/commit/$COMMIT_HASH))"
  else
    echo "Created by: \`$SCRIPT_NAME\` on: $TIMESTAMP (commit: $COMMIT_HASH)"
  fi
  echo
  printf "%b" "$LEGEND"
  echo
  echo "## Official Firmware"
  printf "%b" "$TABLE_HEADER"
  for model in "${MODEL_ORDERED_LIST[@]}"; do
    found=0
    for row in "${sorted_official_rows[@]}"; do
      row_model=$(echo "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $4); print $4}')
      row_status=$(echo "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $3); print $3}')
      version=$(echo "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $5); print $5}')
      if [[ "$row_model" == "$model" ]]; then
        row_noidx=$(echo "$row" | awk -F'|' '{OFS="|"; for(i=3;i<=NF;i++) $i=$i; print "|"$3,$4,$5,$6,$7,$8 }' | sed 's/  */ /g')
        if [[ "$row_status" == "🚩" ]]; then
          print -n "X" >&2
          redflag_summary+=("$model|$version|Official")
        elif [[ "$row_status" == "⚠️" ]]; then
          print -n "W" >&2
          warning_summary+=("$model|$version|Official")
        else
          print -n "." >&2
        fi
        if (( DEBUG )); then print "[DEBUG] Writing official row: $row_noidx" >&2; fi
        printf "%s\n" "$row_noidx"
        found=1
      fi
    done
    if (( !found )); then
      if (( DEBUG )); then print "[DEBUG] Writing official red-flag row for $model" >&2; fi
      print -n "X" >&2
      redflag_summary+=("$model||Official")
      printf "| 🚩 | %s | | | | |\n" "$model"
    fi
  done
  print >&2  # newline after progress dots
  echo
  echo "## Labs Firmware"
  printf "%b" "$TABLE_HEADER"
  for model in "${MODEL_ORDERED_LIST[@]}"; do
    # Skip models that don't have labs firmware
    if [[ "$model" == "The Remote" || "$model" == "HERO (2024)" ]]; then
      continue
    fi
    found=0
    for row in "${sorted_labs_rows[@]}"; do
      row_model=$(echo "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $4); print $4}')
      row_status=$(echo "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $3); print $3}')
      version=$(echo "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $5); print $5}')
      if [[ "$row_model" == "$model" ]]; then
        row_noidx=$(echo "$row" | awk -F'|' '{OFS="|"; for(i=3;i<=NF;i++) $i=$i; print "|"$3,$4,$5,$6,$7,$8 }' | sed 's/  */ /g')
        if [[ "$row_status" == "🚩" ]]; then
          print -n "X" >&2
          redflag_summary+=("$model|$version|Labs")
        elif [[ "$row_status" == "⚠️" ]]; then
          print -n "W" >&2
          warning_summary+=("$model|$version|Labs")
        else
          print -n "." >&2
        fi
        if (( DEBUG )); then print "[DEBUG] Writing labs row: $row_noidx" >&2; fi
        printf "%s\n" "$row_noidx"
        found=1
      fi
    done
    if (( !found )); then
      if (( DEBUG )); then print "[DEBUG] Writing labs red-flag row for $model" >&2; fi
      print -n "X" >&2
      redflag_summary+=("$model||Labs")
      printf "| 🚩 | %s | | | | |\n" "$model"
    fi
  done
  print >&2  # newline after progress dots

  # Print summary of redflags and warnings
  if (( ${#redflag_summary[@]} )); then
    print "\nErrors:" >&2
    print "  Type        Model               Version" >&2
    print "  ----        -----------------   --------------" >&2
    for entry in "${redflag_summary[@]}"; do
      model=${entry%%|*}
      rest=${entry#*|}
      version=${rest%%|*}
      type=${rest#*|}
      printf "  %-11s %-19s %s\n" "$type" "$model" "$version" >&2
    done
  fi
  if (( ${#warning_summary[@]} )); then
    print "\nWarnings:" >&2
    print "  Type        Model               Version" >&2
    print "  ----        -----------------   --------------" >&2
    for entry in "${warning_summary[@]}"; do
      model=${entry%%|*}
      rest=${entry#*|}
      version=${rest%%|*}
      type=${rest#*|}
      printf "  %-11s %-19s %s\n" "$type" "$model" "$version" >&2
    done
  fi
} > "$WIKI_PAGE"

print "" >&2
print "Firmware tracker wiki page updated: GoProX.wiki/firmware-tracker.md" >&2 