func playerGotHurt() {
    game.showMessage("Ouch!")
}

// The game's update script. Runs 60 times a second, after every other script.
func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
    game.showText("💥 " + String(game.deaths))
}

func startPlayer(player: Player) {
    game.deaths += 1
}
