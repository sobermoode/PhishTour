//
//  PhishTour.swift
//  PhishTour
//
//  Created by Aaron Justman on 9/30/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhishTour: NSManagedObject
{
    /// specific information for the tour
    @NSManaged var year: PhishYear?
    @NSManaged var name: String
    @NSManaged var tourID: NSNumber
    
    /// a tour consists of a series of shows at several different locations
    @NSManaged var shows: [PhishShow]
    
    /// unique tour locations (some shows are played at the same venue, in a multi-night run)
    var uniqueLocations: [PhishShow]?
    {
        guard !self.shows.isEmpty
        else
        {
            return nil
        }
        
        var uniques = [PhishShow]()
        var previousShow: PhishShow = self.shows.first!
        
        for (index, show) in self.shows.enumerate()
        {
            print("index: \(index)")
            print("previous venue: \(previousShow.venue), current venue: \(show.venue)")
            /// there might only be one location
            if self.shows.count == 1
            {
                uniques.append(show)
                
                return uniques
            }
            
            /// add the first show
            if index == 0
            {
                print("Added \(show.venue)")
                uniques.append(show)
                
                continue
            }
            else
            {
                /// we're still at the same place
                if show.venue == previousShow.venue
                {
                    print("Still at \(show.venue)")
                    previousShow = show
                }
                /// new location
                else
                {
                    print("Added \(show.venue)")
                    uniques.append(show)
                    previousShow = show
                }
            }
        }
        
        return uniques
    }
    
    /// lookup the shows associated with a given location
    lazy var locationDictionary: [String : [PhishShow]]? =
    {
        var previousShow: PhishShow = self.shows.first!
        var currentVenue: String = previousShow.venue
        var multiNightRun = [PhishShow]()
        var locationDictionary = [String : [PhishShow]]()
        
        /// go through each show and add them to an array. keep adding shows to the array if the venue continues to be the same.
        /// when the next venue is reached, set the array as a value for the key of the venue.
        for (index, show) in self.shows.enumerate()
        {
            /// it's possible that there's only one show for the tour
            if self.shows.count == 1
            {
                multiNightRun.append(show)
                
                show.consecutiveNights = multiNightRun.count
                
                locationDictionary.updateValue(multiNightRun, forKey: currentVenue)
                
                return locationDictionary
            }
            
            /// add the first show to the array
            if index == 0
            {
                multiNightRun.append(show)
                
                continue
            }
            else
            {
                /// we're still at the current venue, so it's a multi-night run
                if show.venue == previousShow.venue
                {
                    /// add the show and remember where we were
                    currentVenue = show.venue
                    multiNightRun.append(show)
                    previousShow = show
                    
                    /// if we're at the last show, then add the array to the dictionary
                    if index == self.shows.count - 1
                    {
                        for aShow in multiNightRun
                        {
                            aShow.consecutiveNights = multiNightRun.count
                        }
                        
                        locationDictionary.updateValue(multiNightRun, forKey: currentVenue)
                    }
                    
                    continue
                }
                else
                {
                    /// there's a new location                    
                    for aShow in multiNightRun
                    {
                        aShow.consecutiveNights = multiNightRun.count
                    }
                    
                    /// add the show(s) to the dictionary
                    locationDictionary.updateValue(multiNightRun, forKey: currentVenue)
                    
                    /// blank the current multi-night run array
                    multiNightRun.removeAll(keepCapacity: false)
                    
                    /// add the current show to the empty multi-night run array and remember where we were
                    currentVenue = show.venue
                    multiNightRun.append(show)
                    previousShow = show
                }
            }
        }
        
        // CoreDataStack.sharedInstance().saveContext()
        
        return locationDictionary
    }()
    
    /// the coordinates of every show
    var showCoordinates: [CLLocationCoordinate2D]
    {
        var coordinates = [CLLocationCoordinate2D]()
        for show in shows
        {
            coordinates.append(show.coordinate)
        }
        
        return coordinates
    }
    
    /// description
    override var description: String
    {
        return "\(self.name)"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?)
    {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(year: PhishYear, name: String, tourID: Int)
    {
        /// insert the object into the core data context
        let context = CoreDataStack.sharedInstance().managedObjectContext
        let tourEntity = NSEntityDescription.entityForName("PhishTour", inManagedObjectContext: context)!
        super.init(entity: tourEntity, insertIntoManagedObjectContext: context)
        
        /// set the tour/year relationship
        self.year = year
        
        self.name = name
        self.tourID = Int(tourID)
    }
    
    init(tourInfo: [String: AnyObject]) 
    {
        /// insert the object into the core data context
        let context = CoreDataStack.sharedInstance().managedObjectContext
        let tourEntity = NSEntityDescription.entityForName("PhishTour", inManagedObjectContext: context)!
        super.init(entity: tourEntity, insertIntoManagedObjectContext: context)
        
        /// extract tour name and ID the from the dictionary and set the properties
        self.name = tourInfo["name"] as! String
        self.tourID = tourInfo["id"] as! Int
        
        /// set the year;
        /// the tour will either be called something like, "2015 Summer Tour," in which case, we can just get at the number directly
        var year: NSNumber
        if let intYear = Int(NSString(string: self.name).substringToIndex(4))
        {
            year = NSNumber(integer: intYear)
        }
        /// or, the tour is referring to a festival (ie., "Lemonwheel"), or something else, in which case, we need to look at another entry in the dictionary
        else
        {
            let startDate = tourInfo["starts_on"] as! String
            let intYear = Int(NSString(string: startDate).substringToIndex(4))!
            year = NSNumber(integer: intYear) // intYear
        }
        
        /// 2002 had no shows that were part of a valid tour
        if year == 2002
        {
            self.year = nil
        }
        else
        {
            /// make a fetch request for the year, if it has been saved to Core Data
            let yearFetchRequest = NSFetchRequest(entityName: "PhishYear")
            let yearFetchPredicate = NSPredicate(format: "%K == %@", "year", year)
            yearFetchRequest.predicate = yearFetchPredicate
            
            do
            {
                let savedYear = try context.executeFetchRequest(yearFetchRequest) as! [PhishYear]
                
                if !savedYear.isEmpty
                {
                    self.year = savedYear.first!
                }
                else
                {
                    self.year = nil
                }
            }
            catch
            {
                print("Couldn't fetch \(year)")
            }
        }
        
        /// create the shows on the tour and set the relationship
        let shows = tourInfo["shows"] as! [[String : AnyObject]]
        for show in shows
        {            
            let newShow = PhishShow(showInfoFromYear: show)
            newShow.tour = self
        }
    }
    
    /// set the tour property on all the shows
    func associateShows()
    {
        for show in self.shows
        {
            show.tour = self
        }
    }
    
    // TODO: Re-instate?
    // I commented it out, while making changes to the shows property to be a Set, to work with Core Data.
    // However, it turned out, that in its initial submit form, I wasn't using this method, anyway.
    /*
    /// for use with highlighting the correct rows in the show list table view
    /// returns the row number of the show to highlight and the row number of the last show of a multi-night run
    func showListNumberForLocation(location: PhishShow) -> (Int, Int)
    {
        /// get all the shows played at the location
        let showsAtVenue = locationDictionary[location.venue]!
        
        /// highlight the row of the first show
        /// scroll to the row of the last show (might be the same)
        /// if the first show of the tour was selected, don't scroll at all
        let highlightIndex = shows.indexOf(location)!
        let scrollToIndex = (highlightIndex == 0) ? highlightIndex : highlightIndex + (showsAtVenue.count - 1)
        
        return (highlightIndex, scrollToIndex)
    }
    */
}
