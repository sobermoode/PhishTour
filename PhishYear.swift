//
//  PhishYear.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 10/1/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class PhishYear: NSObject,
    NSCoding
{
    var year: Int
    var tours: [ PhishTour ]?
    
    var filename: String
    {
        return "year\( self.year )"
    }
    
    init( year: Int )
    {
        self.year = year
    }
    
    required init?( coder aDecoder: NSCoder )
    {
        self.year = aDecoder.decodeIntegerForKey( "year" )
        self.tours = aDecoder.decodeObjectForKey( "tours" ) as? [ PhishTour ]
    }
    
    func encodeWithCoder( aCoder: NSCoder )
    {
        aCoder.encodeInteger( year, forKey: "year" )
        aCoder.encodeObject( tours, forKey: "tours" )
    }
    
    func save()
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory,
            .UserDomainMask,
            true
        )[ 0 ]
        let yearPathURL = NSURL( string: documentsPath )!
        let yearPath = yearPathURL.URLByAppendingPathComponent( self.filename )
        print( "Saving year: \( self.year ) to \( yearPath )" )
        
        if NSKeyedArchiver.archiveRootObject( self, toFile: yearPath.path! )
        {
            return
        }
        else
        {
            print( "There was an error saving \( self.year ) to the device." )
        }
    }
}
