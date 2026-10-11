// Event: runs every frame you touch a 🍄. spring is that spring.
func playerTouchedSpring(spring: Spring) {
    player.speedY = 40
    spring.emoji = "🌀"
    game.playSound(.boing)
}
