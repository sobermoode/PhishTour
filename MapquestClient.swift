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
    
    /// take every location on the tour and geocode it to a latitude/longitude
    func geocodeShowsForTour(tour: PhishTour, withType type: Services.Geocoding.GeocodingType, completionHandler: (geocodingError: NSError!) -> Void)
    {
        /// construct the request URL, starting with the base
        var mapquestRequestString = mapquestBaseURL + Services.Geocoding.GeocodingURL + Versions.Version1 + type.rawValue
        mapquestRequestString += "key=\(apiKey)"
        mapquestRequestString += "&maxResults=\(Options.MaxResults)&thumbMaps=\(Options.MapThumbnails)"
        
        /// first, check to see if the locations need to be geocoded, and return if they already have been;
        /// only geocode every unique location, not every show (some locations have multi-night runs)
        if let uniqueLocations = tour.uniqueLocations
        {
            print("Checking the locations for geocoding...")
            print("uniqueLocations: \(uniqueLocations.description)")
            var counter: Int = 0
            for location in uniqueLocations
            {
                if location.city == ""
                {
                    continue
                }
                
                /// check the coordinates
                if location.showLatitude != 0 && location.showLongitude != 0
                {
                    print("\(location.city) doesn't need to be geocoded.")
                    /// we checked all the locations
                    if counter == uniqueLocations.count - 1
                    {
                        /// complete with no error
                        completionHandler(geocodingError: nil)
                        return
                    }
                    else
                    {
                        /// check next location
                        counter++
                        continue
                    }
                }
                /// there's a location that needs to be geocoded
                else
                {
                    print("\(location.city) needs to be geocoded.")
                    /// turn the location into a string that can be appended to the request;
                    /// some locations need additional formatting
                    var city = location.city
                    city = city.stringByReplacingOccurrencesOfString(" ", withString: "")
                    city = self.fixSpecialCities(city)
                    mapquestRequestString += "&location=\(city)"
                    counter++
                }
            }
        }
        else
        {
            /// create an error to send back
            var geocodingErrorDictionary = [NSObject : AnyObject]()
            geocodingErrorDictionary.updateValue("Couldn't get the tour locations.", forKey: NSLocalizedDescriptionKey)
            let geocodingError = NSError(domain: NSCocoaErrorDomain, code: 9999, userInfo: geocodingErrorDictionary)
            completionHandler(geocodingError: geocodingError)
        }
        
        print("mapquestRequestString: \(mapquestRequestString)")
        
        /// run the request on a background thread, update the progress bar on the main thread
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
                            print("There weren't any geocodeResults.")
                            completionHandler(geocodingError: mapquestError!)
                            return
                        }
                        
                        /// extract the latitude/longitude coordinates for each location and set the values on each PhishShow object
                        /// update the progress bar on the tour map when each location is geocoded
                        var counter: Int = 0
                        let progressBump: Float = 0.2 / Float(tour.uniqueLocations!.count)
                        var totalProgress: Float = self.tourMapProgressBar.progress
                        for result in geocodeResults
                        {
                            /// get the current show, see if its part of a multi-night run, then get all the shows associated with the location
                            guard let currentShow: PhishShow = tour.shows[counter]
                            else
                            {
                                print("There was no currentShow.")
                                completionHandler(geocodingError: mapquestError!)
                                return
                            }
                            guard let shows: [PhishShow] = Array(tour.shows[counter...(counter + (Int(currentShow.consecutiveNights) - 1))])
                            else
                            {
                                print("Couldn't get the shows.")
                                completionHandler(geocodingError: mapquestError!)
                                return
                            }
                            
                            /// get at the latitude/longitude info
                            let locations = result["locations"] as! [AnyObject]
                            print("locations: \(locations.description)")
                            guard let innerLocations = locations[0] as? [String : AnyObject]
                            else
                            {
                                continue
                            }
                            let latLong = innerLocations["latLng"] as! [String : Double]
                            let geocodedLatitude = latLong["lat"]!
                            let geocodedLongitude = latLong["lng"]!
                            
                            /// set the latitude/longitude on each show associated with the multi-night run
                            /// (or just on the one show, if there weren't consecutive nights)
                            for show in shows
                            {
                                show.showLatitude = geocodedLatitude
                                show.showLongitude = geocodedLongitude
                            }
                            
                            /// jump to the first show at the next location
                            counter += Int(currentShow.consecutiveNights)
                            
                            /// update the progress bar
                            totalProgress += progressBump
                            dispatch_async(dispatch_get_main_queue())
                            {
                                self.tourMapProgressBar.setProgress(totalProgress, animated: true)
                            }
                        }
                        
                        /// save new and updated objects to the context
                        CoreDataStack.sharedInstance().saveContext()
                        
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
    
    func fixSpecialCities(var location: String) -> String
    {
        switch location
        {
            case "Nüremberg,Germany":
                location = "Nuremberg,Germany"
                
            case "Lyon/Villeurbanne,France":
                location = "Lyon,France"
                
            case "Montréal,Québec,Canada":
                location = "Montreal,Quebec,Canada"
                
            case "Düsseldorf,Germany":
                location = "Dusseldorf,Germany"
                
            case "OrangeBeach,ALUS":
                location = "OrangeBeach,AL"
                
            default:
                break
        }
        
        return location
    }
}
