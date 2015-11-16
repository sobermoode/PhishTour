//
//  CalloutCellView.swift
//  PhishTour
//
//  Created by Aaron Justman on 9/25/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class CalloutCellView: UIView
{
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clearColor()
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addCells(cells: [CalloutCell]!)
    {
        for currentCell in cells
        {
            /// add all the cells to the callout
            self.addSubview( currentCell )
        }
        
        /// the callout's width is the same as the cells within it,
        /// the height is equal to the cell height * the number of cells in the callout
        self.frame = CGRect(x: 0.0, y: 0.0, width: CalloutCell.cellWidth, height: CalloutCell.cellHeight * CGFloat(cells.count))
    }
}
