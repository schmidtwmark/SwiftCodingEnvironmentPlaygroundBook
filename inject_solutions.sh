#!/bin/bash
# Builds the Robot answer key and keeps the answers out of the student book.
#
# Every page's answer lives in its main.swift, inside the hidden code, as a commented-out
# block that starts at "// MARK: - Solution" and runs to "//#-end-hidden-code".
#
# After a book target copies its book into the build folder, this script:
#   0. Lists extra chapters. The manifest template names one chapter, SELECTED_CHAPTER. A
#      target that sets PLAYGROUND_BOOK_EXTRA_CHAPTERS (the robot book does) gets those
#      chapters listed after it, in order.
#   1. Removes those solution blocks from the book, so the book students download does not
#      carry the answers. Every book gets this, because each one contains all the chapter
#      folders even though its manifest only shows one.
#   2. Unless run with --strip-only, makes an answer key next to the book: a copy with its own
#      identifier and name ("Robot Answer Key", or the name given after --answer-key), and the
#      solution of each page in the book's listed chapters added at the end of the page.
#      Solutions are read from the source pages, so repeated builds always get them.
#   3. For the robot book only (no arguments), makes "Bug Hunt.playgroundbook": a separate book that shows
#      only the Bug Hunt chapter (BUG_HUNT_CHAPTER). Its pages mix robot and text programs,
#      so it auto-imports both RobotAPI and TextAPI. Each page shows broken code, so its
#      answer key, "Bug Hunt Answer Key.playgroundbook", replaces the broken code with the
#      page's solution instead of adding the solution below it.
#   4. For the robot book only (no arguments), makes "Game Design.playgroundbook": a separate book
#      that shows only the Game Design chapters (GAME_CHAPTERS: Chapter9 and Chapter11-16, Parts 1-7) and ships
#      only the GameAPI module. No other book may list those chapters (checked after step 1).
#      GameAPI lives outside PlaygroundBook/Modules, in GameModules/GameAPI.playgroundmodule, so the
#      other books never ship or compile it; this step removes every other module and chapter from
#      the copy, copies GameAPI in, and adds the book icon (GameModules/gameicon.png). Its answer key,
#      "Game Design Answer Key.playgroundbook", replaces each page's starter code with the page's
#      solution, the same way as Bug Hunt. GameAPI is not in the Xcode project, so this step also
#      typechecks it and every page of both books for iPad, and a mistake there fails the build.
#      Tests: GameModules/Tests/run-tests.sh.
#
# Build phases:
#   RobotConsoleBook  "Make Answer Key"  inject_solutions.sh
#   TextConsoleBook   "Remove Answers"   inject_solutions.sh --strip-only
#   TurtleConsoleBook "Make Answer Key"  inject_solutions.sh --answer-key "Turtle Answer Key"
# The older RobotConsoleSolvedBook aggregate target also runs it; that is harmless.

set -euo pipefail

MODE="${1:-answer-key}"
ANSWER_KEY_NAME="Robot Answer Key"
if [ "$MODE" = "--answer-key" ]; then
    ANSWER_KEY_NAME="${2:?--answer-key needs a name for the answer key}"
fi
SOURCE_CHAPTERS="${PROJECT_DIR}/PlaygroundBook/Chapters"
BUG_HUNT_CHAPTER="Chapter8.playgroundchapter"
# Game Design is one chain of pages in seven feature Parts, in this order. (There is no Chapter10:
# its one page, Coyote Time, is in Part 1 since v7, and the later folders kept their names.)
GAME_CHAPTERS=(Chapter9.playgroundchapter Chapter11.playgroundchapter
    Chapter12.playgroundchapter Chapter13.playgroundchapter Chapter14.playgroundchapter
    Chapter15.playgroundchapter Chapter16.playgroundchapter)

# The book this target just built, or the robot book when run from the aggregate target.
if [[ "${FULL_PRODUCT_NAME:-}" == *.playgroundbook ]]; then
    STUDENT_BOOK="${TARGET_BUILD_DIR}/${FULL_PRODUCT_NAME}"
else
    STUDENT_BOOK="${BUILT_PRODUCTS_DIR}/RobotConsoleBook.playgroundbook"
fi

if [ ! -d "$STUDENT_BOOK" ]; then
    echo "error: playground book not found at $STUDENT_BOOK"
    exit 1
fi

# Archive builds reach the product through a symlink. Work on the real folder, so the
# answer key is a separate copy instead of the student book edited through the link.
STUDENT_BOOK=$(cd "$STUDENT_BOOK" && pwd -P)
ANSWER_KEY="$(dirname "$STUDENT_BOOK")/$ANSWER_KEY_NAME.playgroundbook"

# 0. Chapters. Rebuilt from scratch every time, so repeated builds never list one twice.
if [ -n "${PLAYGROUND_BOOK_EXTRA_CHAPTERS:-}" ]; then
    BOOK_MANIFEST="$STUDENT_BOOK/Contents/Manifest.plist"
    /usr/libexec/PlistBuddy -c "Delete :Chapters" -c "Add :Chapters array" "$BOOK_MANIFEST"
    for chapter in ${SELECTED_CHAPTER} ${PLAYGROUND_BOOK_EXTRA_CHAPTERS}; do
        if [ ! -f "$STUDENT_BOOK/Contents/Chapters/$chapter/Manifest.plist" ]; then
            echo "error: chapter $chapter not found in $(basename "$STUDENT_BOOK")"
            exit 1
        fi
        /usr/libexec/PlistBuddy -c "Add :Chapters: string $chapter" "$BOOK_MANIFEST"
    done
    echo "Chapters: ${SELECTED_CHAPTER} ${PLAYGROUND_BOOK_EXTRA_CHAPTERS}"
fi

# Print a page's solution, uncommented.
extract_solution() {
    awk '
        /MARK: - Solution/ { found=1; next }
        /\/\/#-end-hidden-code/ { found=0 }
        found && /^\/\/ *$/ { print ""; next }
        found && /^\/\/ / { sub(/^\/\/ /, ""); print }
    ' "$1"
}

# Print a page without its solution block. Everything else, including the rest of the
# hidden code and the "//#-end-hidden-code" line, is kept.
strip_solution() {
    awk '
        /MARK: - Solution/ { skipping=1; next }
        /\/\/#-end-hidden-code/ { skipping=0 }
        !skipping { print }
    ' "$1"
}

# 1. Student book: remove the solutions.
stripped=0
while IFS= read -r page; do
    if grep -q 'MARK: - Solution' "$page"; then
        strip_solution "$page" > "$page.tmp"
        mv "$page.tmp" "$page"
        stripped=$((stripped + 1))
    fi
done < <(find "$STUDENT_BOOK/Contents/Chapters" -path '*.playgroundpage/main.swift')
echo "Removed solutions from $stripped pages in $(basename "$STUDENT_BOOK")"

# The Game Design chapters belong to the Game Design book only: no other book may list them.
book_chapters=$(/usr/libexec/PlistBuddy -c "Print :Chapters" "$STUDENT_BOOK/Contents/Manifest.plist" 2>/dev/null | tr -d ' ' || true)
for chapter in "${GAME_CHAPTERS[@]}"; do
    if grep -qxF -- "$chapter" <<< "$book_chapters"; then
        echo "error: $(basename "$STUDENT_BOOK") lists $chapter, which belongs only to Game Design"
        exit 1
    fi
done

if [ "$MODE" = "--strip-only" ]; then
    exit 0
fi

# 2. Answer key: copy the student book and give it its own identity, so it can sit next to
#    the student book on the same iPad.
rm -rf "$ANSWER_KEY" "$(dirname "$STUDENT_BOOK")/Robot Console Solved.playgroundbook"
cp -R "$STUDENT_BOOK" "$ANSWER_KEY"
MANIFEST="$ANSWER_KEY/Contents/Manifest.plist"
STUDENT_ID=$(/usr/libexec/PlistBuddy -c "Print :ContentIdentifier" "$MANIFEST")
/usr/libexec/PlistBuddy -c "Set :ContentIdentifier ${STUDENT_ID}.answerkey" "$MANIFEST"
/usr/libexec/PlistBuddy -c "Set :Name $ANSWER_KEY_NAME" "$MANIFEST"

# Add each page's solution at the end of the page, for the chapters this book lists.
listed_chapters=$(/usr/libexec/PlistBuddy -c "Print :Chapters" "$MANIFEST" | grep playgroundchapter | tr -d ' ')
injected=0
while IFS= read -r source_page; do
    solution=$(extract_solution "$source_page")
    if [ -z "$solution" ]; then
        echo "warning: empty solution block in ${source_page#"$SOURCE_CHAPTERS"/}"
        continue
    fi
    answer_page="$ANSWER_KEY/Contents/Chapters/${source_page#"$SOURCE_CHAPTERS"/}"
    if [ ! -f "$answer_page" ]; then
        continue
    fi
    printf '\n%s\n' "$solution" >> "$answer_page"
    injected=$((injected + 1))
done < <(for chapter in $listed_chapters; do grep -rl --include=main.swift 'MARK: - Solution' "$SOURCE_CHAPTERS/$chapter" || true; done)

echo "Built answer key with $injected solutions at: $ANSWER_KEY"

if [ "$MODE" = "--answer-key" ]; then
    exit 0
fi

# 3. Bug Hunt and its answer key.
BUG_HUNT="$(dirname "$STUDENT_BOOK")/Bug Hunt.playgroundbook"
BUG_HUNT_KEY="$(dirname "$STUDENT_BOOK")/Bug Hunt Answer Key.playgroundbook"
if [ ! -f "$STUDENT_BOOK/Contents/Chapters/$BUG_HUNT_CHAPTER/Manifest.plist" ]; then
    echo "error: chapter $BUG_HUNT_CHAPTER not found in $(basename "$STUDENT_BOOK")"
    exit 1
fi
rm -rf "$BUG_HUNT" "$BUG_HUNT_KEY"
cp -R "$STUDENT_BOOK" "$BUG_HUNT"
MANIFEST="$BUG_HUNT/Contents/Manifest.plist"
/usr/libexec/PlistBuddy -c "Set :ContentIdentifier ${STUDENT_ID%.*}.bughunt" -c "Set :Name Bug Hunt" \
    -c "Delete :Chapters" -c "Add :Chapters array" -c "Add :Chapters: string $BUG_HUNT_CHAPTER" \
    -c "Delete :UserAutoImportedAuxiliaryModules" -c "Add :UserAutoImportedAuxiliaryModules array" \
    -c "Add :UserAutoImportedAuxiliaryModules: string RobotAPI" -c "Add :UserAutoImportedAuxiliaryModules: string TextAPI" \
    "$MANIFEST"

cp -R "$BUG_HUNT" "$BUG_HUNT_KEY"
MANIFEST="$BUG_HUNT_KEY/Contents/Manifest.plist"
/usr/libexec/PlistBuddy -c "Set :ContentIdentifier ${STUDENT_ID%.*}.bughunt.answerkey" -c "Set :Name Bug Hunt Answer Key" "$MANIFEST"

# Keep each answer page up to the end of its prose card (the first " */" after the hidden
# code), then put the fixed code where the broken code was.
fixed=0
while IFS= read -r source_page; do
    answer_page="$BUG_HUNT_KEY/Contents/Chapters/${source_page#"$SOURCE_CHAPTERS"/}"
    awk '
        /\/\/#-end-hidden-code/ { visible=1 }
        { print }
        visible && /^ \*\/$/ { exit }
    ' "$answer_page" > "$answer_page.tmp"
    printf '\n%s\n' "$(extract_solution "$source_page")" >> "$answer_page.tmp"
    mv "$answer_page.tmp" "$answer_page"
    fixed=$((fixed + 1))
done < <(grep -rl --include=main.swift 'MARK: - Solution' "$SOURCE_CHAPTERS/$BUG_HUNT_CHAPTER")

echo "Built Bug Hunt and its answer key with $fixed fixed pages at: $BUG_HUNT_KEY"

# 4. Game Design and its answer key.
GAME_MODULE="${PROJECT_DIR}/GameModules/GameAPI.playgroundmodule"
GAME_ICON="${PROJECT_DIR}/GameModules/gameicon.png"
GAME="$(dirname "$STUDENT_BOOK")/Game Design.playgroundbook"
GAME_KEY="$(dirname "$STUDENT_BOOK")/Game Design Answer Key.playgroundbook"
for chapter in "${GAME_CHAPTERS[@]}"; do
    if [ ! -f "$STUDENT_BOOK/Contents/Chapters/$chapter/Manifest.plist" ]; then
        echo "error: chapter $chapter not found in $(basename "$STUDENT_BOOK")"
        exit 1
    fi
    # A page folder that its chapter's manifest doesn't list would quietly disappear from the book.
    listed=$(/usr/libexec/PlistBuddy -c "Print :Pages" "$SOURCE_CHAPTERS/$chapter/Manifest.plist" | sed '1d;$d' | tr -d ' ' | sort | tr '\n' ' ')
    folders=$(cd "$SOURCE_CHAPTERS/$chapter/Pages" && ls -d *.playgroundpage | sort | tr '\n' ' ')
    if [ "$listed" != "$folders" ]; then
        echo "error: $chapter's Manifest.plist lists pages [$listed] but its Pages folder has [$folders]"
        exit 1
    fi
done
if [ ! -d "$GAME_MODULE/Sources" ] || [ ! -f "$GAME_ICON" ]; then
    echo "error: $GAME_MODULE or $GAME_ICON not found"
    exit 1
fi
rm -rf "$GAME" "$GAME_KEY"
cp -R "$STUDENT_BOOK" "$GAME"
# Only the game chapters, only GameAPI, and only the game icon. (Like the spike book: the robot
# book's asset catalog, storyboards and icons belong to the modules this book doesn't have.)
for dir in "$GAME/Contents/Chapters"/*; do
    keep=0
    for chapter in "${GAME_CHAPTERS[@]}"; do
        if [ "$(basename "$dir")" = "$chapter" ]; then keep=1; fi
    done
    if [ $keep = 0 ]; then rm -rf "$dir"; fi
done
rm -rf "$GAME/Contents/Modules"
mkdir "$GAME/Contents/Modules"
cp -R "$GAME_MODULE" "$GAME/Contents/Modules/"
find "$GAME/Contents/Modules" -name .DS_Store -delete
rm -rf "$GAME/Contents/PrivateResources/Assets.car" "$GAME/Contents/PrivateResources/Base.lproj" \
    "$GAME/Contents/PrivateResources/texticon.png" "$GAME/Contents/PrivateResources/turtleicon.png"
cp "$GAME_ICON" "$GAME/Contents/PrivateResources/gameicon.png"
MANIFEST="$GAME/Contents/Manifest.plist"
/usr/libexec/PlistBuddy -c "Set :ContentIdentifier ${STUDENT_ID%.*}.game" -c "Set :Name Game Design" \
    -c "Set :ImageReference gameicon.png" \
    -c "Delete :Chapters" -c "Add :Chapters array" \
    -c "Delete :UserAutoImportedAuxiliaryModules" -c "Add :UserAutoImportedAuxiliaryModules array" \
    -c "Add :UserAutoImportedAuxiliaryModules: string GameAPI" \
    "$MANIFEST"
for chapter in "${GAME_CHAPTERS[@]}"; do
    /usr/libexec/PlistBuddy -c "Add :Chapters: string $chapter" "$MANIFEST"
done
# Swift Playgrounds compiles a book in the language mode of its SwiftVersion. The pages need Swift 5:
# in Swift 6 mode a var at the top of a page (framesInAir, from Coyote Time on) can't be changed
# inside a function ("main actor-isolated var").
GAME_SWIFT=$(/usr/libexec/PlistBuddy -c "Print :SwiftVersion" "$MANIFEST")
case "$GAME_SWIFT" in
    5|5.*) ;;
    *) echo "error: Game Design needs SwiftVersion 5.x in its manifest (top-level vars changed in functions), not $GAME_SWIFT"; exit 1 ;;
esac

cp -R "$GAME" "$GAME_KEY"
MANIFEST="$GAME_KEY/Contents/Manifest.plist"
/usr/libexec/PlistBuddy -c "Set :ContentIdentifier ${STUDENT_ID%.*}.game.answerkey" -c "Set :Name Game Design Answer Key" "$MANIFEST"

# Same as Bug Hunt: keep each answer page up to the end of its prose card, then put the
# solution where the starter code was.
solved=0
while IFS= read -r source_page; do
    answer_page="$GAME_KEY/Contents/Chapters/${source_page#"$SOURCE_CHAPTERS"/}"
    awk '
        /\/\/#-end-hidden-code/ { visible=1 }
        { print }
        visible && /^ \*\/$/ { exit }
    ' "$answer_page" > "$answer_page.tmp"
    printf '\n%s\n' "$(extract_solution "$source_page")" >> "$answer_page.tmp"
    mv "$answer_page.tmp" "$answer_page"
    solved=$((solved + 1))
done < <(for chapter in "${GAME_CHAPTERS[@]}"; do grep -rl --include=main.swift 'MARK: - Solution' "$SOURCE_CHAPTERS/$chapter" || true; done)
# Every page with code needs a solution, or the answer key would quietly ship its starter.
with_code=$(for chapter in "${GAME_CHAPTERS[@]}"; do grep -l '//#-hidden-code' "$SOURCE_CHAPTERS/$chapter"/Pages/*.playgroundpage/main.swift || true; done | wc -l | tr -d ' ')
if [ "$solved" -ne "$with_code" ]; then
    echo "error: Game Design has $with_code pages with code but $solved solutions (MARK: - Solution)"
    exit 1
fi

# GameAPI is not in the Xcode project, so nothing above compiles it. Typecheck it and every page of
# both books for iPad here, so a mistake fails this build instead of the book on every iPad.
GAME_TC="${DERIVED_FILE_DIR:-${TMPDIR:-/tmp}}/game-typecheck"
GAME_SDK=$(xcrun --sdk iphoneos --show-sdk-path)
GAME_FW="${PROJECT_DIR}/SupportingContent/PlaygroundsFrameworks/iphoneos"
rm -rf "$GAME_TC"
mkdir -p "$GAME_TC"
# Xcode's SDK can see helpers that Swift Playgrounds on the iPad can't, so the typecheck below misses
# them. These failed on a real iPad; keep them out of the engine (comments are fine).
if grep -nE '^([^/]|/[^/])*\b(UnsafeMutableAudioBufferListPointer|noErr)\b' "$GAME/Contents/Modules/GameAPI.playgroundmodule/Sources/"*.swift; then
    echo "error: GameAPI uses a symbol Swift Playgrounds on the iPad can't see (listed above)"
    exit 1
fi
xcrun swiftc -emit-module -module-name GameAPI -emit-module-path "$GAME_TC/GameAPI.swiftmodule" \
    -sdk "$GAME_SDK" -target arm64-apple-ios17.6 -swift-version 5 -F "$GAME_FW" \
    "$GAME/Contents/Modules/GameAPI.playgroundmodule/Sources/"*.swift
checked=0
for book in "$GAME" "$GAME_KEY"; do
    for chapter in "${GAME_CHAPTERS[@]}"; do
        for main in "$book/Contents/Chapters/$chapter/Pages/"*.playgroundpage/main.swift; do
            # The README and Hints pages have no code, but they must still parse: a stray /* in
            # their prose would nest, and the page would fail when a student taps Run My Code.
            if ! grep -q '//#-hidden-code' "$main"; then
                xcrun swiftc -parse -sdk "$GAME_SDK" -target arm64-apple-ios17.6 "$main" \
                    || { echo "error: $main doesn't parse"; exit 1; }
                continue
            fi
            xcrun swiftc -typecheck -sdk "$GAME_SDK" -target arm64-apple-ios17.6 -swift-version 5 \
                -F "$GAME_FW" -I "$GAME_TC" "$main"
            checked=$((checked + 1))
        done
    done
done
echo "GameAPI and all $checked Game Design pages typecheck for iPad"

echo "Built Game Design and its answer key with $solved solved pages at: $GAME_KEY"
