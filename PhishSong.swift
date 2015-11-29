//
//  PhishSong.swift
//  PhishTour
//
//  Created by Aaron Justman on 9/30/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit
import CoreData

class PhishSong: NSManagedObject
{
    /// specific information for the song
    @NSManaged var name: String
    @NSManaged var duration: String
    @NSManaged var set: NSNumber
    @NSManaged var position: NSNumber
    @NSManaged var songID: NSNumber
    @NSManaged var show: PhishShow
    @NSManaged var performances: [PhishSongPerformance]?
    
    /// the song has a history of every show it was played at
    var history: [Int : [PhishSongPerformance]]?
    {
        if self.performances?.count == 0
        {
            print("\(self.name)'s performances is nil.")
            return nil
        }
        else
        {
            print("Trying to create the history...")
            var history = [Int : [PhishSongPerformance]]()
            
            var performancesForTheYear = [PhishSongPerformance]()
            var previousYear: Int = self.performances!.first!.year.integerValue
            
            for (index, performance) in self.performances!.enumerate()
            {
                let currentYear: Int = performance.year.integerValue
                
                /// still in the same year
                if currentYear == previousYear
                {
                    /// add the performance to the current array
                    performancesForTheYear.append(performance)
                    
                    /// remember the year
                    previousYear = currentYear
                    
                    /// we're at the last track?
                    if index == self.performances!.count - 1
                    {
                        let reversedPerformances: [PhishSongPerformance] = performancesForTheYear.reverse()
                        history.updateValue(reversedPerformances, forKey: currentYear)
                    }
                    
                    continue
                }
                /// got to a new year
                else
                {
                    /// update the history
                    let reversedPerformances: [PhishSongPerformance] = performancesForTheYear.reverse()
                    history.updateValue(reversedPerformances, forKey: previousYear)
                    
                    /// blank the performances for last year and add the first show for the new year
                    performancesForTheYear.removeAll()
                    performancesForTheYear.append(performance)
                    
                    /// remember the year
                    previousYear = currentYear
                    
                    /// we're at the last track?
                    if index == self.performances!.count - 1
                    {
                        let reversedPerformances: [PhishSongPerformance] = performancesForTheYear.reverse()
                        history.updateValue(reversedPerformances, forKey: currentYear)
                    }
                    
                    continue
                }
            }
            
            return history
        }
        
        
        /*
        for (index, performance) in self.performances.enumerate()
        {
            let currentYear = performance.year.integerValue
            
            if currentYear == previousYear
            {
                performancesForTheYear.append(performance)
                
                previousYear = currentYear
                
                if index == self.performances.count - 1
                {
                    history.updateValue(performancesForTheYear, forKey: currentYear)
                }
                
                continue
            }
            else
            {
                
            }
        }
        */
    }
    
    /// the total number of times the song has been played
    var totalPlays: Int
    {
        return self.performances!.count
        /*
        var total: Int = 0
        let keys = self.history!.keys
        
        for key in keys
        {
            let shows: [PhishShow] = self.history![key]!
            total += shows.count
        }
        
        return total
        */
    }
    
    /// filename to save the song history to for later retrieval
    var historyFilename: String
    {
        return "history\(self.songID.integerValue)"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?)
    {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(songInfo: [String : AnyObject], forShow show: PhishShow)
    {
        /// insert the object into the core data context
        let context = CoreDataStack.sharedInstance().managedObjectContext
        let songEntity = NSEntityDescription.entityForName("PhishSong", inManagedObjectContext: context)!
        super.init(entity: songEntity, insertIntoManagedObjectContext: context)
        
        self.name = songInfo["title"] as! String
        
        /// create a nicely formatted mm:ss string out of an amount of milliseconds
        let milliseconds = songInfo["duration"] as! Float
        let seconds = milliseconds / 1000
        let minutes = seconds / 60
        let finalMinutes = Int(minutes)
        let remainder = minutes - Float(finalMinutes)
        let finalSeconds = Int(floor(remainder * 60))
        let finalSecondsString = (finalSeconds < 10) ? "0\(finalSeconds) " : "\(finalSeconds)"
        self.duration = "\(finalMinutes):" + finalSecondsString
        
        var theSet: Int
        let setString = songInfo["set"] as! String
        if let intSet = Int(setString)
        {
            theSet = intSet
        }
        else
        {
            /// the encore comes back as "E" and soundchecks come back as "S";
            /// using 10 and 20 to avoid potential trouble with some kind of epic fifth-set madness
            if setString == "S"
            {
                theSet = 10
            }
            else if setString == "E"
            {
                theSet = 20
            }
            else
            {
                theSet = 0
            }
        }
        self.set = theSet
        
        self.position = songInfo["position"] as! NSNumber
        
        /// some songs have more than one ID...
        let songIDs = songInfo["song_ids"] as! [Int]
        self.songID = songIDs.first!
        
        /// set the relationship
        self.show = show
    }
    
    func updateProperties(songInfo: [String : AnyObject])
    {
        self.name = songInfo["title"] as! String
        
        /// create a nicely formatted mm:ss string out of an amount of milliseconds
        let milliseconds = songInfo["duration"] as! Float
        let seconds = milliseconds / 1000
        let minutes = seconds / 60
        let finalMinutes = Int(minutes)
        let remainder = minutes - Float(finalMinutes)
        let finalSeconds = Int(floor(remainder * 60))
        let finalSecondsString = (finalSeconds < 10) ? "0\(finalSeconds) " : "\(finalSeconds)"
        self.duration = "\(finalMinutes):" + finalSecondsString
        
        var theSet: Int
        let setString = songInfo["set"] as! String
        if let intSet = Int(setString)
        {
            theSet = intSet
        }
        else
        {
            /// the encore comes back as "E" and soundchecks come back as "S";
            /// using 10 and 20 to avoid potential trouble with some kind of epic fifth-set madness
            if setString == "S"
            {
                theSet = 10
            }
            else if setString == "E"
            {
                theSet = 20
            }
            else
            {
                theSet = 0
            }
        }
        self.set = theSet
        
        self.position = songInfo["position"] as! NSNumber
        
        /// some songs have more than one ID...
        let songIDs = songInfo["song_ids"] as! [Int]
        self.songID = songIDs.first!
    }
    
    /*
    /// write the history to file so it doesn't need to be requested twice
    func saveHistory()
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let pathArray = [documentsPath, self.historyFilename]
        let historyFileURL = NSURL.fileURLWithPathComponents(pathArray)!
        
        let historyData: NSData = NSKeyedArchiver.archivedDataWithRootObject(self.history!)
        if historyData.writeToFile(historyFileURL.path!, atomically: false)
        {
            return
        }
        else
        {
            print("There was an error saving \(self.name)'s history to the device.")
        }
    }
    */
}
