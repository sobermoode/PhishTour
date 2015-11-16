//
//  SetlistViewController.swift
//  PhishTourV2
//
//  Created by Aaron Justman on 10/13/15.
//  Copyright (c) 2015 AaronJ. All rights reserved.
//

import UIKit

class SetlistViewController: UIViewController,
    UITableViewDataSource , UITableViewDelegate
{
    var show: PhishShow!
    var setlist: [Int : [PhishSong]]?
    var setlistTable: UITableView!
    var progressBar: UIProgressView!
    var isRelaunchingApp: Bool = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // self.view.restorationIdentifier = "SetlistViewController"
        // self.restorationClass = SetlistViewController.self
        // self.saveToUserDefaults()
        setupNavBar()
        createScene()
        getSetlist()
    }
    
    override func viewDidAppear(animated: Bool)
    {
        if self.isRelaunchingApp
        {
            self.isRelaunchingApp = false
            
            if let previousHistorySettings = NSUserDefaults.standardUserDefaults().objectForKey("previousHistorySettings")
            {
                if let previousDateData = previousHistorySettings["previousDate"] as? NSData, let previousSongNameData = previousHistorySettings["previousSong"] as? NSData
                {
                    let previousDate = NSKeyedUnarchiver.unarchiveObjectWithData(previousDateData) as! String
                    let previousSongName = NSKeyedUnarchiver.unarchiveObjectWithData(previousSongNameData) as! String
                    let documentsPath: String = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
                    let documentsURL = NSURL(string: documentsPath)!
                    let filename = "song\(previousSongName)"
                    let fileURL = documentsURL.URLByAppendingPathComponent(filename)
                    let savedSong = NSKeyedUnarchiver.unarchiveObjectWithFile(fileURL.path!) as! PhishSong
                    
                    let historyViewController = SongHistoryViewController()
                    historyViewController.date = previousDate
                    historyViewController.song = savedSong
                    self.showViewController(historyViewController, sender: self)
                }
            }
        }
    }
    
    func setupNavBar()
    {
        let backButton = UIButton()
        backButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-SemiBold", size: 16)
        backButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        backButton.setTitle("< Tour Map", forState: .Normal)
        backButton.sizeToFit()
        backButton.addTarget(self, action: "backToMap", forControlEvents: .TouchUpInside)
        let navBackButton = UIBarButtonItem(customView: backButton)
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 20)
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.text = "PhishTour"
        titleLabel.sizeToFit()
        
        self.navigationItem.leftBarButtonItem = navBackButton
        self.navigationItem.titleView = titleLabel
    }
    
    func createScene()
    {
        view.backgroundColor = UIColor.whiteColor()
        
        // create the header labels
        let dateLabel = UILabel()
        dateLabel.font = UIFont(name: "AppleSDGothicNeo-SemiBold", size: 22)
        dateLabel.text = show.date
        dateLabel.sizeToFit()
        
        let yearLabel = UILabel()
        yearLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 26)
        yearLabel.text = show.year.description
        yearLabel.sizeToFit()
        
        let venueLabel = UILabel()
        venueLabel.font = UIFont(name: "Apple SD Gothic Neo", size: 14)
        venueLabel.text = show.venue + ", "
        venueLabel.sizeToFit()
        
        let cityLabel = UILabel()
        cityLabel.font = UIFont(name: "Apple SD Gothic Neo", size: 14)
        cityLabel.text = show.city
        cityLabel.sizeToFit()
        
        dateLabel.frame = CGRect(x: 25, y: 75, width: dateLabel.frame.size.width, height: dateLabel.frame.size.height)
        yearLabel.frame = CGRect(x: dateLabel.frame.origin.x + dateLabel.frame.size.width + 5, y: dateLabel.frame.origin.y - 3, width: yearLabel.frame.size.width, height: yearLabel.frame.size.height)
        venueLabel.frame = CGRect(x: dateLabel.frame.origin.x, y: dateLabel.frame.origin.y + dateLabel.frame.size.height + 5, width: venueLabel.frame.size.width, height: venueLabel.frame.size.height)
        cityLabel.frame = CGRect(x: venueLabel.frame.origin.x + venueLabel.frame.size.width + 5, y: venueLabel.frame.origin.y, width: cityLabel.frame.size.width, height: cityLabel.frame.size.height)
        
        view.addSubview(dateLabel)
        view.addSubview(yearLabel)
        view.addSubview(venueLabel)
        view.addSubview(cityLabel)
        
        // figure out how tall the table can be and create the table
        let remainingHeight = view.bounds.height - ((dateLabel.frame.origin.x + dateLabel.frame.size.height) + (venueLabel.frame.size.height + 5) + 50)
        let setlistTableView = UITableView(frame: CGRect(x: venueLabel.frame.origin.x, y: venueLabel.frame.origin.y + venueLabel.frame.size.height + 20, width: CGRectGetMaxX(view.bounds) - 50, height: remainingHeight - 75), style: .Plain)
        setlistTableView.separatorStyle = .None
        // setlistTableView.tag = 600
        setlistTableView.dataSource = self
        setlistTableView.delegate = self
        
        /// register the table view's cell class and header class
        setlistTableView.registerClass(SongCell.self, forCellReuseIdentifier: "songCell")
        setlistTableView.registerClass(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "SetHeader")
        
        self.setlistTable = setlistTableView
        
        view.addSubview(setlistTableView)
    }
    
    func getSetlist()
    {
        if self.show.setlist != nil
        {
            self.setlist = show.setlist
            self.setlistTable.reloadData()
            self.saveToUserDefaults()
        }
        else
        {
            /// create a progress bar to track the progress of requesting the setlist
            /// give the PhishinClient a reference to the progress bar, so it can update the bar as it does its thing
            let progressBar = UIProgressView(progressViewStyle: .Default)
            // progressBar.frame = CGRect(x: CGRectGetMinX(self.view.bounds), y: CGRectGetMinY(self.view.bounds) + UIApplication.sharedApplication().statusBarFrame.height + self.navigationController!.navigationBar.bounds.height, width: CGRectGetWidth(self.view.bounds), height: 10)
            progressBar.frame = CGRect(x: CGRectGetMinX(self.view.bounds), y: CGRectGetMinY(self.view.bounds) + 100, width: CGRectGetWidth(self.view.bounds), height: 10)
            progressBar.progressTintColor = UIColor.blueColor()
            progressBar.trackTintColor = UIColor.lightGrayColor()
            progressBar.transform = CGAffineTransformMakeScale(1, 2.5)
            self.progressBar = progressBar
            PhishinClient.sharedInstance().setlistProgressBar = self.progressBar
            self.view.addSubview(progressBar)
            
            PhishinClient.sharedInstance().requestSetlistForShow(show)
            {
                setlistError, setlist in
                
                if setlistError != nil
                {
                    /// create an alert for the problem and unwind back to the map
                    let alert = UIAlertController(title: "Whoops!", message: "There was an error requesting the setlist for \(self.show.date) \(self.show.year): \(setlistError!.localizedDescription)", preferredStyle: .Alert)
                    let alertAction = UIAlertAction(title: "OK", style: .Default)
                    {
                        action in
                        
                        self.backToMap()
                    }
                    alert.addAction(alertAction)
                    
                    dispatch_async(dispatch_get_main_queue())
                    {
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                }
                else
                {
                    self.setlist = setlist!
                    
                    self.saveToUserDefaults()
                    
                    dispatch_async(dispatch_get_main_queue())
                    {
                        self.setlistTable.reloadData()
                    }
                    
                    /// make the progress bar green when it finishes successfully
                    /// then, remove it after a short delay
                    dispatch_async(dispatch_get_main_queue())
                    {
                        self.progressBar?.progressTintColor = UIColor.greenColor()
                        dispatch_async(dispatch_get_main_queue())
                        {
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
    }
    
    func saveToUserDefaults()
    {
        var previousSetlistSettings = [String : AnyObject]()
        
        if let show = self.show
        {
            let previousShowIDData: NSData = NSKeyedArchiver.archivedDataWithRootObject(show.showID)
            previousSetlistSettings.updateValue(previousShowIDData, forKey: "previousShow")
        }
        
        NSUserDefaults.standardUserDefaults().setObject(previousSetlistSettings, forKey: "previousSetlistSettings")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func backToMap()
    {
        NSUserDefaults.standardUserDefaults().removeObjectForKey("previousSetlistSettings")
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    // MARK: UITableViewDataSource methods
    
    // each set and the encore will be a section in the table view
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        if setlist != nil
        {
            let numberOfSets: [Int] = Array(setlist!.keys)
        
            return numberOfSets.count
        }
        else
        {
            return 0
        }
    }
    
    // the number of rows will be equal to the number of songs played in the corresponding set
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if self.setlist != nil
        {
            var sets: [Int] = Array(self.setlist!.keys)
            sets.sortInPlace()
            
            let set: Int = sets[section]
            let songs: [PhishSong] = self.setlist![set]!
            
            return songs.count
        }
        else
        {
            return 0
        }
    }
    
    // the header view will indicate each set and the encore
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        // dequeue a header view
        let headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier("SetHeader") as UITableViewHeaderFooterView!
        
        // make sure the setlist exists
        guard self.setlist != nil
        else
        {
            headerView.textLabel?.text = ""
            
            return headerView
        }
        
        // get the title for the header view
        var sets: [Int] = Array(self.setlist!.keys)
        sets.sortInPlace()
        let set: Int = sets[section]
        
        if set == 10
        {
            headerView.textLabel?.text = "Soundcheck"
        }
        else if set == 20
        {
            headerView.textLabel?.text = "Encore"
        }
        else
        {
            headerView.textLabel?.text = "Set \(set)"
        }
        
        return headerView
    }
    
    // customize the header view before it is displayed
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        let headerView = view as! UITableViewHeaderFooterView
        
        headerView.layer.borderColor = UIColor.orangeColor().CGColor
        headerView.layer.borderWidth = 1
        headerView.textLabel!.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 14)
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 30
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 25
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        // dequeue a cell
        let cell = tableView.dequeueReusableCellWithIdentifier("songCell", forIndexPath: indexPath) as! SongCell
        
        // make sure the request was successful, and we have info to give to the table view
        if setlist != nil
        {
            // get to the song for the cell
            var sets: [Int] = Array(self.setlist!.keys)
            sets.sortInPlace()
            let set: Int = sets[indexPath.section]
            let songs: [PhishSong] = setlist![set]!
            let song: PhishSong = songs[indexPath.row]
            
            // set the cell properties
            cell.song = song
            
            cell.textLabel?.font = UIFont(name: "Apple SD Gothic Neo", size: 14)
            cell.textLabel?.text = song.name
            
            cell.detailTextLabel?.font = UIFont(name: "Apple SD Gothic Neo", size: 14)
            cell.detailTextLabel?.text = song.duration
        }
        // no table info yet, just keep the cell blank for the time being
        else
        {
            cell.textLabel?.text = ""
            cell.detailTextLabel?.text = ""
        }
        
        return cell
    }
    
    // segue to the song history scene for whichever song was selected
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! SongCell
        
        let songHistory = SongHistoryViewController()
        songHistory.date = "\(show.date) \(show.year)"
        songHistory.song = cell.song
        
        showViewController(songHistory, sender: self)
    }
}
