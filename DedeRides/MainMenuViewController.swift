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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Handle auth changes
        Auth.auth().addStateDidChangeListener(handleAuthStateChange)
        
        // Hide back button
        let hiddentBackButton = UIBarButtonItem(title: "", style: .plain, target: navigationController, action: nil)
        navigationItem.leftBarButtonItem = hiddentBackButton
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
    
}
