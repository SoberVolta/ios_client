//
//  EventDetailViewController.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/2/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import UIKit

enum RideStatus {
    case RideNotRequested
    case RideInQueue
    case RideActive
}

class EventDetailViewController : UIViewController {
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    // Outlets
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var eventLocationLabel: UILabel!
    @IBOutlet weak var requestRideBtn: UIButton!
    @IBOutlet weak var offerDriveBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    
    // Models
    private var eventModel: EventModel!
    private var userModel: UserModel!
    
    // Member variables
    let defaultButtonColor = UIColor(red: 0.0, green: 0.478431, blue: 1.0, alpha: 1.0)
    private var rideStatus: RideStatus?
    private var currentRide: RideModel?
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - View Controller Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    override func viewWillAppear(_ animated: Bool) {
        // Attach listeners
        self.userModel.attachDatabaseListeners()
        self.eventModel.attachDatabaseListeners()
    }
    
    func prepareForDisplay(userModel: UserModel, eventID: String) {
        
        // User Model
        self.userModel = userModel
        
        // Create Event Model
        self.eventModel = EventModel(eventID: eventID)
        
        // Add Notification Observers
        eventModel.notificationCenter.addObserver(
            forName: .EventNameDidChange,
            object: eventModel,
            queue: nil,
            using: eventNameDidChange
        )
        eventModel.notificationCenter.addObserver(
            forName: .EventLocationDidChange,
            object: eventModel,
            queue: nil,
            using: eventLocationDidChange
        )
        eventModel.notificationCenter.addObserver(
            forName: .EventQueueDidChange,
            object: eventModel,
            queue: nil,
            using: rideStatusDidChange
        )
        userModel.notificationCenter.addObserver(
            forName: .UserRidesSpaceDidChange,
            object: userModel,
            queue: nil,
            using: rideStatusDidChange
        )
        eventModel.notificationCenter.addObserver(
            forName: .EventDriversDidChange,
            object: eventModel,
            queue: nil,
            using: eventUserDriverDidChange
        )
        eventModel.notificationCenter.addObserver(
            forName: .EventOwnerDidChange,
            object: eventModel,
            queue: nil,
            using: eventOwnerDidChange
        )
        
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Notification Listeners
    //-----------------------------------------------------------------------------------------------------------------
    
    // Update Event Name
    private func eventNameDidChange(_:Notification? = nil) {
        self.eventNameLabel.text = self.eventModel.eventName
        self.title = self.eventModel.eventName
    }
    
    // Update Event Location
    private func eventLocationDidChange(_:Notification? = nil) {
        self.eventLocationLabel.text = self.eventModel.eventLocation
    }
    
    // Update Request Ride Button
    private func rideStatusDidChange(_:Notification? = nil) {
        
        self.updateRideStatus()
        
        // Change button colors dependent on ride status
        if self.rideStatus == .RideNotRequested {
            self.requestRideBtn.setTitle("Request a Ride", for: .normal)
            self.requestRideBtn.isEnabled = true
            self.requestRideBtn.setTitleColor(defaultButtonColor, for: .normal)
        } else if self.rideStatus == .RideInQueue {
            self.requestRideBtn.setTitle("Cancel Ride Request", for: .normal)
            self.requestRideBtn.isEnabled = true
            self.requestRideBtn.setTitleColor(.red, for: .normal)
        } else if self.rideStatus == .RideActive {
            self.requestRideBtn.setTitle("Cancel Ride Request", for: .normal)
            self.requestRideBtn.isEnabled = false
            self.requestRideBtn.setTitleColor(.gray, for: .normal)
        }
    }
    
    private func updateRideStatus() {
        // Check if any user ride is also in event queue
        if let rideID = Set(userModel.userRides.keys).intersection(eventModel.eventQueue.keys).first {
            self.rideStatus = .RideInQueue
            self.currentRide = RideModel(rideID: rideID)
            return
        }
        
        // Check if any user ride is also in events active rides
        if let rideID = Set(userModel.userRides.keys).intersection(eventModel.eventActiveRides.keys).first{
            self.rideStatus = .RideActive
            self.currentRide = RideModel(rideID: rideID)
            return
        }
        
        
        self.rideStatus = .RideNotRequested
        self.currentRide = nil
    }
    
    // Update Offer Drive Button
    private func eventUserDriverDidChange(_:Notification? = nil) {
        
        // If user is in events drivers
        if eventModel.eventDrivers[userModel.userUID] != nil {
            
            self.offerDriveBtn.setTitle("Cancel Drive Offer", for: .normal)
            self.offerDriveBtn.setTitleColor(.red, for: .normal)
            
        } else { // If user is not in events drivers
            
            self.offerDriveBtn.setTitle("Offer to Drive", for: .normal)
            self.offerDriveBtn.setTitleColor(defaultButtonColor, for: .normal)
            
        }
    }
    
    // Update Delete Button
    private func eventOwnerDidChange(_:Notification? = nil) {
        self.deleteBtn.isHidden = (self.userModel.userUID != self.eventModel.eventOwner)
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Request Ride
    //-----------------------------------------------------------------------------------------------------------------
    
    @IBAction func requestRideBtnPressed() {
        
        // If the user has not already requested a ride...
        if self.rideStatus! == .RideNotRequested {
            
            // Ask if they want to request a ride
            displayActionSheet(
                viewController: self,
                actionSheetTitle: "Request a Ride",
                actionSheetMessage: "Are you sure you want to request a ride to \(eventModel.eventName ?? "this event")?",
                cancelTitle: "Cancel",
                affirmTitle: "Request a Ride",
                affirmHandler: requestRide
            )
            
        } else {
            
            // Ask if they want to cancel their ride request
            displayActionSheet(
                viewController: self,
                actionSheetTitle: "Cancel Ride Request",
                actionSheetMessage: "Are you sure you want to cancel your ride request?",
                cancelTitle: "Keep Ride Request",
                affirmTitle: "Cancel Ride Request",
                affirmStyle: .destructive,
                affirmHandler: cancelRideRequest
            )
            
        }
    }
    
    private func requestRide(_: UIAlertAction? = nil) {
        eventModel.enqueNewRideRequst(rider: userModel)
    }
    
    private func cancelRideRequest(_: UIAlertAction? = nil) {
        if let curRide = self.currentRide {
            curRide.cancelRideRequest()
        }
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Offer Drive
    //-----------------------------------------------------------------------------------------------------------------
    
    @IBAction func offerDriveBtnPressed() {
        
        // If user has not yet offered to drive...
        if eventModel.eventDrivers[userModel.userUID] == nil  {
            
            // Ask if they want to drive
            displayActionSheet(
                viewController: self,
                actionSheetTitle: "Offer to Drive",
                actionSheetMessage: "Are you sure you want to drive for \(self.eventModel.eventName ?? "this event")?",
                cancelTitle: "Cancel",
                affirmTitle: "Offer to Drive",
                affirmHandler: offerDrive
            )
            
        } else {
            
            // Ask if they want to cancel their offer to drive
            displayActionSheet(
                viewController: self,
                actionSheetTitle: "Cancel Offer to Drive",
                actionSheetMessage: "Are you sure you want to resend you offer to drive for this event?",
                cancelTitle: "Keep Offer to Drive",
                affirmTitle: "Cancel Offer to Drive",
                affirmStyle: .destructive,
                affirmHandler: cancelDriveOffer
            )
            
        }
    }
    
    private func offerDrive(_: UIAlertAction? = nil) {
        eventModel.addDriverToEvent(driver: userModel)
    }
    
    private func cancelDriveOffer(_: UIAlertAction? = nil) {
        eventModel.removeDriverFromEvent(driverUID: userModel.userUID)
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Delete
    //-----------------------------------------------------------------------------------------------------------------
    
    @IBAction func deleteEventBtnPressed() {
        
        // Confirm the user actually wants to delete event
        displayActionSheet(
            viewController: self,
            actionSheetTitle: "Delete Event",
            actionSheetMessage: "Are you sure you want to delete \(eventModel.eventName ?? "thisEvent")",
            cancelTitle: "Cancel",
            affirmTitle: "Delete",
            affirmStyle: .destructive,
            affirmHandler: deleteCurrentEvent
        )
        
    }
    
    private func deleteCurrentEvent(_: UIAlertAction? = nil) {
        // FIXME: Implement Delete Function
        print("Delete Current Event")
    }
    
}
