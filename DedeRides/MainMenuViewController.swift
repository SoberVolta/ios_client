//
//  MainMenuViewController.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/1/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class MainMenuViewController : UITableViewController {
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    // Segue Initialized Variables
    var currentUser: User?
    
    // Database References
    let usersRef = Database.database().reference().child("users")
    let eventsRef = Database.database().reference().child("events")
    
    // Table View Variables
    let sectionTitles = ["New Events", "My Events", "My Rides", "My Drives", "Saved Events"]
    let newEventOptions = ["Create Event", "Search for event"]
    
    var userEventNames = [String:String]()
    var selectedEventIdx = -1
    var userRides = [String:String]()
    var selectedRideIdx = -1
    var userDrives = [String:String]()
    var selectedDriveIdx = -1
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - View Controller Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Handle auth changes
        Auth.auth().addStateDidChangeListener(handleAuthStateChange)
        
        // Hide back button
        let hiddentBackButton = UIBarButtonItem(title: "", style: .plain, target: navigationController, action: nil)
        navigationItem.leftBarButtonItem = hiddentBackButton
        
        // Table View Tasks
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "mainMenuCell")
        
        // Register real time database observers
        if let currentUser = currentUser {
            self.title = currentUser.displayName
            usersRef.child(currentUser.uid).child("ownedEvents").observe(.value, with: userEventsWatcher)
            usersRef.child(currentUser.uid).child("rides").observe(.value, with: userRideWatcher)
            usersRef.child(currentUser.uid).child("drivesFor").observe(.value, with: userDriveForWatcher)
        } else {
            self.title = "No User"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Set back button icon to read "back" instead of users name
        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        navigationItem.backBarButtonItem = backItem
        
        // Get current user
        if let curUser = self.currentUser {
            
            // Branch on segue identifier
            if segue.identifier == "segueToCreateEvent" {
                if let destinationVC = segue.destination as? CreateEventViewController {
                    destinationVC.creatingUserUID = curUser.uid
                }
            } else if segue.identifier == "segueToEventDetail" {
                if let destinationVC = segue.destination as? EventDetailViewController {
                    let selectedEventID = Array(self.userEventNames.keys)[selectedEventIdx]
                    destinationVC.prepareForDisplay(userUID: curUser.uid, eventID: selectedEventID)
                }
            } else if segue.identifier == "segueToRideDetail" {
                if let destinationVC = segue.destination as? RideDetailViewController {
                    let selectedRideID = Array(self.userRides.keys)[selectedRideIdx]
                    destinationVC.prepareForDisplay(
                        rideID: selectedRideID,
                        user: curUser, eventName:
                        userRides[selectedRideID]!
                    )
                }
            } else if segue.identifier == "segueToDriveDetail" {
                if let destinationVC = segue.destination as? DriveDetailViewController {
                    let selectedDriveID = Array(self.userDrives.keys)[selectedDriveIdx]
                    destinationVC.prepareForDisplay(
                        user: curUser,
                        eventID: selectedDriveID,
                        eventName: userDrives[selectedDriveID]!
                    )
                }
            } else if segue.identifier == "segueToSearch" {
                if let destinationVC = segue.destination as? SearchViewController {
                    destinationVC.currentUser = curUser
                }
            }
            
        } else {
            
            // Re authenticate if curent user not set
            let alert = UIAlertController(
                title: "Whoops",
                message: "Please sign in again",
                preferredStyle: UIAlertControllerStyle.alert
            )
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        }
    }
    
    // MARK: Unwind Segues
    
    @IBAction func unwindToMainMenu(segue:UIStoryboardSegue) {
        
    }
    
    @IBAction func unwindToMainMenuFromDriveDetail(segue:UIStoryboardSegue) {
        
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Real Time Database Watchers
    //-----------------------------------------------------------------------------------------------------------------
    
    func userEventsWatcher(snap:DataSnapshot) {
        self.userEventNames.removeAll()

        if let userEvents = snap.value as? [String:Any] {
            for eventID in Array(userEvents.keys) {
                self.userEventNames[eventID] = userEvents[eventID] as? String ?? "Unnamed Event"
            }
        }
        
        self.tableView.reloadData()
    }
    
    func userRideWatcher(snap:DataSnapshot) {
        self.userRides.removeAll()
        
        if let rides = snap.value as? [String:Any] {
            for rideID in Array(rides.keys) {
                if let eventID = rides[rideID] as? String {
                    eventsRef.child(eventID).child("name").observeSingleEvent(of: .value) {(snap) in
                        if let eventName = snap.value as? String {
                            self.userRides[rideID] = eventName
                        } else {
                            print("Can't parse event name")
                        }
                        self.tableView.reloadData()
                    }
                }
            }
        }
        
        self.tableView.reloadData()
    }
    
    func userDriveForWatcher(snap:DataSnapshot) {
        self.userDrives.removeAll()
        
        if let drives = snap.value as? [String:Any] {
            for driveForEventID in Array(drives.keys) {
                self.userDrives[driveForEventID] = drives[driveForEventID] as? String ?? "Unnamed Event"
            }
        }
        
        self.tableView.reloadData()
    }
    
    func handleAuthStateChange( auth: Auth, user: User? ) {
        
        if let _ = user {
        } else {
            // Re authenticate if curent user not set
            let alert = UIAlertController(
                title: "Whoops",
                message: "Please sign in again",
                preferredStyle: UIAlertControllerStyle.alert
            )
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Table View Controller Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    // Number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    // Titles of sections
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    // Number of rows in section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return newEventOptions.count
        } else if section == 1 {
            return userEventNames.count
        } else if section == 2 {
            return userRides.count
        } else if section == 3 {
            return userDrives.count
        }
        
        
        return 0
    }
    
    // Populate cells
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mainMenuCell", for: indexPath as IndexPath)
        
        if indexPath.section == 0 {
            cell.textLabel?.text = newEventOptions[indexPath.item]
        } else if indexPath.section == 1 {
            let key = Array(userEventNames.keys)[indexPath.item]
            cell.textLabel?.text = userEventNames[key]
        } else if indexPath.section == 2 {
            let key = Array(userRides.keys)[indexPath.item]
            cell.textLabel?.text = "Ride to \(userRides[key] ?? "Undetermined Event")"
        } else if indexPath.section == 3 {
            let key = Array(userDrives.keys)[indexPath.item]
            cell.textLabel?.text = "Drive for \(userDrives[key] ?? "Undetermined Event")"
        }
        
        return cell
    }
    
    // Did select cell
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.item == 0 {
                performSegue(withIdentifier: "segueToCreateEvent", sender: self)
            } else if indexPath.item == 1 {
                performSegue(withIdentifier: "segueToSearch", sender: self)
            }
        } else if indexPath.section == 1 {
            self.selectedEventIdx = indexPath.item
            performSegue(withIdentifier: "segueToEventDetail", sender: self)
        } else if indexPath.section == 2 {
            self.selectedRideIdx = indexPath.item
            performSegue(withIdentifier: "segueToRideDetail", sender: self)
        } else if indexPath.section == 3 {
            self.selectedDriveIdx = indexPath.item
            performSegue(withIdentifier: "segueToDriveDetail", sender: self)
        }
    }
    
}
