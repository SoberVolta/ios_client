//
//  CreateEventViewController.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/2/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class CreateEventViewController : UIViewController, UITextFieldDelegate {
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    // MARK: Segue Initialized Variables
    var creatingUserUID: String?
    
    // MARK: Outlets
    @IBOutlet weak var eventNameTextField: UITextField!
    @IBOutlet weak var eventLocationTextField: UITextField!
    
    // MARK: Database References
    let ref = Database.database().reference()
    let eventsRef = Database.database().reference().child("events")
    let usersRef = Database.database().reference().child("users")
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - View Controller Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.eventNameTextField.delegate = self
        self.eventLocationTextField.delegate = self
    }
    
    @IBAction func createEventButtonPressed(_ sender: Any? = nil) {
        
        // Get values
        if let eName = eventNameTextField.text {
            if let eLocation = eventLocationTextField.text {
                
                // Check all fields are filled in
                if( eName == "" || eLocation == "") {
                    
                    // Alert if some fields left blank
                    let alert = UIAlertController(
                        title: "Whoops",
                        message: "Please fill out all fields before creating the event",
                        preferredStyle: UIAlertControllerStyle.alert
                    )
                    alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                } else {
                    
                    // Confirm action before creating
                    displayActionSheet(
                        viewController: self,
                        actionSheetTitle: "Create Event",
                        actionSheetMessage: "Are you sure you want to create this event?",
                        cancelTitle: "Cancel",
                        affirmTitle: "Create Event",
                        affirmHandler: createEvent
                    )
                    
                }
            }
        }
    }
    
    private func createEvent(_: UIAlertAction ) {
        
        // Get Values
        if let eName = eventNameTextField.text {
            if let eLocation = eventLocationTextField.text {
                if let uid = creatingUserUID {
                    
                    // Create event space in database
                    let newEventKey = eventsRef.childByAutoId().key
                    let newEventData = [
                        "name": eName,
                        "location": eLocation,
                        "owner": uid
                    ]
                    
                    // Update database
                    let updates: [String:Any] = [
                        "/events/\(newEventKey)": newEventData,
                        "/users/\(uid)/ownedEvents/\(newEventKey)": eName
                    ]
                    ref.updateChildValues(updates)
                    
                    // Exit once completed
                    exit()
                }
            }
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any? = nil) {
        
        // Get values
        if let eName = eventNameTextField.text {
            if let eLocation = eventLocationTextField.text {
                
                // If some text fields have been filled in...
                if( eName != "" || eLocation != "") {
                    
                    // Confirm before discarding
                    displayActionSheet(
                        viewController: self,
                        actionSheetTitle: "Cancel Create Event",
                        actionSheetMessage: "All details will be lost",
                        cancelTitle: "Continue Editing",
                        affirmTitle: "Discard Details",
                        affirmHandler: exit
                    )
                    
                } else {
                    
                    // Otherwise exit without confirming
                    exit()
                }
            }
        }
    }
    
    func exit( _:UIAlertAction? = nil) {
        dismiss(animated: true, completion: nil)
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Text Field Delegate
    //-----------------------------------------------------------------------------------------------------------------
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if textField == self.eventNameTextField {
            self.eventLocationTextField.becomeFirstResponder()
        } else if textField == self.eventLocationTextField {
            self.createEventButtonPressed()
        }
        
        return true
    }
}
