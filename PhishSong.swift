//
//  PhishSong.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 9/30/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class PhishSong: NSObject,
    NSCoding
{
    /// specific information for the song
    var name: String
    var duration: String
    var set: Int!
    var songID: Int
    var show: PhishShow!
    
    /// the song has a history of every show it was played at
    var history: [Int : [PhishShow]]?
    
    /// the total number of times the song has been played
    var totalPlays: Int
    {
        var total: Int = 0
        let keys = self.history!.keys
        
        for key in keys
        {
            let shows: [PhishShow] = self.history![key]!
            total += shows.count
        }
        
        return total
    }
    
    /// filename to save the song data to for later retrieval
    var filename: String
    {
        return "song\(self.name)"
    }
    
    init(songInfo: [String : AnyObject], forShow show: PhishShow)
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
        
        // some songs have more than one ID...
        // (i dunno, the value comes back as an array)
        let songIDs = songInfo["song_ids"] as! [Int]
        self.songID = songIDs.first!
        
        self.show = show
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        self.name = aDecoder.decodeObjectForKey("name") as! String
        self.duration = aDecoder.decodeObjectForKey("duration") as! String
        self.set = aDecoder.decodeIntegerForKey("set")
        self.songID = aDecoder.decodeIntegerForKey("songID")
        self.show = aDecoder.decodeObjectForKey("show") as! PhishShow
        self.history = aDecoder.decodeObjectForKey("history") as? [Int : [PhishShow]]
    }
    
    func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(self.name, forKey: "name")
        aCoder.encodeObject(self.duration, forKey: "duration")
        aCoder.encodeInteger(self.set, forKey: "set")
        aCoder.encodeInteger(self.songID, forKey: "songID")
        aCoder.encodeObject(self.show, forKey: "show")
        aCoder.encodeObject(self.history, forKey: "history")
    }
    
    func save()
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let songPathURL = NSURL(string: documentsPath)!
        let songPath = songPathURL.URLByAppendingPathComponent(self.filename)
        
        if NSKeyedArchiver.archiveRootObject(self, toFile: songPath.path!)
        {
            return
        }
        else
        {
            print("There was an error saving \( self.name ) to the device.")
        }
    }
}
