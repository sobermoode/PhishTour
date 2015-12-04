//
//  MapquestClient.swift
//  PhishTour
//
//  Created by Aaron Justman on 10/4/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class MapquestClient: NSObject
{
    let session: NSURLSession = NSURLSession.sharedSession()
    
    /// to construct request URLs
    let mapquestBaseURL: String = "http://www.mapquestapi.com/"
    let apiKey: String = "sFvGlJbu43uE3lAkJFxj5gEAE1nUpjhM"
    
    struct Services
    {
        struct Geocoding
        {
            static let GeocodingURL = "geocoding/"
            
            enum GeocodingType: String
            {
                case Address = "address?"
                case Reverse = "reverse?"
                case Batch = "batch?"
            }
        }
    }
    
    struct Versions
    {
        static let Version1 = "v1/"
    }
    
    struct Options
    {
        static let MaxResults = "1"
        static let MapThumbnails = "false"
    }
    
    /// reference to the progress bar on the tour map
    var tourMapProgressBar: UIProgressView!
    
    class func sharedInstance() -> MapquestClient
    {
        struct Singleton
        {
            static var sharedInstance = MapquestClient()
        }
        
        return Singleton.sharedInstance
    }
    
    /// any shows that don't have lat/long info will get geocoded by Mapquest
    func geocodeShows(shows: [PhishShow], withType type: Services.Geocoding.GeocodingType, completionHandler: (geocodingError: NSError!) -> Void)
    {
        /// construct the request URL, starting with the base
        var mapquestRequestString = mapquestBaseURL + Services.Geocoding.GeocodingURL + Versions.Version1 + type.rawValue
        mapquestRequestString += "key=\(apiKey)"
        mapquestRequestString += "&maxResults=\(Options.MaxResults)&thumbMaps=\(Options.MapThumbnails)"
        
        /// add each city to the batch geocoding request string;
        /// record the shows with the same location, for use after the request is made
        var showsWithSameLocation = [String : Int]()
        var currentShowsWithSameLocation: Int = 1
        var previousCity: String = ""
        var previousFixedCity: String = ""
        for (index, show) in shows.enumerate()
        {
            /// don't geocode the same location more than once
            if show.city != previousCity
            {
                /// update the dictionary and reset the counter
                showsWithSameLocation.updateValue(currentShowsWithSameLocation, forKey: previousFixedCity)
                currentShowsWithSameLocation = 1
                
                /// turn the location into a string that can be appended to the request
                var city = show.city
                city = city.stringByReplacingOccurrencesOfString(" ", withString: "")
                mapquestRequestString += "&location=\(city)"
                
                /// remember the previous location
                previousCity = show.city
                previousFixedCity = city
                
                /// update the dictionary if we're at the last show
                if index == shows.count - 1
                {
                    showsWithSameLocation.updateValue(currentShowsWithSameLocation, forKey: previousFixedCity)
                }
            }
            else
            {
                /// more than one show at the same location
                ++currentShowsWithSameLocation
                
                /// update the dictionary if we're at the last show
                if index == shows.count - 1
                {
                    showsWithSameLocation.updateValue(currentShowsWithSameLocation, forKey: previousFixedCity)
                }
            }
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
        {
            dispatch_async(dispatch_get_main_queue())
            {
                self.tourMapProgressBar.setProgress(0.8, animated: true)
            }
            
            /// create the URL and start the task
            let mapquestRequestURL = NSURL(string: mapquestRequestString)!
            let mapquestGeocodeRequest = self.session.dataTaskWithURL(mapquestRequestURL)
            {
                mapquestData, mapquestResponse, mapquestError in
                
                /// there was an error geocoding the locations
                if mapquestError != nil
                {
                    completionHandler(geocodingError: mapquestError)
                }
                else
                {                    
                    do
                    {
                        let jsonMapquestData = try NSJSONSerialization.JSONObjectWithData(mapquestData!, options: []) as! [String : AnyObject]
                        guard let geocodeResults = jsonMapquestData["results"] as? [[String : AnyObject]]
                        else
                        {
                            completionHandler(geocodingError: mapquestError!)
                            
                            return
                        }
                        
                        /// extract the latitude/longitude coordinates for each location and set the values on each PhishShow object
                        /// update the progress bar on the tour map when each location is geocoded
                        let progressBump: Float = 0.2 / Float(shows.count)
                        var totalProgress: Float = self.tourMapProgressBar.progress
                        var nextShow: Int = 0
                        for result in geocodeResults
                        {
                            /// get at the latitude/longitude info
                            let locations = result["locations"] as! [AnyObject]
                            guard let innerLocations = locations[0] as? [String : AnyObject]
                            else
                            {
                                continue
                            }
                            let latLong = innerLocations["latLng"] as! [String : Double]
                            let geocodedLatitude = latLong["lat"]!
                            let geocodedLongitude = latLong["lng"]!
                            
                            /// get the number of shows with the same lat/long, from that dictionary from earlier
                            let providedLocation = result["providedLocation"] as! [String : AnyObject]
                            let city = providedLocation["location"] as! String
                            let numberOfShows: Int = showsWithSameLocation[city]!
                            
                            /// set the latitude/longitude on the shows
                            for index in nextShow..<(nextShow + numberOfShows)
                            {
                                shows[index].showLatitude = geocodedLatitude
                                shows[index].showLongitude = geocodedLongitude
                            }
                            
                            /// set the next index
                            nextShow += numberOfShows
                            
                            /// update the progress bar
                            totalProgress += (progressBump * Float(numberOfShows))
                            dispatch_async(dispatch_get_main_queue())
                            {
                                self.tourMapProgressBar.setProgress(totalProgress, animated: true)
                            }
                        }
                        
                        /// everything completed successfully
                        completionHandler(geocodingError: nil)
                    }
                    catch
                    {
                        print("There was a problem parsing the geocoding data from mapquest.com")
                    }
                }
            }
            mapquestGeocodeRequest.resume()
        }
    }
}
