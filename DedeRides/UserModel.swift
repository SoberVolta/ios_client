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
    public static let UserActiveDrivesSpaceDidChange = Notification.Name("UserActiveDrivesSpaceDidChange")
    public static let UserSavedEventsDidChange = Notification.Name("UserSavedEventsDidChange")
}

class UserModel {
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    // Database Reference
    static let userSpaceRef = Database.database().reference().child("users")
    let userRef: DatabaseReference
 
    // Notification Center
    let notificationCenter: NotificationCenter

    // Initialized Value
    let userUID: String
    
    // Database Populated Values
    var userDisplayName: String?
    var userOwnedEvents = [EventID:EventName]()
    var userRides = [RideID:EventName]()
    var userDrivesFor = [EventID:EventName]()
    var userActiveDrives = [RideID:EventID]()
    var userSavedEvents = [EventID:EventName]()
    var subscribedEvents = [String]()
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Initialization
    //-----------------------------------------------------------------------------------------------------------------
    
    init(userUID uid: String) {
        self.notificationCenter = NotificationCenter.default
        self.userUID = uid
        self.userRef = UserModel.userSpaceRef.child(self.userUID)
        
        attachDatabaseListeners()
    }
    
    func attachDatabaseListeners() {
        self.userRef.child("displayName").observe(.value, with: self.userDisplayNameValueDidChange)
        self.userRef.child("ownedEvents").observe(.value, with: self.userOwnedEventsValueDidChange)
        self.userRef.child("rides").observe(.value, with: self.userRidesSpaceValueDidChange)
        self.userRef.child("drivesFor").observe(.value, with: self.userDrivesForSpaceValueDidChange)
        self.userRef.child("drives").observe(.value, with: self.userActiveDrivesSpaceValueDidChange)
        self.userRef.child("savedEvents").observe(.value, with: self.userSavedEventsSpaceValueDidChange)
    }
    
    static func addUserToDatabase(firebaseUserContext user: User) {
        UserModel.userSpaceRef.child(user.uid).runTransactionBlock({(currentData: MutableData) -> TransactionResult in
            
            // Check if this user already exists
            if let _ = currentData.value as? [String : AnyObject] {
                return TransactionResult.success(withValue: currentData)
            }
            
            // Add user's facebook display name to database
            if let displayName = user.displayName {
                var newUserData = [String : AnyObject]()
                newUserData["displayName"] = displayName as AnyObject
                
                // Update database
                currentData.value = newUserData
            }
            
            // Signal done
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snap) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    private func subscribeToEventNotifications(eventID: String) {
        self.subscribedEvents.append(eventID)
        print( "Subcribing to \(eventID)" )
        Messaging.messaging().subscribe(toTopic: eventID)
    }
    
    private func unsubscribeFromAllEventNotifications() {
        for eventID: String in self.subscribedEvents {
            print( "Unsubcribing from \(eventID)" )
            Messaging.messaging().unsubscribe(fromTopic: eventID)
        }
        
        self.subscribedEvents.removeAll()
    }
    
    func saveEvent(event: EventModel) {
        if let eventName = event.eventName {
            self.saveEvent(eventID: event.eventID, eventName: eventName)
        }
    }
    
    func saveEvent(eventID: String, eventName: String) {
        userRef.child("savedEvents").child(eventID).setValue(eventName)
    }
    
    func unsaveEvent(event: EventModel) {
        self.unsaveEvent(eventID: event.eventID)
    }
    
    func unsaveEvent(eventID: String) {
        userRef.child("savedEvents").child(eventID).setValue(NSNull())
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
        
        self.unsubscribeFromAllEventNotifications()
        
        self.userDrivesFor = snap.value as? [String:String] ?? [String:String]()
        
        for eventID: EventID in self.userDrivesFor.keys {
            self.subscribeToEventNotifications(eventID: eventID)
        }
        
        self.notificationCenter.post(name: .UserDrivesForSpaceDidChange, object: self)
    }
    
    // Update Active Drives
    private func userActiveDrivesSpaceValueDidChange(snap:DataSnapshot) {
        self.userActiveDrives = snap.value as? [String:String] ?? [String:String]()
        self.notificationCenter.post(name: .UserActiveDrivesSpaceDidChange, object: self)
    }
    
    // Update Saved Events
    private func userSavedEventsSpaceValueDidChange(snap:DataSnapshot) {
        self.userSavedEvents = snap.value as? [String:String] ?? [String:String]()
        self.notificationCenter.post(name: .UserSavedEventsDidChange, object: self)
    }
    
}
