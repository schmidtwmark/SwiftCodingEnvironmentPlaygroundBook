// The game's start script. Runs once when the game starts, and again when it starts over (after game over, or when you play again after a win).
func startGame(game: Game) {
    game.lives = 3
}

func playerGotHurt() {
    game.deaths += 1
    game.showMessage("Ouch!")
    game.lives -= 1
    if game.lives < 0 {
        game.lose()
    }
}

// The game's update script. Runs 60 times a second, after every other script.
func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
    game.showText("💥 " + String(game.deaths))
    game.showText("❤️ " + String(game.lives))
}
