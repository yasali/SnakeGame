//
//  SnakeGameModel.swift
//  SnakeGame
//
//  Created by Yasir Ali on 2022-07-29.
//

import SwiftUI

class SnakeGameModel: ObservableObject {
    @Published var gameState = GameState.stopped
    @Published var gameResult = GameResult.unknown
    @Published var gameScore: Int = 0
    enum GameState {
        case started
        case stopped
        case paused
    }

    public enum GameResult {
        case unknown
        case lost
        case won
    }

    var numRows: Int
    var numColumns: Int
    @Published var gameBoard: [[GameBlock?]]
    @Published var snake: Block?
    @Published var food: Block?

    var timer: Timer?
    var speed: Double


    init(numRows: Int = 50, numColumns: Int = 20) {
        self.numRows = numRows
        self.numColumns = numColumns
        gameBoard = Array(repeating: Array(repeating: nil, count: numRows), count: numColumns)
        speed = 0.5
        resumeGame()
    }

    func resumeGame() {
        gameState = .started
        gameResult = .unknown
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true, block: runEngine)
    }

    func pauseGame() {
        gameState = .paused
        timer?.invalidate()
    }

    func endGame() {
        gameState = .stopped
        timer?.invalidate()
        snake = nil
        food = nil
    }

    func runEngine(timer: Timer) {
        guard snake != nil else {
            snake = Block.createSnake(numRows: numRows, numColumns: numColumns)
            placeSnake()
            return
        }

        guard food != nil else {
            addFood()
            placeFood()
            return
        }

        gameScore+=1

        if hasCrashedItself() {
            // Game Over
            endGame()
            return
        }

        if !moveSnake() {
            guard let currentSnake = snake else { return }

            if canEatFood() {
                // create and place new food
                addFood()
                placeFood()
                return
            }

            // Update direction
            if currentSnake.direction == .right || currentSnake.direction == .left {
                if currentSnake.origin.row > numRows/2 {
                    // Go Up
                    changeSnakeDirection(newDirection: .down)
                } else {
                    // Go Down
                    changeSnakeDirection(newDirection: .up)
                }
            }

            if currentSnake.direction == .up || currentSnake.direction == .down {
                if currentSnake.origin.column > numColumns/2 {
                    // Go Left
                    changeSnakeDirection(newDirection: .left)
                } else {
                    // Go Right
                    changeSnakeDirection(newDirection: .right)
                }
            }
        }
    }

    func hasCrashedItself() -> Bool {
        guard var currentSnake = snake else { return false }
        var row: Int = 0
        var column: Int = 0
        switch (currentSnake.direction) {
        case .right:
            row = 0
            column = 1
        case .left:
            row = 0
            column = -1
        case .up:
            row = 1
            column = 0
        case .down:
            row = -1
            column = 0
        }

        var hasCrashed = false
        let newSnake = currentSnake.moveBy(row: row, column: column)
        currentSnake.blocks.forEach { block in
            if block.row == newSnake.origin.row && block.column == newSnake.origin.column {
                hasCrashed = true
            }
        }
        return hasCrashed

    }

    func addFood() {
        guard let currentSnake = snake else { return }
        if var currentFood = food {
            gameBoard[currentFood.origin.column][currentFood.origin.row] = nil
            currentFood = Block.createFood(numRows: numRows, numColumns: numColumns, snakeOrigin: currentSnake.origin)
            food = currentFood
        } else {
            food = Block.createFood(numRows: numRows, numColumns: numColumns, snakeOrigin: currentSnake.origin)
        }
    }

    func changeSnakeDirection(newDirection: BlockDirection) {
        guard var currentSnake = snake else { return }
        if currentSnake.direction == newDirection ||
            currentSnake.direction == .right && newDirection == .left ||
            currentSnake.direction == .left && newDirection == .right ||
            currentSnake.direction == .up && newDirection == .down ||
            currentSnake.direction == .down && newDirection == .up {
            return
        }

        currentSnake.direction = newDirection
        snake = currentSnake
    }

    func canEatFood() -> Bool {
        guard var currentSnake = snake else { return false}
        var row: Int = 0
        var column: Int = 0
        switch (currentSnake.direction) {
        case .right:
            row = 0
            column = 1
        case .left:
            row = 0
            column = -1
        case .up:
            row = 1
            column = 0
        case .down:
            row = -1
            column = 0
        }

        var newSnake = currentSnake.moveBy(row: row, column: column)
        guard let currentFood = food else { return false }

        if newSnake.origin.row == currentFood.origin.row &&
            newSnake.origin.column == currentFood.origin.column {
            newSnake.blocks.append(BlockLocation(row: currentFood.origin.row, column: currentFood.origin.column))
            snake = newSnake // think this will not wokr!
            return true
        }

        return false
    }

    func moveSnake() -> Bool {
        guard let currentSnake = snake else { return false}

        switch (currentSnake.direction) {
        case .right:
            return moveSnakeRight()
        case .left:
            return moveSnakeLeft()
        case .up:
            return moveSnakeUp()
        case .down:
            return moveSnakeDown()
        }
    }

    func moveSnakeRight() -> Bool {
        return moveSnake(rowOffset: 0, columnOffset: 1)
    }

    func moveSnakeLeft() -> Bool {
        return moveSnake(rowOffset: 0, columnOffset: -1)
    }

    func moveSnakeUp() -> Bool {
        return moveSnake(rowOffset: 1, columnOffset: 0)
    }

    func moveSnakeDown() -> Bool {
        return moveSnake(rowOffset: -1, columnOffset: 0)
    }

    func moveSnake(rowOffset: Int, columnOffset: Int) -> Bool {
        guard var currentSnake = snake else { return false }

        let newSnake = currentSnake.moveBy(row: rowOffset, column: columnOffset)
        if isValidSnake(testSnake: newSnake) {
            snake = newSnake
            return true
        }
        return false
    }
    func placeSnake() {
        guard let currentSnake = snake else { return }
        currentSnake.blocks.forEach { block in
            gameBoard[block.column][block.row] = GameBlock(blockType: currentSnake.blockType)
        }
    }

    func placeTail() {
        guard let currentSnake = snake else { return }
        currentSnake.blocks.forEach { blockLocation in
            gameBoard[currentSnake.origin.column][currentSnake.origin.row] = GameBlock(blockType: currentSnake.blockType)
        }
    }

    func placeFood() {
        guard let currentFood = food else { return }
        gameBoard[currentFood.origin.column][currentFood.origin.row] = GameBlock(blockType: currentFood.blockType)
    }

    func isValidSnake(testSnake: Block) -> Bool {
        let row = testSnake.origin.row
        if row < 0 || row >= numRows { return false }

        let column = testSnake.origin.column
        if column < 0 || column >= numColumns { return false }

        if gameBoard[testSnake.origin.column][testSnake.origin.row] != nil {
            return false
        }
        return true
    }
}

enum BlockDirection {
    case right
    case left
    case up
    case down
}

struct Block {
    var origin: BlockLocation {
        return blocks.last!
    }
    var blockType: BlockType
    var direction: BlockDirection
    var blocks: [BlockLocation] = []

    mutating func moveBy(row: Int, column: Int) -> Block {
        var blocksToMove = blocks
        if var currentHead = blocksToMove.last {
            currentHead.row = currentHead.row+row
            currentHead.column = currentHead.column+column
            blocksToMove.removeFirst()
            blocksToMove.append(currentHead)
        }
        return Block(blockType: blockType, direction: direction, blocks: blocksToMove)
    }

    static func createSnake(numRows: Int, numColumns: Int) -> Block {
        let blockType = BlockType.snake
        let origin = BlockLocation(row: numRows/2, column: numColumns/2)
        return Block(blockType: blockType, direction: .right, blocks: [origin])
    }

    static func createFood(numRows: Int, numColumns: Int, snakeOrigin: BlockLocation) -> Block {
        let blockType = BlockType.food
        let randomRow = (0...numRows).random(without: [snakeOrigin.row])
        let randomColumn = (0...numColumns).random(without: [snakeOrigin.column])

        let origin = BlockLocation(row: randomRow, column: randomColumn)
        return Block(blockType: blockType, direction: .right, blocks: [origin])
    }
}

struct GameBlock {
    var blockType: BlockType
}

enum BlockType: CaseIterable {
    case snake, food, tail
}

struct BlockLocation {
    var row: Int
    var column: Int
}

extension ClosedRange where Element: Hashable {
    func random(without excluded:[Element]) -> Element {
        let valid = Set(self).subtracting(Set(excluded))
        let random = Int(arc4random_uniform(UInt32(valid.count)))
        return Array(valid)[random]
    }
}
