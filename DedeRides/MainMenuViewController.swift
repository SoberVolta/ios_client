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
            usersRef.child(currentUser.uid).child("events").observe(.value, with: userEventsWatcher)
        } else {
            self.title = "No User"
        }
    }
    
    func userEventsWatcher(snap:DataSnapshot) {
        self.userEventNames.removeAll()
        let userEvents = Array((snap.value as? [String : AnyObject] ?? [:]).keys)
        for eventID in userEvents {
            eventsRef.child(eventID).child("name").observeSingleEvent(of: .value) {(snap) in
                let eventName = snap.value as? String ?? "Unnamed Event"
                self.userEventNames[eventID] = eventName
                print("Adding event: \(eventID):\(eventName)")
                self.tableView.reloadData()
            }
        }
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
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return newEventOptions.count
        } else if section == 1 {
            return userEventNames.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.item == 0 {
                performSegue(withIdentifier: "segueToCreateEvent", sender: self)
            }
        }
    }
    
    
}
