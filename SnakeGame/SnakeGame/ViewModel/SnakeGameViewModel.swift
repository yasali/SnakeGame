//
//  SnakeGameViewModel.swift
//  SnakeGameViewModel
//
//  Created by Yasir Ali on 2022-07-26.
//

import Foundation
import SwiftUI
import Combine

class SnakeGameViewModel: ObservableObject {
    @Published var snakeGameModel = SnakeGameModel()

    var numRows: Int { snakeGameModel.numRows }
    var numColumns: Int { snakeGameModel.numColumns }
    var gameBoard: [[SnakeGameSquare]] {
        var board = snakeGameModel.gameBoard.map { $0.map(convertToSquare) }
        if let snake = snakeGameModel.snake {
            snake.blocks.forEach { block in
                board[block.column][block.row] = SnakeGameSquare(color: Color.white)
            }
        }

        if let snake = snakeGameModel.food {
            board[snake.origin.column][snake.origin.row] = SnakeGameSquare(color: Color.pink)
        }
        return board
    }

    var lastMoveLocation: CGPoint?
    var anyCancellable: AnyCancellable?

    var snake: Block? {
        return snakeGameModel.snake
    }

    init() {
        anyCancellable = snakeGameModel.objectWillChange.sink {
            self.objectWillChange.send()
        }
    }

    func convertToSquare(block: GameBlock?) -> SnakeGameSquare {
        return SnakeGameSquare(color: Color.black)
    }

    // MARK: Functions

    func startGame() {
        snakeGameModel.resumeGame()
    }

    func pauseGame() {
        snakeGameModel.pauseGame()
    }

    func getMoveGesture() -> some Gesture {
        return DragGesture()
        .onChanged(onMoveChanged(value:))
        .onEnded(onMoveEnded(_:))
    }

    func onMoveChanged(value: DragGesture.Value) {
        guard let start = lastMoveLocation else {
            lastMoveLocation = value.location
            return
        }

        let xDiff = value.location.x - start.x
        if xDiff > 10 {
            print("Moving right")
            let _ = snakeGameModel.changeSnakeDirection(newDirection: .right)
            lastMoveLocation = value.location
            return
        }
        if xDiff < -10 {
            print("Moving left")
            let _ = snakeGameModel.changeSnakeDirection(newDirection: .left)
            lastMoveLocation = value.location
            return
        }

        let yDiff = value.location.y - start.y
        if yDiff > 10 {
            print("Moving Down")
            let _ = snakeGameModel.changeSnakeDirection(newDirection: .down)
            lastMoveLocation = value.location
            return
        }
        if yDiff < -10 {
            print("Moving up")
            let _ = snakeGameModel.changeSnakeDirection(newDirection: .up)
            lastMoveLocation = value.location
            return
        }
    }

    func onMoveEnded(_: DragGesture.Value) {
        lastMoveLocation = nil
    }

}

struct SnakeGameSquare {
    var color: Color
}
