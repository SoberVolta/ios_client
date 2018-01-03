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

class EventDetailViewController : UIViewController {
    
    var currentUser: User?
    var eventUID: String?
    
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var eventLocationLabel: UILabel!
    @IBOutlet weak var deleteBtn: UIButton!
    
    let ref = Database.database().reference()
    let eventsRef = Database.database().reference().child("events")
    let usersRef = Database.database().reference().child("users")
    let ridesRef = Database.database().reference().child("rides")
    
    private var uiReady = false;
    private var eventNameText = "Unnamed Event"
    private var eventLocationText = "Unspecified Location"
    private var eventOwner: String?
    
    override func viewDidAppear(_ animated: Bool) {
        uiReady = true;
        updateUI()
    }
    
    func prepareForDisplay(user: User, eventID: String) {
        self.currentUser = user
        self.eventUID = eventID
        
        eventsRef.child(eventID).observeSingleEvent(of: .value) { (snap) in
            if let eventData = snap.value as? [String:String] {
                self.eventNameText = eventData["name"] ?? "Unnamed Event"
                self.eventLocationText = eventData["location"] ?? "Unspecified Location"
                self.eventOwner = eventData["owner"]
                self.updateUI()
            } else {
                print("Cannot parse event as [String:String]")
            }
        }
        
    }
    
    func updateUI() {
        if(!uiReady) {
            return;
        }
        
        eventNameLabel.text = eventNameText
        eventLocationLabel.text = eventLocationText
        
        if let eventOwnerUID = self.eventOwner {
            if let curUser = self.currentUser {
                if curUser.uid != eventOwnerUID {
                    self.deleteBtn.isHidden = true
                }
            }
        }
    }
    
    @IBAction func requestRideBtnPressed() {
        let actionSheet = UIAlertController(title: "Request a Ride", message: "Are you sure you want to request a ride to \(eventNameText)?", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        let requestRideAction = UIAlertAction(title: "Request a Ride", style: .default, handler: requestRide)
        actionSheet.addAction(requestRideAction)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func requestRide(_: UIAlertAction) {
        if let curUser = self.currentUser {
            if let eventID = self.eventUID {
                // Get unique key
                let rideKey = self.ridesRef.childByAutoId().key
                
                // Set Data
                let rideData: [String : Any] = [
                    "status": 0,         // requested but not yet claimed
                    "rider": curUser.uid,
                    "event": eventID
                ]
                
                // Mark all updates
                let updates: [String : Any] = [
                    "/rides/\(rideKey)": rideData,
                    "/events/\(eventID)/queue/\(rideKey)": true,
                    "/users/\(curUser.uid)/rides/\(rideKey)": true
                ]
                
                // Update database
                ref.updateChildValues(updates)
            }
        }
    }
    
    @IBAction func offerRideBtnPressed() {
        let actionSheet = UIAlertController(title: "Offer to Drive", message: "Are you sure you want to offer to drive for \(eventNameText)?", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        let offerDriveAction = UIAlertAction(title: "Offer to Drive", style: .default, handler: offerDrive)
        actionSheet.addAction(offerDriveAction)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func offerDrive(_: UIAlertAction) {
        if let curUser = self.currentUser {
            if let eventID = self.eventUID {
                let updates = [
                    "/events/\(eventID)/drivers/\(curUser.uid)": true,
                    "/users/\(curUser.uid)/drivesFor/\(eventID)": true
                ]
                ref.updateChildValues(updates)
            }
        }
    }
    
    @IBAction func deleteEventBtnPressed() {
        let actionSheet = UIAlertController(title: "Delete Event", message: "Are you sure you want to delete \(eventNameText)?", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .default, handler: deleteCurrentEvent)
        actionSheet.addAction(deleteAction)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func deleteCurrentEvent(_: UIAlertAction) {
        
    }
    
}
