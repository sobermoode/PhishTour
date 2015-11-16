//
//  PhishShow.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 9/30/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit

class PhishShow: NSObject,
    NSCoding, MKAnnotation
{
    var date: String
    var day: Int?
    var month: Int?
    var year: Int
    var venue: String
    var city: String
    var showID: Int
    var consecutiveNights: Int = 1
    var tour: PhishTour?  // being set in PhishTour.associateShows()
    var tourID: Int?
    var setlist: [ Int : [ PhishSong ] ]?
    var totalSongs: Int
    {
        var total: Int = 0
        let keys = self.setlist!.keys
        
        for key in keys
        {
            let songs: [PhishSong] = self.setlist![key]!
            total += songs.count
        }
        
        return total
    }
    
    var filename: String
    {
        return "show\( self.showID )"
    }
    
    var showLatitude, showLongitude: Double?
    var coordinate: CLLocationCoordinate2D
    {
        return CLLocationCoordinate2D(
            latitude: showLatitude!,
            longitude: showLongitude!
        )
    }
    
    override init()
    {
        self.date = ""
        self.year = 9999
        self.venue = ""
        self.city = ""
        self.showID = 0
    }
    
    init(showInfoFromYear showInfo: [String : AnyObject])
    {
        // need to convert the date to a more pleasing form;
        // step 1: get the date, as returned from phish.in
        let date = showInfo["date"] as! String
        
        // step 2: create a date formatter and set the input format;
        // create an NSDate object with the input format
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.dateFromString(date)!
        
        // step 3:
        // set the output date format;
        // create a new string with the reformatted date
        dateFormatter.dateFormat = "MMM dd,"
        let formattedString = dateFormatter.stringFromDate(formattedDate)
        self.date = formattedString
        
        self.year = Int(NSString(string: date).substringToIndex(4))!
        self.venue = showInfo["venue_name"] as! String
        self.city = showInfo["location"] as! String
        self.showID = showInfo["id"] as! Int
    }
    
    init(showInfoFromShow showInfo: [String : AnyObject])
    {
        // format the date and set the property
        let date = showInfo["date"] as! String
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.dateFromString(date)!
        dateFormatter.dateFormat = "MMM dd,"
        let formattedString = dateFormatter.stringFromDate(formattedDate)
        self.date = formattedString
        
        // cast the date string to NSString, extract the first four characters, then cast *that* to an Int
        self.year = Int(NSString(string: date).substringToIndex(4))!
        
        // get to the venue, location, and coordinates, and set the properties
        let venueData = showInfo["venue"] as! [String : AnyObject]
        self.venue = venueData["name"] as! String
        self.city = venueData["location"] as! String
        self.showLatitude = venueData["latitude"] as? Double
        self.showLongitude = venueData["longitude"] as? Double
        
        // set the show's ID and tourID
        self.showID = showInfo["id"] as! Int
        self.tourID = showInfo["tour_id"] as? Int
    }
    
    required init?( coder aDecoder: NSCoder )
    {
        self.date = aDecoder.decodeObjectForKey( "date" ) as! String
        self.year = aDecoder.decodeIntegerForKey( "year" )
        self.venue = aDecoder.decodeObjectForKey( "venue" ) as! String
        self.city = aDecoder.decodeObjectForKey( "city" ) as! String
        self.showID = aDecoder.decodeIntegerForKey( "showID" )
        self.consecutiveNights = aDecoder.decodeIntegerForKey( "consecutiveNights" )
        self.tour = aDecoder.decodeObjectForKey( "tour" ) as? PhishTour
        self.setlist = aDecoder.decodeObjectForKey( "setlist" ) as? [ Int : [ PhishSong ] ]
        self.showLatitude = aDecoder.decodeObjectForKey( "latitude" ) as? Double
        self.showLongitude = aDecoder.decodeObjectForKey( "longitude" ) as? Double
    }
    
    func encodeWithCoder( aCoder: NSCoder )
    {
        aCoder.encodeObject( self.date, forKey: "date" )
        aCoder.encodeInteger( self.year, forKey: "year" )
        aCoder.encodeObject( self.venue, forKey: "venue" )
        aCoder.encodeObject( self.city, forKey: "city" )
        aCoder.encodeInteger( self.showID, forKey: "showID" )
        aCoder.encodeInteger( self.consecutiveNights, forKey: "consecutiveNights" )
        aCoder.encodeObject( self.tour, forKey: "tour" )
        aCoder.encodeObject( self.setlist, forKey: "setlist" )
        aCoder.encodeObject( self.showLatitude, forKey: "latitude" )
        aCoder.encodeObject( self.showLongitude, forKey: "longitude" )
    }
    
    func save()
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory,
            .UserDomainMask,
            true
        )[ 0 ]
        let showPathURL = NSURL( string: documentsPath )!
        let showPath = showPathURL.URLByAppendingPathComponent( self.filename )
        print( "Saving \( self.date ) \( self.year ) to \( showPath )" )
        
        if NSKeyedArchiver.archiveRootObject( self, toFile: showPath.path! )
        {
            return
        }
        else
        {
            print( "There was an error saving \( self.date ) \( self.year ) to the device." )
        }
    }
}
