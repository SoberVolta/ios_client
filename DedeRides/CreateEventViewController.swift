//
//  CreateEventViewController.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/2/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import UIKit

class CreateEventViewController : UIViewController {
    
    @IBOutlet weak var eventNameTextField: UITextField!
    @IBOutlet weak var eventLocationTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.title = "Create Event"
    }
    
    @IBAction func createEventButtonPressed(_ sender: Any) {
        if let eName = eventNameTextField.text {
            if let eLocation = eventLocationTextField.text {
                if( eName == "" || eLocation == "") {
                    let alert = UIAlertController(
                        title: "Whoops",
                        message: "Please fill out all fields before creating the event",
                        preferredStyle: UIAlertControllerStyle.alert
                    )
                    alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    let actionSheet = UIAlertController(
                        title: "Create Event",
                        message: "Create event '\(eName)' at '\(eLocation)'",
                        preferredStyle: .actionSheet
                    )
                    let cancelCreate = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    actionSheet.addAction(cancelCreate)
                    
                    let submitCreate = UIAlertAction(title: "Create Event", style: .default, handler: createEvent)
                    actionSheet.addAction(submitCreate)
                    self.present(actionSheet, animated: true, completion: nil)
                }
            }
        }
    }
    
    func createEvent( _: UIAlertAction ) {
        if let eName = eventNameTextField.text {
            if let eLocation = eventLocationTextField.text {
                let alert = UIAlertController(
                    title: "Alert",
                    message: "Create event \(eName) at \(eLocation)",
                    preferredStyle: UIAlertControllerStyle.alert
                )
                alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        if let eName = eventNameTextField.text {
            if let eLocation = eventLocationTextField.text {
                if( eName != "" || eLocation != "") {
                    let actionSheet = UIAlertController(title: "Cancel Create Event", message: "All details will be lost", preferredStyle: .actionSheet)
                    let continueEditingAction = UIAlertAction(title: "Continue editing", style: .cancel, handler: nil)
                    actionSheet.addAction(continueEditingAction)
                    
                    let discardDetailsAction = UIAlertAction(title: "Discard all event details", style: .default, handler: exit)
                    actionSheet.addAction(discardDetailsAction)
                    self.present(actionSheet, animated: true, completion: nil)
                } else {
                    exit()
                }
            }
        }
    }
    
    func exit( _:UIAlertAction ) {
        exit()
    }
    
    func exit() {
        dismiss(animated: true, completion: nil)
    }
}
