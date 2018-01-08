//
//  RideModel.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/5/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import Firebase

//-----------------------------------------------------------------------------------------------------------------
// MARK: - Notifications
//-----------------------------------------------------------------------------------------------------------------

extension NSNotification.Name {
    public static let RideEventDidChange = Notification.Name("RideEventDidChange")
    public static let RideRiderDidChange = Notification.Name("RideRiderDidChange")
    public static let RideDriverDidChange = Notification.Name("RideDriverDidChange")
    public static let RideStatusDidChange = Notification.Name("RideStatusDidChange")
    public static let RideWasRemoved = Notification.Name("RideWasRemoved")
}

class RideModel {
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    // Database References
    static let ref = Database.database().reference()
    static let rideSpaceRef = Database.database().reference().child("rides")
    let rideRef: DatabaseReference
    
    // Notification Center
    let notificationCenter: NotificationCenter
    
    // Initialized Value
    let rideID: String
    
    // Database Populated Values
    var rideEventID: String?
    var rideRiderUID: String?
    var rideDriverUID: String?
    var rideStatus: Int?
    var rideWasRemoved = false
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Initialization
    //-----------------------------------------------------------------------------------------------------------------
    
    init(rideID: String) {
        self.notificationCenter = NotificationCenter.default
        self.rideID = rideID
        self.rideRef = RideModel.rideSpaceRef.child(rideID)
        
        attachDatabaseListeners()
    }
    
    func attachDatabaseListeners() {
        self.rideRef.child("event").observe(.value, with: rideEventValueDidChange)
        self.rideRef.child("rider").observe(.value, with: rideRiderValueDidChange)
        self.rideRef.child("driver").observe(.value, with: rideDriverValueDidChange)
        self.rideRef.child("status").observe(.value, with: rideStatusValueDidChange)
        self.rideRef.observe(.value, with: rideWasRemovedValue)
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Static Update Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    static func createNewRide(forEventWithID eventID: String, withName eventName: String, userUID: String) {
        
        // Generte new key
        let rideKey = Database.database().reference().child("rides").childByAutoId().key
        
        // Form new data
        let rideData: [String : Any] = [
            "status": 0,         // requested but not yet claimed
            "rider": userUID,
            "event": eventID
        ]
        
        // Update database
        let updates: [String : Any] = [
            "/rides/\(rideKey)": rideData,
            "/events/\(eventID)/queue/\(rideKey)": userUID,
            "/users/\(userUID)/rides/\(rideKey)": eventName
        ]
        Database.database().reference().updateChildValues(updates)
    }
    
    static func cancelRideRequest(rideID: String, eventID: String, userUID: String) {
        
        // Update database
        let updates: [String : Any] = [
            "/rides/\(rideID)": NSNull(),
            "/events/\(eventID)/queue/\(rideID)": NSNull(),
            "/users/\(userUID)/rides/\(rideID)": NSNull()
        ]
        Database.database().reference().updateChildValues(updates)
    }
    
    func endActiveRide() {
        if let eventID = self.rideEventID, let riderUID = self.rideRiderUID, let driverUID = self.rideDriverUID {
            
            let updates: [String:Any] = [
                "/rides/\(self.rideID)": NSNull(),
                "/events/\(eventID)/activeRides/\(self.rideID)": NSNull(),
                "/users/\(driverUID)/drives/\(self.rideID)": NSNull(),
                "/users/\(riderUID)/rides/\(self.rideID)": NSNull()
            ]
            
            RideModel.ref.updateChildValues(updates)
        }
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Realtime Database Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    private func rideEventValueDidChange(snap:DataSnapshot) {
        self.rideEventID = snap.value as? String
        self.notificationCenter.post(name: .RideEventDidChange, object: self)
    }
    
    private func rideRiderValueDidChange(snap:DataSnapshot) {
        self.rideRiderUID = snap.value as? String
        self.notificationCenter.post(name: .RideRiderDidChange, object: self)
    }
    
    private func rideDriverValueDidChange(snap:DataSnapshot) {
        self.rideDriverUID = snap.value as? String
        self.notificationCenter.post(name: .RideDriverDidChange, object: self)
    }
    
    private func rideStatusValueDidChange(snap:DataSnapshot) {
        self.rideStatus = snap.value as? Int
        self.notificationCenter.post(name: .RideStatusDidChange, object: self)
    }
    
    private func rideWasRemovedValue(snap:DataSnapshot) {
        if let _ = snap.value as? [String:Any] {
        } else {
            self.rideWasRemoved = true
            self.notificationCenter.post(name: .RideWasRemoved, object: self)
        }
    }
    
}
