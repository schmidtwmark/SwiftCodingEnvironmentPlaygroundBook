func playerTouchedFlag() {
    if game.coinsLeft == 0 {
        if game.enemiesLeft == 0 {
            game.win()
        } else {
            game.showMessage("Squish every enemy!")
        }
    } else {
        game.showMessage("🪙 " + String(game.coinsLeft) + " coins left!")
    }
}

// The game's update script. Runs 60 times a second, after every other script.
func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
}
