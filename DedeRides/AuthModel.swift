//
//  AuthModel.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/7/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import Firebase

//-----------------------------------------------------------------------------------------------------------------
// MARK: - Notifications
//-----------------------------------------------------------------------------------------------------------------

extension NSNotification.Name {
    public static let AuthValueDidChange = Notification.Name("AuthValueWillChange")
    public static let AuthValueDidChangeLastCall = Notification.Name("AuthValueWillChangeLastCall")
}

class AuthModel {
 
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    static let defaultAuthModel = AuthModel()
    
    let notificationCenter = NotificationCenter.default
    var currentUser: UserModel?
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Initialize
    //-----------------------------------------------------------------------------------------------------------------
    
    init() {
        Auth.auth().addStateDidChangeListener(self.handleAuthStateChange)
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Public Interface Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    func signIn(authenticationToken: String) {
        let credential = FacebookAuthProvider.credential(withAccessToken: authenticationToken)
        Auth.auth().signIn(with: credential, completion: nil)
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Oberver Function
    //-----------------------------------------------------------------------------------------------------------------
    
    private func handleAuthStateChange(auth: Auth, user: User?) {
        
        // Update database/variables
        if let user = user {
            UserModel.addUserToDatabase(firebaseUserContext: user)
            self.currentUser = UserModel(userUID: user.uid)
        } else {
            self.currentUser = nil
        }
        
        // Send notifications
        self.notificationCenter.post(name: .AuthValueDidChange, object: self)
        self.notificationCenter.post(name: .AuthValueDidChangeLastCall, object: self)
        
    }
    
}
