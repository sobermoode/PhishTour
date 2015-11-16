//
//  PhishTour.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 9/30/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit

class PhishTour: NSObject,
    NSCoding
{
    var year: PhishYear?
    var name: String
    var tourID: Int
    var shows: [ PhishShow ]
    var uniqueLocations: [ PhishShow ]?
    var locationDictionary: [ String : [ PhishShow ] ]
    
    var showCoordinates: [ CLLocationCoordinate2D ]
    {
        var coordinates = [ CLLocationCoordinate2D ]()
        for show in shows
        {
            coordinates.append( show.coordinate )
        }
        
        return coordinates
    }
    var filename: String
    {
        return "tour\( self.tourID )"
    }
    
    init(
        year: PhishYear,
        name: String,
        tourID: Int,
        shows: [ PhishShow ]
    )
    {
        self.year = year
        self.name = name
        self.tourID = tourID
        self.shows = shows
        self.uniqueLocations = [ PhishShow ]()
        self.locationDictionary = [ String : [ PhishShow ] ]()
    }
    
    init(tourInfo: [String: AnyObject]) 
    {        
        // set the year
        // self.year = PhishModel.sharedInstance().selectedYear
        
        // extract tour name and ID the from the dictionary and set the properties
        self.name = tourInfo["name"] as! String
        self.tourID = tourInfo["id"] as! Int
        
        // set the year
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let yearPathURL = NSURL(string: documentsPath)!
        if let intYear = Int(NSString(string: self.name).substringToIndex(4))
        {
            let yearPath = yearPathURL.URLByAppendingPathComponent("year\(intYear)")
            self.year = NSKeyedUnarchiver.unarchiveObjectWithFile(yearPath.path!) as? PhishYear
        }
        else
        {
            let startDate = tourInfo["starts_on"] as! String
            let year = Int(NSString(string: startDate).substringToIndex(4))!
            let yearPath = yearPathURL.URLByAppendingPathComponent("year\(year)")
            self.year = NSKeyedUnarchiver.unarchiveObjectWithFile(yearPath.path!) as? PhishYear
        }
        
        // create the shows on the tour
        let shows = tourInfo["shows"] as! [[String : AnyObject]]
        var showArray = [PhishShow]()
        for show in shows
        {            
            let newShow = PhishShow(showInfoFromYear: show)
            showArray.append(newShow)
        }
        self.shows = showArray
        
        self.uniqueLocations = [PhishShow]()
        self.locationDictionary = [String : [PhishShow]]()
    }
    
    required init?( coder aDecoder: NSCoder )
    {
        self.year = aDecoder.decodeObjectForKey( "year" ) as? PhishYear
        self.name = aDecoder.decodeObjectForKey( "name" ) as! String
        self.tourID = aDecoder.decodeIntegerForKey( "tourID" )
        self.shows = aDecoder.decodeObjectForKey( "shows" ) as! [ PhishShow ]
        self.uniqueLocations = aDecoder.decodeObjectForKey( "uniqueLocations" ) as? [ PhishShow ]
        self.locationDictionary = aDecoder.decodeObjectForKey( "locationDictionary" ) as! [ String : [ PhishShow ] ]
    }
    
    func encodeWithCoder( aCoder: NSCoder )
    {
        aCoder.encodeObject( year, forKey: "year" )
        aCoder.encodeObject( name, forKey: "name" )
        aCoder.encodeInteger( tourID, forKey: "tourID" )
        aCoder.encodeObject( shows, forKey: "shows" )
        aCoder.encodeObject( uniqueLocations, forKey: "uniqueLocations" )
        aCoder.encodeObject( locationDictionary, forKey: "locationDictionary" )
    }
    
    // set the tour property on all the shows
    func associateShows()
    {
        for show in self.shows
        {
            show.tour = self
            
            show.save()
        }
    }
    
    // this creates a dictionary keyed a venue name, which retuns an array of shows played there during a tour.
    // this is how i accomplished letting the map know when a callout for an annotation at any one location
    // should display info for more than one show
    func createLocationDictionary()
    {
        print( "There are \( shows.count ) shows in the \( name )" )
        var previousShow: PhishShow = shows.first!
        var currentVenue: String = previousShow.venue
        var multiNightRun = [ PhishShow ]()
        var locationDictionary = [ String : [ PhishShow ] ]()
        
        // go through each show and add the to an array. keep adding shows to the array if the venue continues to be the same.
        // when the next venue is reached, set the array as a value for the key of the venue.
        for ( index, show ) in shows.enumerate()
        {
            // it's possible that there's only one show for the tour
            if shows.count == 1
            {
                uniqueLocations!.append( show )
                multiNightRun.append( show )
                
                show.consecutiveNights = multiNightRun.count
                // print( "\( show.date ) has \( multiNightRun.count ) shows." )
                
                locationDictionary.updateValue( multiNightRun, forKey: currentVenue )
                
                self.locationDictionary = locationDictionary
                
                return
            }
            
            // add the first show to the array
            if index == 0
            {
                uniqueLocations!.append( show )
                multiNightRun.append( show )
                
                continue
            }
            else
            {
                // we're still at the current venue, so it's a multi-night run
                if show.venue == previousShow.venue
                {
                    // add the show and remember where we were
                    currentVenue = show.venue
                    multiNightRun.append( show )
                    previousShow = show
                    
                    // if we're at the last show, then add the array to the dictionary
                    if index == shows.count - 1
                    {
                        for aShow in multiNightRun
                        {
                            aShow.consecutiveNights = multiNightRun.count
                        }
                        // print( "\( show.date ) has \( multiNightRun.count ) shows." )
                        
                        locationDictionary.updateValue( multiNightRun, forKey: currentVenue )
                    }
                    
                    continue
                }
                else
                {
                    // there's a new location
                    uniqueLocations!.append( show )
                    
                    for aShow in multiNightRun
                    {
                        aShow.consecutiveNights = multiNightRun.count
                    }
                    // print( "\( show.date ) has \( multiNightRun.count ) shows." )
                    
                    // add the show(s) to the dictionary
                    locationDictionary.updateValue( multiNightRun, forKey: currentVenue )
                    
                    // blank the current multi-night run array
                    multiNightRun.removeAll( keepCapacity: false )
                    
                    // add the current show to the empty multi-night run array and remember where we were
                    currentVenue = show.venue
                    multiNightRun.append( show )
                    previousShow = show
                }
            }
        }
        
        // set the tour's location dictionary
        self.locationDictionary = locationDictionary
    }
    
    // for use with highlighting the correct rows in the show list table view
    // returns the row number of the show to highlight and the row number of the last show of a multi-night run
    func showListNumberForLocation( location: PhishShow ) -> ( Int, Int )
    {
        // get all the shows played at the location
        let showsAtVenue = locationDictionary[ location.venue ]!
        
        // highlight the row of the first show
        // scroll to the row of the last show (might be the same)
        // if the first show of the tour was selected, don't scroll at all
        let highlightIndex = shows.indexOf(location )!
        let scrollToIndex = ( highlightIndex == 0 ) ? highlightIndex : highlightIndex + ( showsAtVenue.count - 1 )
        
        return ( highlightIndex, scrollToIndex )
    }
    
    func save()
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory,
            .UserDomainMask,
            true
        )[ 0 ]
        let tourPathURL = NSURL( string: documentsPath )!
        let tourPath = tourPathURL.URLByAppendingPathComponent( self.filename )
        
        print( "Saving tour: \( self.name ) to \( tourPath )" )
        
        if NSKeyedArchiver.archiveRootObject( self, toFile: tourPath.path! )
        {
            return
        }
        else
        {
            print( "There was an error saving \( self.name ) to the device." )
        }
    }
}
