func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
    game.timer += 1
    game.showText("⏱ " + String(game.timer))
}

// Event: runs every frame you touch the 🚩.
func playerTouchedFlag() {
    game.showMessage("🏁 " + String(game.timer / 60) + " seconds!")
    game.win()
}
