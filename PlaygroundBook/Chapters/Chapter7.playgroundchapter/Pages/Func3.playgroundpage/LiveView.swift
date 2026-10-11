import UIKit
import BookCore
import PlaygroundSupport

PlaygroundPage.current.liveView = RobotLiveViewController(level: .ascii("""
########################
#####1############1#####
#####1########1###1#####
####.1.#1#...#1##.1.####
#>...#..1..#..1...#...*#
########1#####1#########
########1#####1#########
########################
########################
########################
"""), par: 45)
