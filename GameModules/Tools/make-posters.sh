#!/bin/zsh
# Redraws PrivateResources/poster.png for every Game Design page (Chapter9 and Chapter11-16) that has a
# PosterReference: a square, crop-safe title card with the page's emoji, number and title (see
# make-posters.swift). Run it after renaming, adding or moving a page.
#   Usage: zsh GameModules/Tools/make-posters.sh [Chapters folder]   (default: the book's)
set -e
HERE=${0:A:h}
REPO=${HERE:h:h}
CHAPTERS=${1:-$REPO/PlaygroundBook/Chapters}
OUT=${TMPDIR:-/tmp}/game-posters-$$
mkdir -p $OUT
xcrun swiftc -O -swift-version 5 -parse-as-library -module-name MakePosters $HERE/make-posters.swift -o $OUT/make-posters
$OUT/make-posters $CHAPTERS
rm -rf $OUT
