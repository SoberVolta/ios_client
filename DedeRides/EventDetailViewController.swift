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
    @IBOutlet weak var requestRideBtn: UIButton!
    @IBOutlet weak var offerDriveBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    
    let ref = Database.database().reference()
    let eventsRef = Database.database().reference().child("events")
    let usersRef = Database.database().reference().child("users")
    let ridesRef = Database.database().reference().child("rides")
    
    private var uiReady = false;
    private var eventNameText: String?
    private var eventLocationText = "Unspecified Location"
    private var eventOwner: String?
    private var userHasRequestedRide = false
    private var userRideRequestID: String?
    private var blueButtonColor: UIColor?
    private var userHasOfferedDrive = false
    
    override func viewWillAppear(_ animated: Bool) {
        uiReady = true;
        updateUI()
    }
    
    func prepareForDisplay(user: User, eventID: String) {
        self.currentUser = user
        self.eventUID = eventID
        
        eventsRef.child(eventID).observeSingleEvent(of: .value) { (snap) in
            if let eventData = snap.value as? [String:Any] {
                
                // Get Values
                self.eventNameText = eventData["name"] as? String ?? "Unnamed Event"
                self.eventLocationText = eventData["location"] as? String ?? "Unspecified Location"
                self.eventOwner = eventData["owner"] as? String
                
                // Check ride status
                self.userHasRequestedRide = false
                self.userRideRequestID = nil
                if let queue = eventData["queue"] as? [String:String] {
                    for rideID in Array(queue.keys) {
                        if queue[rideID] == user.uid {
                            self.userHasRequestedRide = true
                            self.userRideRequestID = rideID
                            break
                        }
                    }
                } else {
                    print("Not able to parse queue")
                }
                
                // Check driver status
                self.userHasOfferedDrive = false
                if let drivers = eventData["drivers"] as? [String:Any] {
                    if drivers[user.uid] != nil {
                      self.userHasOfferedDrive = true
                    }
                } else {
                    print("Not able to parse drivers")
                }
                
                // Update UI
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
        
        self.title = eventNameText
        
        eventNameLabel.text = eventNameText
        eventLocationLabel.text = eventLocationText
        
        if let eventOwnerUID = self.eventOwner {
            if let curUser = self.currentUser {
                if curUser.uid != eventOwnerUID {
                    self.deleteBtn.isHidden = true
                }
            }
        }
        
        if userHasRequestedRide {
            self.blueButtonColor = requestRideBtn.tintColor
            requestRideBtn.setTitle("Cancel Ride Request", for: .normal)
            requestRideBtn.setTitleColor(.red, for: .normal)
        } else {
            requestRideBtn.setTitle("Request a Ride", for: .normal)
            if let color = self.blueButtonColor {
                requestRideBtn.setTitleColor(color, for: .normal)
            }
        }
        
        if userHasOfferedDrive {
            self.blueButtonColor = requestRideBtn.tintColor
            offerDriveBtn.setTitle("Cancel Drive Offer", for: .normal)
            offerDriveBtn.setTitleColor(.red, for: .normal)
        } else {
            offerDriveBtn.setTitle("Offer to Drive", for: .normal)
            if let color = self.blueButtonColor {
                offerDriveBtn.setTitleColor(color, for: .normal)
            }
        }
        
    }
    
    @IBAction func requestRideBtnPressed() {
        if(userHasRequestedRide) {
            confirmCancelRideRequest()
        } else {
            confirmRideRequest()
        }
    }
    
    func confirmRideRequest() {
        let actionSheet = UIAlertController(title: "Request a Ride", message: "Are you sure you want to request a ride to \(eventNameText)?", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        let requestRideAction = UIAlertAction(title: "Request a Ride", style: .default, handler: requestRide)
        actionSheet.addAction(requestRideAction)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func confirmCancelRideRequest() {
        let actionSheet = UIAlertController(title: "Cancel Ride Request", message: "Are you sure you want to cancel your ride request to \(eventNameText)?", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Keep Ride Request", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        let requestRideAction = UIAlertAction(title: "Cancel Ride Request", style: .default, handler: cancelRideRequest)
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
                    "/events/\(eventID)/queue/\(rideKey)": curUser.uid,
                    "/users/\(curUser.uid)/rides/\(rideKey)": eventID
                ]
                
                // Update database
                ref.updateChildValues(updates)
                
                // Update UI
                prepareForDisplay(user: curUser, eventID: eventID)
            }
        }
    }
    
    func cancelRideRequest(_: UIAlertAction) {
        if let curUser = self.currentUser {
            if let eventID = self.eventUID {
                if let rideID = self.userRideRequestID {
                    let updates: [String : Any] = [
                        "/rides/\(rideID)": NSNull(),
                        "/events/\(eventID)/queue/\(rideID)": NSNull(),
                        "/users/\(curUser.uid)/rides/\(rideID)": NSNull()
                    ]
                    
                    // Update database
                    ref.updateChildValues(updates)
                    
                    // Update UI
                    prepareForDisplay(user: curUser, eventID: eventID)
                }
            }
        }
    }
    
    @IBAction func offerDriveBtnPressed() {
        if(userHasOfferedDrive) {
            confirmCancelDriveOffer()
        } else {
            confirmOfferDrive()
        }
    }
    
    func confirmOfferDrive() {
        let actionSheet = UIAlertController(title: "Offer to Drive", message: "Are you sure you want to offer to drive for \(eventNameText ?? "Unnamed Event")?", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        let offerDriveAction = UIAlertAction(title: "Offer to Drive", style: .default, handler: offerDrive)
        actionSheet.addAction(offerDriveAction)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func confirmCancelDriveOffer() {
        let actionSheet = UIAlertController(title: "Cancel Offer to Drive", message: "Are you sure you want to offer to drive for \(eventNameText ?? "Unnamed Event")?", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Keep Offer to Drive", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        let affirm = UIAlertAction(title: "Cancel Offer to Drive", style: .default, handler: cancelDriveOffer)
        actionSheet.addAction(affirm)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func offerDrive(_: UIAlertAction) {
        if let curUser = self.currentUser {
            if let eventID = self.eventUID {
                if let eventName = self.eventNameText {
                    let updates = [
                        "/events/\(eventID)/drivers/\(curUser.uid)": curUser.displayName ?? "Unnamed Driver",
                        "/users/\(curUser.uid)/drivesFor/\(eventID)": eventName
                    ]
                    ref.updateChildValues(updates)
                
                    // Update UI
                    prepareForDisplay(user: curUser, eventID: eventID)
                }
            }
        }
    }
    
    func cancelDriveOffer(_: UIAlertAction) {
        if let curUser = self.currentUser {
            if let eventID = self.eventUID {
                let updates = [
                    "/events/\(eventID)/drivers/\(curUser.uid)": NSNull(),
                    "/users/\(curUser.uid)/drivesFor/\(eventID)": NSNull()
                ]
                
                ref.updateChildValues(updates)
                
                // Update UI
                prepareForDisplay(user: curUser, eventID: eventID)
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
