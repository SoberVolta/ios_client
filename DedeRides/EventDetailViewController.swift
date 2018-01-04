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
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    // Segue initialized variables
    var currentUser: User?
    var eventUID: String?
    
    // Outlets
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var eventLocationLabel: UILabel!
    @IBOutlet weak var requestRideBtn: UIButton!
    @IBOutlet weak var offerDriveBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    
    // Database references
    let ref = Database.database().reference()
    let eventsRef = Database.database().reference().child("events")
    let usersRef = Database.database().reference().child("users")
    let ridesRef = Database.database().reference().child("rides")
    
    // Member variables
    private var uiReady = false;
    private var eventNameText: String?
    private var eventLocationText = "Unspecified Location"
    private var eventOwner: String?
    private var userHasRequestedRide = false
    private var userRideRequestID: String?
    private var userIsInActiveRide = false
    private var blueButtonColor: UIColor?
    private var userHasOfferedDrive = false
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - View Controller Functions
    //-----------------------------------------------------------------------------------------------------------------
    
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
                
                // Check for active ride
                self.userIsInActiveRide = false
                if !self.userHasRequestedRide {
                    Database.database().reference().child("users").child(user.uid).child("rides")
                        .observeSingleEvent(of: .value) { (snap) in
                        if let ridesData = snap.value as? [String:Any] {
                            for rideID in Array(ridesData.keys) {
                                if let eventIDForCurrentRide = ridesData[rideID] as? String {
                                    if eventIDForCurrentRide == eventID {
                                        self.userIsInActiveRide = true
                                    }
                                }
                            }
                        }
                        self.updateUI()
                    }
                } else {
                    self.updateUI()
                }
            } else {
                print("Cannot parse event as [String:String]")
            }
        }
        
    }
    
    func updateUI() {
        if(!uiReady) {
            return;
        }
        
        // Set labels
        self.title = eventNameText
        eventNameLabel.text = eventNameText
        eventLocationLabel.text = eventLocationText
        
        // Hide/Show delete button
        if let eventOwnerUID = self.eventOwner {
            if let curUser = self.currentUser {
                if curUser.uid != eventOwnerUID {
                    self.deleteBtn.isHidden = true
                } else {
                    self.deleteBtn.isHidden = false
                }
            }
        }
        
        // Update "Request Ride" button depending on current ride status
        // (not requested/requested/driver en route)
        if userHasRequestedRide {
            // Ride status: Requested
            self.blueButtonColor = requestRideBtn.tintColor
            requestRideBtn.setTitle("Cancel Ride Request", for: .normal)
            requestRideBtn.setTitleColor(.red, for: .normal)
        } else if userIsInActiveRide {
            // Ride status: Driver en route
            self.blueButtonColor = requestRideBtn.tintColor
            requestRideBtn.setTitle("Cancel Ride Request", for: .normal)
            requestRideBtn.setTitleColor(.gray, for: .normal)
            requestRideBtn.isEnabled = false
        } else {
            // Ride status: Not requested
            requestRideBtn.setTitle("Request a Ride", for: .normal)
            requestRideBtn.isEnabled = true
            if let color = self.blueButtonColor {
                requestRideBtn.setTitleColor(color, for: .normal)
            }
        }
        
        // Update "Offer Drive" button based on if user has already offered to drive or not
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
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Request Ride
    //-----------------------------------------------------------------------------------------------------------------
    
    @IBAction func requestRideBtnPressed() {
        
        // If the user has not already requested a ride...
        if !self.userHasRequestedRide {
            
            // Ask if they want to request a ride
            displayActionSheet(
                viewController: self,
                actionSheetTitle: "Request a Ride",
                actionSheetMessage: "Are you sure you want to request a ride to \(eventNameText ?? "this event")?",
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
    
    func requestRide(_: UIAlertAction? = nil) {
        
        // Get values
        if let curUser = self.currentUser {
            if let eventID = self.eventUID {
                
                // Generte new key
                let rideKey = self.ridesRef.childByAutoId().key
                
                // Form new data
                let rideData: [String : Any] = [
                    "status": 0,         // requested but not yet claimed
                    "rider": curUser.uid,
                    "event": eventID
                ]
                
                // Update database
                let updates: [String : Any] = [
                    "/rides/\(rideKey)": rideData,
                    "/events/\(eventID)/queue/\(rideKey)": curUser.uid,
                    "/users/\(curUser.uid)/rides/\(rideKey)": eventID
                ]
                ref.updateChildValues(updates)
                
                // Update UI
                prepareForDisplay(user: curUser, eventID: eventID)
            }
        }
    }
    
    func cancelRideRequest(_: UIAlertAction? = nil) {
        
        // Get values
        if let curUser = self.currentUser {
            if let eventID = self.eventUID {
                if let rideID = self.userRideRequestID {
                    
                    // Update database
                    let updates: [String : Any] = [
                        "/rides/\(rideID)": NSNull(),
                        "/events/\(eventID)/queue/\(rideID)": NSNull(),
                        "/users/\(curUser.uid)/rides/\(rideID)": NSNull()
                    ]
                    ref.updateChildValues(updates)
                    
                    // Update UI
                    prepareForDisplay(user: curUser, eventID: eventID)
                    
                }
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Offer Drive
    //-----------------------------------------------------------------------------------------------------------------
    
    @IBAction func offerDriveBtnPressed() {
        
        // If user has not yet offered to drive...
        if !self.userHasOfferedDrive {
            
            // Ask if they want to drive
            displayActionSheet(
                viewController: self,
                actionSheetTitle: "Offer to Drive",
                actionSheetMessage: "Are you sure you want to drive for \(eventNameText ?? "thisEvent")?",
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
    
    func offerDrive(_: UIAlertAction? = nil) {
        
        // Get values
        if let curUser = self.currentUser {
            if let eventID = self.eventUID {
                if let eventName = self.eventNameText {
                    
                    // Update Database
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
    
    func cancelDriveOffer(_: UIAlertAction? = nil) {
        
        // Get values
        if let curUser = self.currentUser {
            if let eventID = self.eventUID {
                
                // Update Database
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
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Delete
    //-----------------------------------------------------------------------------------------------------------------
    
    @IBAction func deleteEventBtnPressed() {
        
        // Confirm the user actually wants to delete event
        displayActionSheet(
            viewController: self,
            actionSheetTitle: "Delete Event",
            actionSheetMessage: "Are you sure you want to delete \(eventNameText ?? "thisEvent")",
            cancelTitle: "Cancel",
            affirmTitle: "Delete",
            affirmHandler: deleteCurrentEvent
        )
        
    }
    
    func deleteCurrentEvent(_: UIAlertAction? = nil) {
        // FIXME: Implement Delete Function
        print("Delete Current Event")
    }
    
}
