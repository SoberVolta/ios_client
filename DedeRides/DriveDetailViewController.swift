//
//  DriveDetailViewController.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/3/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import UIKit

class DriveDetailViewController: UIViewController {
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    // Segue Initialized Values
    var currentUser: UserModel!
    var eventModel: EventModel!
    
    // Outlets
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var queueIdentifierLabel: UILabel!
    @IBOutlet weak var nextInQueueBtn: UIButton!
    @IBOutlet weak var currentRideIdentifierLabel: UILabel!
    @IBOutlet weak var currentRideBtn: UIButton!
    @IBOutlet weak var endCurrentDriveBtn: UIButton!
    @IBOutlet weak var cancelDriveOfferBtn: UIButton!
    
    // Member variables
    private var activeDrive: RideModel?
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - View Controller Function
    //-----------------------------------------------------------------------------------------------------------------
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Add Notification Observers
        self.currentUser.notificationCenter.addObserver(
            forName: .UserActiveDrivesSpaceDidChange,
            object: currentUser,
            queue: nil,
            using: self.userActiveDrivesSpaceDidChange
        )
        self.eventModel.notificationCenter.addObserver(
            forName: .EventQueueDidChange,
            object: eventModel,
            queue: nil,
            using: self.eventQueueSpaceDidChange
        )
        self.eventModel.notificationCenter.addObserver(
            forName: .EventActiveRidesDidChange,
            object: eventModel,
            queue: nil,
            using: self.userActiveDrivesSpaceDidChange
        )
        self.eventModel.notificationCenter.addObserver(
            forName: .EventNameDidChange,
            object: self.eventModel,
            queue: nil,
            using: self.eventNameDidChange)
        
        // Trigger notifications for value updates
        eventModel.attachDatabaseListeners()
        currentUser.attachDatabaseListeners()
    }
    
    func prepareForDisplay(user: UserModel, event: EventModel) {
        self.currentUser = user
        self.eventModel = event
    }
    
    func exit() {
        performSegue(withIdentifier: "unwindFromDriveDetailToMainMenu", sender: self)
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Notification Observers
    //-----------------------------------------------------------------------------------------------------------------
    
    private func eventNameDidChange(_:Notification? = nil) {
        self.title = "Drive for \(self.eventModel.eventName ?? "Undetermined Event")"
        eventLabel.text = self.eventModel.eventName
    }
    
    private func userActiveDrivesSpaceDidChange(_:Notification? = nil) {
        if let rideID = Set(self.currentUser.userActiveDrives.keys).intersection(self.eventModel.eventActiveRides.keys).first {
            
            self.activeDrive = RideModel(rideID: rideID)
            self.queueIdentifierLabel.text = nil
            self.nextInQueueBtn.setTitle(nil, for: .normal)
            self.currentRideIdentifierLabel.text = "Current Ride"
            self.currentRideBtn.setTitle(rideID, for: .normal)
            self.endCurrentDriveBtn.setTitle("End Current Drive", for: .normal)
            self.cancelDriveOfferBtn.setTitle(nil, for: .normal)
            
        } else {
            
            self.queueIdentifierLabel.text = "Queue:"
            self.nextInQueueBtn.setTitle("Take Next Ride in Queue", for: .normal)
            self.currentRideIdentifierLabel.text = nil
            self.currentRideBtn.setTitle(nil, for: .normal)
            self.endCurrentDriveBtn.setTitle(nil, for: .normal)
            self.cancelDriveOfferBtn.setTitle("Cancel Drive Offer", for: .normal)
            
        }
    }
    
    private func eventQueueSpaceDidChange(_:Notification? = nil) {
        if  eventModel.eventQueue.count > 0 {
            self.nextInQueueBtn.isEnabled = true
        } else {
            self.nextInQueueBtn.isEnabled = false
        }
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Take Next In Queue
    //-----------------------------------------------------------------------------------------------------------------
    
    @IBAction func takeNextInQueueBtnPressed() {
        displayActionSheet(
            viewController: self,
            actionSheetTitle: "Accept Next Rider in Queue",
            actionSheetMessage: "Are you sure you want to accept the next rider in the queue?",
            cancelTitle: "Cancel",
            affirmTitle: "Accept Next Rider in Queue",
            affirmHandler: takeNextInQueue
        )
    }
    
    func takeNextInQueue(_:UIAlertAction) {
        self.eventModel.takeNextRideInQueue(driverUID: currentUser.userUID)
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - End Current Drive
    //-----------------------------------------------------------------------------------------------------------------
    
    @IBAction func endCurrentDriveBtnPressed() {
        displayActionSheet(
            viewController: self,
            actionSheetTitle: "End Current Drive",
            actionSheetMessage: "Are you sure the current drive is over?",
            cancelTitle: "Continue Current Drive",
            affirmTitle: "End Current Drive",
            affirmHandler: endCurrentDrive
        )
    }
    
    func endCurrentDrive(_:UIAlertAction) {
        if let curDrive = self.activeDrive {
            curDrive.endActiveRide()
        }
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Cancel Drive Offer
    //-----------------------------------------------------------------------------------------------------------------
    
    @IBAction func cancelDriveOfferBtnPressed() {
        displayActionSheet(
            viewController: self,
            actionSheetTitle: "Resend Offer to Drive",
            actionSheetMessage: "Are you sure you want to stop driving for \(eventModel.eventName ?? "this event")",
            cancelTitle: "Continue Driving",
            affirmTitle: "Resend Offer to Drive",
            affirmHandler: cancelDriveOffer
        )
    }
    
    func cancelDriveOffer(_:UIAlertAction) {
        eventModel.removeDriverFromEvent(driverUID: currentUser.userUID)
        exit()
    }
    
}
