//
//  ViewController.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/1/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import Firebase

class ViewController: UIViewController {
    
    @IBOutlet weak var signInLabel: UILabel!
    let rootRef = Database.database().reference()
    let usersRef = Database.database().reference().child("users")
    var labelText = "Sign in to use ΔΔ"
    var uiReady = false
    var userAlreadySignedIn = false
    var userToPresent: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Auth.auth().addStateDidChangeListener(handleAuthStateChange)
        signIn()
        
        // Facebook Login button
        let fbSignInButtonDelegate = DedeSignInButtonDelegate(callingController: self)
        let loginButton = LoginButton(readPermissions: [ .publicProfile ])
        loginButton.delegate = fbSignInButtonDelegate as LoginButtonDelegate
        loginButton.center = view.center
        view.addSubview(loginButton)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        uiReady = true;
        updateUI()
    }

    func handleAuthStateChange( auth: Auth, user: User? ) {
        if let user = user {
            if let displayName = user.displayName {
                labelText = displayName
                updateUI()
                addUserToDatabase(user: user)
                userAlreadySignedIn = true
                userToPresent = user
                performSegue(withIdentifier: "segueToMainMenu", sender: self)
            }
        } else {
            labelText = "Sign in to use ΔΔ"
            updateUI()
            userAlreadySignedIn = false
        }
    }
    
    func signOut() {
        FacebookLogin.LoginManager().logOut()
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    func signIn() {
        if let currentAccessToken = AccessToken.current {
            let credential = FacebookAuthProvider.credential(withAccessToken: currentAccessToken.authenticationToken)
            Auth.auth().signIn(with: credential, completion: nil)
        }
    }
    
    func updateUI() {
        if( !uiReady ) {
            return;
        }
        
        signInLabel.text = labelText
    }
    
    func addUserToDatabase(user: User) {
        usersRef.child(user.uid).runTransactionBlock({(currentData: MutableData) -> TransactionResult in
            
            if let userData = currentData.value as? [String : AnyObject] {
                print("User already in data base: \(userData["displayName"] ?? "Unnamed" as AnyObject).")
                return TransactionResult.success(withValue: currentData)
            }
        
            print("Adding user to database.")
            var newUserData = [String : AnyObject]()
            if let displayName = user.displayName {
                newUserData["displayName"] = displayName as AnyObject
            } else {
                newUserData["displayName"] = "Unnamed" as AnyObject
            }
            
            currentData.value = newUserData
            
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snap) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToMainMenu" {
            if let destinationVC = segue.destination as? MainMenuViewController {
                if let newUser = self.userToPresent {
                    destinationVC.userModel = UserModel(userUID: newUser.uid)
                }
            } else {
                print("destination not main menu")
            }
        }
    }
    
}

