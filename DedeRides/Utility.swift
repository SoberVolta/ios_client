//
//  Utility.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/3/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import UIKit

func displayActionSheet(
    viewController: UIViewController,
    actionSheetTitle: String,
    actionSheetMessage: String,
    cancelTitle: String,
    affirmTitle: String,
    affirmHandler: ((_:UIAlertAction)->Void)? = nil
    ){
    let actionSheet = UIAlertController(
        title: actionSheetTitle,
        message: actionSheetMessage,
        preferredStyle: .actionSheet
    )
    let cancelAction = UIAlertAction(title: cancelTitle, style: .destructive, handler: nil)
    actionSheet.addAction(cancelAction)
    
    let affirmAction = UIAlertAction(title: affirmTitle, style: .default, handler: affirmHandler)
    actionSheet.addAction(affirmAction)
    viewController.present(actionSheet, animated: true, completion: nil)
}

func displayAlert(
    viewController: UIViewController,
    titleText: String,
    messageText: String,
    awknowledgeText: String
    ) {
    let alert = UIAlertController(
        title: titleText,
        message: messageText,
        preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: awknowledgeText, style: .default, handler: nil))
    viewController.present(alert, animated: true, completion: nil)
}
