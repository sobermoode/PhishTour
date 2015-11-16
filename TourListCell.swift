//
//  TourListCell.swift
//  new phishtour navbar test
//
//  Created by Aaron Justman on 11/1/15.
//  Copyright © 2015 AaronJ. All rights reserved.
//

import UIKit

class TourListCell: UITableViewCell
{
    var show: PhishShow!
    var showNumber: Int!
    var showNumberLabel: UILabel!
    var dateLabel: UILabel!
    var yearLabel: UILabel!
    var venueLabel: UILabel!
    var cityLabel: UILabel!
    var setlistButton: UIButton!
    
    var delegate: TourListCellDelegate?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.showNumberLabel = UILabel()
        self.dateLabel = UILabel()
        self.yearLabel = UILabel()
        self.venueLabel = UILabel()
        self.cityLabel = UILabel()
        self.setlistButton = UIButton(type: .Custom)
        
        self.contentView.addSubview(self.showNumberLabel)
        self.contentView.addSubview(self.dateLabel)
        self.contentView.addSubview(self.yearLabel)
        self.contentView.addSubview(self.venueLabel)
        self.contentView.addSubview(self.cityLabel)
        self.contentView.addSubview(self.setlistButton)
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews()
    {
        self.showNumberLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 14)
        self.showNumberLabel.text = "\(self.showNumber + 1)"
        self.showNumberLabel.sizeToFit()
        self.showNumberLabel.frame = CGRect(x: 5, y: self.contentView.bounds.height - self.showNumberLabel.bounds.height, width: self.showNumberLabel.bounds.width, height: self.showNumberLabel.bounds.height)
        
        self.dateLabel.font = UIFont(name: "AppleSDGothicNeo-SemiBold", size: 16)
        self.dateLabel.sizeToFit()
        self.dateLabel.frame = CGRect(x: 35, y: 7, width: self.dateLabel.bounds.width, height: self.dateLabel.bounds.height)
        
        self.yearLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 18)
        self.yearLabel.sizeToFit()
        self.yearLabel.frame = CGRect(x: self.dateLabel.frame.origin.x + self.dateLabel.bounds.width + 5, y: self.dateLabel.frame.origin.y - 1.25, width: self.yearLabel.bounds.width, height: self.yearLabel.bounds.height)
        
        self.venueLabel.font = UIFont(name: "Apple SD Gothic Neo", size: 11)
        self.venueLabel.sizeToFit()
        self.venueLabel.frame = CGRect(x: self.dateLabel.frame.origin.x, y: CGRectGetMaxY(self.contentView.bounds) - self.venueLabel.bounds.height - 1, width: self.venueLabel.bounds.width, height: self.venueLabel.bounds.height)
        
        self.cityLabel.font = UIFont(name: "Apple SD Gothic Neo", size: 11)
        self.cityLabel.sizeToFit()
        self.cityLabel.frame = CGRect(x: self.venueLabel.frame.origin.x + self.venueLabel.bounds.width + 5, y: self.venueLabel.frame.origin.y, width: self.cityLabel.bounds.width, height: self.cityLabel.bounds.height)
        
        // put the setlist button on the right side of the cell
        self.setlistButton.setImage(UIImage(named: "setlistButton"), forState: .Normal)
        self.setlistButton.sizeToFit()
        self.setlistButton.frame = CGRect(x: CGRectGetMaxX(self.contentView.bounds) - 10 - self.setlistButton.bounds.width, y: (CalloutCell.cellHeight / 2) - (self.setlistButton.bounds.height / 2), width: self.setlistButton.bounds.width, height: self.setlistButton.bounds.height)
        self.setlistButton.addTarget(self, action: "seeSetlist", forControlEvents: .TouchUpInside)
        
        // place the cell within the table view
        self.frame = CGRect(x: 0, y: self.bounds.height * CGFloat(self.showNumber), width: self.bounds.width, height: self.bounds.height)
    }
    
    func seeSetlist()
    {
        print("seeSetlist...")
        guard self.delegate != nil
        else
        {
            print("The TourListCellDelegate isn't set!!!")
            
            return
        }
        
        self.delegate!.didPressSetlistButtonInTourListCell(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

protocol TourListCellDelegate
{
    func didPressSetlistButtonInTourListCell(cell: TourListCell)
}
