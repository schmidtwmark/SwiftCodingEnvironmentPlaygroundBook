func playerTouchedFlag(flag: Thing) {
    game.win()
}

// The game's update script. Runs 60 times a second, after every other script.
func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
}
