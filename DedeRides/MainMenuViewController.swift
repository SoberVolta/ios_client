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
    
    let sectionTitles = ["New Events", "My Events", "My Rides", "My Drives", "Saved Events"]
    let newEventOptions = ["Create Event", "Search for event"]
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let currentUser = userToPresent {
            self.title = currentUser.displayName
        } else {
            self.title = "No User"
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
        return 5
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mainMenuCell", for: indexPath as IndexPath)
        
        if indexPath.section == 0 {
            cell.textLabel?.text = newEventOptions[indexPath.item]
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
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
