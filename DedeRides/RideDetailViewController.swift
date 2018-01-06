//
//  RideDetailViewController.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/2/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class RideDetailViewController : UIViewController {
    
    var rideUID: String?
    var currentUser: User?
    var eventName: String?
    
    @IBOutlet weak var eventLink: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var driverLabel: UILabel!
    @IBOutlet weak var driverIndicatorLabel: UILabel!
    @IBOutlet weak var cancelRideBtn: UIButton!
    
    let ref = Database.database().reference()
    let ridesRef = Database.database().reference().child("rides")
    let statusLookupTable = [
        "Waiting in queue",
        "Driver en route"
    ]
    
    var uiReady = false;
    var dbEventID: String?
    var dbStatus: Int?
    var dbDriverID: String?
    var dbRiderID: String?
    
    override func viewWillAppear(_ animated: Bool) {
        uiReady = true;
        prepareForDisplay(rideID: self.rideUID!, user: self.currentUser!, eventName: self.eventName!)
    }
    
    func prepareForDisplay(rideID: String, user: User, eventName: String) {
        self.rideUID = rideID
        self.currentUser = user
        self.eventName = eventName
        
        ridesRef.child(rideID).observeSingleEvent(of: .value) {(snap) in
            if let rideData = snap.value as? [String:Any] {
                if let eventID = rideData["event"] as? String {
                    self.dbEventID = eventID
                } else {
                    self.dbEventID = nil
                }
                if let status = rideData["status"] as? Int {
                    self.dbStatus = status
                }else {
                    self.dbStatus = nil
                }
                if let driverID = rideData["driver"] as? String {
                    self.dbDriverID = driverID
                }else {
                    self.dbDriverID = nil
                }
                if let riderID = rideData["rider"] as? String {
                    self.dbRiderID = riderID
                }else {
                    self.dbRiderID = nil
                }
            } else {
                self.exit()
            }
            self.updateUI()
        }
    }
    
    func updateUI() {
        if(!uiReady) {
            return;
        }
        
        self.title = "Ride to \(self.eventName ?? "")"
        self.eventLink.setTitle(eventName, for: .normal)
        self.statusLabel.text = statusLookupTable[dbStatus ?? 0]
        self.driverLabel.text = dbDriverID
        if dbDriverID == nil {
            self.driverIndicatorLabel.text = nil
        }
        if let status = self.dbStatus {
            if status == 0 {
                cancelRideBtn.isEnabled = true
                cancelRideBtn.setTitleColor(.red, for: .normal)
            } else if status == 1 {
                cancelRideBtn.isEnabled = false
                cancelRideBtn.setTitleColor(.gray, for: .normal)
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueFromRideDetailToEventDetail" {
            if let destinationVC = segue.destination as? EventDetailViewController {
                if let curUser = self.currentUser {
                    if let eventID = self.dbEventID {
                        destinationVC.prepareForDisplay(userUID: curUser.uid, eventID: eventID)
                    }
                }
            }
        }
    }
    
    @IBAction func eventLinkButtonPressed() {
        performSegue(withIdentifier: "segueFromRideDetailToEventDetail", sender: self)
    }
    
    @IBAction func cancelRideRequestButtonPressed() {
        let actionSheet = UIAlertController(title: "Cancel Ride Request", message: "Are you sure you want to cancel your ride request to \(self.eventName ?? "Undetermined Event")?", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Keep Ride Request", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        let requestRideAction = UIAlertAction(title: "Cancel Ride Request", style: .default, handler: cancelRideRequest)
        actionSheet.addAction(requestRideAction)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func cancelRideRequest(_: UIAlertAction) {
        if let curUser = self.currentUser {
            if let eventID = self.dbEventID {
                if let rideID = self.rideUID {
                    let updates: [String : Any] = [
                        "/rides/\(rideID)": NSNull(),
                        "/events/\(eventID)/queue/\(rideID)": NSNull(),
                        "/users/\(curUser.uid)/rides/\(rideID)": NSNull()
                    ]
                    
                    // Update database
                    ref.updateChildValues(updates)
                    
                    exit()
                }
            }
        }
    }
    
    func exit() {
        performSegue(withIdentifier: "unwindFromRideDetailToMainMenu", sender: self)
    }
}
