// Event: runs every frame you touch the 🚩.
func playerTouchedFlag() {
    if game.coinsLeft == 0 {
        game.showMessage("⭐ " + String(game.score))
        game.win()
    } else {
        game.showMessage("🪙 " + String(game.coinsLeft) + " coins left!")
    }
}

// The game's update script. Runs 60 times a second, after every other script.
func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
}
