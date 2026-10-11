// Event: runs once for every ouch (an enemy, spikes, a fall or player.hurt()).
func playerGotHurt(player: Player) {
    game.deaths += 1
    game.showMessage("Ouch!")
}

// The game's update script. Runs 60 times a second, after every other script.
func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
    game.showText("💥 " + String(game.deaths))
}
