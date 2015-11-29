//
//  SongCell.swift
//  PhishTour
//
//  Created by Aaron Justman on 10/16/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class SongCell: UITableViewCell
{
    /// for use with the setlist
    var song: PhishSong!
    // var tourID: Int!
    
    // var otherTourShow: PhishShow?
    
    /// for use with the history
    var performance: PhishSongPerformance!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: .Value1, reuseIdentifier: "songCell")
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}
