func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
    game.showText("⏱ " + String(game.timer / 60))
}

// Event: runs every frame you touch the 🚩.
func playerTouchedFlag() {
    game.showMessage("🏁 " + String(game.timer / 60) + " seconds!")
    game.win()
}

func startGame(game: Game) {
    game.timer += 1
}
