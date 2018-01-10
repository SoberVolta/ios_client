//
//  EventDetailViewController.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/2/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import UIKit
import MapKit

enum RideStatus {
    case RideNotRequested
    case RideInQueue
    case RideActive
}

class EventDetailViewController : UIViewController, CLLocationManagerDelegate {
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    // Outlets
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var eventLocationLabel: UILabel!
    @IBOutlet weak var requestRideBtn: UIButton!
    @IBOutlet weak var offerDriveBtn: UIButton!
    @IBOutlet weak var saveEventBtn: UIButton!
    @IBOutlet weak var viewDriversBtn: UIButton!
    @IBOutlet weak var copyEventLinkBtn: UIButton!
    @IBOutlet weak var disableEventBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    
    // Models
    private var eventModel: EventModel!
    private var userModel: UserModel!
    private let locationManager = CLLocationManager()
    
    // Member variables
    let defaultButtonColor = UIColor(red: 0.0, green: 0.478431, blue: 1.0, alpha: 1.0)
    let cloverColor = UIColor(red: 0.0, green: 143/255, blue: 0.0, alpha: 1.0)
    private var rideStatus: RideStatus?
    private var currentRide: RideModel?
    private var currentLatitude: Double?
    private var currentLongitude: Double?
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - View Controller Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.startUpdatingLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
            forName: .EventPendingDriversDidChange,
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
        eventModel.notificationCenter.addObserver(
            forName: .EventActiveRidesDidChange,
            object: eventModel,
            queue: nil,
            using: rideStatusDidChange
        )
        userModel.notificationCenter.addObserver(
            forName: .UserSavedEventsDidChange,
            object: userModel,
            queue: nil,
            using: userSavedEventsDidChange
        )
        eventModel.notificationCenter.addObserver(
            forName: .EventDisabledDidChange,
            object: eventModel,
            queue: nil,
            using: eventDisabledDidChange
        )
        eventModel.notificationCenter.addObserver(
            forName: .EventDisabledDidChange,
            object: eventModel,
            queue: nil,
            using: eventOwnerDidChange
        )
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewDriveOffersSegue" {
            if let destinationVC = segue.destination as? ViewDriversViewController {
                destinationVC.prepareForDisplay(event: self.eventModel)
            }
        }
    }
    
    func exit() {
        performSegue(withIdentifier: "unwindFromEventDetail", sender: self)
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
        
        let pendingCount = eventModel.eventPendingDrivers.count
        self.viewDriversBtn.setTitle(
            "View Drivers \(pendingCount == 0 ? "" : "(\(pendingCount) Pending)")",
            for: .normal
        )
        
        // If user is in events drivers
        if eventModel.eventDrivers[userModel.userUID] != nil
            || eventModel.eventPendingDrivers[userModel.userUID] != nil {
            
            self.offerDriveBtn.setTitle("Cancel Drive Offer", for: .normal)
            self.offerDriveBtn.setTitleColor(.red, for: .normal)
            
        } else { // If user is not in events drivers
            
            self.offerDriveBtn.setTitle("Offer to Drive", for: .normal)
            self.offerDriveBtn.setTitleColor(defaultButtonColor, for: .normal)
            
        }
    }
    
    // Update Saved Event Button
    private func userSavedEventsDidChange(_:Notification? = nil) {
        
        // If event is saved
        if userModel.userSavedEvents[eventModel.eventID] != nil {
            
            self.saveEventBtn.setTitle("✔️ Event Saved!", for: .normal)
            
        // If event is not saved
        } else {
         
            self.saveEventBtn.setTitle("Save Event", for: .normal)
            
        }
    }
    
    // Update Diable Event Button
    private func eventDisabledDidChange(_:Notification? = nil) {
        if eventModel.eventDisabled {
            disableEventBtn.setTitle("Enable Event", for: .normal)
            disableEventBtn.setTitleColor(self.cloverColor, for: .normal)
        } else {
            disableEventBtn.setTitle("Disable Event", for: .normal)
            disableEventBtn.setTitleColor(.red, for: .normal)
        }
    }
    
    // Update Owner Only Buttons
    private func eventOwnerDidChange(_:Notification? = nil) {
        let hide = (self.userModel.userUID != self.eventModel.eventOwner)
        
        if hide && eventModel.eventDisabled {
            exit()
        }
        
        self.viewDriversBtn.isHidden = hide
        self.copyEventLinkBtn.isHidden = hide
        self.disableEventBtn.isHidden = hide
        self.deleteBtn.isHidden = hide
        
        
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
        if let lat = locationManager.location?.coordinate.latitude, let lon = locationManager.location?.coordinate.longitude {
            eventModel.enqueNewRideRequst(rider: userModel, latitude: lat, longitude: lon)
        }
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
        
        // If user drive offer is pending
        if eventModel.eventPendingDrivers[userModel.userUID] != nil {
            
            // Ask if they want to cancel their offer to drive
            displayActionSheet(
                viewController: self,
                actionSheetTitle: "Cancel Offer to Drive",
                actionSheetMessage: "Are you sure you want to resend you offer to drive for this event?",
                cancelTitle: "Keep Offer to Drive",
                affirmTitle: "Cancel Offer to Drive",
                affirmStyle: .destructive,
                affirmHandler: cancelPendingDriveOffer
            )
            
        // If user is an active driver
        } else if eventModel.eventDrivers[userModel.userUID] != nil  {
            
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
            
        // If user has not offered to drive
        } else {
            
            // Ask if they want to drive
            displayActionSheet(
                viewController: self,
                actionSheetTitle: "Offer to Drive",
                actionSheetMessage: "Are you sure you want to drive for \(self.eventModel.eventName ?? "this event")?",
                cancelTitle: "Cancel",
                affirmTitle: "Offer to Drive",
                affirmHandler: offerDrive
            )
            
        }
    }
    
    private func offerDrive(_: UIAlertAction? = nil) {
        eventModel.addDriveOffer(driver: userModel)
    }
    
    private func cancelPendingDriveOffer(_: UIAlertAction? = nil) {
        eventModel.cancelPendingDriveOffer(driverUID: userModel.userUID)
    }
    
    private func cancelDriveOffer(_: UIAlertAction? = nil) {
        eventModel.removeDriverFromEvent(driverUID: userModel.userUID)
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Save Event
    //-----------------------------------------------------------------------------------------------------------------
    
    @IBAction func saveEventBtnPressed(sender:Any? = nil) {
        
        // If event is saved
        if userModel.userSavedEvents[eventModel.eventID] != nil {
            
            userModel.unsaveEvent(eventID: eventModel.eventID)
            
        // If event is not saved
        } else {
            
            userModel.saveEvent(event: eventModel)
            
        }
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - View Drive Offers
    //-----------------------------------------------------------------------------------------------------------------
    
    @IBAction func viewDriveOffersBtnPressed(sender:Any? = nil) {
        performSegue(withIdentifier: "viewDriveOffersSegue", sender: self)
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Copy Event Link
    //-----------------------------------------------------------------------------------------------------------------
    
    @IBAction func copyEventLinkBtnPressed(sender:Any? = nil) {
        UIPasteboard.general.string = eventModel.eventHTTPLink
        
        self.copyEventLinkBtn.setTitle("✔️ Link Copied!", for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            self.copyEventLinkBtn.setTitle("Copy Event Link", for: .normal)
        })
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Disable Event
    //-----------------------------------------------------------------------------------------------------------------
    
    @IBAction func disableEventBtnPressed(sender:Any? = nil) {
        eventModel.eventDisabled ? eventModel.enableEvent() : eventModel.disableEvent()
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
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Location Manager Delegate
    //-----------------------------------------------------------------------------------------------------------------
    
    private func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            self.locationManager.startUpdatingLocation()
        } else {
            displayAlert(
                viewController: self,
                titleText: "Whoops!",
                messageText: "Dede needs your location in order for you to request a ride.",
                awknowledgeText: "Okay"
            )
        }
    }
    
}
