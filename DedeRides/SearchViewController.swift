//
//  SearchViewController.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/3/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class SearchViewController : UIViewController {
    
    var currentUserUID: String?
    var validSearchEvent: String?
    
    @IBOutlet weak var searchIdentifierLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    
    let ref = Database.database().reference()
    let eventsRef = Database.database().reference().child("events")
    
    @IBAction func searchBtnPressed() {
        if let searchText = searchTextField.text {
            if searchText != "" {
                eventsRef.child(searchText).observeSingleEvent(of: .value) {(snap) in
                    if let _ = snap.value as? [String:Any] {
                        self.showEvent(eventID: searchText)
                    }
                }
            }
        }
    }
    
    func showEvent(eventID: String) {
        self.validSearchEvent = eventID
        performSegue(withIdentifier: "segueFromSearchToEventDetail", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueFromSearchToEventDetail" {
            if let destinationVC = segue.destination as? EventDetailViewController {
                destinationVC.prepareForDisplay(userModel: UserModel(userUID: self.currentUserUID!), eventID: self.validSearchEvent!)
            }
        }
        
    }
    
}
