#!/bin/zsh
# Checks the built "Game Design" book and its answer key, after building the RobotPlaygroundBook scheme.
#
#   zsh GameModules/Tests/check-book.sh <folder with the built books>
#   (for example DerivedData/.../Build/Products/Release-iphoneos)
#
# Game Design: only its seven chapters (Chapter9 and Chapter11-16: Parts 1-7) listed and shipped, only
# the GameAPI module (same as GameModules), the icon, chapter and page manifests and posters as in the
# repo, and no solution text anywhere: every page is exactly the stripped source page. Answer key:
# every page's code is the page's solution. Then each page with code of both books is typechecked for
# iPad against the book's OWN GameAPI sources, and run on the Mac harness (built from the book's own
# sources): student pages with checks fail a check, answer-key pages pass every check and the bot
# completes them (Design Your Own Game, which has no checks, is completed in both); no page may have
# a warning. The 23 posters (square title cards) are redrawn by make-posters.sh and must match the
# repo's. Other books in the folder must not contain GameAPI or list a Game Design chapter.

HERE=${0:A:h}
REPO=${HERE:h:h}
PRODUCTS=${1:?usage: check-book.sh <folder with the built books>}
CHAPTERS=(Chapter9 Chapter11 Chapter12 Chapter13 Chapter14 Chapter15 Chapter16)   # no Chapter10 since v7
CHAPTER_DIRS=(${CHAPTERS/%/.playgroundchapter})
SOURCES=$REPO/PlaygroundBook/Chapters
FW=$REPO/SupportingContent/PlaygroundsFrameworks/iphoneos
OUT=${OUT:-${TMPDIR:-/tmp}/game-design-book-check}
rm -rf $OUT/ios $OUT/mac $OUT/posters; mkdir -p $OUT   # only the folders this script writes
BOOK="$PRODUCTS/Game Design.playgroundbook"
KEY="$PRODUCTS/Game Design Answer Key.playgroundbook"
problems=0
ok()  { print -r -- "ok   $*"; }
bad() { print -r -- "FAIL $*"; problems=$((problems + 1)); }

extract_solution() {
    awk '
        /MARK: - Solution/ { found=1; next }
        /\/\/#-end-hidden-code/ { found=0 }
        found && /^\/\/ *$/ { print ""; next }
        found && /^\/\/ / { sub(/^\/\/ /, ""); print }
    ' "$1"
}
strip_solution() {
    awk '
        /MARK: - Solution/ { skipping=1; next }
        /\/\/#-end-hidden-code/ { skipping=0 }
        !skipping { print }
    ' "$1"
}
up_to_prose_end() { awk '/\/\/#-end-hidden-code/ { visible=1 } { print } visible && /^ \*\/$/ { exit }' "$1"; }
after_prose_end() { awk 'done { print } /\/\/#-end-hidden-code/ { visible=1 } visible && /^ \*\/$/ { done=1 }' "$1"; }
plist() { /usr/libexec/PlistBuddy -c "Print :$2" "$1/Contents/Manifest.plist" 2>/dev/null | tr -s ' \n' ' ' | sed 's/^ //; s/ $//'; }

print "== the chain (source pages)"
python3 -I $REPO/GameModules/Tools/chain.py check $SOURCES > $OUT/chain.txt 2>&1 && ok "$(sed 's/^ok   //' $OUT/chain.txt)" || { cat $OUT/chain.txt; bad "the source pages are not the chain (GameModules/Tools/chain.py check)"; }

for b in $BOOK $KEY; do
    [[ -d $b ]] || { bad "${b:t} not found in $PRODUCTS"; exit 1; }
    n=${b:t:r}
    print "== $n"
    [[ $(plist $b Name) == $n ]] && ok "Name: $n" || bad "Name is $(plist $b Name)"
    id=$(plist $b ContentIdentifier)
    want=game; [[ $b == $KEY ]] && want=game.answerkey
    [[ $id == *.$want ]] && ok "ContentIdentifier: $id" || bad "ContentIdentifier is $id"
    [[ $(plist $b Chapters) == "Array { ${CHAPTER_DIRS[*]} }" ]] \
        && ok "Chapters: $CHAPTERS only, in order" || bad "Chapters: $(plist $b Chapters)"
    [[ $(plist $b UserAutoImportedAuxiliaryModules) == "Array { GameAPI }" ]] && ok "auto-imported modules: GameAPI only" || bad "modules: $(plist $b UserAutoImportedAuxiliaryModules)"
    [[ $(plist $b ImageReference) == gameicon.png && -f $b/Contents/PrivateResources/gameicon.png ]] && ok "icon: gameicon.png" || bad "icon"
    # Swift Playgrounds compiles a book in its SwiftVersion's language mode; the pages need Swift 5
    # (in Swift 6 mode a var at the top of a page can't be changed inside a function).
    [[ $(plist $b SwiftVersion) == 5 || $(plist $b SwiftVersion) == 5.* ]] && ok "SwiftVersion $(plist $b SwiftVersion) (Swift 5 language mode)" || bad "SwiftVersion is $(plist $b SwiftVersion): the pages need 5.x"
    print "     (DeploymentTarget $(plist $b DeploymentTarget), PrivateResources: $(ls $b/Contents/PrivateResources | tr '\n' ' '))"
    [[ $(ls $b/Contents/Chapters | sort | tr '\n' ' ') == "$(print -l $CHAPTER_DIRS | sort | tr '\n' ' ')" ]] \
        && ok "Chapters folder: $CHAPTERS only" || bad "Chapters folder: $(ls $b/Contents/Chapters | tr '\n' ' ')"
    [[ $(ls $b/Contents/Modules) == GameAPI.playgroundmodule ]] && ok "Modules folder: GameAPI only" || bad "Modules folder: $(ls $b/Contents/Modules | tr '\n' ' ')"
    diff -r $REPO/GameModules/GameAPI.playgroundmodule $b/Contents/Modules/GameAPI.playgroundmodule > /dev/null \
        && ok "GameAPI sources are GameModules/GameAPI.playgroundmodule" || bad "GameAPI sources differ from GameModules"
    for c in $CHAPTERS; do
        cmp -s $SOURCES/$c.playgroundchapter/Manifest.plist $b/Contents/Chapters/$c.playgroundchapter/Manifest.plist \
            && ok "$c manifest: $(/usr/libexec/PlistBuddy -c 'Print :Name' $SOURCES/$c.playgroundchapter/Manifest.plist), $(ls -d $SOURCES/$c.playgroundchapter/Pages/*.playgroundpage | wc -l | tr -d ' ') pages" \
            || bad "$c manifest"
    done
    if grep -rq 'MARK: - Solution' $b; then bad "solution blocks found: $(grep -rl 'MARK: - Solution' $b | head -3)"; else ok "no \"MARK: - Solution\" block anywhere"; fi
    pages=0; same=0
    for src in $SOURCES/${^CHAPTERS}.playgroundchapter/Pages/*.playgroundpage; do
        p=$b/Contents/Chapters/${src:h:h:t}/Pages/${src:t}
        pages=$((pages + 1))
        cmp -s $src/Manifest.plist $p/Manifest.plist || { bad "${src:t} manifest differs"; continue; }
        if grep -q '//#-hidden-code' $src/main.swift; then
            cmp -s $src/PrivateResources/poster.png $p/PrivateResources/poster.png || { bad "${src:t} poster missing or differs"; continue; }
            [[ $(LC_ALL=C ls -A $p | tr '\n' ' ') == "Manifest.plist PrivateResources main.swift " ]] || { bad "${src:t} has extra files: $(ls -A $p)"; continue; }
        fi
        if [[ $b == $BOOK ]]; then
            [[ "$(cat $p/main.swift)" == "$(strip_solution $src/main.swift)" ]] || { bad "${src:t}: student page is not the stripped source page"; continue; }
        else
            [[ "$(up_to_prose_end $p/main.swift)" == "$(strip_solution $src/main.swift | up_to_prose_end /dev/stdin)" ]] || { bad "${src:t}: answer page top differs"; continue; }
            [[ "$(after_prose_end $p/main.swift)" == "$(printf '\n%s' "$(extract_solution $src/main.swift)")" ]] || { bad "${src:t}: answer page code is not the solution"; continue; }
            # The solution must not just be the starter (the README page has neither).
            if grep -q '//#-hidden-code' $src/main.swift; then
                [[ "$(after_prose_end $p/main.swift | sed '/^$/d')" != "$(after_prose_end $src/main.swift | sed '/^$/d')" ]] || { bad "${src:t}: solution equals starter"; continue; }
            fi
        fi
        same=$((same + 1))
    done
    if [[ $b == $BOOK ]]; then ok "$same/$pages pages: manifest, poster (1024 x 1024) and main.swift = source page without its solution"
    else ok "$same/$pages pages: manifest, poster, prose as shipped, and the code below the prose is the page's solution"; fi
    sips -g pixelWidth -g pixelHeight $b/Contents/Chapters/*/Pages/*/PrivateResources/poster.png \
        | awk '/pixelWidth/ { w = $2 } /pixelHeight/ { if (w != 1024 || $2 != 1024) bad++ } END { exit bad > 0 }' \
        && ok "posters are 1024 x 1024" || bad "poster size"
done

# iPad typecheck of every page in both books, against each book's own GameAPI.
print "== iPad typecheck (each book's own GameAPI, Swift 5, GameAPI auto-imported)"
SDK=$(xcrun --sdk iphoneos --show-sdk-path)
for b in $BOOK $KEY; do
    n=${b:t:r}; O=$OUT/ios/${n// /-}; mkdir -p $O
    xcrun swiftc -emit-module -module-name GameAPI -emit-module-path $O/GameAPI.swiftmodule -sdk $SDK -target arm64-apple-ios17.6 \
        -F $FW -swift-version 5 $b/Contents/Modules/GameAPI.playgroundmodule/Sources/*.swift 2> $O/module.err \
        || { bad "$n: GameAPI does not build"; head $O/module.err; continue; }
    clean=0; warn=0; total=0
    for p in $b/Contents/Chapters/*/Pages/*.playgroundpage; do
        grep -q '//#-hidden-code' $p/main.swift || continue   # README: no code
        total=$((total + 1)); mkdir -p $O/${p:t:r}; cp $p/main.swift $O/${p:t:r}/main.swift
        if xcrun swiftc -typecheck -sdk $SDK -target arm64-apple-ios17.6 -F $FW -I $O -swift-version 5 \
             -Xfrontend -import-module -Xfrontend GameAPI $O/${p:t:r}/main.swift 2> $O/${p:t:r}/err.txt; then
            clean=$((clean + 1)); warn=$((warn + $(grep -c 'warning:' $O/${p:t:r}/err.txt)))
        else
            bad "$n ${p:t}: $(grep -m1 'error:' $O/${p:t:r}/err.txt)"
        fi
    done
    # A warning is a yellow triangle on the iPad: the books ship with none.
    (( warn == 0 )) && ok "$n: $clean/$total pages typecheck, 0 warnings" || bad "$n: $clean/$total pages typecheck, but with $warn warnings"
done

# Mac harness: the book's own engine files + the test harness.
print "== Mac harness (each book's own engine sources)"
for b in $BOOK $KEY; do
    n=${b:t:r}; M=$OUT/mac/${n// /-}; mkdir -p $M
    S=$b/Contents/Modules/GameAPI.playgroundmodule/Sources
    sources=(${S}/*.swift); sources=(${sources:#*/Engine.swift}); sources=(${sources:#*/Audio.swift})
    xcrun swiftc -O -swift-version 5 -parse-as-library -emit-library -emit-module -module-name GameAPI \
        -emit-module-path $M/GameAPI.swiftmodule -o $M/libGameAPI.dylib \
        $sources $HERE/Headless.swift $HERE/Autopilot.swift || { bad "$n: Mac build"; continue; }
    for p in $b/Contents/Chapters/*/Pages/*.playgroundpage; do
        grep -q '//#-hidden-code' $p/main.swift || continue   # README: no code
        d=$M/${p:t:r}; mkdir -p $d
        { cat $p/main.swift; echo; echo "runHarness()"; } > $d/main.swift
        if ! xcrun swiftc -O -swift-version 5 -I $M -L $M -lGameAPI -Xlinker -rpath -Xlinker $M $d/main.swift -o $d/run 2> $d/err.txt; then
            bad "$n ${p:t}: does not compile"; continue
        fi
        SEEDS=10 SECONDS=60 ALLSEEDS=1 perl -e 'alarm 600; exec @ARGV' $d/run > $d/log.txt 2>&1
        checks=$(sed -n 's/^  RESULT checks=//p' $d/log.txt); botr=$(sed -n 's/^  RESULT bot=\([0-9]*\/[0-9]*\).*/\1/p' $d/log.txt)
        hint=$(sed -n 's/^  RESULT hint=//p' $d/log.txt)
        line="$n ${(r:20:)p:t:r} checks $checks  bot $botr"
        if [[ $b == $BOOK ]]; then
            if [[ ${p:t:r} == DesignYourOwnGame ]]; then [[ ${botr%/*} -gt 0 ]] && ok "$line" || bad "$line"
            elif [[ $checks == *❌* && ${botr%/*} == 0 ]]; then ok "$line  (hidden hint: ${hint[1,50]})"
            else bad "$line (a student page should fail a check)"; fi
        else
            if [[ $checks != *❌* && ${botr%/*} -gt 0 ]]; then ok "$line"; else bad "$line (an answer key page should pass and complete)"; fi
        fi
    done
done

# The posters must be up to date: redraw all of them with make-posters.sh (titles from the page
# manifests) and compare with the repo's posters (which the books ship, see above).
print "== posters"
rm -rf $OUT/posters; mkdir -p $OUT/posters
cp -R $SOURCES/${^CHAPTERS}.playgroundchapter $OUT/posters/
find $OUT/posters -name poster.png -delete
TMPDIR=$OUT zsh $REPO/GameModules/Tools/make-posters.sh $OUT/posters > /dev/null || bad "make-posters failed"
nposters=0
for p in $OUT/posters/*/Pages/*/PrivateResources/poster.png(N); do
    nposters=$((nposters + 1))
    cmp -s $p $SOURCES/${p#$OUT/posters/} || bad "poster out of date: ${p#$OUT/posters/} (run GameModules/Tools/make-posters.sh)"
done
(( nposters == 23 )) && ok "23 posters are up to date" || bad "redrew $nposters posters, expected 23"

# The other books must not ship GameAPI.
print "== other books"
for b in $PRODUCTS/*.playgroundbook(N); do
    [[ $b == $BOOK || $b == $KEY ]] && continue
    if [[ -e $b/Contents/Modules/GameAPI.playgroundmodule ]] || grep -rqs 'GameAPI' $b/Contents/Modules $b/Contents/Manifest.plist; then
        bad "${b:t} contains GameAPI"
    elif plist $b Chapters | grep -qE "(${(j:|:)CHAPTERS})\.playgroundchapter"; then
        bad "${b:t} lists a Game Design chapter: $(plist $b Chapters)"
    else
        ok "${b:t}: no GameAPI. Chapters listed: $(plist $b Chapters | sed 's/Array { //; s/ }//; s/\.playgroundchapter//g'). Modules: $(ls $b/Contents/Modules | sed 's/\.playgroundmodule//' | tr '\n' ' ')- chapter folders shipped: $(ls $b/Contents/Chapters | sed 's/\.playgroundchapter//; s/Chapter//' | tr '\n' ' ')"
    fi
done

print
if (( problems )); then print "NOT AS EXPECTED: $problems problem(s)"; exit 1; fi
print "ALL AS EXPECTED"
