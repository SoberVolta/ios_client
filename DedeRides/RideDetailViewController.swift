//
//  RideDetailViewController.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/2/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import UIKit

class RideDetailViewController : UIViewController {
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    // Segue Initialized Variables
    var rideModel: RideModel!
    var currentUser: UserModel!
    var eventName: String?
    
    // Outlets
    @IBOutlet weak var eventLink: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var driverLabel: UILabel!
    @IBOutlet weak var driverIndicatorLabel: UILabel!
    @IBOutlet weak var cancelRideBtn: UIButton!
    
    // Lookup table
    let statusLookupTable = [
        "Waiting in queue",
        "Driver en route"
    ]
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - View Controller Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    override func viewWillAppear(_ animated: Bool) {
        rideModel.attachDatabaseListeners()
        
        self.title = "Ride to \(self.eventName ?? "Unnamed Event")"
        self.eventLink.setTitle(self.eventName ?? "Unnamed Event", for: .normal)
    }
    
    func prepareForDisplay(ride: RideModel, user: UserModel, eventName: String) {
        self.rideModel = ride
        self.currentUser = user
        self.eventName = eventName
        
        // Add Notification Observers
        rideModel.notificationCenter.addObserver(
            forName: .RideStatusDidChange,
            object: rideModel,
            queue: nil,
            using: rideStatusDidChange
        )
        rideModel.notificationCenter.addObserver(
            forName: .RideDriverDidChange,
            object: rideModel,
            queue: nil,
            using: rideDriverDidChange
        )
        rideModel.notificationCenter.addObserver(forName: .RideWasRemoved, object: rideModel, queue: nil, using: rideWasRemoved)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueFromRideDetailToEventDetail" {
            if let destinationVC = segue.destination as? EventDetailViewController {
                destinationVC.prepareForDisplay(userModel: currentUser, eventID: rideModel.rideEventID!)
            }
        }
    }
    
    func exit() {
        performSegue(withIdentifier: "unwindFromRideDetailToMainMenu", sender: self)
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Follow Event Link
    //-----------------------------------------------------------------------------------------------------------------
    
    @IBAction func eventLinkButtonPressed() {
        performSegue(withIdentifier: "segueFromRideDetailToEventDetail", sender: self)
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Cancel Ride
    //-----------------------------------------------------------------------------------------------------------------
    
    @IBAction func cancelRideRequestButtonPressed() {
        displayActionSheet(
            viewController: self,
            actionSheetTitle: "Cancel Ride Request",
            actionSheetMessage: "Are you sure you want to cancel your ride request to \(self.eventName ?? "this event")?",
            cancelTitle: "Keep Ride Request",
            affirmTitle: "Cancel Ride Request",
            affirmHandler: cancelRideRequest
        )
    }
    
    func cancelRideRequest(_: UIAlertAction) {
        RideModel.cancelRideRequest(
            rideID: rideModel.rideID,
            eventID: rideModel.rideEventID!,
            userUID: currentUser.userUID
        )
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Notification Observer Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    private func rideStatusDidChange(_:Notification? = nil) {
        if let rideStatus = rideModel.rideStatus {
            self.statusLabel.text = statusLookupTable[rideStatus]
            
            if rideStatus == 0 {
                cancelRideBtn.isEnabled = true
                cancelRideBtn.setTitleColor(.red, for: .normal)
            } else {
                cancelRideBtn.isEnabled = false
                cancelRideBtn.setTitleColor(.gray, for: .normal)
            }
        }
    }
    
    private func rideDriverDidChange(_:Notification? = nil) {
        if rideModel.rideDriverUID == nil {
            self.driverIndicatorLabel.text = nil
        } else {
            self.driverIndicatorLabel.text = "Driver:"
        }
        self.driverLabel.text = rideModel.rideDriverUID
    }
    
    private func rideWasRemoved(_:Notification? = nil) {
        if rideModel.rideWasRemoved {
            exit()
        }
    }
}
