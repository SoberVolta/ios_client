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

class SignInViewController: UIViewController, LoginButtonDelegate {
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    let authModel = AuthModel.defaultAuthModel
    var userToPresent: UserModel?
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - View Controller Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get notified when user authentication changes
        self.authModel.notificationCenter.addObserver(
            forName: .AuthValueDidChange,
            object: AuthModel.defaultAuthModel,
            queue: nil,
            using: handleAuthStateChange
        )
        
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
    
    @IBAction func unwindToSignInView(segue:UIStoryboardSegue) {
        
    }
    
    func handleAuthStateChange(_:Notification? = nil) {
        if let user = self.authModel.currentUser {
            userToPresent = user
            performSegue(withIdentifier: "segueToMainMenu", sender: self)
        }
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Login Button Delegate Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        if let currentAccessToken = AccessToken.current {
            self.authModel.signIn(authenticationToken: currentAccessToken.authenticationToken)
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        FacebookLogin.LoginManager().logOut()
        authModel.signOut()
    }
    
}

