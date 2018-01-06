//
//  DriveDetailViewController.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/3/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class DriveDetailViewController: UIViewController {
    
    var currentUserUID: String?
    var eventUID: String?
    var eventName: String?
    
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var queueIdentifierLabel: UILabel!
    @IBOutlet weak var nextInQueueBtn: UIButton!
    @IBOutlet weak var currentRideIdentifierLabel: UILabel!
    @IBOutlet weak var currentRideBtn: UIButton!
    @IBOutlet weak var endCurrentDriveBtn: UIButton!
    @IBOutlet weak var cancelDriveOfferBtn: UIButton!
    
    let ref = Database.database().reference()
    let eventsRef = Database.database().reference().child("events")
    let ridesRef = Database.database().reference().child("rides")
    let usersRef = Database.database().reference().child("users")
    
    private var uiReady = false
    private var isActiveDrive = false;
    private var activeDriveID: String?
    private var riderWaitingInQueue = false
    private var nextRideInQueue: String?
    
    override func viewWillAppear(_ animated: Bool) {
        uiReady = true;
        updateUI()
    }
    
    func prepareForDisplay(userUID: String, eventID: String, eventName: String) {
        self.currentUserUID = userUID
        self.eventUID = eventID
        self.eventName = eventName
        
        self.isActiveDrive = false
        self.activeDriveID = nil
        
        usersRef.child(userUID).child("drives").observeSingleEvent(of: .value){(snap) in
            if let drivesData = snap.value as? [String:Any] {
                for drivesRideID in Array(drivesData.keys) {
                    if let drivesEventID = drivesData[drivesRideID] as? String {
                        if drivesEventID == eventID {
                            self.isActiveDrive = true
                            self.activeDriveID = drivesRideID
                            break
                        }
                    } else {
                        print("Cant parse event ID from drives space")
                    }
                }
            }
            self.updateUI()
        }
        
        eventsRef.child(eventID).child("queue").observeSingleEvent(of: .value) {(snap) in
            if let queueData = snap.value as? [String:Any] {
                let nextRide = Array(queueData.keys)[0]
                self.nextRideInQueue = nextRide
                self.riderWaitingInQueue = true
            } else {
                self.riderWaitingInQueue = false;
            }
            self.updateUI()
        }
    }
    
    func updateUI() {
        if !uiReady {
            return;
        }
        
        if(self.isActiveDrive) {
            self.queueIdentifierLabel.text = nil
            self.nextInQueueBtn.setTitle(nil, for: .normal)
            self.currentRideIdentifierLabel.text = "Current Ride"
            self.currentRideBtn.setTitle(self.activeDriveID ?? "Unidentified Ride", for: .normal)
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
        
        if(!self.riderWaitingInQueue) {
            self.nextInQueueBtn.isEnabled = false
        } else {
            self.nextInQueueBtn.isEnabled = true
        }
        
        self.title = "Drive for \(self.eventName ?? "Undetermined Event")"
        eventLabel.text = self.eventName
    }
    
    @IBAction func takeNextInQueueBtnPressed() {
        let actionSheet = UIAlertController(title: "Accept Next Rider in Queue", message: "Are you sure you want to accept the next ride waiting in the queue?", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        let affirm = UIAlertAction(title: "Accept Next Ride in Queue", style: .default, handler: takeNextInQueue)
        actionSheet.addAction(affirm)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func takeNextInQueue(_:UIAlertAction) {
        if let rideID = self.nextRideInQueue {
            if let eventID = self.eventUID {
                let updates: [String:Any] = [
                    "/users/\(self.currentUserUID!)/drives/\(rideID)": eventID,
                    "/rides/\(rideID)/status": 1,
                    "/rides/\(rideID)/driver:": self.currentUserUID!,
                    "/events/\(eventID)/queue/\(rideID)": NSNull(),
                    "/events/\(eventID)/activeRides/\(rideID)": self.currentUserUID!
                ]
                
                ref.updateChildValues(updates)
                
                prepareForDisplay(userUID: self.currentUserUID!, eventID: eventID, eventName: self.eventName!)
            }
        }
    }
    
    @IBAction func endCurrentDriveBtnPressed() {
        let actionSheet = UIAlertController(title: "End Current Drive", message: "Are you sure the current drive is over?", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        let affirm = UIAlertAction(title: "End Current Drive", style: .default, handler: endCurrentDrive)
        actionSheet.addAction(affirm)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func endCurrentDrive(_:UIAlertAction) {
        if let rideID = self.activeDriveID {
            if let eventID = self.eventUID {
                ridesRef.child(rideID).child("rider").observeSingleEvent(of: .value){(snap) in
                    if let riderUID = snap.value as? String {
                        let updates: [String:Any] = [
                            "/rides/\(rideID)": NSNull(),
                            "/events/\(eventID)/activeRides/\(rideID)": NSNull(),
                            "/users/\(self.currentUserUID!)/drives/\(rideID)": NSNull(),
                            "/users/\(riderUID)/rides/\(rideID)": NSNull()
                        ]
                        
                        self.ref.updateChildValues(updates)
                        
                        self.prepareForDisplay(userUID: self.currentUserUID!, eventID: eventID, eventName: self.eventName!)
                    } else {
                        print("Unable to parse rider id")
                    }
                }
            }
        }
    }
    
    @IBAction func cancelDriveOfferBtnPressed() {
        let actionSheet = UIAlertController(title: "Cancel Offer to Drive", message: "Are you sure you want to no longer offer to drive for \(self.eventName ?? "this event")?", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Continue Offering to Drive", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        let affirm = UIAlertAction(title: "Cancel Offer to Drive", style: .default, handler: cancelDriveOffer)
        actionSheet.addAction(affirm)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func cancelDriveOffer(_:UIAlertAction) {
        if let eventID = self.eventUID {
            let updates = [
                "/events/\(eventID)/drivers/\(self.currentUserUID!)": NSNull(),
                "/users/\(self.currentUserUID!)/drivesFor/\(eventID)": NSNull()
            ]
            
            ref.updateChildValues(updates)
            
            exit()
        }
    }
    
    func exit() {
        performSegue(withIdentifier: "unwindFromDriveDetailToMainMenu", sender: self)
    }
    
}
