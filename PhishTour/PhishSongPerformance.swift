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
    @NSManaged var song: PhishSong
    @NSManaged var showID: NSNumber
    @NSManaged var tourID: NSNumber
    @NSManaged var date: String
    @NSManaged var year: NSNumber
}
