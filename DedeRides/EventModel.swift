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
    public static let EventNameDidChange = Notification.Name("EventNameValueDidChange")
    public static let EventLocationDidChange = Notification.Name("EventLocationValueDidChange")
    public static let EventOwnerDidChange = Notification.Name("EventOwnerValueDidChange")
    public static let EventQueueValueDidChange = Notification.Name("EventQueueValueDidChange")
    public static let EventActiveRidesValueDidChange = Notification.Name("EventActiveRidesValueDidChange")
}

class EventModel {
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    // Database References
    let eventRef: DatabaseReference
    
    // Notification Center
    let notificationCenter: NotificationCenter
    
    // Initialized Value
    var eventID: String
    
    // Database Populated Variables
    var eventName: String?
    var eventLocation: String?
    var eventOwner: String?
    var eventQueue: [String:String]?
    var eventActiveRides: [String:Any]?
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Initialization
    //-----------------------------------------------------------------------------------------------------------------
    
    init(eventID:String) {
        self.notificationCenter = NotificationCenter.default
        self.eventID = eventID
        self.eventRef = Database.database().reference().child("events").child(eventID)
    }
    
    func attachDatabaseListeners() {
        eventRef.child("name").observe(.value, with: eventNameValueHasChanged)
        eventRef.child("location").observe(.value, with: eventLocationValueHasChanged)
        eventRef.child("owner").observe(.value, with: eventOwnerValueHasChanged)
        eventRef.child("queue").observe(.value, with: eventQueueValueHasChanged)
        eventRef.child("activeRides").observe(.value, with: eventActiveRidesValueHasChanged)
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Realtime Database Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    // Update event name
    private func eventNameValueHasChanged(snap:DataSnapshot) {
        self.eventName = snap.value as? String
        self.notificationCenter.post(name: .EventNameDidChange, object: self)
    }
    
    // Update event location
    private func eventLocationValueHasChanged(snap:DataSnapshot) {
        self.eventLocation = snap.value as? String
        self.notificationCenter.post(name: .EventLocationDidChange, object: self)
    }
    
    // Update event owner
    private func eventOwnerValueHasChanged(snap:DataSnapshot) {
        self.eventOwner = snap.value as? String
        self.notificationCenter.post(name: .EventOwnerDidChange, object: self)
    }
    
    // Update event queue
    private func eventQueueValueHasChanged(snap:DataSnapshot) {
        self.eventQueue = snap.value as? [String:String] ?? [String:String]()
        self.notificationCenter.post(name: .EventQueueValueDidChange, object: self)
    }
    
    // Update active rides
    private func eventActiveRidesValueHasChanged(snap:DataSnapshot) {
        self.eventActiveRides = snap.value as? [String:String] ?? [String:String]()
        self.notificationCenter.post(name: .EventActiveRidesValueDidChange, object: self)
    }
    
}
