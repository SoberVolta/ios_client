//
//  UserModel.swift
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
    public static let UserDisplayNameDidChange = Notification.Name("UserDisplayNameDidChange")
    public static let UserOwnedEventsDidChange = Notification.Name("UserOwnedEventsDidChange")
    public static let UserRidesSpaceDidChange = Notification.Name("UserRidesSpaceDidChange")
    public static let UserDrivesForSpaceDidChange = Notification.Name("UserDrivesForSpaceDidChange")
}

class UserModel {
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    // Database Reference
    let userRef: DatabaseReference
 
    // Notification Center
    let notificationCenter: NotificationCenter

    // Initialized Value
    let userUID: String
    
    // Database Populated Values
    var userDisplayName: String?
    var userOwnedEvents: [String:String]?
    var userRides: [String:String]?
    var userDrivesFor: [String:String]?
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Initialization
    //-----------------------------------------------------------------------------------------------------------------
    
    init(userUID uid: String) {
        self.notificationCenter = NotificationCenter.default
        self.userUID = uid
        self.userRef = Database.database().reference().child("users").child(self.userUID)
    }
    
    func attachDatabaseListeners() {
        self.userRef.child("displayName").observe(.value, with: self.userDisplayNameValueDidChange)
        self.userRef.child("ownedEvents").observe(.value, with: self.userOwnedEventsValueDidChange)
        self.userRef.child("rides").observe(.value, with: self.userRidesSpaceValueDidChange)
        self.userRef.child("drivesFor").observe(.value, with: self.userDrivesForSpaceValueDidChange)
    }
     
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Realtime Database Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    // Update Display Name
    private func userDisplayNameValueDidChange(snap:DataSnapshot) {
        self.userDisplayName = snap.value as? String
        self.notificationCenter.post(name: .UserDisplayNameDidChange, object: self)
    }
    
    // Update Owned Events
    private func userOwnedEventsValueDidChange(snap:DataSnapshot) {
        self.userOwnedEvents = snap.value as? [String:String] ?? [String:String]()
        self.notificationCenter.post(name: .UserOwnedEventsDidChange, object: self)
    }
    
    // Update Rides
    private func userRidesSpaceValueDidChange(snap:DataSnapshot) {
        self.userRides = snap.value as? [String:String] ?? [String:String]()
        self.notificationCenter.post(name: .UserRidesSpaceDidChange, object: self)
    }
    
    // Update Drives For
    private func userDrivesForSpaceValueDidChange(snap:DataSnapshot) {
        self.userDrivesFor = snap.value as? [String:String] ?? [String:String]()
        self.notificationCenter.post(name: .UserDrivesForSpaceDidChange, object: self)
    }
    
    
}
