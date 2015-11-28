//
//  PhishShow.swift
//  PhishTour
//
//  Created by Aaron Justman on 9/30/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhishShow: NSManagedObject,
    MKAnnotation, NSCoding
{
    /// specific inforamation for the show
    @NSManaged var date: String
    @NSManaged var day: NSNumber?
    @NSManaged var month: NSNumber?
    @NSManaged var year: NSNumber
    @NSManaged var venue: String
    @NSManaged var city: String
    @NSManaged var showID: NSNumber
    @NSManaged var consecutiveNights: NSNumber
    @NSManaged var tour: PhishTour? 
    @NSManaged var tourID: NSNumber?
    
    /// a show consists of sets of songs (the "setlist")
    @NSManaged var songs: [PhishSong]?
    var setlist: [Int : [PhishSong]]?
    {
        if self.songs?.count == 0
        {
            return nil
        }
        else
        {
            /// create the setlist by creating new PhishSong objects for each song
            var set = [PhishSong]()
            var setlist = [Int : [PhishSong]]()
            var currentSet: Int = 1                        
            var previousSet: Int = currentSet
            for (index, song) in self.songs!.enumerate()
            {
                /// add the first song
                guard index != 0
                else
                {
                    set.append(song)
                    previousSet = song.set.integerValue
                    
                    /// maybe there's only one song
                    if index == self.songs!.count - 1
                    {
                        setlist.updateValue(set, forKey: currentSet)
                    }
                    
                    continue
                }
                
                /// we're still in the same set, so add a new song to the set array
                if song.set.integerValue == previousSet
                {
                    set.append(song)
                    previousSet = song.set.integerValue
                    
                    /// update the setlist if we're at the last song
                    if index == self.songs!.count - 1
                    {
                        setlist.updateValue(set, forKey: currentSet)
                    }
                    
                    continue
                }
                /// we got to the start of the next set or encore
                else
                {
                    /// update the setlist with the complete set
                    setlist.updateValue(set, forKey: currentSet)
                    
                    /// update the current set
                    currentSet = song.set.integerValue
                    
                    /// blank the set array, so we can start over with a new set
                    /// and add that first song to it
                    set.removeAll(keepCapacity: false)
                    set.append(song)
                    
                    /// update the setlist if we're at the last song
                    if index == self.songs!.count - 1
                    {
                        setlist.updateValue(set, forKey: currentSet)
                    }
                    /// otherwise, remember which set we're in
                    else
                    {
                        previousSet = song.set.integerValue
                    }
                }
            }
            
            return setlist
        }
    }
    
    /// location information for the show
    @NSManaged var showLatitude: NSNumber
    @NSManaged var showLongitude: NSNumber
    var coordinate: CLLocationCoordinate2D
    {
        return CLLocationCoordinate2D(
            latitude: Double(showLatitude),
            longitude: Double(showLongitude)
        )
    }
    
    /*
    private var months: [String : Int] =
    [
        "Jan" : 1,
        "Feb" : 2,
        "Mar" : 3,
        "Apr"
    ]
    */
    
    /// description
    /*
    override var description: String
    {
        return "\(self.date) \(self.year)"
    }
    */
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?)
    {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    /// shows are initialized from different requests, which all provide different information;
    /// in this case, we need a default show object, which will get specific information later
    /*
    init()
    {
        /// insert the object into the core data context
        let context = CoreDataStack.sharedInstance().managedObjectContext
        let showEntity = NSEntityDescription.entityForName("PhishShow", inManagedObjectContext: context)!
        super.init(entity: showEntity, insertIntoManagedObjectContext: context)
        
        /// set some default values
        self.date = ""
        self.year = 9999
        self.venue = ""
        self.city = ""
        self.showID = 0
    }
    */
    
    init(showInfoFromYear showInfo: [String : AnyObject])
    {
        /// insert the object into the core data context
        let context = CoreDataStack.sharedInstance().managedObjectContext
        let showEntity = NSEntityDescription.entityForName("PhishShow", inManagedObjectContext: context)!
        super.init(entity: showEntity, insertIntoManagedObjectContext: context)
        
        /// need to convert the date to a more pleasing form;
        /// step 1: get the date, as returned from phish.in
        let date = showInfo["date"] as! String
        
        /// step 2: create a date formatter and set the input format;
        /// create an NSDate object with the input format
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.dateFromString(date)!
        
        /// step 3:
        /// set the output date format;
        /// create a new string with the reformatted date
        dateFormatter.dateFormat = "MMM dd,"
        let formattedString = dateFormatter.stringFromDate(formattedDate)
        self.date = formattedString
        
        /// set the day/month/year
        let datePieces = date.componentsSeparatedByString("-")
        self.year = NSNumber(integer: Int(datePieces[0])!)
        self.month = NSNumber(integer: Int(datePieces[1])!)
        self.day = NSNumber(integer: Int(datePieces[2])!)
        
        // self.year = Int(NSString(string: date).substringToIndex(4))!
        self.venue = showInfo["venue_name"] as! String
        self.city = showInfo["location"] as! String
        self.showID = showInfo["id"] as! Int
    }
    
    func updateProperties(showInfoFromYear showInfo: [String : AnyObject])
    {
        /// need to convert the date to a more pleasing form;
        /// step 1: get the date, as returned from phish.in
        let date = showInfo["date"] as! String
        
        /// step 2: create a date formatter and set the input format;
        /// create an NSDate object with the input format
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.dateFromString(date)!
        
        /// step 3:
        /// set the output date format;
        /// create a new string with the reformatted date
        dateFormatter.dateFormat = "MMM dd,"
        let formattedString = dateFormatter.stringFromDate(formattedDate)
        self.date = formattedString
        
        /// set the day/month/year
        let datePieces = date.componentsSeparatedByString("-")
        self.year = NSNumber(integer: Int(datePieces[0])!)
        self.month = NSNumber(integer: Int(datePieces[1])!)
        self.day = NSNumber(integer: Int(datePieces[2])!)
        
        // self.year = Int(NSString(string: date).substringToIndex(4))!
        self.venue = showInfo["venue_name"] as! String
        self.city = showInfo["location"] as! String
        self.showID = showInfo["id"] as! Int
    }
    
    init(showInfoFromShow showInfo: [String : AnyObject])
    {
        /// insert the object into the core data context
        let context = CoreDataStack.sharedInstance().managedObjectContext
        let showEntity = NSEntityDescription.entityForName("PhishShow", inManagedObjectContext: context)!
        super.init(entity: showEntity, insertIntoManagedObjectContext: context)
        
        /// format the date and set the property
        let date = showInfo["date"] as! String
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.dateFromString(date)!
        dateFormatter.dateFormat = "MMM dd,"
        let formattedString = dateFormatter.stringFromDate(formattedDate)
        self.date = formattedString
        
        /// set the day/month/year
        let datePieces = date.componentsSeparatedByString("-")
        self.year = NSNumber(integer: Int(datePieces[0])!)
        self.month = NSNumber(integer: Int(datePieces[1])!)
        self.day = NSNumber(integer: Int(datePieces[2])!)
        
        /*
        /// cast the date string to NSString, extract the first four characters, then cast *that* to an Int
        self.year = Int(NSString(string: date).substringToIndex(4))!
        */
        
        /// get to the venue, location, and coordinates, and set the properties
        let venueData = showInfo["venue"] as! [String : AnyObject]
        self.venue = venueData["name"] as! String
        self.city = venueData["location"] as! String
        if let latitude = venueData["latitude"] as? Double
        {
            self.showLatitude = latitude
        }
        else
        {
            print("Couldn't set the latitude for \(self.date), \(self.year)")
        }
        if let longitude = venueData["longitude"] as? Double
        {
            self.showLongitude = longitude
        }
        else
        {
            print("Couldn't set the longitude for \(self.date), \(self.year)")
        }
        
        /// set the show's ID and tourID
        self.showID = showInfo["id"] as! Int
        self.tourID = showInfo["tour_id"] as? Int
    }
    
    func createDate(date: String)
    {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.dateFromString(date)!
        dateFormatter.dateFormat = "MMM dd,"
        let formattedString = dateFormatter.stringFromDate(formattedDate)
        self.date = formattedString
    }
    
    /// PhishShow objects are archived as part of a PhishSong history
    required init?(coder aDecoder: NSCoder)
    {
        let context = CoreDataStack.sharedInstance().managedObjectContext
        let showEntity = NSEntityDescription.entityForName("PhishShow", inManagedObjectContext: context)!
        super.init(entity: showEntity, insertIntoManagedObjectContext: context)
        
        self.date = aDecoder.decodeObjectForKey("date") as! String
        self.day = aDecoder.decodeObjectForKey("day") as? NSNumber
        self.month = aDecoder.decodeObjectForKey("month") as? NSNumber
        self.year = aDecoder.decodeObjectForKey("year") as! NSNumber
        self.venue = aDecoder.decodeObjectForKey("venue") as! String
        self.city = aDecoder.decodeObjectForKey("city") as! String
        self.showID = aDecoder.decodeObjectForKey("showID") as! NSNumber
        self.consecutiveNights = aDecoder.decodeObjectForKey("consecutiveNights") as! NSNumber
        self.tour = aDecoder.decodeObjectForKey("tour") as? PhishTour
        self.tourID = aDecoder.decodeObjectForKey("tourID") as? NSNumber
        self.songs = aDecoder.decodeObjectForKey("songs") as? [PhishSong]
        self.showLatitude = aDecoder.decodeObjectForKey("latitude") as! NSNumber
        self.showLongitude = aDecoder.decodeObjectForKey("longitude") as! NSNumber
    }
    
    func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(self.date, forKey: "date")
        aCoder.encodeObject(self.day, forKey: "day")
        aCoder.encodeObject(self.month, forKey: "month")
        aCoder.encodeObject(self.year, forKey: "year")
        aCoder.encodeObject(self.venue, forKey: "venue")
        aCoder.encodeObject(self.city, forKey: "city")
        aCoder.encodeObject(self.showID, forKey: "showID")
        aCoder.encodeObject(self.consecutiveNights, forKey: "consecutiveNights")
        aCoder.encodeObject(self.tour, forKey: "tour")
        aCoder.encodeObject(self.tourID, forKey: "tourID")
        aCoder.encodeObject(self.songs, forKey: "songs")
        aCoder.encodeObject(self.showLatitude, forKey: "latitude")
        aCoder.encodeObject(self.showLongitude, forKey: "longitude")
    }
}
