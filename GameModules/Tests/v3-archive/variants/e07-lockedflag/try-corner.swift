// Event: runs every frame you touch the 🚩.
func playerTouchedFlag() {
    if game.coinsLeft == 0 {
        game.win()
    } else {
        game.showMessage("🪙 " + String(game.coinsLeft) + " coins left!")
    }
}

func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
    game.showText("🪙 " + String(game.coinsLeft) + " left")
}
