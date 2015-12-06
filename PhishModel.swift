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
    
    /// current selections
    var currentShow: PhishShow?
    var selectedYear: PhishYear?
    var selectedTour: PhishTour?
    
    /// references to the TourMapViewController and its map view
    var tourMapVC: TourMapViewController?
    var tourMap: MKMapView?
    var tourPicker: UIPickerView?
    
    /// a progress bar to display on the TourMapViewController as certain requests are in-progress
    var progressBar: UIProgressView?
    
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
        
        self.context.performBlockAndWait()
        {
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
                                self.context.performBlockAndWait()
                                {
                                    let newYear = PhishYear(year: year)
                                    
                                    self.years?.append(newYear)
                                }
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
    }
    
    /// fetch the saved tours for a given year or request them
    func getToursForYear(year: PhishYear, completionHandler: (toursError: ErrorType?, tours: [PhishTour]?) -> Void)
    {
        /// create a fetch request with a predicate to match the year being requested
        let toursFetchRequest = NSFetchRequest(entityName: "PhishTour")
        let toursFetchPredicate = NSPredicate(format: "year = %@", year)
        toursFetchRequest.predicate = toursFetchPredicate
        
        /// a specific tour might have been requested from the song history;
        /// we'll need to get the other tours for that year
        if !year.didRequestAllTours
        {
            /// request the tours for the year
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
                    
                    /// set the flag for the year
                    year.didRequestAllTours = true
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
        /// we've got all the tours, so fetch them from core data
        else
        {
            self.context.performBlockAndWait()
            {
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
                }
                catch
                {
                    completionHandler(toursError: error, tours: nil)
                }
            }
        }
    }
    
    /// retrieve the shows for a tour from core data or request them for the given tour
    func getShowsForTour(var tour: PhishTour, completionHandler: (showRequestError: NSError!) -> Void)
    {
        /// create a fetch request for the tour and a predicate that matches the year and tour ID
        let tourFetchRequest = NSFetchRequest(entityName: "PhishTour")
        let yearPredicate = NSPredicate(format: "year = %@", tour.year!)
        let tourFetchPredicate = NSPredicate(format: "tourID = %@", tour.tourID)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [yearPredicate, tourFetchPredicate])
        tourFetchRequest.predicate = compoundPredicate
        
        self.context.performBlockAndWait()
        {
            do
            {
                /// fetch the tour from core data
                let fetchedTours = try self.context.executeFetchRequest(tourFetchRequest) as! [PhishTour]
                if !fetchedTours.isEmpty
                {
                    /// get the specific tour
                    let fetchedTour = fetchedTours.first!
                    if !fetchedTour.shows.isEmpty
                    {
                        completionHandler(showRequestError: nil)
                        
                        return
                    }
                    /// the tour didn't already have show info
                    else
                    {
                        /// request the shows
                        PhishinClient.sharedInstance().requestShowsForTour(&tour)
                        {
                            showsRequestError in
                            
                            if showsRequestError != nil
                            {
                                completionHandler(showRequestError: showsRequestError)
                            }
                            else
                            {
                                /// save the context
                                self.context.performBlockAndWait()
                                {
                                    CoreDataStack.sharedInstance().saveContext()
                                }
                                
                                completionHandler(showRequestError: nil)
                            }
                        }
                    }
                }
            }
            catch
            {
                print("There was a problem fetching \(tour.name) from Core Data.")
            }
        }
    }
    
    /// retrieve a setlist from core data or request one for a given show
    func getSetlistForShow(show: PhishShow, completionHandler: (setlistError: NSError?, setlist: [Int : [PhishSong]]?) -> Void)
    {
        /// create a fetch request for the show and a predicate that matches the show ID
        let showsFetchRequest = NSFetchRequest(entityName: "PhishShow")
        let showsFetchPredicate = NSPredicate(format: "showID = %@", show.showID)
        showsFetchRequest.predicate = showsFetchPredicate
        
        self.context.performBlockAndWait()
        {
            do
            {
                /// fetch the shows from core data
                let shows = try self.context.executeFetchRequest(showsFetchRequest) as! [PhishShow]
                if !shows.isEmpty
                {
                    /// get the show we're requesting
                    let savedShow = shows.first!
                    if let savedSetlist = savedShow.setlist
                    {
                        /// return the setlist
                        completionHandler(setlistError: nil, setlist: savedSetlist)
                    
                        return
                    }
                    /// no saved setlist, we need to request one
                    else
                    {
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
                    /// create an error to send back
                    var errorDictionary = [NSObject : AnyObject]()
                    errorDictionary.updateValue("Couldn't find the setlist.", forKey: NSLocalizedDescriptionKey)
                    let fetchError = NSError(domain: NSCocoaErrorDomain, code: 9999, userInfo: errorDictionary)
                    
                    completionHandler(setlistError: fetchError, setlist: nil)
                }
            }
            catch
            {
                print("There was a problem fetching show \(show.showID) from Core Data.")
            } 
        }
    }
    
    /// retrieve a show from core data or request one for a given ID
    func getShowForID(id: Int, completionHandler: (showError: NSError?, show: PhishShow?) -> Void)
    {
        /// check for a saved show
        /// create the fetch request
        let showFetchRequest = NSFetchRequest(entityName: "PhishShow")
        let nsNumberID = NSNumber(integer: id)
        let showFetchPredicate = NSPredicate(format: "showID = %@", nsNumberID)
        showFetchRequest.predicate = showFetchPredicate
        
        self.context.performBlockAndWait()
        {
            do
            {
                /// execute the fetch request
                let shows = try self.context.executeFetchRequest(showFetchRequest) as! [PhishShow]
                
                /// make sure we got something from Core Data
                if !shows.isEmpty
                {
                    /// get the show we're looking for
                    let show = shows.first!
                    
                    /// send the show back through the completion handler
                    completionHandler(showError: nil, show: show)
                }
                /// no saved show, we need to request it
                else
                {
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
        }
    }
    
    /// retrieve a tour from core data or request one for a given ID
    func getTourForID(id: Int, inYear year: Int, withName name: String, completionHandler: (tourError: ErrorType?, tour: PhishTour?) -> Void)
    {
        /// check for a saved tour and return it
        let tourFetchRequest = NSFetchRequest(entityName: "PhishTour")
        let nsNumberID = NSNumber(integer: id)
        let tourFetchPredicate = NSPredicate(format: "tourID = %@", nsNumberID)
        tourFetchRequest.predicate = tourFetchPredicate
        
        self.context.performBlockAndWait()
        {
            do
            {
                /// fetch the tours from core data
                let tours = try self.context.executeFetchRequest(tourFetchRequest) as! [PhishTour]
                
                if !tours.isEmpty
                {
                    /// get the tour we're looking for
                    let tour = tours.first!
                    
                    completionHandler(tourError: nil, tour: tour)
                    
                    return
                }
                /// no saved tour, we need to create it
                else
                {
                    /// fetch the tour's year from core data
                    let yearFetchRequest = NSFetchRequest(entityName: "PhishYear")
                    let nsNumberYear = NSNumber(integer: year)
                    let yearFetchPredicate = NSPredicate(format: "year = %@", nsNumberYear)
                    yearFetchRequest.predicate = yearFetchPredicate
                    
                    self.context.performBlockAndWait()
                    {
                       do
                       {
                            let years = try self.context.executeFetchRequest(yearFetchRequest) as! [PhishYear]
                            
                            if !years.isEmpty
                            {
                                let year = years.first!
                                
                                let newTour = PhishTour(year: year, name: name, tourID: id)
                                
                                self.context.performBlockAndWait()
                                {
                                    CoreDataStack.sharedInstance().saveContext()
                                }
                                
                                completionHandler(tourError: nil, tour: newTour)
                            }
                        }
                        catch
                        {
                            print("There was a problem fetching \(year) from Core Data.")
                        }
                    }
                }
            }
            catch
            {
                print("Couldn't retrieve tour \(id) from Core Data.")
            }
        }
    }
    
    /// retrieve a tour from core data or request a name for a given tour ID
    func getTourNameForTourID(id: Int, completionHandler: (tourNameError: NSError?, tourName: String?) -> Void)
    {
        /// check for a saved tour and return its name
        let tourFetchRequest = NSFetchRequest(entityName: "PhishTour")
        let nsNumberID = NSNumber(integer: id)
        let tourFetchPredicate = NSPredicate(format: "tourID = %@", nsNumberID)
        tourFetchRequest.predicate = tourFetchPredicate
        
        self.context.performBlockAndWait()
        {
            do
            {
                /// fetch the tours from core data
                let tours = try self.context.executeFetchRequest(tourFetchRequest) as! [PhishTour]
                
                if !tours.isEmpty
                {
                    let savedTour = tours.first!
                    
                    completionHandler(tourNameError: nil, tourName: savedTour.name)
                }
                /// no saved tour, we need to request one
                else
                {
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
        }
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
                guard let currentTours = self.currentTours
                else
                {
                    return 0
                }
                
                return currentTours.count
                
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
                
                guard let currentTours = self.currentTours
                else
                {
                    label?.text = ". . ."
                    
                    return label!
                }
                label?.text = currentTours[row].name
                
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
                        
                        /// reload the tour picker with the new tours
                        if let tourPicker = self.tourPicker
                        {
                            dispatch_async(dispatch_get_main_queue())
                            {
                                tourPicker.reloadAllComponents()
                                tourPicker.selectRow(0, inComponent: 0, animated: false)
                            }
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
        
        /// get the correct show info
        let shows = PhishModel.sharedInstance().selectedTour!.shows
        let yearSortDescriptor = NSSortDescriptor(key: "year", ascending: true)
        let monthSortDescriptor = NSSortDescriptor(key: "month", ascending: true)
        let daySortDescriptor = NSSortDescriptor(key: "day", ascending: true)
        let sortedShows = (shows as NSArray).sortedArrayUsingDescriptors([yearSortDescriptor, monthSortDescriptor, daySortDescriptor]) as! [PhishShow]
        let show = sortedShows[indexPath.row]
        
        /// set the cell properties
        cell.show = show
        cell.showNumber = indexPath.row
        cell.dateLabel.text = show.date
        cell.yearLabel.text = "\(show.year)"
        cell.venueLabel.text = show.venue
        cell.cityLabel.text = show.city
        
        /// set the delegate
        cell.delegate = self.tourMapVC
        
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
        let venue = cell.venueLabel.text!
        let locationIndices = (self.selectedTour!.shows as NSArray).indexesOfObjectsPassingTest()
        {
            object, index, stop in
            
            let show = object as! PhishShow
            
            return show.venue == venue
        }
        let show = self.selectedTour!.shows[locationIndices.firstIndex]
        
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
