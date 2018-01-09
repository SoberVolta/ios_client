//
//  MainMenuViewController.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/1/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import UIKit

class MainMenuViewController : UITableViewController {
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    // Segue Initialized Variable
    var userModel: UserModel!
    
    // Database References
    
    // Table View Variables
    let sectionTitles = ["New Events", "My Events", "My Rides", "My Drives", "Saved Events"]
    let newEventOptions = ["Create Event", "Search for event"]
    
    var selectedEventIdx = -1
    var selectedRideIdx = -1
    var selectedDriveIdx = -1
    var selectedSavedEventIdx = -1
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - View Controller Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide back button
        let hiddentBackButton = UIBarButtonItem(title: "", style: .plain, target: navigationController, action: nil)
        navigationItem.leftBarButtonItem = hiddentBackButton
        
        // Table View Tasks
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "mainMenuCell")
        
        // Add notification observers
        userModel.notificationCenter.addObserver(
            forName: .UserDisplayNameDidChange,
            object: userModel,
            queue: nil,
            using: userDisplayNameDidChange
        )
        userModel.notificationCenter.addObserver(
            forName: .UserOwnedEventsDidChange,
            object: userModel,
            queue: nil,
            using: userOwnedEventsDidChange
        )
        userModel.notificationCenter.addObserver(
            forName: .UserRidesSpaceDidChange,
            object: userModel,
            queue: nil,
            using: userRidesDidChange
        )
        userModel.notificationCenter.addObserver(
            forName: .UserDrivesForSpaceDidChange,
            object: userModel,
            queue: nil,
            using: userDrivesForDidChange
        )
        userModel.notificationCenter.addObserver(
            forName: .UserSavedEventsDidChange,
            object: userModel,
            queue: nil,
            using: userSavedEventsDidChange
        )
    
        // Auth notification
        AuthModel.defaultAuthModel.notificationCenter.addObserver(
            forName: .AuthValueDidChangeLastCall,
            object: AuthModel.defaultAuthModel,
            queue: nil,
            using: forceReSignIn
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        userModel.attachDatabaseListeners()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Set back button icon to read "back" instead of users name
        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        navigationItem.backBarButtonItem = backItem
        
        // Branch on segue identifier
        if segue.identifier == "segueToCreateEvent" {
            if let destinationVC = segue.destination as? CreateEventViewController {
                destinationVC.creatingUser = userModel
            }
        } else if segue.identifier == "segueToEventDetail" {
            if let destinationVC = segue.destination as? EventDetailViewController {
                var eventID = ""
                if selectedEventIdx == -1 {
                    eventID = Array(self.userModel.userSavedEvents.keys)[selectedSavedEventIdx]
                } else {
                    eventID = Array(self.userModel.userOwnedEvents.keys)[selectedEventIdx]
                }
                destinationVC.prepareForDisplay(userModel: self.userModel, eventID: eventID)
            }
        } else if segue.identifier == "segueToRideDetail" {
            if let destinationVC = segue.destination as? RideDetailViewController {
                let rideID = Array(self.userModel.userRides.keys)[selectedRideIdx]
                destinationVC.prepareForDisplay(
                    ride: RideModel(rideID: rideID),
                    user: userModel,
                    eventName: userModel.userRides[rideID]!
                )
            }
        } else if segue.identifier == "segueToDriveDetail" {
            if let destinationVC = segue.destination as? DriveDetailViewController {
                let rideID = Array(self.userModel.userDrivesFor.keys)[selectedDriveIdx]
                destinationVC.prepareForDisplay(
                    user: userModel,
                    event: EventModel(eventID: rideID)
                )
            }
        } else if segue.identifier == "segueToSearch" {
            if let destinationVC = segue.destination as? SearchViewController {
                destinationVC.currentUserUID = userModel.userUID
            }
        }
    }
    
    // MARK: Unwind Segues
    
    @IBAction func unwindToMainMenu(segue:UIStoryboardSegue) {
        
    }
    
    @IBAction func unwindToMainMenuFromDriveDetail(segue:UIStoryboardSegue) {
        
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Notification Observers
    //-----------------------------------------------------------------------------------------------------------------
    
    func userDisplayNameDidChange(_:Notification? = nil) {
        self.title = userModel.userDisplayName
    }
    
    func userOwnedEventsDidChange(_:Notification? = nil) {
        self.tableView.reloadData()
    }
    
    func userRidesDidChange(_:Notification? = nil) {
        self.tableView.reloadData()
    }
    
    func userDrivesForDidChange(_:Notification? = nil) {
        self.tableView.reloadData()
    }
    
    func userSavedEventsDidChange(_:Notification? = nil) {
        self.tableView.reloadData()
    }
    
    func forceReSignIn(_:Notification? = nil) {
        if AuthModel.defaultAuthModel.currentUser == nil {
            displayAlert(
                viewController: self,
                titleText: "Whoops!",
                messageText: "Looks like you've been signed out. Please sign back in.",
                awknowledgeText: "Okay!"
            )
            performSegue(withIdentifier: "unwindToSignInView", sender: self)
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
            return userModel.userOwnedEvents.count
        } else if section == 2 {
            return userModel.userRides.count
        } else if section == 3 {
            return userModel.userDrivesFor.count
        } else if section == 4 {
            return userModel.userSavedEvents.count
        }
        
        return 0
    }
    
    // Populate cells
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MainMenuCell", for: indexPath) as! LabelCell
        
        if indexPath.section == 0 {
            cell.textLabel?.text = newEventOptions[indexPath.item]
        } else if indexPath.section == 1 {
            let eventID = Array(userModel.userOwnedEvents.keys)[indexPath.item]
            cell.textLabel?.text = userModel.userOwnedEvents[eventID]
        } else if indexPath.section == 2 {
            let rideID = Array(userModel.userRides.keys)[indexPath.item]
            cell.textLabel?.text = "Ride to \(userModel.userRides[rideID] ?? "Undetermined Event")"
        } else if indexPath.section == 3 {
            let rideID = Array(userModel.userDrivesFor.keys)[indexPath.item]
            cell.textLabel?.text = "Drive for \(userModel.userDrivesFor[rideID] ?? "Undetermined Event")"
        } else if indexPath.section == 4 {
            let idx = indexPath.item
            let eventID = Array(userModel.userSavedEvents.keys)[idx]
            cell.textLabel?.text = userModel.userSavedEvents[eventID]
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
            self.selectedSavedEventIdx = -1
            performSegue(withIdentifier: "segueToEventDetail", sender: self)
        } else if indexPath.section == 2 {
            self.selectedRideIdx = indexPath.item
            performSegue(withIdentifier: "segueToRideDetail", sender: self)
        } else if indexPath.section == 3 {
            self.selectedDriveIdx = indexPath.item
            performSegue(withIdentifier: "segueToDriveDetail", sender: self)
        } else if indexPath.section == 4 {
            self.selectedEventIdx = -1
            self.selectedSavedEventIdx = indexPath.item
            performSegue(withIdentifier: "segueToEventDetail", sender: self)
        }
    }
}

//-----------------------------------------------------------------------------------------------------------------
// MARK: - Custom Cell Type
//-----------------------------------------------------------------------------------------------------------------

class LabelCell: UITableViewCell {
    
}
