//
//  PhishModel.swift
//  PhishTour
//
//  Created by Aaron Justman on 10/27/15.
//  Copyright © 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhishModel: NSObject,
    UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDataSource, UITableViewDelegate
{
    /// reference to the device's documents directory
    let documentsPath: String = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    
    /// reference to the Core Data context
    let context = CoreDataStack.sharedInstance().managedObjectContext
    
    /// the available years
    var years: [PhishYear]?
    
    /// previous selections
    var previousYear: Int?
    var previousTour: Int?
    
    /// the tours for the currently selected year and their names
    var currentTours: [PhishTour]?
    var currentTourNames: [String]?
    {
        guard self.currentTours != nil
        else
        {
            return nil
        }
        
        var tourNames = [String]()
        for tour in self.currentTours!
        {
            tourNames.append(tour.name)
        }
        
        return tourNames
    }
    
    /// current selections
    var currentShow: PhishShow?
    var selectedYear: PhishYear?
    var selectedTour: PhishTour?
    
    /// references to the TourMapViewController and its map view
    var tourMapVC: TourMapViewController?
    var tourMap: MKMapView?
    
    /// a progress bar to display on the TourMapViewController as certain requests are in-progress
    var progressBar: UIProgressView!
    
    class func sharedInstance() -> PhishModel
    {
        struct Singleton
        {
            static var sharedInstance = PhishModel()
        }
        
        return Singleton.sharedInstance
    }
    
    /// fetch the saved years or request them
    func getYears(completionHandler: (yearsError: ErrorType?) -> Void)
    {
        /// create a fetch request with sort descriptor to sort them in descending order
        let yearsFetchRequest = NSFetchRequest(entityName: "PhishYear")
        let sortDescriptor = NSSortDescriptor(key: "year", ascending: false)
        yearsFetchRequest.sortDescriptors = [sortDescriptor]
        
        do
        {
            /// execute the fetch request
            let years = try self.context.executeFetchRequest(yearsFetchRequest) as! [PhishYear]
            
            /// make sure we got something back
            if !years.isEmpty
            {
                /// set the years
                self.years = years
                
                /// return the years
                completionHandler(yearsError: nil)
                
                return
            }
            /// no saved years, we need to request them
            else
            {
                PhishinClient.sharedInstance().requestYears()
                {
                    yearsRequestError, years in
                    
                    /// something went wrong
                    if yearsRequestError != nil
                    {
                        completionHandler(yearsError: yearsRequestError)
                    }
                    else
                    {
                        /// set the years
                        self.years = years!
                        
                        /// the years request was successful;
                        /// 1983-1987 all come back as one "year",
                        /// need to add them as individual PhishYears
                        var year: Int = 1987
                        repeat
                        {
                            let newYear = PhishYear(year: year)
                            
                            self.years?.append(newYear)
                        }
                        while --year >= 1983
                    }
                    
                    /// save new objects to the context
                    self.context.performBlockAndWait()
                    {
                        CoreDataStack.sharedInstance().saveContext()
                    }
                    
                    completionHandler(yearsError: nil)
                }
            }
        }
        catch
        {
            completionHandler(yearsError: error)
        }
    }
    
    /*
    /// get the available years or request them
    func getYears(completionHandler: (yearsError: NSError?) -> Void)
    {
        guard self.years != nil
        else
        {
            /// return saved years
            if let savedYears = self.getSavedYears()
            {
                /// set the years
                self.years = savedYears
                
                completionHandler(yearsError: nil)
                
                return
            }
            /// request the years
            else
            {
                PhishinClient.sharedInstance().requestYears()
                {
                    yearsRequestError, years in
                    
                    /// something went wrong
                    if yearsRequestError != nil
                    {
                        completionHandler(yearsError: yearsRequestError)
                    }
                    else
                    {
                        /// set the years
                        self.years = years!
                        
                        /// the years request was successful;
                        /// 1983-1987 all come back as one "year",
                        /// need to add them as individual PhishYears
                        var year: Int = 1987
                        repeat
                        {
                            let newYear = PhishYear(year: year)
                            // newYear.save()
                            
                            self.years?.append(newYear)
                        }
                        while --year >= 1983
                        
                        /*
                        /// write the years to the device
                        let documentsURL = NSURL(string: self.documentsPath)!
                        let yearsURL = documentsURL.URLByAppendingPathComponent("allYears")
                        NSKeyedArchiver.archiveRootObject(self.years!, toFile: yearsURL.path!)
                        */
                        
                        /// save new and updated objects to the context
                        CoreDataStack.sharedInstance().saveContext()
                        
                        completionHandler(yearsError: nil)
                    }
                }
                
                return
            }
        }
        
        completionHandler(yearsError: nil)
    }
    */
    
    /*
    /// retrieve the saved years from the device
    func getSavedYears() -> [PhishYear]?
    {
        let filename = "allyears"
        let filepath = self.createFileURLWithFilename(filename)
        
        if let savedYears = NSKeyedUnarchiver.unarchiveObjectWithFile(filepath) as? [PhishYear]
        {
            return savedYears
        }
        else
        {
            return nil
        }
    }
    */
    
    /// fetch the saved tours for a given year or request them
    func getToursForYear(year: PhishYear, completionHandler: (toursError: ErrorType?, tours: [PhishTour]?) -> Void)
    {
        /// create a fetch request with a predicate to match the year being requested
        /// and a sort descriptor to sort ascending by tour ID
        let toursFetchRequest = NSFetchRequest(entityName: "PhishTour")
        let toursFetchPredicate = NSPredicate(format: "%K == %@", "year", year)
        let sortDescriptor = NSSortDescriptor(key: "tourID", ascending: true)
        toursFetchRequest.predicate = toursFetchPredicate
        toursFetchRequest.sortDescriptors = [sortDescriptor]
        
        do
        {
            /// fetch the tours from core data
            let tours = try self.context.executeFetchRequest(toursFetchRequest) as! [PhishTour]
            
            /// make sure we got the saved tours
            if !tours.isEmpty
            {
                /// set the current tours
                self.currentTours = tours
                
                /// return the tours
                completionHandler(toursError: nil, tours: tours)
                
                return
            }
            /// no saved tours, we need to request them
            else
            {
                PhishinClient.sharedInstance().requestToursForYear(year)
                {
                    toursRequestError, requestedTours in
                    
                    /// something went wrong
                    if toursRequestError != nil
                    {
                        completionHandler(toursError: toursRequestError!, tours: nil)
                    }
                    else
                    {
                        /// set the tours
                        self.currentTours = requestedTours!
                    }
                    
                    /// save the new tours to the context
                    self.context.performBlockAndWait()
                    {
                        CoreDataStack.sharedInstance().saveContext()
                    }
                    
                    /// return the tours
                    completionHandler(toursError: nil, tours: requestedTours!)
                }
            }
        }
        catch
        {
            completionHandler(toursError: error, tours: nil)
        }
    }
    
    /*
    /// retrieve the tours for a given year or request them
    func getToursForYear(year: PhishYear, completionHandler: (toursError: NSError?, tours: [PhishTour]?) -> Void)
    {
        /// retrieve the tours from the device and return them
        let filename: String = "year\(year.year)"
        let filepath = self.createFileURLWithFilename(filename)
        if let savedYearWithTours = NSKeyedUnarchiver.unarchiveObjectWithFile(filepath) as? PhishYear
            where savedYearWithTours.tours != nil
        {
            self.currentTours = savedYearWithTours.tours
            
            completionHandler(toursError: nil, tours: savedYearWithTours.tours!)
        }
        /// no saved tours, we need to request them
        else
        {
            PhishinClient.sharedInstance().requestToursForYear(year)
            {
                toursRequestError, tours in
                
                /// something went wrong
                if toursRequestError != nil
                {
                    completionHandler(toursError: toursRequestError!, tours: nil)
                }
                else
                {
                    /// set the tours
                    self.currentTours = tours!
                    
                    /// return the tours
                    completionHandler(toursError: nil, tours: tours!)
                }
            }
        }
    }
    */
    
    /// retrieve saved tours from the device
    func getSavedToursForYear(year: Int) -> [PhishTour]?
    {
        let filename = "year\(year)"
        let filepath = self.createFileURLWithFilename(filename)
        guard let savedYearWithTours = NSKeyedUnarchiver.unarchiveObjectWithFile(filepath) as? PhishYear
            where savedYearWithTours.tours != nil
        else
        {
            return nil
        }
        
        return savedYearWithTours.tours
    }
    
    /// retrieve a setlist from core data or request one for a given show
    func getSetlistForShow(show: PhishShow, completionHandler: (setlistError: NSError?, setlist: [Int : [PhishSong]]?) -> Void)
    {
        /// create a fetch request for the show and a predicate that matches the show ID
        let showsFetchRequest = NSFetchRequest(entityName: "PhishShow")
        let showsFetchPredicate = NSPredicate(format: "%K == %@", "showID", "\(show.showID)")
        showsFetchRequest.predicate = showsFetchPredicate
        
        do
        {
            let shows = try self.context.executeFetchRequest(showsFetchRequest) as! [PhishShow]
            if !shows.isEmpty
            {
                print("Got a saved show!!!")
                let savedShow = shows.first!
                print("savedShow: \(savedShow)")
                if let savedSetlist = savedShow.setlist
                {
                    print("Got a saved setlist!!!")
                    completionHandler(setlistError: nil, setlist: savedSetlist)
                
                    return
                }
                /// no saved setlist, we need to request one
                else
                {
                    print("Requesting the setlist for \(show.date), \(show.year)")
                    PhishinClient.sharedInstance().requestSetlistForShow(show)
                    {
                        setlistError, setlist in
                        
                        /// something went wrong
                        if setlistError != nil
                        {
                            completionHandler(setlistError: setlistError!, setlist: setlist!)
                        }
                        /// return the setlist
                        else
                        {
                            completionHandler(setlistError: nil, setlist: setlist!)
                        }
                    }
                }
            }
            else
            {
                print("The fetch request for \(show.date) \(show.year) returned nothing.")
            }
        }
        catch
        {
            print("There was a problem fetching show \(show.showID) from Core Data.")
        }
        
        /*
        let filename = "setlist\(show.showID)"
        let filepath = self.createFileURLWithFilename(filename)
        if let savedSetlist = NSKeyedUnarchiver.unarchiveObjectWithFile(filepath) as? [Int : [PhishSong]]
        {
            completionHandler(setlistError: nil, songs: savedSetlist)
        }
        */
        
    }
    
    /// retrieve a history from the device or request one for a given song
    func getHistoryForSong(song: PhishSong, completionHandler: (songHistoryError: NSError?, songWithHistory: [Int : [PhishShow]]?) -> Void)
    {
        /*
        /// create a fetch request for the song and a predicate that matches the song ID
        let songsFetchRequest = NSFetchRequest(entityName: "PhishSong")
        let songsFetchPredicate = NSPredicate(format: "%K == %@", "songID", "\(song.songID)")
        songsFetchRequest.predicate = songsFetchPredicate
        
        do
        {
            let songs = try self.context.executeFetchRequest(songsFetchRequest) as! [PhishSong]
            if !songs.isEmpty
            {
                print("Got a saved song!!!")
                let savedSong = songs.first!
                if let savedHistory = savedSong.history
                {
                    completionHandler(songHistoryError: nil, songWithHistory: savedHistory)
                }
            }
        }
        catch
        {
            print("Couldn't fetch song \(song.songID) from Core Data.")
        }
        */
        
        /// check for a saved history and return it
        // let filename = "song\(song.name)"
        let documentsURL = NSURL(string: self.documentsPath)!
        let filename = song.historyFilename
        let fileURL = documentsURL.URLByAppendingPathComponent(filename)
        // let filepath = self.createFileURLWithFilename(filename)
        /*
        if let savedSongWithHistory = NSKeyedUnarchiver.unarchiveObjectWithFile(filepath) as? PhishSong where savedSongWithHistory.history != nil
        {
            completionHandler(songHistoryError: nil, songWithHistory: savedSongWithHistory.history!)
        }
        */
        guard !NSFileManager.defaultManager().fileExistsAtPath(fileURL.path!)
        else
        {
            let historyTask = NSURLSession.sharedSession().dataTaskWithURL(fileURL)
            {
                historyData, historyResponse, historyError in
                
                if historyError != nil
                {
                    completionHandler(songHistoryError: historyError!, songWithHistory: nil)
                }
                else
                {
                    if let history = NSKeyedUnarchiver.unarchiveObjectWithData(historyData!) as? [Int : [PhishShow]]
                    {
                        completionHandler(songHistoryError: nil, songWithHistory: history)
                    }
                }
            }
            historyTask.resume()
            
            return
        }
        
        PhishinClient.sharedInstance().requestHistoryForSong(song)
        {
            songHistoryError, songHistory in
            
            /// something went wrong
            if songHistoryError != nil
            {
                completionHandler(songHistoryError: songHistoryError, songWithHistory: nil)
            }
                /// return the history
            else
            {
                completionHandler(songHistoryError: nil, songWithHistory: songHistory!)
            }
        }
        
        /*
        let historyTask = NSURLSession.sharedSession().dataTaskWithURL(fileURL)
        {
            historyData, historyResponse, historyError in
            
            if historyError != nil
            {
                completionHandler(songHistoryError: historyError!, songWithHistory: nil)
            }
            else
            {
                if let history = NSKeyedUnarchiver.unarchiveObjectWithData(historyData!) as? [Int : [PhishShow]]
                {
                    completionHandler(songHistoryError: nil, songWithHistory: history)
                }
                /// no saved history, we need to request one
                else
                {
                    PhishinClient.sharedInstance().requestHistoryForSong(song)
                    {
                        songHistoryError, songHistory in
                        
                        /// something went wrong
                        if songHistoryError != nil
                        {
                            completionHandler(songHistoryError: songHistoryError, songWithHistory: nil)
                        }
                        /// return the history
                        else
                        {
                            completionHandler(songHistoryError: nil, songWithHistory: songHistory!)
                        }
                    }
                }
            }
        }
        historyTask.resume()
        */
    }
    
    /// retrieve a show from core data or request one for a given ID
    func getShowForID(id: Int, completionHandler: (showError: NSError?, show: PhishShow?) -> Void)
    {
        /// check for a saved show
        /// create the fetch request
        let showFetchRequest = NSFetchRequest(entityName: "PhishShow")
        let showFetchPredicate = NSPredicate(format: "%K == %@", "showID", "\(id)")
        showFetchRequest.predicate = showFetchPredicate
        
        do
        {
            /// execute the fetch request
            let shows = try self.context.executeFetchRequest(showFetchRequest) as! [PhishShow]
            
            /// make sure we got something from Core Data
            if !shows.isEmpty
            {
                print("Got a saved show!!!")
                let show = shows.first!
                print("\(show)")
                
                /// send the show back through the completion handler
                completionHandler(showError: nil, show: show)
            }
            /// no saved show, we need to request it
            else
            {
                print("Requesting a show...")
                PhishinClient.sharedInstance().requestShowForID(id)
                {
                    showRequestError, show in
                    
                    /// something went wrong
                    if showRequestError != nil
                    {
                        completionHandler(showError: showRequestError, show: nil)
                    }
                    /// return the show
                    else
                    {
                        completionHandler(showError: nil, show: show!)
                    }
                }
            }
        }
        catch
        {
            print("Couldn't retrieve show \(id) from Core Data.")
        }
        
        /*
        let filename = "show\(id)"
        let filepath = self.createFileURLWithFilename(filename)
        if let savedShow = NSKeyedUnarchiver.unarchiveObjectWithFile(filepath) as? PhishShow
        {
            completionHandler(showError: nil, show: savedShow)
        }
        */
        
    }
    
    /// retrieve a tour from core data or request one for a given ID
    func getTourForID(id: Int, completionHandler: (tourError: NSError?, tour: PhishTour?) -> Void)
    {
        /// check for a saved tour and return it
        let tourFetchRequest = NSFetchRequest(entityName: "PhishTour")
        let tourFetchPredicate = NSPredicate(format: "%K == %@", "tourID", "\(id)")
        tourFetchRequest.predicate = tourFetchPredicate
        
        do
        {
            let tours = try self.context.executeFetchRequest(tourFetchRequest) as! [PhishTour]
            
            if !tours.isEmpty
            {
                let tour = tours.first!
                
                completionHandler(tourError: nil, tour: tour)
            }
            /// no saved tour, we need to request it
            else
            {
                PhishinClient.sharedInstance().requestTourForID(id)
                {
                    tourRequestError, tour in
                    
                    /// something went wrong
                    if tourRequestError != nil
                    {
                        completionHandler(tourError: tourRequestError!, tour: nil)
                    }
                    /// return the tour
                    else
                    {
                        completionHandler(tourError: nil, tour: tour!)
                    }
                }
            }
        }
        catch
        {
            print("Couldn't retrieve tour \(id) from Core Data.")
        }
        
        /*
        let filename = "tour\(id)"
        let filepath = self.createFileURLWithFilename(filename)
        if let savedTour = NSKeyedUnarchiver.unarchiveObjectWithFile(filepath) as? PhishTour
        {
            completionHandler(tourError: nil, tour: savedTour)
        }
        */
        
    }
    
    /// retrieve a tour from core data or request a name for a given tour ID
    func getTourNameForTourID(id: Int, completionHandler: (tourNameError: NSError?, tourName: String?) -> Void)
    {
        /// check for a saved tour and return its name
        /// check for a saved tour and return it
        let tourFetchRequest = NSFetchRequest(entityName: "PhishTour")
        let tourFetchPredicate = NSPredicate(format: "%K == %@", "tourID", "\(id)")
        tourFetchRequest.predicate = tourFetchPredicate
        
        do
        {
            print("Making a fetch request for tour \(id)...")
            let tours = try self.context.executeFetchRequest(tourFetchRequest) as! [PhishTour]
            
            if !tours.isEmpty
            {
                let savedTour = tours.first!
                
                completionHandler(tourNameError: nil, tourName: savedTour.name)
            }
            /// no saved tour, we need to request one
            else
            {
                print("No saved tour, requesting...")
                PhishinClient.sharedInstance().requestTourNameForID(id)
                {
                    tourNameRequestError, tourName in
                    
                    /// something went wrong
                    if tourNameRequestError != nil
                    {
                        completionHandler(tourNameError: tourNameRequestError!, tourName: nil)
                    }
                    /// return the tour name
                    else
                    {
                        completionHandler(tourNameError: nil, tourName: tourName!)
                    }
                }
            }
        }
        catch
        {
            print("Couldn't retrieve tour \(id) from Core Data.")
        }
        /*
        let filename = "tour\(id)"
        let filepath = self.createFileURLWithFilename(filename)
        if let savedTour = NSKeyedUnarchiver.unarchiveObjectWithFile(filepath) as? PhishTour
        {
            completionHandler(tourNameError: nil, tourName: savedTour.name)
        }
        */
    }
    
    /// returns a string to plug into the keyed unarchiver to retrieve files
    func createFileURLWithFilename(filename: String) -> String
    {
        let documentsURL = NSURL(string: self.documentsPath)!
        let fileURL = documentsURL.URLByAppendingPathComponent(filename)
        
        return fileURL.path!
    }
    
    // MARK: UIPickerViewDataSource, UIPickerViewDelegate methods
    
    /// the PhishModel is delegate of the year picker and the tour picker on the TourMapViewController's tour selecter
    
    /// each picker has one component
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int
    {
        switch pickerView.tag
        {
            case 201:
                return 1
                
            case 202:
                return 1
                
            default:
                return 0
        }
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        switch pickerView.tag
        {
            /// the year picker has a row for each year
            case 201:
                guard let years = self.years
                else
                {
                    return 0
                }
                
                return years.count
            
            /// the tour picker has a row for each tour in the year
            case 202:
                guard let currentTourNames = self.currentTourNames
                else
                {
                    return 0
                }
                
                return currentTourNames.count
                
            default:
                return 0
        }
    }
    
    /// using a label set with a custom font and text size for each row in the pickers
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView
    {
        var label = view as? UILabel
        
        if label == nil
        {
            label = UILabel()
            
            label?.textAlignment = .Center
        }
        
        switch pickerView.tag
        {
            /// the years can have a bigger font
            case 201:
                label?.font = UIFont(name: "Apple SD Gothic Neo", size: 20)
                
                guard let years = self.years
                else
                {
                    label?.text =  ". . ."
                    
                    return label!
                }
                
                label?.text = "\(years[row].year)"
            
            /// the tours need to be set smaller, because some tours have long names
            case 202:
                label?.font = UIFont(name: "Apple SD Gothic Neo", size: 12)
                
                guard let currentTourNames = self.currentTourNames
                else
                {
                    label?.text = ". . ."
                    
                    return label!
                }
                
                label?.text = currentTourNames[row]
                
            default:
                label?.text =  ". . ."
        }
        
        return label!
    }
    
    /// when a year is selected, reload the tour picker with that year's tours;
    /// when a tour is selected, all the info needed to follow a tour is available
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        switch pickerView.tag
        {
            /// selected a year
            case 201:
                /// make sure we get a valid year
                guard let year = self.years?[row]
                else
                {
                    return
                }
                
                /// set the selected year
                self.selectedYear = year
                
                /// create a progress bar that will update as the tours for the selected year are requested
                let progressBar = UIProgressView(progressViewStyle: .Default)
                progressBar.frame = CGRect(x: CGRectGetMinX(self.tourMapVC!.tourSelecter!.contentView.bounds), y: CGRectGetMinY(self.tourMapVC!.tourSelecter!.contentView.bounds) + UIApplication.sharedApplication().statusBarFrame.height + self.tourMapVC!.navigationController!.navigationBar.bounds.height - 41, width: CGRectGetWidth(self.tourMapVC!.view.bounds), height: 10)
                progressBar.progressTintColor = UIColor.blueColor()
                progressBar.trackTintColor = UIColor.lightGrayColor()
                progressBar.transform = CGAffineTransformMakeScale(1, 2.5)
                self.progressBar = progressBar
                PhishinClient.sharedInstance().tourSelecterProgressBar = self.progressBar
                self.tourMapVC!.tourSelecter!.contentView.addSubview(progressBar)
                
                /// get the tours for the selected year
                self.getToursForYear(year)
                {
                    toursError, tours in
                    
                    /// something went wrong
                    if toursError != nil
                    {
                        /// set the tour selecter to display the previous successfully requested year and its tours
                        self.selectedYear = self.years![self.previousYear!]
                        self.currentTours = self.selectedYear!.tours
                        
                        /// create an alert for the problem and dismiss the tour selecter
                        let alert = UIAlertController(title: "Whoops!", message: "There was an error requesting the tours for \(year.year): \(toursError!)", preferredStyle: .Alert)
                        let alertAction = UIAlertAction(title: "OK", style: .Default)
                        {
                            action in
                            
                            /// revert the "select tour" button
                            self.tourMapVC!.selectTourButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
                            self.tourMapVC!.selectTourButton.setTitle("Select Tour", forState: .Normal)
                            
                            self.tourMapVC!.tourSelecter?.removeFromSuperview()
                            self.tourMapVC!.tourSelecter = nil
                        }
                        alert.addAction(alertAction)
                        
                        dispatch_async(dispatch_get_main_queue())
                        {
                            self.tourMapVC!.presentViewController(alert, animated: true, completion: nil)
                        }
                    }
                    /// the request was successful
                    else
                    {
                        /// remember the currently selected year
                        self.previousYear = row
                        
                        /// set the tours for the selected year
                        self.currentTours = tours
                        
                        /// set first tour as the current selection
                        self.selectedTour = tours!.first!
                        self.previousTour = 0
                        
                        /// get at the year picker so we can reload it with the new tours
                        let tourSelecter = pickerView.superview! as UIView
                        let tourPicker = tourSelecter.viewWithTag(202) as! UIPickerView
                        
                        dispatch_async(dispatch_get_main_queue())
                        {
                            tourPicker.reloadAllComponents()
                        }
                        
                        /// indicate that the request has completed successfully by making the progress bar green;
                        /// then remove it after a short delay
                        dispatch_async(dispatch_get_main_queue())
                        {
                            self.progressBar?.progressTintColor = UIColor.greenColor()
                            
                            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
                            dispatch_after(delayTime, dispatch_get_main_queue())
                            {
                                self.progressBar?.removeFromSuperview()
                                self.progressBar = nil
                            }
                        }
                    }
                }
            
            /// selected a tour
            case 202:
                /// set the selected tour and remember which row it was at
                self.selectedTour = self.currentTours![row]
                self.previousTour = row
            
            default:
                self.selectedYear = nil
                self.selectedTour = nil
        }
    }
    
    // MARK: UITableViewDataSource, UITableViewDelegate methods
    
    /// these methods are for the tour list on the TourMapViewController
    
    /// just one section
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        guard self.selectedTour != nil
        else
        {
            print("No selected tour!!!")
            return 0
        }
        
        return 1
    }
    
    /// every show on the tour is a row in the table
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        guard self.selectedTour != nil
        else
        {
            print("No selected tour!!!")
            return 0
        }
        
        return self.selectedTour!.shows.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 45
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        /// dequeue a cell
        let cell = tableView.dequeueReusableCellWithIdentifier("tourListCell", forIndexPath: indexPath) as! TourListCell
        
        /// make sure we get a valid show to build the cell with
        guard let show = PhishModel.sharedInstance().selectedTour?.shows[indexPath.row]
        else
        {
            print("Couldn't get the show for cell \(indexPath.row)!!!")
            
            return cell
        }
        
        /// set the cell properties
        cell.show = show
        cell.showNumber = indexPath.row
        cell.dateLabel.text = show.date
        cell.yearLabel.text = "\(show.year)"
        cell.venueLabel.text = show.venue
        cell.cityLabel.text = show.city
        
        /// set the delegate
        cell.delegate = self.tourMapVC
        
        /// create the gradient effect with the cells' background colors;
        /// each set of shows at a unique location will share the same background color
        let shows = PhishModel.sharedInstance().selectedTour!.locationDictionary![show.venue]!
        let firstShow = shows.first!
        let position = PhishModel.sharedInstance().selectedTour!.uniqueLocations.indexOf(firstShow)!
        let grayFactor = CGFloat(0.02 * Double(position))
        let bgColor = UIColor(red: 1.0 - grayFactor, green: 1.0 - grayFactor, blue: 1.0 - grayFactor, alpha: 1.0)
        cell.backgroundColor = bgColor
        
        return cell
    }
    
    /// when a cell is selected, display the callout for the pin on the map
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        /// dismiss the current callout if one is showing
        if self.tourMapVC!.currentCallout != nil
        {
            self.tourMap?.deselectAnnotation(self.currentShow, animated: true)
            self.tourMapVC?.currentCallout?.dismissCalloutAnimated(true)
            self.tourMapVC?.currentCallout = nil
        }
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! TourListCell
        
        /// annotations are added by location, not by show, so we need to find the location that corresponds to the annotation
        // get the venue and use it to find the location
        let venue = cell.venueLabel.text!
        let locations = PhishModel.sharedInstance().selectedTour!.locationDictionary![venue]
        let show = locations!.first!
        
        /// move the map to the annotaton, so the callout doesn't appear offscreen
        self.tourMap?.setCenterCoordinate(show.coordinate, animated: true)
        
        /// select the annotation and dismiss the list after a short delay
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue())
        {
            self.tourMap!.selectAnnotation(show, animated: true)
            self.tourMapVC!.didPressListButton()
        }
    }
}
