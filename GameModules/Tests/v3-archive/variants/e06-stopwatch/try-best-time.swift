var bestTime = 0

// The game's update script. Runs 60 times a second, after every other script.
func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
    game.timer += 1
    game.showText("⏱ " + String(game.timer / 60))
    game.showText("🏆 " + String(bestTime))
}

// Event: runs every frame you touch the 🚩.
func playerTouchedFlag() {
    if bestTime == 0 {
        bestTime = game.timer / 60
    } else if game.timer / 60 < bestTime {
        bestTime = game.timer / 60
    }
    game.showMessage("🏁 " + String(game.timer / 60) + " seconds!")
    game.win()
}
