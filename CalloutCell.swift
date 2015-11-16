//
//  CalloutCell.swift
//  PhishTour
//
//  Created by Aaron Justman on 10/30/15.
//  Copyright © 2015 AaronJ. All rights reserved.
//

import UIKit

class CalloutCell: UIView
{
    var dateLabel: UILabel!
    var yearLabel: UILabel!
    var venueLabel: UILabel!
    var cityLabel: UILabel!
    var setlistButton = UIButton(type: .Custom)
    
    var cellNumber: Int!
    var show: PhishShow!
    
    static var cellWidth: CGFloat!
    static var cellHeight: CGFloat = 45
    
    var delegate: CalloutCellDelegate?
    
    init()
    {
        let cellFrame = CGRect(x: 0, y: 0, width: 300, height: 45)
        super.init(frame: cellFrame)
        
        self.dateLabel = UILabel()
        self.yearLabel = UILabel()
        self.venueLabel = UILabel()
        self.cityLabel = UILabel()
        
        self.addSubview(self.dateLabel)
        self.addSubview(self.yearLabel)
        self.addSubview(self.venueLabel)
        self.addSubview(self.cityLabel)
        self.addSubview(self.setlistButton)
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews()
    {
        /// set the look and frames of all the labels
        self.dateLabel.font = UIFont(name: "AppleSDGothicNeo-SemiBold", size: 16)
        self.dateLabel.sizeToFit()
        self.dateLabel.frame = CGRect(x: 7, y: 7, width: self.dateLabel.bounds.width, height: self.dateLabel.bounds.height)
        
        self.yearLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 18)
        self.yearLabel.sizeToFit()
        self.yearLabel.frame = CGRect(x: self.dateLabel.frame.origin.x + self.dateLabel.bounds.width + 5, y: self.dateLabel.frame.origin.y - 1.25, width: self.yearLabel.bounds.width, height: self.yearLabel.bounds.height)
        
        self.venueLabel.font = UIFont(name: "Apple SD Gothic Neo", size: 11)
        self.venueLabel.sizeToFit()
        self.venueLabel.frame = CGRect(x: 7, y: self.dateLabel.frame.origin.y + self.dateLabel.bounds.height + 5, width: self.venueLabel.bounds.width, height: self.venueLabel.bounds.height)
        
        self.cityLabel.font = UIFont(name: "Apple SD Gothic Neo", size: 11)
        self.cityLabel.sizeToFit()
        self.cityLabel.frame = CGRect(x: self.venueLabel.frame.origin.x + self.venueLabel.bounds.width + 5, y: self.venueLabel.frame.origin.y, width: self.cityLabel.bounds.width, height: self.cityLabel.bounds.height)
        
        /// get the button to be the right size
        self.setlistButton.setImage(UIImage(named: "setlistButton"), forState: .Normal)
        self.setlistButton.sizeToFit()
        
        /// find the width of the widest pair of the labels, either the top two or the bottom two,
        /// and calculate the width and height of the cell
        let widerPair = ((self.dateLabel.bounds.width + self.yearLabel.bounds.width) > (self.venueLabel.bounds.width + self.cityLabel.bounds.width)) ? (self.dateLabel.bounds.width + self.yearLabel.bounds.width) : (self.venueLabel.bounds.width + self.cityLabel.bounds.width)
        let width = 7 + widerPair + 25 + self.setlistButton.bounds.width + 12
        let height = 7 + self.yearLabel.bounds.height + 5 + self.venueLabel.bounds.height + 2
        
        CalloutCell.cellWidth = width
        CalloutCell.cellHeight = height
        
        /// use the width and height values to set the cell's frame 
        self.frame = CGRect(x: 0, y: CalloutCell.cellHeight * CGFloat(self.cellNumber), width: CalloutCell.cellWidth, height: CalloutCell.cellHeight)
        
        /// finally, set the setlist button to the right of the widest pair of labels and midway from top to bottom
        self.setlistButton.frame = CGRect(x: self.cityLabel.frame.origin.x + self.cityLabel.bounds.width + 25, y: (CalloutCell.cellHeight / 2) - (self.setlistButton.bounds.height / 2), width: self.setlistButton.bounds.width, height: self.setlistButton.bounds.height)
        self.setlistButton.addTarget(self, action: "seeSetlist", forControlEvents: .TouchUpInside)
    }
    
    /// create a "gradient" effect on callouts with multiple shows by making them successively grayer
    func setBackgroundColor()
    {
        let grayFactor = CGFloat(0.05 * Double(cellNumber))
        let bgColor = UIColor(red: 1.0 - grayFactor, green: 1.0 - grayFactor, blue: 1.0 - grayFactor, alpha: 1.0)
        
        self.backgroundColor = bgColor
    }
    
    func seeSetlist()
    {
        guard self.delegate != nil
        else
        {
            print("The CalloutCell delegate isn't set!!!")
            
            return
        }
        
        delegate!.didPressSetlistButton(self)
    }
}

protocol CalloutCellDelegate
{
    func didPressSetlistButton(cell: CalloutCell)
}
