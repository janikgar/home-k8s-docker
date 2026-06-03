#!/bin/bash
#
# Script to find directories modified in the last week and run docker operations
# Usage: ./docker-manage.sh [directory]
#
# Options:
#   [directory] - Optional directory to search. If not provided, searches current directory.
#

set -euo pipefail

# Configuration
FIND_DAYS=7

# Optional: directory to search (defaults to current directory)
SEARCH_DIR="${1:-.}"

echo "Searching for directories modified in the last $FIND_DAYS days..."
echo "Search directory: $SEARCH_DIR"
echo ""

# Find all directories modified in the last week, excluding common directories we don't want to process
# -mindepth 1: Exclude the search directory itself if searching from a directory
# -name '.git' -prune -o -name '.gitignore' -prune: Skip .git and .gitignore directories
find "$SEARCH_DIR" -mindepth 1 -type d -name ".git" -prune -o \
    -type d -name ".gitignore" -prune -o \
    -type d -newermt "-$FIND_DAYS.days" ! -path "*/\.*" 2>/dev/null | \
sort | \
while IFS= read -r dir; do
    echo "Processing: $dir"
    echo "---"
    
    # Change into the directory
    (
        cd "$dir" || exit 1
        
        # Run docker-compose up -d
        if [[ -f "docker-compose.yml" || -f "docker-compose.yaml" ]]; then
            echo "  Running: docker-compose up -d"
            docker-compose up -d 2>&1 || {
                echo "  Warning: docker-compose up -d failed in $dir (no docker-compose file found)"
                continue
            }
        else
            echo "  Warning: No docker-compose.yml found in $dir"
        fi
        
        # Run docker system prune
        echo "  Running: docker system prune -f"
        docker system prune -f 2>&1 || {
            echo "  Warning: docker system prune failed"
        }
        
        echo "  Completed"
    ) || {
        echo "  Error processing $dir"
    }
    echo ""
done

echo "All done!"

