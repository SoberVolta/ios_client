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
    
    var currentUser: User?
    var eventUID: String?
    
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var eventLocationLabel: UILabel!
    @IBOutlet weak var deleteBtn: UIButton!
    
    let eventsRef = Database.database().reference().child("events")
    
    private var uiReady = false;
    private var eventNameText = "Unnamed Event"
    private var eventLocationText = "Unspecified Location"
    private var eventOwner: String?
    
    override func viewDidAppear(_ animated: Bool) {
        uiReady = true;
        updateUI()
    }
    
    func prepareForDisplay(user: User, eventID: String) {
        self.currentUser = user
        self.eventUID = eventID
        
        eventsRef.child(eventID).observeSingleEvent(of: .value) { (snap) in
            if let eventData = snap.value as? [String:String] {
                self.eventNameText = eventData["name"] ?? "Unnamed Event"
                self.eventLocationText = eventData["location"] ?? "Unspecified Location"
                self.eventOwner = eventData["owner"]
                self.updateUI()
            } else {
                print("Cannot parse event as [String:String]")
            }
        }
        
    }
    
    func updateUI() {
        if(!uiReady) {
            return;
        }
        
        eventNameLabel.text = eventNameText
        eventLocationLabel.text = eventLocationText
        
        if let eventOwnerUID = self.eventOwner {
            if let curUser = self.currentUser {
                if curUser.uid != eventOwnerUID {
                    self.deleteBtn.isHidden = true
                }
            }
        }
    }
    
    @IBAction func requestRideBtnPressed() {
    }
    
    @IBAction func offerRideBtnPressed() {
    }
    
    @IBAction func deleteEventBtnPressed() {
    }
    
}
