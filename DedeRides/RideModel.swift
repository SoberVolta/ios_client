//
//  RideModel.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/5/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import Firebase

class RideModel {
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    
    // Database References
    static let rideSpaceRef = Database.database().reference().child("rides")
    
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
    
}
