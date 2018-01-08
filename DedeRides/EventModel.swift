//
//  EventDetailModel.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/4/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import Firebase

//-----------------------------------------------------------------------------------------------------------------
// MARK: - Notifications
//-----------------------------------------------------------------------------------------------------------------

extension NSNotification.Name {
    public static let EventNameDidChange = Notification.Name("EventNameDidChange")
    public static let EventLocationDidChange = Notification.Name("EventLocationDidChange")
    public static let EventOwnerDidChange = Notification.Name("EventOwnerDidChange")
    public static let EventQueueDidChange = Notification.Name("EventQueueDidChange")
    public static let EventActiveRidesDidChange = Notification.Name("EventActiveRidesDidChange")
    public static let EventDriversDidChange = Notification.Name("EventDriversDidChange")
}

class EventModel {
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    // Database References
    static let ref = Database.database().reference()
    static let eventSpaceRef = Database.database().reference().child("events")
    let eventRef: DatabaseReference
    
    // Notification Center
    let notificationCenter: NotificationCenter
    
    // Initialized Value
    var eventID: String
    
    // Database Populated Variables
    var eventName: String?
    var eventLocation: String?
    var eventOwner: String?
    var eventQueue = [String:String]()
    var eventActiveRides = [String:String]()
    var eventDrivers = [String:String]()
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Initialization
    //-----------------------------------------------------------------------------------------------------------------
    
    init(eventID:String) {
        self.notificationCenter = NotificationCenter.default
        self.eventID = eventID
        self.eventRef = EventModel.eventSpaceRef.child(eventID)
        
        attachDatabaseListeners()
    }
    
    func attachDatabaseListeners() {
        eventRef.child("name").observe(.value, with: eventNameValueDidChange)
        eventRef.child("location").observe(.value, with: eventLocationValueDidChange)
        eventRef.child("owner").observe(.value, with: eventOwnerValueDidChange)
        eventRef.child("queue").observe(.value, with: eventQueueValueDidChange)
        eventRef.child("activeRides").observe(.value, with: eventActiveRidesValueDidChange)
        eventRef.child("drivers").observe(.value, with: eventDriversValueDidChange)
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Static Update Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    static func createEvent(eventName: String, eventLocation: String, eventOwnerUID: String) {
        
        // Create event space in database
        let newEventKey = eventSpaceRef.childByAutoId().key
        
        let newEventData = [
            "name": eventName,
            "location": eventLocation,
            "owner": eventOwnerUID
        ]
        
        // Update database
        let updates: [String:Any] = [
            "/events/\(newEventKey)": newEventData,
            "/users/\(eventOwnerUID)/ownedEvents/\(newEventKey)": eventName
        ]
        ref.updateChildValues(updates)
    }
    
    static func addDriverToEvent(eventID: String, eventName: String, driverUID: String, driverDisplayName: String) {
        
        // Update Database
        let updates = [
            "/events/\(eventID)/drivers/\(driverUID)": driverDisplayName,
            "/users/\(driverUID)/drivesFor/\(eventID)": eventName
        ]
        Database.database().reference().updateChildValues(updates)
    }
    
    static func removeDriverFromEvent(eventID: String, driverUID: String) {
        
        // Update Database
        let updates = [
            "/events/\(eventID)/drivers/\(driverUID)": NSNull(),
            "/users/\(driverUID)/drivesFor/\(eventID)": NSNull()
        ]
        Database.database().reference().updateChildValues(updates)
    }
    
    func takeNextRideInQueue(driverUID: String) {
        let eventID = self.eventID
        self.eventRef.child("queue").runTransactionBlock({ (curData: MutableData) -> TransactionResult in
            
            // Get queue
            var queue = curData.value as? [String:String] ?? [String:String]()
            
            // Get the first ride in queue
            if let firstRideInQueue = Array(queue.keys).sorted().first {
                
                // Remove from queue
                queue.removeValue(forKey: firstRideInQueue)
                
                // Update other database spaces
                let updates: [String:Any] = [
                    "/users/\(driverUID)/drives/\(firstRideInQueue)": eventID,      // Driver space
                    "/rides/\(firstRideInQueue)/status": 1,                         // Ride status
                    "/rides/\(firstRideInQueue)/driver": driverUID,                 // Ride driver
                    "/events/\(eventID)/activeRides/\(firstRideInQueue)": driverUID // Event active rides
                ]
                EventModel.ref.updateChildValues(updates)
            }
            
            // Return data
            curData.value = queue
            return TransactionResult.success(withValue: curData)
        })
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Realtime Database Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    // Update event name
    private func eventNameValueDidChange(snap:DataSnapshot) {
        self.eventName = snap.value as? String
        self.notificationCenter.post(name: .EventNameDidChange, object: self)
    }
    
    // Update event location
    private func eventLocationValueDidChange(snap:DataSnapshot) {
        self.eventLocation = snap.value as? String
        self.notificationCenter.post(name: .EventLocationDidChange, object: self)
    }
    
    // Update event owner
    private func eventOwnerValueDidChange(snap:DataSnapshot) {
        self.eventOwner = snap.value as? String
        self.notificationCenter.post(name: .EventOwnerDidChange, object: self)
    }
    
    // Update Drivers
    private func eventDriversValueDidChange(snap:DataSnapshot) {
        self.eventDrivers = snap.value as? [String:String] ?? [String:String]()
        self.notificationCenter.post(name: .EventDriversDidChange, object: self)
    }
    
    // Update event queue
    private func eventQueueValueDidChange(snap:DataSnapshot) {
        self.eventQueue = snap.value as? [String:String] ?? [String:String]()
        notificationCenter.post(name: .EventQueueDidChange, object: self)
    }
    
    // Update active rides
    private func eventActiveRidesValueDidChange(snap:DataSnapshot) {
        self.eventActiveRides = snap.value as? [String:String] ?? [String:String]()
        notificationCenter.post(name: .EventActiveRidesDidChange, object: self)
    }
    
}
