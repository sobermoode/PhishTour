//
//  PhishYear.swift
//  PhishTour
//
//  Created by Aaron Justman on 10/1/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import CoreData

class PhishYear: NSManagedObject
{
    /// the year
    @NSManaged var year: Int
    
    /// a year is composed of a set of tours
    @NSManaged var tours: [PhishTour]?
    
    /*
    /// filename for the data saved to the device
    var filename: String
    {
        return "year\(self.year)"
    }
    */
    
    /*
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?)
    {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    */
    
    init(year: Int)
    {
        self.year = year
    }
    
    /*
    init(year: Int)
    {
        self.year = year
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        self.year = aDecoder.decodeIntegerForKey("year")
        self.tours = aDecoder.decodeObjectForKey("tours") as? [PhishTour]
    }
    
    func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeInteger(year, forKey: "year")
        aCoder.encodeObject(tours, forKey: "tours")
    }
    
    /// save the year to the device for later retrieval
    func save()
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let yearPathURL = NSURL(string: documentsPath)!
        let yearPath = yearPathURL.URLByAppendingPathComponent(self.filename)
        
        if NSKeyedArchiver.archiveRootObject(self, toFile: yearPath.path!)
        {
            return
        }
        else
        {
            print("There was an error saving \(self.year) to the device.")
        }
    }
    */
}
