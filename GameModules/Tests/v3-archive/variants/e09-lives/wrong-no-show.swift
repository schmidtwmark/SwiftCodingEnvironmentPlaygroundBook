// The game's start script. Runs once when the game starts, and again when it starts over (after game over, or when you play again after a win).
func startGame(game: Game) {
    game.lives = 3
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

func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
    game.showText("💥 " + String(game.deaths))
}
