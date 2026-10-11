#!/bin/zsh
# Tests for the Game Design book (Chapter9 and Chapter11-16 + GameModules/GameAPI). See README.md.
#
#   zsh GameModules/Tests/run-tests.sh              both parts below
#   zsh GameModules/Tests/run-tests.sh mac [text]   (a) Mac harness only; text picks versions, e.g. 09-crab
#   zsh GameModules/Tests/run-tests.sh ios          (b) iPad typecheck only
#   zsh GameModules/Tests/run-tests.sh prose        only the chain and prose checks (seconds, no engine build)
#
# Every mode first runs `chain.py check` (every page is the chain's code: GameModules/Tools/chain.py)
# and the prose check (check-prose.py): no page's prose, Hints page or README shows a line of an
# answer or a piece of one; every code page's card is short (Your turn, Your tools) and ends with its
# Stuck line; every Part with code ends with its prose-only Hints page, with 3 hints per page.
#
# (a) Runs the engine rule tests (EngineRules.swift). Then builds GameAPI for the Mac (every engine
#     file except the iPad-only Engine.swift and Audio.swift, + Headless.swift + Autopilot.swift) and
#     runs every page version: its checks (✅/❌, and the first failing check's hint, which the
#     student never sees but which tells the mistakes apart), the bot on the real level (SEEDS seeds of
#     60 s), and FUZZ random-input runs for each starter and wrong-* version (not Design Your Own
#     Game). On Busy Bees the solution also runs BEEWINDOW, Mark's bee-spacing targets. The starter and the solution
#     are read from the pages exactly as inject_solutions.sh ships them (student page, and answer-key
#     page); the other versions are variants/<slug>/*.swift under the page's real hidden code.
#     check-results.py compares everything with expected.tsv. (There is no hint check since v6: the
#     header above the game shows no hints, only ✅ / ❌, a short status and "Can't find:" lines.)
# (b) Typechecks the engine for iPad (Swift 6 and 5, the book's PlaygroundSupport) and reports its
#     typecheck time (it fails above 1.35 x the v3 engine's, timed right next to it in
#     v3-archive/engine, or if one function body or expression takes over 300 ms), and refuses the
#     symbols the iPad can't see (as inject_solutions.sh step 4 does), then every page as shipped, as the student page and as the answer-key page, every variant, and the compile probes (Swift 5, GameAPI auto-imported,
#     like Swift Playgrounds, with -warn-long-expression-type-checking=200).
#
#     The probes include the first-line rule for all 21 functions: inside `func _startGamePage()` the
#     hidden code names every function by its full name (wire.crab(start: startCrab(crab:), update:
#     updateCrab(crab:))), so a page function with exactly that first line replaces the built-in one,
#     and a missing or different one (a label, the v2 `deltaTime: Double`, another type) still compiles,
#     quietly uses the built-in, and never puts an error or a warning in the hidden code. A function
#     declared twice gets "invalid redeclaration" on the student's own line only.
#
# A page that doesn't exist yet is skipped, with a note, together
# with its variants and expected.tsv rows.
#
# env: JOBS (parallel jobs, default: CPU count)  FUZZ (default 500)  SEEDS (default 10)
#      OUT (work folder, default $TMPDIR/game-design-tests)
#      CHAPTERS, VARIANTS, EXPECTED: other chapter / variant folders and expected.tsv (default: the book's)

SCRIPT=${0:A}
HERE=${SCRIPT:h}
REPO=${HERE:h:h}
SRC=$REPO/GameModules/GameAPI.playgroundmodule/Sources
CHAPTERS=${CHAPTERS:-$REPO/PlaygroundBook/Chapters}
VARIANTS=${VARIANTS:-$HERE/variants}
EXPECTED=${EXPECTED:-$HERE/expected.tsv}
FW=$REPO/SupportingContent/PlaygroundsFrameworks/iphoneos
OUT=${OUT:-${TMPDIR:-/tmp}/game-design-tests}
JOBS=${JOBS:-$(sysctl -n hw.ncpu)}
export OUT HERE SRC FW
# Every page with code: slug, then chapter/folder. (README and the Hints pages have no code.)
PAGE_TABLE=(
    01-walk          Chapter9/Walk
    02-fall          Chapter9/Fall
    03-jump          Chapter9/Jump
    04-coyote        Chapter9/CoyoteTime
    05-coins         Chapter11/Coins
    06-score         Chapter11/ShowTheScore
    07-sounds        Chapter11/Sounds
    08-sparkles      Chapter11/Sparkles
    09-crab          Chapter12/CrabPatrol
    10-bee           Chapter12/BusyBees
    11-ghost         Chapter12/GhostChase
    12-stomp         Chapter12/Stomp
    13-heromoves     Chapter13/HeroMoves
    14-backgrounds   Chapter13/Backgrounds
    15-boing         Chapter14/Boing
    16-starpower     Chapter14/StarPower
    17-fireballs     Chapter14/Fireballs
    18-stopwatch     Chapter15/Stopwatch
    19-deathcounter  Chapter15/DeathCounter
    20-lives         Chapter15/LivesAndGameOver
    21-lockedflag    Chapter15/LockedFlag
    22-level2        Chapter15/Level2
    23-design        Chapter16/DesignYourOwnGame
)
# The typecheck-time gate compares with the v3 engine (the one Mark ran on his iPad, Oct 9 2026),
# timed in turn with this one, so a busy Mac slows both: v4 may take at most this many times as long.
V3_ENGINE=$HERE/v3-archive/engine
TYPECHECK_RATIO_LIMIT=1.35

# Every engine file the Mac can build (all but the iPad-only ones).
mac_sources() {
    local files=(${SRC}/*.swift(N))
    files=(${files:#*/Engine.swift})
    files=(${files:#*/Audio.swift})
    print -l $files
}
page_path() { print -r -- $CHAPTERS/${1%%/*}.playgroundchapter/Pages/${1#*/}.playgroundpage/main.swift; }

# The three awk programs below are copied from inject_solutions.sh.
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
# Answer-key page: the student page up to the end of its prose card, then the solution.
answer_key() {
    strip_solution "$1" | awk '
        /\/\/#-end-hidden-code/ { visible=1 }
        { print }
        visible && /^ \*\/$/ { exit }
    '
    printf '\n%s\n' "$(extract_solution "$1")"
}

# ---------------------------------------------------------------- one version (run by xargs)
if [[ ${1:-} == _mac ]]; then
    d=$2; B=$OUT/mac
    { cat $d/page.swift; echo; echo "runHarness()"; } > $d/main.swift
    if xcrun swiftc -O -swift-version 5 -I $B -L $B -lGameAPI -Xlinker -rpath -Xlinker $B $d/main.swift -o $d/run 2> $d/err.txt; then
        fz=0; bw=()
        [[ ${d:t} == starter || ${d:t} == wrong-* ]] && [[ ${d:h:t} != 23-design ]] && fz=${FUZZ:-500}
        [[ ${d:h:t}/${d:t} == 10-bee/solution ]] && bw=(BEEWINDOW=1)
        env FUZZ=$fz SEEDS=${SEEDS:-10} SECONDS=60 ALLSEEDS=1 $bw perl -e 'alarm 900; exec @ARGV' $d/run > $d/log.txt 2>&1
    fi
    print -n .
    exit 0
fi
if [[ ${1:-} == _ios ]]; then
    f=$2
    if xcrun swiftc -typecheck -sdk $(xcrun --sdk iphoneos --show-sdk-path) -target arm64-apple-ios17.6 -F $FW -I $OUT/ios \
         -swift-version 5 -Xfrontend -import-module -Xfrontend GameAPI $f 2> ${f:r}.err; then
        print -r -- "ok   ${f#$OUT/ios/}  warnings: $(grep -c 'warning:' ${f:r}.err)"
    else
        print -r -- "FAIL ${f#$OUT/ios/}"; grep 'error:' ${f:r}.err | head -3 | sed 's/^/       /'
    fi
    exit 0
fi
if [[ ${1:-} == _probe ]]; then
    # A probe folder: main.swift, expect (ok|error), needle (text the first error must contain), hidden (lines).
    p=$2; f=$p/main.swift
    if xcrun swiftc -typecheck -sdk $(xcrun --sdk iphoneos --show-sdk-path) -target arm64-apple-ios17.6 -F $FW -I $OUT/ios -swift-version 5 \
         -Xfrontend -warn-long-expression-type-checking=200 -Xfrontend -import-module -Xfrontend GameAPI $f 2> $p/err.txt; then got=ok; else got=error; fi
    want=$(<$p/expect); needle=$(<$p/needle); hidden=$(<$p/hidden)
    msg=$(grep -m1 'error:' $p/err.txt | sed 's/^.*error: //')
    warns=$(grep -c 'warning:' $p/err.txt)
    inHidden=$(grep -E "main\.swift:[0-9]+:[0-9]+: (error|warning)" $p/err.txt | awk -F: -v h=$hidden '$2 <= h' | wc -l | tr -d ' ')
    bad=""
    [[ $got != $want ]] && bad="(expected $want)"
    [[ $got == ok && $warns != 0 ]] && bad="$bad ($warns warnings: $(grep -m1 'warning:' $p/err.txt | sed 's/^.*warning: //'))"
    [[ $inHidden != 0 ]] && bad="$bad ($inHidden errors/warnings in the hidden code)"
    [[ -n $needle && $msg != *$needle* ]] && bad="$bad (expected the error to contain \"$needle\")"
    if [[ -z $bad ]]; then print -r -- "ok   probe ${p:t} -> $got${msg:+ [$msg]}"
    else print -r -- "FAIL probe ${p:t} -> $got $bad${msg:+ [$msg]}"; fi
    exit 0
fi

# ---------------------------------------------------------------- page versions
SLUGS=()      # the slugs whose page exists
compose() {
    rm -rf $OUT/src; mkdir -p $OUT/src
    local i slug page header v missing=()
    for (( i = 1; i <= ${#PAGE_TABLE}; i += 2 )); do
        slug=${PAGE_TABLE[i]}; page=$(page_path ${PAGE_TABLE[i+1]})
        if [[ ! -f $page ]]; then missing+=($slug); continue; fi
        SLUGS+=($slug)
        mkdir -p $OUT/src/$slug/{starter,solution}
        strip_solution $page > $OUT/src/$slug/starter/page.swift
        answer_key $page > $OUT/src/$slug/solution/page.swift
        header=$(strip_solution $page | awk '{ print } /\/\/#-end-hidden-code/ { exit }')
        for v in $VARIANTS/$slug/*.swift(N); do
            mkdir -p $OUT/src/$slug/${v:t:r}
            { print -r -- "$header"; cat $v; } > $OUT/src/$slug/${v:t:r}/page.swift
        done
    done
    # expected.tsv rows for pages that exist (the others wait for their page).
    awk -F'\t' -v keep=" ${SLUGS[*]} " '/^#/ || NF < 2 { print; next } { split($1, a, "/"); if (index(keep, " " a[1] " ")) print }' $EXPECTED > $OUT/expected.tsv
    print "pages: ${#SLUGS} found in ${CHAPTERS}${missing:+; not there yet (skipped): ${missing[*]}}"
    local all=($OUT/src/*/*(/))
    print "page versions: ${#all} (${#SLUGS} starters + ${#SLUGS} solutions, $(( ${#all} - 2 * ${#SLUGS} )) variants)"
}

# The first-line rule at run time, for all 21 functions: a page whose functions have exactly the
# engine's first lines runs its own (0 built-ins); one with other labels, the v2 `deltaTime: Double`
# or no functions at all runs every built-in (21). Every page uses the same hidden code.
wiring() {
    local B=$OUT/mac W=$OUT/mac/wiring header kind code got want wfails=0
    local headerPage=$(page_path ${PAGE_TABLE[${PAGE_TABLE[(i)${SLUGS[1]}]} + 1]})
    header=$(strip_solution $headerPage | awk '{ print } /\/\/#-end-hidden-code/ { exit }')
    rm -rf $W; mkdir -p $W
    local exact='func startPlayer(player: Player) { }
func updatePlayer(player: Player) { }
func startGame(game: Game) { }
func updateGame(game: Game) { }
func startCrab(crab: Crab) { }
func updateCrab(crab: Crab) { }
func startBee(bee: Bee) { }
func updateBee(bee: Bee) { }
func startGhost(ghost: Ghost) { }
func updateGhost(ghost: Ghost) { }
func startFrog(frog: Frog) { }
func updateFrog(frog: Frog) { }
func startFireball(fireball: Fireball) { }
func updateFireball(fireball: Fireball) { }
func playerTouchedCoin(coin: Coin) { }
func playerTouchedEnemy(enemy: Enemy) { }
func playerTouchedFlag() { }
func playerTouchedSpring(spring: Spring) { }
func playerTouchedStar(star: Star) { }
func fireballTouchedEnemy(fireball: Fireball, enemy: Enemy) { }
func playerGotHurt() { }'
    local labels=$(print -r -- $exact | sed -E 's/\(([a-z]+): /(the\1: /; s/, ([a-z]+): /, the\1: /; s/^func (playerTouchedFlag|playerGotHurt)\(\)/func \1(n: Int)/')
    local v2=$(print -r -- $exact | sed -E '/\(\)/!s/: ([A-Z][a-z]+)\) \{/: \1, deltaTime: Double) {/; s/\(\)/(deltaTime: Double)/')
    for kind in exact labels v2 none; do
        case $kind in
            exact) code=$exact; want=0 ;;
            labels) code=$labels; want=21 ;;
            v2) code=$v2; want=21 ;;
            none) code='let nothing = 0'; want=21 ;;
        esac
        { print -r -- "$header"; print -r -- "$code"; print; print "runWiringProof()"; } > $W/$kind.swift
        if xcrun swiftc -O -swift-version 5 -I $B -L $B -lGameAPI -Xlinker -rpath -Xlinker $B $W/$kind.swift -o $W/$kind 2> $W/$kind.err; then
            got=$($W/$kind | sed -n 's/^  RESULT builtins=\([0-9]*\).*/\1/p')
        else
            got="no build: $(grep -m1 error: $W/$kind.err)"
        fi
        if [[ $got == $want ]]; then print "ok   wiring: $kind first lines -> $got of 21 functions use the built-in"
        else print "FAIL wiring: $kind first lines -> $got (expected $want)"; wfails=$((wfails + 1)); fi
    done
    (( wfails == 0 ))
}

mac() {
    local pat=${1:-} B=$OUT/mac
    rm -rf $B; mkdir -p $B
    local sources=($(mac_sources))
    print "== (a) Mac harness: engine rules (EngineRules.swift)"
    xcrun swiftc -swift-version 5 -parse-as-library -module-name GameAPI -o $B/engine-rules \
        $sources $HERE/Headless.swift $HERE/Autopilot.swift $HERE/EngineRules.swift || exit 1
    $B/engine-rules > $OUT/engine-rules.log 2>&1
    local rules=$?
    grep -v '^ok' $OUT/engine-rules.log
    print "engine rules: $(grep -c '^ok' $OUT/engine-rules.log) ok (full list: $OUT/engine-rules.log)"
    print "== (a) Mac harness: building GameAPI for the Mac (${#sources} engine files)"
    xcrun swiftc -O -swift-version 5 -parse-as-library -emit-library -emit-module -module-name GameAPI \
        -emit-module-path $B/GameAPI.swiftmodule -o $B/libGameAPI.dylib \
        $sources $HERE/Headless.swift $HERE/Autopilot.swift || exit 1
    wiring || rules=1
    local dirs=() d
    for d in $OUT/src/*/*(/); do
        [[ -n $pat && ${d:h:t}/${d:t} != *$pat* ]] && rm -rf $d && continue
        dirs+=($d)
    done
    print "running ${#dirs} page versions, $JOBS at a time (FUZZ=${FUZZ:-500}, SEEDS=${SEEDS:-10})"
    # The slowest versions first, so they don't finish last.
    { print -l $dirs | grep -e '10-bee/solution$'; print -l $dirs | grep -v -e '10-bee/solution$'; } | xargs -P $JOBS -I{} zsh $SCRIPT _mac {}
    print
    for d in $dirs; do print "######## ${d:h:t}/${d:t}"; cat $d/log.txt 2>/dev/null || cat $d/err.txt; done > $OUT/mac.log
    print "full log: $OUT/mac.log"
    grep -h 'BEEWINDOW' $OUT/src/10-bee/solution/log.txt 2>/dev/null
    python3 $HERE/check-results.py $OUT/src $OUT/expected.tsv "$pat" | tee $OUT/mac-summary.txt
    local pages=${pipestatus[1]}
    (( rules == 0 && pages == 0 ))
}

ios() {
    local O=$OUT/ios SDK=$(xcrun --sdk iphoneos --show-sdk-path) v n fails=0
    rm -rf $O; mkdir -p $O/pages $O/probes
    print "== (b) iPad typecheck"
    for v in 6 5; do
        if xcrun swiftc -emit-module -module-name GameAPI -emit-module-path $O/GameAPI.swiftmodule -sdk $SDK \
             -target arm64-apple-ios17.6 -F $FW -swift-version $v $SRC/*.swift 2> $O/module$v.err; then
            print "ok   GameAPI engine (all $(ls $SRC/*.swift | wc -l | tr -d ' ') files), Swift $v: $(grep -c 'error:' $O/module$v.err) errors, $(grep -c 'warning:' $O/module$v.err) warnings"
        else
            print "FAIL GameAPI engine, Swift $v"; head -20 $O/module$v.err; return 1
        fi
    done
    # Xcode's SDK can see helpers that Swift Playgrounds on the iPad can't (these failed on a real
    # iPad). The same check as inject_solutions.sh step 4; comments are fine.
    if /usr/bin/grep -nE '^([^/]|/[^/])*\b(UnsafeMutableAudioBufferListPointer|noErr)\b' $SRC/*.swift; then
        print "FAIL GameAPI uses a symbol Swift Playgrounds on the iPad can't see (listed above)"; fails=$((fails + 1))
    else
        print "ok   GameAPI uses no symbol the iPad can't see (UnsafeMutableAudioBufferListPointer, noErr)"
    fi
    # Typecheck time of the engine, best of 3, timed in turn with the v3 engine (so a busy Mac slows
    # both), and any function body or expression over 300 ms (both timings print to stderr). Most of
    # the time is size, not one slow expression; a pathological expression shows up in the 300 ms gate.
    zmodload zsh/datetime
    local best=999.0 best3=999.0 t t0
    for v in 1 2 3; do
        t0=$EPOCHREALTIME
        xcrun swiftc -typecheck -sdk $SDK -target arm64-apple-ios17.6 -F $FW -swift-version 5 $V3_ENGINE/*.swift > /dev/null 2>&1
        t=$(( EPOCHREALTIME - t0 ))
        (( t < best3 )) && best3=$t
        t0=$EPOCHREALTIME
        xcrun swiftc -typecheck -sdk $SDK -target arm64-apple-ios17.6 -F $FW -swift-version 5 $SRC/*.swift > /dev/null 2>&1
        t=$(( EPOCHREALTIME - t0 ))
        (( t < best )) && best=$t
    done
    local ratio=$(printf '%.2f' $(( best / best3 )))
    best=$(printf '%.2f' $best); best3=$(printf '%.2f' $best3)
    xcrun swiftc -typecheck -sdk $SDK -target arm64-apple-ios17.6 -F $FW -swift-version 5 -Xfrontend -debug-time-function-bodies \
        -Xfrontend -debug-time-expression-type-checking $SRC/*.swift > /dev/null 2> $O/timings.txt
    awk -F'ms' '$1 + 0 > 300 { print }' $O/timings.txt > $O/slow-bodies.txt
    local ntimed=$(grep -c 'ms' $O/timings.txt)
    local slowest=$(awk -F'ms' '$1 + 0 > m { m = $1 + 0 } END { printf "%.1f", m }' $O/timings.txt)
    if (( ntimed < 100 )); then
        print "FAIL engine typecheck timings: only $ntimed lines printed"; fails=$((fails + 1))
    elif (( ratio <= TYPECHECK_RATIO_LIMIT )) && [[ ! -s $O/slow-bodies.txt ]]; then
        print "ok   engine typecheck time ${best} s, ${ratio} x the v3 engine's ${best3} s (limit ${TYPECHECK_RATIO_LIMIT} x); slowest of $ntimed function bodies and expressions ${slowest} ms (limit 300)"
    else
        print "FAIL engine typecheck time ${best} s, ${ratio} x the v3 engine's ${best3} s (limit ${TYPECHECK_RATIO_LIMIT} x), slowest function body or expression ${slowest} ms"; cat $O/slow-bodies.txt; fails=$((fails + 1))
    fi
    local i slug page files=()
    for slug in $SLUGS; do
        page=$(page_path ${PAGE_TABLE[${PAGE_TABLE[(i)$slug]} + 1]})
        mkdir -p $O/pages/$slug-{shipped,student,answerkey}
        cp $page $O/pages/$slug-shipped/main.swift
        strip_solution $page > $O/pages/$slug-student/main.swift
        answer_key $page > $O/pages/$slug-answerkey/main.swift
        files+=($O/pages/$slug-{shipped,student,answerkey}/main.swift)
    done
    local nvar=0
    for slug in $SLUGS; do
        page=$(page_path ${PAGE_TABLE[${PAGE_TABLE[(i)$slug]} + 1]})
        for v in $VARIANTS/$slug/*.swift(N); do
            mkdir -p $O/pages/$slug-${v:t:r}
            { strip_solution $page | awk '{ print } /\/\/#-end-hidden-code/ { exit }'; cat $v; } > $O/pages/$slug-${v:t:r}/main.swift
            files+=($O/pages/$slug-${v:t:r}/main.swift)
            nvar=$((nvar + 1))
        done
    done
    print -l $files | xargs -P $JOBS -I{} zsh $SCRIPT _ios {} | sort > $O/pages.log
    n=$(grep -c '^ok' $O/pages.log)
    fails=$((fails + $(grep -c '^FAIL' $O/pages.log)))
    local warns=$(awk '/^ok/ { w += $NF } END { print w + 0 }' $O/pages.log)
    grep -v '^ok' $O/pages.log
    print "pages: $n typecheck clean, $(grep -c '^FAIL' $O/pages.log) failed, $warns warnings in total (${#SLUGS} pages as shipped, as the student page and as the answer key, plus $nvar variants)"
    (( warns > 0 )) && fails=$((fails + 1))

    # Compile probes: friendly errors, code that must still compile, and the first-line rule.
    # Every probe is a real page's hidden code plus the probe's code. "ok" must typecheck with
    # 0 warnings (an expression over 200 ms is a warning); "error" must fail, with every error in
    # the probe's own lines (never in hidden code).
    local headerPage=$(page_path Chapter12/CrabPatrol)
    [[ -f $headerPage ]] || headerPage=$(page_path ${PAGE_TABLE[${PAGE_TABLE[(i)${SLUGS[1]}]} + 1]})
    local header=$(strip_solution $headerPage | awk '{ print } /\/\/#-end-hidden-code/ { exit }')
    local hidden=$(print -r -- "$header" | wc -l | tr -d ' ')
    probe() {  # name, ok|error, code [, text the first error must contain]
        local p=$O/probes/$1
        mkdir -p $p; { print -r -- "$header"; print -r -- "$3"; } > $p/main.swift
        print -r -- $2 > $p/expect; print -r -- "${4:-}" > $p/needle; print -r -- $hidden > $p/hidden
    }
    local walk='if isPressed(.right) { player.speedX = 6 } else if isPressed(.left) { player.speedX = -6 } else { player.speedX = 0 }'
    probe int-literal ok "func updatePlayer(player: Player) { $walk; player.speedY -= 1; game.score += 1; player.x += 2 }"
    probe int-var ok 'var speed = 6
func updatePlayer(player: Player) { player.speedX = speed; player.speedX = -speed; player.x += speed }'
    probe timer-frames ok 'func updateBee(bee: Bee) { if bee.timer < 60 { bee.speedY = 2 } else { bee.speedY = -2 }; bee.timer += 1; if bee.timer == 120 { bee.timer = 0 } }'
    probe game-timer-seconds ok 'func updateGame(game: Game) { game.timer += 1; game.showText("⏱ " + String(game.timer / 60)) }'
    probe flip-minus ok 'func startCrab(crab: Crab) { crab.speedX = -2 }
func updateCrab(crab: Crab) { if crab.facingWall() { crab.speedX = -crab.speedX }; if crab.facingLedge() { crab.speedX = 0 - crab.speedX } }'
    probe double-literal error "func updatePlayer(player: Player) { player.x += 2.5 }" "Game numbers are whole numbers"
    probe double-minus error "func updatePlayer(player: Player) { player.speedY -= 0.5 }" "Game numbers are whole numbers"
    probe double-var error 'var speed = 2.5
func updatePlayer(player: Player) { player.speedX += speed }' "Game numbers are whole numbers"
    probe timer-decimal error "func updateBee(bee: Bee) { bee.timer += 0.5 }" "Game numbers are whole numbers"
    probe game-timer-decimal error "func updateGame(game: Game) { game.timer += 1.5 }" "Game numbers are whole numbers"
    probe deltatime-gone error "func updateBee(bee: Bee) { bee.timer += deltaTime }" "deltaTime"
    probe double-assign error "func updatePlayer(player: Player) { player.speedX = 2.5 }"
    probe join-number error 'func updateGame(game: Game) { game.showText("⭐ " + game.score) }' "String(game.score)"
    probe join-number-first error 'func updateGame(game: Game) { game.showText(game.score + " points") }' "String(game.score)"
    probe join-number-plus-equals error 'func updateGame(game: Game) { var text = "⭐ "; text += game.score; game.showText(text) }' "String(game.score)"
    probe join-literal error 'func updateGame(game: Game) { game.showText("Lives: " + 3) }' "String(game.score)"
    probe showtext-number error 'func updateGame(game: Game) { game.showText(game.score) }' "showText needs text"
    probe showmessage-number error 'func playerGotHurt() { game.showMessage(game.deaths) }' "showMessage needs text"
    probe join-ok ok 'func updateGame(game: Game) { game.showText("⭐ " + String(game.score)); game.showMessage("🪙 " + String(game.coinsLeft) + " coins left!") }'
    probe join-long-chain ok 'func updateGame(game: Game) { game.showText("⭐ " + String(game.score) + "  💥 " + String(game.deaths) + "  ❤️ " + String(game.lives) + "  ⏱ " + String(game.timer / 60) + " s") }'
    probe plain-arithmetic ok 'let a = 1 + 2
let b = "a" + "b" + "c"
func updateGhost(ghost: Ghost) { if player.y + 60 > ghost.y - 10 { ghost.speedY = a - 2 }; game.showText(b) }'
    probe hearts-loop ok 'func updateGame(game: Game) { var hearts = ""; if game.lives > 0 { for _ in 1...game.lives { hearts = hearts + "❤️" } }; game.showText(hearts) }'
    probe numbers-read-only error 'func updateGame(game: Game) { game.coinsLeft = 0 }'
    probe while-compiles ok "func updatePlayer(player: Player) { while isPressed(.right) { player.speedX = 6 } }"
    probe isOnGround-no-parens error "func updatePlayer(player: Player) { if player.isOnGround { player.speedY = 18 } }"
    probe v1-me-gone error "func updateCrab(crab: Crab) { me.speedX = 2 }" "me"
    probe v1-forward-gone error "func updateCrab(crab: Crab) { crab.forward(2) }" "forward"
    probe spring-not-ambiguous ok 'func playerTouchedSpring(spring: Spring) { player.speedY = 25; spring.emoji = "🌀" }
func playerTouchedStar(star: Star) { star.remove(); player.timer = 300 }
var springs: [Spring] = []'
    probe player-is-player ok "func updatePlayer(player: Player) { player.hurt() }
func updateGhost(ghost: Ghost) { if player.x > ghost.x { ghost.speedX = 1 } }
func playerTouchedEnemy(enemy: Enemy) { if player.speedY < 0 { enemy.remove() } else { player.hurt() } }"
    # Effects, Looks, Power-ups and Rules of the Game: sounds, bursts, shakes, backgrounds, spawn, ▼, levels.
    probe sound-ok ok 'func playerTouchedCoin(coin: Coin) { game.score += 1; game.playSound(.coin); coin.burst("✨"); coin.remove(); game.shake(); game.shake(strength: 20) }
func updatePlayer(player: Player) { if player.isOnGround() { game.playSound(.jump); player.burst("💨", count: 6, speed: 2) }; if player.speedX != 0 { player.burst("✨", count: 1, speed: 0) } }'
    probe sound-by-name error 'func playerTouchedCoin(coin: Coin) { game.playSound("coin") }' "Pick a sound with a dot"
    probe sound-volume ok 'game.soundVolume = 60
func playerTouchedCoin(coin: Coin) { game.soundVolume = game.soundVolume - 10; if game.soundVolume < 20 { game.soundVolume = 100 } }'
    probe sound-volume-decimal error 'game.soundVolume = 0.5'
    probe justreleased-gone error 'func updatePlayer(player: Player) { if justReleased(.up) { player.speedY = player.speedY / 2 } }' "justReleased"
    probe sound-without-game error 'func playerTouchedCoin(coin: Coin) { playSound(.coin) }' "Sounds belong to the game"
    probe background-ok ok 'game.background = .night
game.skyColor = .hex("3a7bd5")
game.horizonColor = .hex("ffd194")
game.addLayer("🌲 🌳🌲   🌲🌲 ", y: 64, size: 100, distance: 2)
game.addLayer("⛰️    🏔️      ⛰️  ", y: 0, size: 220, distance: 5)
game.addLayer("🌕               ")
game.weather = "❄️🍂"
game.blockEmoji = "🧱"
game.fireballEmoji = "☄️"'
    probe spawn-ok ok 'func updatePlayer(player: Player) {
    if justPressed(.down) {
        if player.facingRight() { game.spawn(.fireball, x: player.x, y: player.y, speedX: 12, speedY: 0) } else { game.spawn(.fireball, x: player.x, y: player.y, speedX: -12, speedY: 0) }
    }
}
func updateFireball(fireball: Fireball) { fireball.speedY -= 1; if fireball.isOnGround() { fireball.speedY = 8 }; if fireball.facingWall() { fireball.remove() } }
func fireballTouchedEnemy(fireball: Fireball, enemy: Enemy) { game.spawn(.coin, x: enemy.x, y: enemy.y + 64); enemy.remove(); fireball.remove() }
func updateGhost(ghost: Ghost) { ghost.timer += 1; if ghost.timer == 120 { game.spawn(.crab, x: ghost.x, y: ghost.y); ghost.timer = 0 } }'
    probe levels-ok ok 'game.level2 = """
.P..F.
######
"""
game.level3 = ""
func playerTouchedFlag() { if game.levelNumber == 2 { game.win() } else { game.nextLevel() } }
func updateGame(game: Game) { game.showText("Level " + String(game.levelNumber)) }'
    probe levelnumber-read-only error 'func playerTouchedFlag() { game.levelNumber = 2 }'
    probe star-spring-ok ok 'func playerTouchedStar(star: Star) { star.remove(); player.timer = 300; star.burst("✨") }
func playerTouchedSpring(spring: Spring) { player.speedY = 25; spring.emoji = "🌀"; game.playSound(.boing) }
func playerTouchedEnemy(enemy: Enemy) { if player.timer > 0 { enemy.remove() } else if player.speedY < 0 { enemy.remove(); player.speedY = 12 } else { player.hurt() } }'
    probe startgame-game-param ok 'func startGame(game: Game) { game.lives = 3; game.score = 0 }
func playerGotHurt() { game.deaths += 1; game.lives -= 1; if game.lives == 0 { game.lose() } }'
    # The first-line rule, for all 21 functions. For each: exact (the page's runs), left out, a
    # misspelled label, another type, the v2 form (an extra `deltaTime: Double`), and written twice.
    local spec name params other wrong alllines=""
    for spec in \
        'startPlayer|player: Player|p: Player|player: Thing' 'updatePlayer|player: Player|p: Player|player: Thing' \
        'startGame|game: Game|g: Game|game: Thing' 'updateGame|game: Game|g: Game|game: Thing' \
        'startCrab|crab: Crab|c: Crab|crab: Enemy' 'updateCrab|crab: Crab|c: Crab|crab: Enemy' \
        'startBee|bee: Bee|b: Bee|bee: Enemy' 'updateBee|bee: Bee|b: Bee|bee: Enemy' \
        'startGhost|ghost: Ghost|g: Ghost|ghost: Enemy' 'updateGhost|ghost: Ghost|g: Ghost|ghost: Enemy' \
        'startFrog|frog: Frog|f: Frog|frog: Enemy' 'updateFrog|frog: Frog|f: Frog|frog: Enemy' \
        'startFireball|fireball: Fireball|f: Fireball|fireball: Thing' 'updateFireball|fireball: Fireball|f: Fireball|fireball: Thing' \
        'playerTouchedCoin|coin: Coin|c: Coin|coin: Thing' 'playerTouchedEnemy|enemy: Enemy|e: Enemy|enemy: Crab' \
        'playerTouchedFlag||flag: Thing|_ flag: Thing' 'playerTouchedSpring|spring: Spring|s: Spring|spring: Thing' \
        'playerTouchedStar|star: Star|s: Star|star: Thing' 'fireballTouchedEnemy|fireball: Fireball, enemy: Enemy|f: Fireball, e: Enemy|fireball: Fireball, enemy: Crab' \
        'playerGotHurt||player: Player|_ n: Int'; do
        name=${spec%%|*}; spec=${spec#*|}; params=${spec%%|*}; spec=${spec#*|}; other=${spec%%|*}; wrong=${spec#*|}
        alllines+="func $name($params) { }"$'\n'
        probe first-line-$name-label ok "func $name($other) { }"
        probe first-line-$name-type ok "func $name($wrong) { }"
        probe first-line-$name-v2-deltatime ok "func $name(${params:+$params, }deltaTime: Double) { }"
        probe first-line-$name-twice error "func $name($params) { }
func $name($params) { }" "redeclaration"
    done
    probe first-line-all-exact ok "$alllines"
    local one
    for one in ${(f)alllines}; do
        name=${${one#func }%%\(*}
        probe first-line-$name-left-out ok "${alllines/$one$'\n'/}"
    done
    probe first-line-all-left-out ok "let nothing = 0"
    probe first-line-misspelled ok "func updateCrabs(crab: Crab) { crab.speedX = 2 }
func playerGotHurts() { }
func updategame(game: Game) { }"
    probe first-line-v1-names ok "func updatePlayer() { }
func updateCrab() { }
func coinTouchedPlayer() { }
func enemyTouchedPlayer() { }
func flagTouchedPlayer() { }"
    probe first-line-unlabeled ok "func updateCrab(_ crab: Crab) { crab.speedX = 2 }"
    probe first-line-returns ok "func updateCrab(crab: Crab) -> Int { return 2 }"
    probe first-line-both ok "func updateCrab(crab: Crab) { crab.speedX = 2 }
func updateCrab(crab: Enemy) { crab.speedX = 3 }"
    probe first-line-twice-with-other error 'func updateCrab(crab: Crab) { }
func updateCrab(crab: Enemy) { }
func updateCrab(crab: Enemy) { }' "redeclaration"
    print -l $O/probes/*(/) | xargs -P $JOBS -I{} zsh $SCRIPT _probe {} | sort > $O/probes.log
    grep -v '^ok' $O/probes.log
    local pfails=$(grep -c '^FAIL' $O/probes.log)
    print "probes: $(grep -c '^ok' $O/probes.log) as expected, $pfails not (full list: $O/probes.log)"
    [[ $fails == 0 && $pfails == 0 ]]
}

mode=${1:-all}
compose
result=0
# The chain: every page is chain.py's code (hidden code, solution, starter = previous solution + stub).
python3 -I $REPO/GameModules/Tools/chain.py check $CHAPTERS || result=1
# The prose check: the pages' words, the Hints pages and README (reads the page files; no build).
python3 -I $HERE/check-prose.py $CHAPTERS > $OUT/prose.log; prose=$?
grep -v '^ok' $OUT/prose.log; print "(full list: $OUT/prose.log)"
(( prose == 0 )) || result=1
if [[ $mode == all || $mode == mac ]]; then mac ${2:-} || result=1; fi
if [[ $mode == all || $mode == ios ]]; then ios || result=1; fi
exit $result
