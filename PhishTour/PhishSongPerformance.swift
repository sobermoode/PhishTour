//
//  PhishSongPerformance.swift
//  PhishTour
//
//  Created by Aaron Justman on 11/28/15.
//  Copyright © 2015 AaronJ. All rights reserved.
//

import UIKit
import CoreData

class PhishSongPerformance: NSManagedObject
{
    /// the song the performance is related to
    @NSManaged var song: PhishSong
    
    /// show info for this performance
    @NSManaged var showID: NSNumber
    @NSManaged var date: String
    @NSManaged var year: NSNumber
    
    /// that show's tour info
    @NSManaged var tourID: NSNumber?
    @NSManaged var tourName: String?
}
