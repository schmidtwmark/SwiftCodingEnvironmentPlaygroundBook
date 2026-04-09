#!/bin/bash
# Copies the built Robot Console playground book and injects solutions
# from the commented-out MARK: - Solution blocks in each level's main.swift.
#
# Used by the RobotConsoleSolvedBook aggregate target.

set -euo pipefail

SOURCE_BOOK="${BUILT_PRODUCTS_DIR}/RobotConsoleBook.playgroundbook"
SOLVED_BOOK="${BUILT_PRODUCTS_DIR}/Robot Console Solved.playgroundbook"

if [ ! -d "$SOURCE_BOOK" ]; then
    echo "error: RobotConsoleBook.playgroundbook not found at $SOURCE_BOOK"
    exit 1
fi

# Copy the whole book
rm -rf "$SOLVED_BOOK"
cp -R "$SOURCE_BOOK" "$SOLVED_BOOK"

PAGES_DIR="$SOLVED_BOOK/Contents/Chapters/Chapter3.playgroundchapter/Pages"

for level_dir in "$PAGES_DIR"/Level*.playgroundpage; do
    main_file="$level_dir/main.swift"

    if [ ! -f "$main_file" ]; then
        continue
    fi

    # Extract solution: take lines after "MARK: - Solution" up to "//#-end-hidden-code", strip leading "// "
    solution=$(awk '
        /MARK: - Solution/ { found=1; next }
        /\/\/#-end-hidden-code/ { found=0 }
        found && /^\/\/ *$/ { print ""; next }
        found && /^\/\/ / { sub(/^\/\/ /, ""); print }
    ' "$main_file")

    if [ -z "$solution" ]; then
        echo "warning: No solution found in $(basename "$level_dir")/main.swift"
        continue
    fi

    # Append solution after the "Write your solution here:" comment
    printf '\n%s\n' "$solution" >> "$main_file"
    echo "Injected solution into $(basename "$level_dir")"
done

echo "Built solved playground book at: $SOLVED_BOOK"
