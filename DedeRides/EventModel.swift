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
