//
//  SnakeGameView.swift
//  SwiftUILearning
//
//  Created by Yasir Ali on 2022-08-01.
//

import SwiftUI

struct SnakeGameView: View {
    @ObservedObject var viewModel = SnakeGameViewModel()

    var body: some View {
        GeometryReader { (geometry: GeometryProxy) in
            self.drawBoard(boundingRect: geometry.size)
        }
        .gesture(viewModel.getMoveGesture())
    }

    func drawBoard(boundingRect: CGSize) -> some View {
        let columns = self.viewModel.numColumns
        let rows = self.viewModel.numRows
        let blocksize = min(boundingRect.width/CGFloat(columns), boundingRect.height/CGFloat(rows))
        let xoffset = (boundingRect.width - blocksize*CGFloat(columns))/2
        let yoffset = (boundingRect.height - blocksize*CGFloat(rows))/2
        let gameBoard = self.viewModel.gameBoard
        return ZStack {
            ForEach(0...columns-1, id:\.self) { (column:Int) in
                ForEach(0...rows-1, id:\.self) { (row:Int) in
                    Path { path in
                        let x = xoffset + blocksize * CGFloat(column)
                        let y = boundingRect.height - yoffset - blocksize*CGFloat(row+1)

                        let rect = CGRect(x: x, y: y, width: blocksize, height: blocksize)
                        path.addRect(rect)
                    }
                    .fill(gameBoard[column][row].color)
                }
            }
            VStack {
                if viewModel.snakeGameModel.gameState == .stopped {
                    Button("Game Over"){
                        viewModel.snakeGameModel.resumeGame()
                    }
                    .background(.clear)
                }
            }
        }


    }
}

struct SnakeGameView_Previews: PreviewProvider {
    static var previews: some View {
        SnakeGameView()
    }
}
