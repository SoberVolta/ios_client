//
//  DedeSignInButtonDelegate.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/1/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import FacebookCore
import FacebookLogin
import Firebase

class DedeSignInButtonDelegate : LoginButtonDelegate {
    
    let controller: ViewController
    
    init( callingController: ViewController) {
        controller = callingController
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        controller.signOut()
    }
    
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        controller.signIn()
    }
    
}
