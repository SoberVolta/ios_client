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

class SignInViewController: UIViewController, LoginButtonDelegate {
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    var userToPresent: UserModel?
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - View Controller Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Auth.auth().addStateDidChangeListener(handleAuthStateChange)
        
        // Facebook Login button
        let loginButton = LoginButton(readPermissions: [ .publicProfile ])
        loginButton.delegate = self
        loginButton.center = view.center
        view.addSubview(loginButton)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToMainMenu" {
            if let destinationVC = segue.destination as? MainMenuViewController {
                if let newUser = self.userToPresent {
                    destinationVC.userModel = newUser
                }
            }
        }
    }
    
    func handleAuthStateChange( auth: Auth, user: User? ) {
        if let user = user {
            UserModel.addUserToDatabase(firebaseUserContext: user)
            userToPresent = UserModel(userUID: user.uid)
            performSegue(withIdentifier: "segueToMainMenu", sender: self)
        }
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Login Button Delegate Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        if let currentAccessToken = AccessToken.current {
            let credential = FacebookAuthProvider.credential(withAccessToken: currentAccessToken.authenticationToken)
            Auth.auth().signIn(with: credential, completion: nil)
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        FacebookLogin.LoginManager().logOut()
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
}

