func startGame(game: Game) {
}

// Event: runs once for every ouch (an enemy, spikes, a fall or player.hurt()).
func playerGotHurt() {
    game.deaths += 1
    game.showMessage("Ouch!")
    game.lives -= 1
    if game.lives == 0 {
        game.lose()
    }
}

// The game's update script. Runs 60 times a second, after every other script.
func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
    game.showText("💥 " + String(game.deaths))
    game.showText("❤️ " + String(game.lives))
}

func startPlayer(player: Player) {
    game.lives = 3
}
