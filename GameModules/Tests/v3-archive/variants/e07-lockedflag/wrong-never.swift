func playerTouchedFlag() {
    if game.coinsLeft == 10 {
        game.win()
    } else {
        game.showMessage("🪙 " + String(game.coinsLeft) + " coins left!")
    }
}

// The game's update script. Runs 60 times a second, after every other script.
func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
}
