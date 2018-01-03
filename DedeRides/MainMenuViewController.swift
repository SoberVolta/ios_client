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
    
    var userToPresent: User?
    
    let usersRef = Database.database().reference().child("users")
    let eventsRef = Database.database().reference().child("events")
    let sectionTitles = ["New Events", "My Events", "My Rides", "My Drives", "Saved Events"]
    let newEventOptions = ["Create Event", "Search for event"]
    var userEventNames = [String:String]()
    var selectedEventIdx = -1
    var userRides = [String:String]()
    var selectedRideIdx = -1
    
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
        
        // Set user specific data
        if let currentUser = userToPresent {
            self.title = currentUser.displayName
            usersRef.child(currentUser.uid).child("ownedEvents").observe(.value, with: userEventsWatcher)
            usersRef.child(currentUser.uid).child("rides").observe(.value, with: userRideWatcher)
        } else {
            self.title = "No User"
        }
    }
    
    func userEventsWatcher(snap:DataSnapshot) {
        self.userEventNames.removeAll()

        if let userEvents = snap.value as? [String:Any] {
            for eventID in Array(userEvents.keys) {
                self.userEventNames[eventID] = userEvents[eventID] as? String ?? "Unnamed Event"
            }
        } else {
            print("Cant parse user events")
        }
        
        self.tableView.reloadData()
    }
    
    func userRideWatcher(snap:DataSnapshot) {
        self.userRides.removeAll()
        
        if let rides = snap.value as? [String:Any] {
            for rideID in Array(rides.keys) {
                self.userRides[rideID] = rides[rideID] as? String ?? "Undetermined Event"
            }
        } else {
            print("Cant parse rides")
        }
        
        self.tableView.reloadData()
    }
    
    func handleAuthStateChange( auth: Auth, user: User? ) {
        
        if let _ = user {
        } else {
            print("User not signed in")
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToCreateEvent" {
            if let destinationVC = segue.destination as? CreateEventViewController {
                if let currentUser = self.userToPresent {
                    destinationVC.creatingUserUID = currentUser.uid
                } else {
                    let alert = UIAlertController(
                        title: "Whoops",
                        message: "Please sign in to create an event",
                        preferredStyle: UIAlertControllerStyle.alert
                    )
                    alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                print("Destination VC not CreateEventVC")
            }
        } else if segue.identifier == "segueToEventDetail" {
            if let destinationVC = segue.destination as? EventDetailViewController {
                if let currentUser = self.userToPresent {
                    destinationVC.prepareForDisplay(user: currentUser, eventID: Array(self.userEventNames.keys)[selectedEventIdx])
                } else {
                    let alert = UIAlertController(
                        title: "Whoops",
                        message: "Please sign in to create an event",
                        preferredStyle: UIAlertControllerStyle.alert
                    )
                    alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                print("Destination VC not EventDetailVC")
            }
        }
    }
    
    // Table View Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mainMenuCell", for: indexPath as IndexPath)
        
        if indexPath.section == 0 {
            cell.textLabel?.text = newEventOptions[indexPath.item]
        } else if indexPath.section == 1 {
            let key = Array(userEventNames.keys)[indexPath.item]
            cell.textLabel?.text = userEventNames[key]
        } else if indexPath.section == 2 {
            let key = Array(userRides.keys)[indexPath.item]
            cell.textLabel?.text = userRides[key]
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return newEventOptions.count
        } else if section == 1 {
            return userEventNames.count
        } else if section == 2 {
            return userRides.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.item == 0 {
                performSegue(withIdentifier: "segueToCreateEvent", sender: self)
            }
        } else if indexPath.section == 1 {
            self.selectedEventIdx = indexPath.item
            performSegue(withIdentifier: "segueToEventDetail", sender: self)
        }
    }
    
    
}
