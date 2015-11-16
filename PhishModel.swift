//
//  PhishModel.swift
//  new phishtour navbar test
//
//  Created by Aaron Justman on 10/27/15.
//  Copyright © 2015 AaronJ. All rights reserved.
//

import UIKit
import MapKit

class PhishModel: NSObject,
    UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDataSource, UITableViewDelegate
{
    let documentsPath: String = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    
    var years: [PhishYear]?
    /*
    var tours: [PhishYear : [PhishTour]]?
    var shows: [PhishTour : [PhishShow]]?
    var setlists: [PhishShow : [PhishSong]]?
    */
    
    var previousYear: Int?
    var previousTour: Int?
    
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
    
    var currentShow: PhishShow?
    
    var selectedYear: PhishYear?
    var selectedTour: PhishTour?
    
    // TODO: need to set this to access it; in the final version the map will be on a custom view controller class, and this wont be necessary
    var tourMapVC: TourMapViewController?
    var tourMap: MKMapView?
    
    var progressBar: UIProgressView!
    
    class func sharedInstance() -> PhishModel
    {
        struct Singleton
        {
            static var sharedInstance = PhishModel()
        }
        
        return Singleton.sharedInstance
    }
    
    func getYears(completionHandler: (yearsError: NSError?) -> Void)
    {
        guard self.years != nil
        else
        {
            if let savedYears = self.getSavedYears()
            {
                self.years = savedYears
                // self.previousYear = 0
                
                completionHandler(yearsError: nil)
                
                return
            }
            else
            {
                PhishinClient.sharedInstance().requestYears()
                {
                    yearsRequestError, years in
                    
                    if yearsRequestError != nil
                    {
                        completionHandler(yearsError: yearsRequestError)
                    }
                    else
                    {
                        self.years = years!
                        // self.previousYear = 0
                        
                        /// the years request was successful;
                        /// 1983-1987 all come back as one "year",
                        /// need to add them as individual PhishYears
                        var year: Int = 1987
                        repeat
                        {
                            let newYear = PhishYear(year: year)
                            newYear.save()
                            
                            self.years?.append(newYear)
                        }
                        while --year >= 1983
                        
                        let documentsURL = NSURL(string: self.documentsPath)!
                        let yearsURL = documentsURL.URLByAppendingPathComponent("allYears")
                        NSKeyedArchiver.archiveRootObject(self.years!, toFile: yearsURL.path!)
                        
                        completionHandler(yearsError: nil)
                    }
                }
                
                return
            }
        }
        
        completionHandler(yearsError: nil)
    }
    
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
    
    // NEW getToursForYear 11.14.2015
    func getToursForYear(year: PhishYear, completionHandler: (toursError: NSError?, tours: [PhishTour]?) -> Void)
    {
        let filename: String = "year\(year.year)"
        let filepath = self.createFileURLWithFilename(filename)
        
        if let savedYearWithTours = NSKeyedUnarchiver.unarchiveObjectWithFile(filepath) as? PhishYear
            where savedYearWithTours.tours != nil
        {
            self.currentTours = savedYearWithTours.tours
            // self.selectedTour = self.currentTours?.first!
            // self.previousTour = 0
            
            completionHandler(toursError: nil, tours: savedYearWithTours.tours!)
        }
        else
        {
            PhishinClient.sharedInstance().requestToursForYear(year)
            {
                toursRequestError, tours in
                
                if toursRequestError != nil
                {
                    completionHandler(toursError: toursRequestError!, tours: nil)
                }
                else
                {
                    // year.tours = tours
                    
                    self.currentTours = tours!
                    
                    // set the selected tour, so the user doesn't have to do anything to start following a tour
                    // self.selectedTour = self.currentTours?.first!
                    
                    // remember which tour was selected
                    // self.previousTour = 0
                    
                    completionHandler(toursError: nil, tours: tours!)
                }
            }
        }
    }
    
    /*
    func getToursForYear(year: PhishYear, completionHandler: (toursRequestError: NSError?) -> Void)
    {
        guard year.tours != nil
        else
        {
            if let savedTours = self.getSavedToursForYear(year.year)
            {
                // year.tours = savedTours
                self.currentTours = savedTours
                self.selectedTour = self.currentTours?.first!
                
                completionHandler(toursRequestError: nil)
                
                return
            }
            else
            {
                PhishinClient.sharedInstance().requestToursForYear(year)
                {
                    toursRequestError, tours in
                    
                    if toursRequestError != nil
                    {
                        completionHandler(toursRequestError: toursRequestError!)
                    }
                    else
                    {
                        year.tours = tours
                        
                        self.currentTours = tours!
                        
                        // set the selected tour, so the user doesn't have to do anything to start following a tour
                        self.selectedTour = self.currentTours?.first!
                        
                        // remember which tour was selected
                        self.previousTour = 0
                        
                        completionHandler(toursRequestError: nil)
                    }
                }
                
                return
            }
        }
        
        completionHandler(toursRequestError: nil)
    }
    */
    
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
    
    func getSetlistForShow(show: PhishShow, completionHandler: (setlistError: NSError?, setlist: [Int : [PhishSong]]?) -> Void)
    {
        let filename = "show\(show.showID)"
        let filepath = self.createFileURLWithFilename(filename)
        
        if let savedShowWithSetlist = NSKeyedUnarchiver.unarchiveObjectWithFile(filepath) as? PhishShow
            where savedShowWithSetlist.setlist != nil
        {
            print("Got a saved setlist!!!")
            completionHandler(setlistError: nil, setlist: savedShowWithSetlist.setlist!)
        }
        else
        {
            PhishinClient.sharedInstance().requestSetlistForShow(show)
            {
                setlistError, setlist in
                
                if setlistError != nil
                {
                    completionHandler(setlistError: setlistError!, setlist: nil)
                }
                else
                {
                    completionHandler(setlistError: nil, setlist: setlist!)
                }
            }
        }
    }
    
    func getHistoryForSong(song: PhishSong, completionHandler: (songHistoryError: NSError?, songWithHistory: [Int : [PhishShow]]?) -> Void)
    {
        let filename = "song\(song.name)"
        let filepath = self.createFileURLWithFilename(filename)
        
        if let savedSongWithHistory = NSKeyedUnarchiver.unarchiveObjectWithFile(filepath) as? PhishSong where savedSongWithHistory.history != nil
        {
            print("Getting saved history...")
            completionHandler(songHistoryError: nil, songWithHistory: savedSongWithHistory.history!)
        }
        else
        {
            PhishinClient.sharedInstance().requestHistoryForSong(song)
            {
                songHistoryError, songHistory in
                
                if songHistoryError != nil
                {
                    completionHandler(songHistoryError: songHistoryError, songWithHistory: nil)
                }
                else
                {
                    completionHandler(songHistoryError: nil, songWithHistory: songHistory!)
                }
            }
        }
    }
    
    func getShowForID(id: Int, completionHandler: (showError: NSError?, show: PhishShow?) -> Void)
    {
        let filename = "show\(id)"
        let filepath = self.createFileURLWithFilename(filename)
        
        if let savedShow = NSKeyedUnarchiver.unarchiveObjectWithFile(filepath) as? PhishShow
        {
            completionHandler(showError: nil, show: savedShow)
        }
        else
        {
            PhishinClient.sharedInstance().requestShowForID(id)
            {
                showRequestError, show in
                
                if showRequestError != nil
                {
                    completionHandler(showError: showRequestError, show: nil)
                }
                else
                {
                    completionHandler(showError: nil, show: show!)
                }
            }
        }
    }
    
    func getTourForID(id: Int, completionHandler: (tourError: NSError?, tour: PhishTour?) -> Void)
    {
        let filename = "tour\(id)"
        let filepath = self.createFileURLWithFilename(filename)
        
        if let savedTour = NSKeyedUnarchiver.unarchiveObjectWithFile(filepath) as? PhishTour
        {
            completionHandler(tourError: nil, tour: savedTour)
        }
        else
        {
            PhishinClient.sharedInstance().requestTourForID(id)
            {
                tourRequestError, tour in
                
                if tourRequestError != nil
                {
                    completionHandler(tourError: tourRequestError!, tour: nil)
                }
                else
                {
                    completionHandler(tourError: nil, tour: tour!)
                }
            }
        }
    }
    
    func getTourNameForTourID(id: Int, completionHandler: (tourNameError: NSError?, tourName: String?) -> Void)
    {
        let filename = "tour\(id)"
        let filepath = self.createFileURLWithFilename(filename)
        
        if let savedTour = NSKeyedUnarchiver.unarchiveObjectWithFile(filepath) as? PhishTour
        {
            completionHandler(tourNameError: nil, tourName: savedTour.name)
        }
        else
        {
            PhishinClient.sharedInstance().requestTourNameForID(id)
            {
                tourNameRequestError, tourName in
                
                if tourNameRequestError != nil
                {
                    completionHandler(tourNameError: tourNameRequestError!, tourName: nil)
                }
                else
                {
                    completionHandler(tourNameError: nil, tourName: tourName!)
                }
            }
        }
    }
    
    func createFileURLWithFilename(filename: String) -> String
    {
        let documentsURL = NSURL(string: self.documentsPath)!
        let fileURL = documentsURL.URLByAppendingPathComponent(filename)
        
        return fileURL.path!
    }
    
    // MARK: UIPickerViewDataSource, UIPickerViewDelegate methods
    
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
        case 201:
            guard let years = self.years
            else
            {
                return 0
            }
            
            return years.count
            
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
        case 201:
            label?.font = UIFont(name: "Apple SD Gothic Neo", size: 20)
            
            guard let years = self.years
            else
            {
                label?.text =  ". . ."
                
                return label!
            }
            
            label?.text = "\(years[row].year)"
            
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
                        let alert = UIAlertController(title: "Whoops!", message: "There was an error requesting the tours for \(year.year): \(toursError!.localizedDescription)", preferredStyle: .Alert)
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
                    // the request was successful
                    else
                    {
                        /// remember the currently selected year
                        self.previousYear = row
                        
                        /// set the tours for the selected year
                        // self.currentTours = year.tours!
                        self.currentTours = tours
                        
                        // self.selectedTour = self.currentTours![row]
                        // self.selectedTour = year.tours!.first!
                        self.selectedTour = tours!.first!
                        self.previousTour = 0
                        
                        // self.tourMapVC!.saveToUserDefaults()
                        
                        // get at the year picker so we can reload it with the new tours
                        print("Reloading the tour picker...")
                        let tourSelecter = pickerView.superview! as UIView
                        let tourPicker = tourSelecter.viewWithTag(202) as! UIPickerView
                        
                        dispatch_async(dispatch_get_main_queue())
                        {
                            tourPicker.reloadAllComponents()
                        }
                        
                        /// indicate that the request has completed successfully by making it green;
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
            
            // selected a tour
            case 202:
                self.selectedTour = self.currentTours![row]
                self.previousTour = row
                // self.tourMapVC!.saveToUserDefaults()
            
            default:
                self.selectedYear = nil
                self.selectedTour = nil
        }
    }
    
    // MARK: UITableViewDataSource, UITableViewDelegate methods
    
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
        // dequeue a cell
        let cell = tableView.dequeueReusableCellWithIdentifier("tourListCell", forIndexPath: indexPath) as! TourListCell
        
        // make sure we get a valid show to build the cell with
        guard let show = PhishModel.sharedInstance().selectedTour?.shows[indexPath.row]
        else
        {
            print("Couldn't get the show for cell \(indexPath.row)!!!")
            
            return cell
        }
        
        // set the cell properties
        cell.show = show
        cell.showNumber = indexPath.row
        cell.dateLabel.text = show.date
        cell.yearLabel.text = "\(show.year)"
        cell.venueLabel.text = show.venue
        cell.cityLabel.text = show.city
        
        // set the delegate
        cell.delegate = self.tourMapVC
        
        /// create the gradient effect with the cells' background colors;
        /// each set of shows at a unique location will share the same background color
        let shows = PhishModel.sharedInstance().selectedTour!.locationDictionary[show.venue]!
        let firstShow = shows.first!
        let position = PhishModel.sharedInstance().selectedTour!.uniqueLocations!.indexOf(firstShow)!
        let grayFactor = CGFloat(0.02 * Double(position))
        let bgColor = UIColor(red: 1.0 - grayFactor, green: 1.0 - grayFactor, blue: 1.0 - grayFactor, alpha: 1.0)
        cell.backgroundColor = bgColor
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if self.tourMapVC!.currentCallout != nil
        {
            self.tourMap?.deselectAnnotation(self.currentShow, animated: true)
            self.tourMapVC?.currentCallout?.dismissCalloutAnimated(true)
            self.tourMapVC?.currentCallout = nil
        }
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! TourListCell
        
        // annotations are added by location, not by show, so we need to find the location that corresponds to the annotation
        // get the venue and use it to find the location
        let venue = cell.venueLabel.text!
        let locations = PhishModel.sharedInstance().selectedTour!.locationDictionary[ venue ]
        let show = locations!.first!
        
        // move the map to the annotaton, so the callout doesn't appear offscreen
        self.tourMap?.setCenterCoordinate(show.coordinate, animated: true)
        
        // select the annotation and dismiss the list after a short delay
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue())
        {
            self.tourMap!.selectAnnotation(show, animated: true)
            self.tourMapVC!.didPressListButton()
        }
    }
}
