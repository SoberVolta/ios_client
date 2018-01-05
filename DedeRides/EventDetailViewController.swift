//
//  EventDetailViewController.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/2/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import UIKit
import Firebase

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
    private var currentRideID: String?
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - View Controller Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    func prepareForDisplay(user: User, eventID: String) {
        
        // Create Event Model
        self.eventModel = EventModel(eventID: eventID)
        
        // Create User Model
        self.userModel = UserModel(userUID: user.uid)
        
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
        
        // Attach listeners
        self.userModel.attachDatabaseListeners()
        self.eventModel.attachDatabaseListeners()
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Notification Listeners
    //-----------------------------------------------------------------------------------------------------------------
    
    // Update Event Name
    private func eventNameDidChange(_:Notification? = nil) {
        self.eventNameLabel.text = self.eventModel.eventName
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
        // Check if rider is in queue
        for rideID in Array(self.eventModel.eventQueue.keys) {
            if self.eventModel.eventQueue[rideID] == self.userModel.userUID {
                self.rideStatus = .RideInQueue
                self.currentRideID = rideID
                return
            }
        }
        
        // Check if user is going to this event
        for rideID in Array(self.userModel.userRides.keys) {
            if self.userModel.userRides[rideID] == self.eventModel.eventID {
                self.rideStatus = .RideActive
                self.currentRideID = rideID
                return
            }
        }
        
        self.rideStatus = .RideNotRequested
        self.currentRideID = nil
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
                affirmHandler: cancelRideRequest
            )
            
        }
    }
    
    private func requestRide(_: UIAlertAction? = nil) {
        
        // Generte new key
        let rideKey = Database.database().reference().child("rides").childByAutoId().key
        
        // Form new data
        let rideData: [String : Any] = [
            "status": 0,         // requested but not yet claimed
            "rider": userModel.userUID,
            "event": eventModel.eventID
        ]
        
        // Update database
        let updates: [String : Any] = [
            "/rides/\(rideKey)": rideData,
            "/events/\(eventModel.eventID)/queue/\(rideKey)": userModel.userUID,
            "/users/\(userModel.userUID)/rides/\(rideKey)": eventModel.eventID
        ]
        Database.database().reference().updateChildValues(updates)
        
    }
    
    private func cancelRideRequest(_: UIAlertAction? = nil) {
        
        if let rideID = self.currentRideID {
            
            // Update database
            let updates: [String : Any] = [
                "/rides/\(rideID)": NSNull(),
                "/events/\(eventModel.eventID)/queue/\(rideID)": NSNull(),
                "/users/\(userModel.userUID)/rides/\(rideID)": NSNull()
            ]
            Database.database().reference().updateChildValues(updates)
            
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
                affirmHandler: cancelDriveOffer
            )
            
        }
    }
    
    private func offerDrive(_: UIAlertAction? = nil) {
        
        // Update Database
        let updates = [
            "/events/\(eventModel.eventID)/drivers/\(userModel.userUID)": userModel.userDisplayName ?? "Unnamed Driver",
            "/users/\(userModel.userUID)/drivesFor/\(eventModel.eventID)": eventModel.eventName!
        ]
        Database.database().reference().updateChildValues(updates)
        
    }
    
    private func cancelDriveOffer(_: UIAlertAction? = nil) {
                
        // Update Database
        let updates = [
            "/events/\(eventModel.eventID)/drivers/\(userModel.userUID)": NSNull(),
            "/users/\(userModel.userUID)/drivesFor/\(eventModel.eventID)": NSNull()
        ]
        Database.database().reference().updateChildValues(updates)
        
        
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
            affirmHandler: deleteCurrentEvent
        )
        
    }
    
    private func deleteCurrentEvent(_: UIAlertAction? = nil) {
        // FIXME: Implement Delete Function
        print("Delete Current Event")
    }
    
}
