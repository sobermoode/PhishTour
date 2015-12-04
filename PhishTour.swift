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
            /// there might only be one location
            if self.shows.count == 1
            {
                uniques.append(show)
                
                return uniques
            }
            
            /// add the first show
            if index == 0
            {
                uniques.append(show)
                
                continue
            }
            else
            {
                /// we're still at the same place
                if show.venue == previousShow.venue
                {
                    previousShow = show
                }
                /// new location
                else
                {
                    uniques.append(show)
                    previousShow = show
                }
            }
        }
        
        let monthSortDescriptor = NSSortDescriptor(key: "month", ascending: true)
        let daySortDescriptor = NSSortDescriptor(key: "day", ascending: true)
        let sortedUniques = (uniques as NSArray).sortedArrayUsingDescriptors([monthSortDescriptor, daySortDescriptor]) as! [PhishShow]
        
        return sortedUniques
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
            year = NSNumber(integer: intYear)
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
            // let yearFetchPredicate = NSPredicate(format: "%K == %@", "year", year)
            let yearFetchPredicate = NSPredicate(format: "year = %@", year)
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
