// The game's update script. Runs 60 times a second, after every other script.
func updateGame(g: Game) {
    g.showText("⭐ " + String(g.score))
    g.timer += 1
    g.showText("⏱ " + String(g.timer / 60))
}

// Event: runs every frame you touch the 🚩.
func playerTouchedFlag() {
    game.showMessage("🏁 " + String(game.timer / 60) + " seconds!")
    game.win()
}
