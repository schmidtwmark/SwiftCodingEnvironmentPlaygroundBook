func playerTouchedFlag() {
    if game.coinsLeft == 0 {
        game.win()
    }
}

// The game's update script. Runs 60 times a second, after every other script.
func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
}
