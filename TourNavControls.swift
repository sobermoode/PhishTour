//
//  TourNavControls.swift
//  PhishTour
//
//  Created by Aaron Justman on 10/26/15.
//  Copyright © 2015 AaronJ. All rights reserved.
//

/*
* NOTE: (11.15.2015)
* I had ideas for "following" the tour, with controls for going back and forth from show to show,
* along the tour. The buttons and the functionality were implemented at one point in the project,
* but, ultimately, it wasn't providing any more information than the pin callouts and the table
* view with the list of shows, and it wasn't necessarily a good way of seeing the tour information.
* I tried to come up with a good idea for how to use them, but I ended up getting rid of everything
* except the List button. Maybe in a future update I'll add them back with better functionality.
*/

import UIKit

class TourNavControls: NSObject
{
    /// the control button
    let listButton = UIButton(type: .Custom)
    
    /// the superview
    let parentView: UIView!
    
    /// tour nav controls delegate
    var delegate: TourNavControlsDelegate?
    
    init(parentView: UIView)
    {
        self.parentView = parentView
        
        super.init()
        
        /// create the list button and set it on the bottom of the screen
        self.listButton.setImage(UIImage(named: "listButton"), forState: .Normal)
        self.listButton.sizeToFit()
        self.listButton.alpha = 0.5
        self.listButton.frame = CGRect(x: CGRectGetMidX(parentView.bounds) - (self.listButton.bounds.width / 2), y: CGRectGetMaxY(parentView.bounds) - self.listButton.bounds.height, width: self.listButton.bounds.width, height: self.listButton.bounds.height)
        self.listButton.addTarget(self, action: "didPressListButton", forControlEvents: .TouchUpInside)
    }
    
    /// add the control button
    func addButtons()
    {
        parentView.addSubview(self.listButton)
    }
    
    /// remove the control button
    func removeButtons()
    {
        self.listButton.removeFromSuperview()
    }
    
    // MARK: TourNavControlsDelegate methods
    
    func didPressListButton()
    {
        guard delegate != nil else
        {
            print("You didn't set the TourNavControls delegate!!!")
            return
        }
        
        delegate!.didPressListButton()
    }
}

// MARK: TourNavControls protocol

protocol TourNavControlsDelegate
{
    func didPressListButton()
}
