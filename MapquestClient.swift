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
        /*
        if let uniqueLocations = tour.uniqueLocations
        {
            print("Geocoding \(tour.uniqueLocations!) shows for the \(tour.name).")
        }
        else
        {
            print("The \(tour.name) doesn't have any unique locations to geocode.")
        }
        */
        
        
        /// construct the request URL, starting with the base
        var mapquestRequestString = mapquestBaseURL + Services.Geocoding.GeocodingURL + Versions.Version1 + type.rawValue
        mapquestRequestString += "key=\(apiKey)"
        mapquestRequestString += "&maxResults=\(Options.MaxResults)&thumbMaps=\(Options.MapThumbnails)"
        
        /// first, check to see if the locations need to be geocoded, and return if they already have been;
        /// only geocode every unique location, not every show (some locations have multi-night runs)
        let uniqueLocations = tour.uniqueLocations
        var counter: Int = 0
        for location in uniqueLocations
        {
            print("Going to check the coordinates for \(location)...")
            /// check the coordinates
            if location.showLatitude != 0 && location.showLongitude != 0
            {
                print("\(location) doesn't need to be geocoded.")
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
                print("\(location) needs to be geocoded.")
                /// turn the location into a string that can be appended to the request;
                /// some locations need additional formatting
                var city = location.city
                city = city.stringByReplacingOccurrencesOfString(" ", withString: "")
                city = self.fixSpecialCities(city)
                mapquestRequestString += "&location=\(city)"
                counter++
            }
        }
        
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
                        let geocodeResults = jsonMapquestData["results"] as! [[String : AnyObject]]
                        
                        /// extract the latitude/longitude coordinates for each location and set the values on each PhishShow object
                        /// update the progress bar on the tour map when each location is geocoded
                        var counter: Int = 0
                        let progressBump: Float = 0.2 / Float(tour.uniqueLocations.count)
                        var totalProgress: Float = self.tourMapProgressBar.progress
                        for result in geocodeResults
                        {
                            /// get the current show, see if its part of a multi-night run, then get all the shows associated with the location
                            let currentShow: PhishShow = tour.shows[counter]
                            let shows: [PhishShow] = Array(tour.shows[counter...(counter + (Int(currentShow.consecutiveNights) - 1))])
                            
                            /// get at the latitude/longitude info
                            let locations = result["locations"] as! [AnyObject]
                            let innerLocations = locations[0] as! [String : AnyObject]
                            let latLong = innerLocations["latLng"] as! [String : Double]
                            let geocodedLatitude = latLong["lat"]!
                            let geocodedLongitude = latLong["lng"]!
                            
                            /// set the latitude/longitude on each show associated with the multi-night run
                            /// (or just on the one show, if there weren't consecutive nights)
                            for show in shows
                            {
                                print("Going to set the lat/long on the \(show.city)")
                                show.showLatitude = geocodedLatitude
                                show.showLongitude = geocodedLongitude
                                // show.save()
                                // show.tour?.save()
                                // show.tour?.year!.save()
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
