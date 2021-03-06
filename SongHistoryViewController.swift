//
//  SongHistoryViewController.swift
//  PhishTour
//
//  Created by Aaron Justman on 10/17/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class SongHistoryViewController: UIViewController,
    UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate
{
    /// the song who's history is being displayed
    var song: PhishSong!
    var history: [Int : [PhishSongPerformance]]?
    
    /// associated info for the song
    var date: String!
    var totalPlaysLabel: UILabel!
    
    /// references to the table view and the progress bar
    var historyTable: UITableView!
    var progressBar: UIProgressView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.restorationIdentifier = "SongHistoryViewController"
        
        setupNavBar()
        sceneSetup()
        getHistory()
    }
    
    /// create the back button and nav bar title
    func setupNavBar()
    {
        let backButton = UIButton()
        backButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-SemiBold", size: 16)
        backButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        backButton.setTitle("< \(self.date)", forState: .Normal)
        backButton.sizeToFit()
        backButton.addTarget(self, action: "backToSetlist", forControlEvents: .TouchUpInside)
        let navBackButton = UIBarButtonItem(customView: backButton)
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 20)
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.text = "PhishTour"
        titleLabel.sizeToFit()
        
        self.navigationItem.leftBarButtonItem = navBackButton
        self.navigationItem.titleView = titleLabel
    }
    
    /// add all the views to the view controller
    func sceneSetup()
    {
        view.backgroundColor = UIColor.whiteColor()
        
        /// the song name is the title for the scene
        let songLabel = UILabel()
        songLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 20)
        songLabel.text = song.name
        songLabel.sizeToFit()
        songLabel.frame = CGRect(x: 25, y: 75, width: songLabel.frame.size.width, height: songLabel.frame.size.height)
        view.addSubview(songLabel)
        
        /// a label indicating the total number of times the song has been played
        self.totalPlaysLabel = UILabel()
        self.totalPlaysLabel.font = UIFont(name: "AppleSDGothicNeo-SemiBold", size: 14)
        self.totalPlaysLabel.text = "Total performances: 9999"
        self.totalPlaysLabel.sizeToFit()
        self.totalPlaysLabel.frame = CGRect(x: 25, y: songLabel.frame.origin.y + songLabel.bounds.height + 5, width: self.totalPlaysLabel.bounds.width, height: self.totalPlaysLabel.bounds.height)
        self.totalPlaysLabel.hidden = true
        view.addSubview(self.totalPlaysLabel)
        
        /// figure out how tall the table can be and create the table
        let remainingHeight = view.bounds.height - (songLabel.frame.origin.y + songLabel.frame.size.height) - 5 - totalPlaysLabel.bounds.height
        self.historyTable = UITableView(frame: CGRect(x: songLabel.frame.origin.x, y: totalPlaysLabel.frame.origin.y + totalPlaysLabel.frame.size.height + 20, width: CGRectGetMaxX(view.bounds) - 50, height: remainingHeight - 75), style: .Plain)
        self.historyTable.sectionIndexMinimumDisplayRowCount = 1
        self.historyTable.sectionIndexColor = UIColor.orangeColor()
        self.historyTable.separatorStyle = .None
        self.historyTable.dataSource = self
        self.historyTable.delegate = self
        
        /// register the table view's cell class and header view class
        self.historyTable.registerClass(SongCell.self, forCellReuseIdentifier: "songCell")
        self.historyTable.registerClass(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "yearHeader")
        
        view.addSubview(historyTable)
    }
    
    func backToSetlist()
    {        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    /// gets the list of shows the song was played at, as an array of show IDs
    func getHistory()
    {
        /// the song already has a history
        if let history = self.song.history
        {
            self.history = history
            self.totalPlaysLabel.text = "Total performances: \(self.song.totalPlays)"
            self.totalPlaysLabel.hidden = false
            self.historyTable.reloadData()
        }
        /// otherwise, we need to request it
        else
        {
            /// create a progress bar to track the progress of requesting the history
            /// give the PhishinClient a reference to the progress bar, so it can update the bar as it does its thing
            let progressBar = UIProgressView(progressViewStyle: .Default)
            progressBar.frame = CGRect(x: CGRectGetMinX(self.view.bounds), y: CGRectGetMinY(self.view.bounds) + UIApplication.sharedApplication().statusBarFrame.height + self.navigationController!.navigationBar.bounds.height, width: CGRectGetWidth(self.view.bounds), height: 10)
            progressBar.progressTintColor = UIColor.blueColor()
            progressBar.trackTintColor = UIColor.lightGrayColor()
            progressBar.transform = CGAffineTransformMakeScale(1, 2.5)
            self.progressBar = progressBar
            PhishinClient.sharedInstance().historyProgressBar = self.progressBar
            self.view.addSubview(progressBar)
            
            PhishinClient.sharedInstance().requestHistoryForSong(self.song)
            {
                historyError in
                
                if historyError != nil
                {
                    CoreDataStack.sharedInstance().managedObjectContext.performBlockAndWait()
                    {
                        /// create an alert for the problem and unwind back to the setlist
                        let alert = UIAlertController(title: "Whoops!", message: "There was an error requesting the history for \(self.song.name): \(historyError!.localizedDescription)", preferredStyle: .Alert)
                        let alertAction = UIAlertAction(title: "OK", style: .Default)
                        {
                            action in
                            
                            self.backToSetlist()
                        }
                        alert.addAction(alertAction)
                        
                        dispatch_async(dispatch_get_main_queue())
                        {
                            self.presentViewController(alert, animated: true, completion: nil)
                        }
                    }
                }
                else
                {
                    /// save the history
                    self.history = self.song.history!
                    
                    /// reload the table on the main thread
                    dispatch_async(dispatch_get_main_queue())
                    {
                        self.totalPlaysLabel.text = "Total performances: \(self.song.totalPlays)"
                        self.totalPlaysLabel.hidden = false
                        self.historyTable.reloadData()
                    }
                    
                    /// make the progress bar green when it finishes successfully
                    /// then, remove it after a short delay
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
        }
    }
    
    // MARK: UITableViewDataSource methods
    
    /// each year the song was played in will be a section in the table view
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        if self.history != nil
        {
            return self.history!.keys.count
        }
        else
        {
            return 1
        }
    }
    
    /// the years a song was played in will be listed in descending order next to the table view
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]?
    {
        if self.history != nil
        {
            let years: [Int] = Array(self.history!.keys)
            let sortedYears: [Int] = years.sort().reverse()
            
            var sectionIndexTitles = [String]()
            for year in sortedYears
            {
                sectionIndexTitles.append("\(year)")
            }
            
            return sectionIndexTitles
        }
        else
        {
            return nil
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        /// dequeue a header view
        let headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier("yearHeader") as UITableViewHeaderFooterView!
        
        /// make sure the history exists
        if self.history != nil
        {
            /// get the year and its shows
            let years: [Int] = Array(self.history!.keys)
            let sortedYears: [Int] = years.sort().reverse()
            let year: Int = sortedYears[section]
            
            headerView.textLabel!.text = "\(year)"
        }
        else
        {
            headerView.textLabel!.text = ""
        }
        
        return headerView
    }
    
    /// customize the header view before it is displayed
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        let headerView = view as! UITableViewHeaderFooterView
        
        headerView.layer.borderColor = UIColor.orangeColor().CGColor
        headerView.layer.borderWidth = 1
        headerView.textLabel!.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 14)
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if self.history != nil
        {
            /// get the year and its shows
            let years: [Int] = Array(self.history!.keys)
            let sortedYears: [Int] = years.sort().reverse()
            let year: Int = sortedYears[section]
            
            return "\(year)"
        }
        else
        {
            return ""
        }
    }
    
    /// each section (a year) will have a row for every date the song was played
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if history != nil
        {
            /// get the year and its shows
            let years: [Int] = Array(self.history!.keys)
            let sortedYears: [Int] = years.sort().reverse()
            let year: Int = sortedYears[section]
            let performances: [PhishSongPerformance] = self.history![year]!
            
            return performances.count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 25
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        /// dequeue a cell
        let cell = tableView.dequeueReusableCellWithIdentifier("songCell", forIndexPath: indexPath) as! SongCell
        
        /// set some placeholder text and disable the cell, for now
        cell.textLabel?.font = UIFont(name: "Apple SD Gothic Neo", size: 14)
        cell.textLabel?.textColor = UIColor.blackColor()
        cell.textLabel?.text = "Requesting date..."
        cell.detailTextLabel?.font = UIFont(name: "Apple SD Gothic Neo", size: 14)
        cell.detailTextLabel?.textColor = UIColor.grayColor()
        cell.detailTextLabel?.text = "Requesting tour..."
        cell.userInteractionEnabled = false
        
        /// make sure we've got a history to work with
        if self.history != nil
        {
            /// get the year and its shows
            let years: [Int] = Array(self.history!.keys)
            let sortedYears: [Int] = years.sort().reverse()
            let year: Int = sortedYears[indexPath.section]
            let performances: [PhishSongPerformance] = self.history![year]!
            
            /// get the ID of the show
            let performance: PhishSongPerformance = performances[indexPath.row]
            
            /// set the cell's performance
            cell.performance = performance
            
            /// set the cell's date
            cell.textLabel?.text = performance.date
            
            if let tourName = performance.tourName
            {
                cell.detailTextLabel?.text = tourName
                cell.userInteractionEnabled = (performance.tourID?.integerValue == 71) ? false : true
            }
            else
            {
                /// get the tour ID to request
                if let tourID = performance.tourID
                {
                    PhishModel.sharedInstance().getTourNameForTourID(tourID.integerValue)
                    {
                        tourNameError, tourName in
                        
                        /// something went wrong
                        if tourNameError != nil
                        {
                            /// update the cell to reflect that the tour couldn't be retrieved
                            dispatch_async(dispatch_get_main_queue())
                            {
                                cell.detailTextLabel?.textColor = UIColor.redColor()
                                cell.detailTextLabel?.text = "Tour Error..."
                            }
                        }
                        else
                        {
                            /// set the tour name and save the context
                            performance.tourName = tourName
                            
                            /// update the cell with the tour name on the main thread and enable the cell
                            dispatch_async(dispatch_get_main_queue())
                            {
                                cell.detailTextLabel?.text = tourName
                                
                                /// tour ID 71 means, "Not Part of a Tour"; these cells are disabled
                                cell.userInteractionEnabled = (tourID == 71) ? false : true
                            }
                        }
                    }
                }
                else
                {
                    /// we didn't have the tour ID, but we can get it from the show
                    PhishinClient.sharedInstance().requestTourIDFromShowForID(performance.showID.integerValue)
                    {
                        tourIDRequestError, tourID in
                        
                        /// something went wrong
                        if tourIDRequestError != nil
                        {
                            /// update the cell to reflect that the tour couldn't be retrieved
                            dispatch_async(dispatch_get_main_queue())
                            {
                                cell.detailTextLabel?.textColor = UIColor.redColor()
                                cell.detailTextLabel?.text = "Tour Error..."
                            }
                        }
                        /// we got the tour ID, now we can request the tour name with it
                        else
                        {
                            CoreDataStack.sharedInstance().managedObjectContext.performBlockAndWait()
                            {
                                /// set the show's tour ID
                                performance.tourID = tourID
                            }
                            
                            PhishModel.sharedInstance().getTourNameForTourID(tourID.integerValue)
                            {
                                tourNameError, tourName in
                                
                                /// something went wrong
                                if tourNameError != nil
                                {
                                    /// update the cell to reflect that the tour couldn't be retrieved
                                    dispatch_async(dispatch_get_main_queue())
                                    {
                                        cell.detailTextLabel?.textColor = UIColor.redColor()
                                        cell.detailTextLabel?.text = "Tour Error..."
                                    }
                                }
                                else
                                {
                                    CoreDataStack.sharedInstance().managedObjectContext.performBlockAndWait()
                                    {
                                        /// set the tour name
                                        performance.tourName = tourName
                                    }
                                    
                                    /// update the cell with the tour name on the main thread and enable the cell
                                    dispatch_async(dispatch_get_main_queue())
                                    {
                                        cell.detailTextLabel?.text = tourName
                                        
                                        /// tour ID 71 means, "Not Part of a Tour"; these cells are disabled
                                        cell.userInteractionEnabled = (tourID.integerValue == 71) ? false : true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        else
        {
            
            cell.textLabel?.font = UIFont(name: "Apple SD Gothic Neo", size: 14)
            cell.textLabel?.textColor = UIColor.blackColor()
            cell.textLabel?.text = "Requesting date..."
            cell.detailTextLabel?.font = UIFont(name: "Apple SD Gothic Neo", size: 14)
            cell.detailTextLabel?.textColor = UIColor.grayColor()
            cell.detailTextLabel?.text = "Requesting tour..."
            cell.userInteractionEnabled = false
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate method
    
    /// when a cell is selected, pop back to the map, which will now display the selected tour, and dislpay a callout on the associated show
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        /// get the cell that was selected
        let cell = tableView.cellForRowAtIndexPath( indexPath ) as! SongCell
        
        let performance = cell.performance
        
        /// get or create the tour that was selected
        PhishModel.sharedInstance().getTourForID(performance.tourID!.integerValue, inYear: performance.year.integerValue, withName: performance.tourName!)
        {
            tourError, tour in
            
            if tourError != nil
            {
                /// create an alert for the problem and unwind back to the setlist
                let alert = UIAlertController(title: "Whoops!", message: "There was an error with the tour for \(performance.date) \(performance.year): \(tourError!)", preferredStyle: .Alert)
                let alertAction = UIAlertAction(title: "OK", style: .Default)
                {
                    action in
                    
                    tableView.deselectRowAtIndexPath(indexPath, animated: true)
                }
                alert.addAction(alertAction)
                
                dispatch_async(dispatch_get_main_queue())
                {
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
            else
            {
                /// set the selected year
                PhishModel.sharedInstance().selectedYear = tour?.year!
                
                /// set the selected tour and the rest of the tours in the year
                PhishModel.sharedInstance().selectedTour = tour
                PhishModel.sharedInstance().currentTours = tour!.year!.tours!
                
                /// let the tour selecter know what to set the year and tour pickers to
                PhishModel.sharedInstance().previousYear = PhishModel.sharedInstance().years?.indexOf(tour!.year!)
                PhishModel.sharedInstance().previousTour = PhishModel.sharedInstance().currentTours?.indexOf(tour!)
                
                /// get the selected show
                PhishModel.sharedInstance().getShowForID(performance.showID.integerValue)
                {
                    showError, show in
                    
                    if showError != nil
                    {
                        CoreDataStack.sharedInstance().managedObjectContext.performBlockAndWait()
                        {
                            /// create an alert for the problem and unwind back to the setlist
                            let alert = UIAlertController(title: "Whoops!", message: "There was an error loading \(performance.date) for the \(tour!.name): \(showError!.localizedDescription)", preferredStyle: .Alert)
                            let alertAction = UIAlertAction(title: "OK", style: .Default)
                            {
                                action in
                                
                                tableView.deselectRowAtIndexPath(indexPath, animated: true)
                            }
                            alert.addAction(alertAction)
                            
                            dispatch_async(dispatch_get_main_queue())
                            {
                                self.presentViewController(alert, animated: true, completion: nil)
                            }
                        }
                    }
                    else
                    {
                        /// set the selected show
                        PhishModel.sharedInstance().currentShow = show
                        
                        /// get a reference to the tour map view controller, to let it know the song history view controller is updating it
                        let tourMap = self.navigationController?.viewControllers.first! as! TourMapViewController
                        tourMap.isComingFromSongHistory = true
                        
                        /// make the segue on the main thread, because we're modifying the map view
                        dispatch_async(dispatch_get_main_queue())
                        {
                            self.navigationController?.popToRootViewControllerAnimated(true)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: UIScrollViewDelegate method
    
    /// save the context after the table view stops scrolling, because tour objects are created as cells scroll into view;
    /// otherwise, the app crashes when saving tons of times consecutively
    func scrollViewDidEndDecelerating(scrollView: UIScrollView)
    {
        /// save new and updated objects to the context
        CoreDataStack.sharedInstance().managedObjectContext.performBlockAndWait()
        {
            CoreDataStack.sharedInstance().saveContext()
        }
    }
}
