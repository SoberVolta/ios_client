//
//  ViewDriversViewController.swift
//  DedeRides
//
//  Created by Grant Broadwater on 1/9/18.
//  Copyright © 2018 Grant Broadwater. All rights reserved.
//

import Foundation
import UIKit

class ViewDriversViewController : UITableViewController {
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Member Variables
    //-----------------------------------------------------------------------------------------------------------------
    
    // Segue Initialized Variables
    var eventModel: EventModel!
    
    let sectionTitles = ["Pending Drivers", "Active Drivers"]
    let PendingSection = 0
    let ActiveSection = 1
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - View Controller
    //-----------------------------------------------------------------------------------------------------------------
    
    override func viewWillAppear(_ animated: Bool) {
        self.pendingDriversDidChange()
        self.activeDriversDidChange()
    }
    
    func prepareForDisplay(event: EventModel) {
        
        // Set event Model
        self.eventModel = event
        
        // Add Notification Observers
        eventModel.notificationCenter.addObserver(
            forName: .EventPendingDriversDidChange,
            object: eventModel,
            queue: nil,
            using: pendingDriversDidChange
        )
        eventModel.notificationCenter.addObserver(
            forName: .EventDriversDidChange,
            object: eventModel,
            queue: nil,
            using: activeDriversDidChange
        )
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Notification Observers
    //-----------------------------------------------------------------------------------------------------------------
    
    private func pendingDriversDidChange(_:Notification? = nil) {
        self.tableView.reloadData()
    }
    
    private func activeDriversDidChange(_:Notification? = nil) {
        self.tableView.reloadData()
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Table View Controller Functions
    //-----------------------------------------------------------------------------------------------------------------
    
    // Number of Sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    // Section Titles
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    // Number of rows in section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == PendingSection {
            return eventModel?.eventPendingDrivers.count ?? 0
        } else if section == ActiveSection {
            return eventModel?.eventDrivers.count ?? 0
        }
        
        return 0
    }
    
    // Populate Cells
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "driveOfferCell", for: indexPath)
        
        if indexPath.section == PendingSection {
            let pendingDriverUID = Array(eventModel.eventPendingDrivers.keys)[indexPath.item]
            cell.textLabel?.text = eventModel.eventPendingDrivers[pendingDriverUID]
        } else if indexPath.section == ActiveSection {
            let activeDriverUID = Array(eventModel.eventDrivers.keys)[indexPath.item]
            cell.textLabel?.text = eventModel.eventDrivers[activeDriverUID]
        }
        
        return cell
    }
    
    // Cell Selected
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == PendingSection {
            let selectedDriverUID = Array(eventModel.eventPendingDrivers.keys)[indexPath.item]
            self.promptPendingOffer(pendingDriver: (
                driverUID: selectedDriverUID,
                driverDisplayName: eventModel.eventPendingDrivers[selectedDriverUID]!
            ))
        } else if indexPath.section == ActiveSection {
            let selectedDriverUID = Array(eventModel.eventDrivers.keys)[indexPath.item]
            self.promptActiveOffer(activeDriver: (
                driverUID: selectedDriverUID,
                driverDisplayName: eventModel.eventDrivers[selectedDriverUID]!
            ))
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Actions
    //-----------------------------------------------------------------------------------------------------------------
    
    // Pending driver selected
    private func promptPendingOffer(pendingDriver pd: (driverUID: String, driverDisplayName:String)) {
        let alert = UIAlertController(
            title: pd.driverDisplayName,
            message: "Allow \(pd.driverDisplayName) to drive for \(eventModel.eventName ?? "this event")",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        ))
        alert.addAction(UIAlertAction(
            title: "Accept Offer",
            style: .default,
            handler: { (_:UIAlertAction) in
                self.eventModel.addDriverToEvent(driverUID: pd.driverUID, driverDisplayName: pd.driverDisplayName)
            }
        ))
        alert.addAction(UIAlertAction(
            title: "Remove Offer",
            style: .destructive,
            handler: { (_:UIAlertAction) in
                self.eventModel.cancelPendingDriveOffer(driverUID: pd.driverUID)
            }
        ))
        self.present(alert, animated: true, completion: nil)
    }
    
    // Active driver selected
    private func promptActiveOffer(activeDriver ad: (driverUID: String, driverDisplayName: String)) {
        let alert = UIAlertController(
            title: ad.driverDisplayName,
            message: "Remove \(ad.driverDisplayName) as a driver for \(eventModel.eventName ?? "this event")",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        ))
        alert.addAction(UIAlertAction(
            title: "Remove Driver",
            style: .destructive,
            handler: { (_:UIAlertAction) in
                self.eventModel.removeDriverFromEvent(driverUID: ad.driverUID)
        }
        ))
        self.present(alert, animated: true, completion: nil)
    }
    
}
