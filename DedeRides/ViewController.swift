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
    var labelText = "Sign in to use ΔΔ"
    var uiReady = false
    var userAlreadySignedIn = false
    
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
                userAlreadySignedIn = true
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
    
}

