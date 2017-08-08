//
//  RFIDTableViewController.swift
//  NFC-Example
//
//  Created by Hans Knöchel on 14.06.17.
//  Copyright © 2017 Hans Knoechel. All rights reserved.
//

import UIKit
import CoreNFC

class RFIDTableViewController: UITableViewController {
    
    // Reference the RFID session
    private var rfidSession: NFCISO15693ReaderSession!
    
    // Reference the found NFC messages
    private var rfidTags: [[NFCISO15693Tag]] = []
    
    // Start the search when tapping the "Start Search" button
    @IBAction func startRFIDSearchButtonTapped(_ sender: Any) {
        // NOTE: iOS 11 Beta 1-2 will throw a "Feature not supported" error, so they probably did not finish
        // exposing the RFID-related API's so far.

        // NOTE: iOS 11 Beta 3-5 will show the scan-dialog, but then fail with an error. They seem to still 
        // not figured out how to expose it properly.
        self.rfidSession.begin()
    }
    
    // Dismisses the current RFID view-controller
    @IBAction func dismissViewController(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(NFCTableViewCell.self, forCellReuseIdentifier: "NFCTableCell")
        
        // Create the RFID Reader Session when the app starts
        self.rfidSession = NFCISO15693ReaderSession(delegate: self, queue: nil)
        self.rfidSession.alertMessage = "You can scan RFID-tags by holding them behind the top of your iPhone."
    }
}

// MARK: UITableViewDelegate / UITableViewDataSource

extension RFIDTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.rfidTags.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rfidTags[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let numberOfMessages = self.rfidTags[section].count
        let headerTitle = numberOfMessages == 1 ? "One Tag" : "\(numberOfMessages) Tags"
        
        return headerTitle
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NFCTableCell", for: indexPath) as! NFCTableViewCell
        let nfcTag = self.rfidTags[indexPath.section][indexPath.row]
        
        cell.textLabel?.text = "\(nfcTag.identifier) (\(nfcTag.icSerialNumber))"
        cell.detailTextLabel?.text = "Available: \(nfcTag.isAvailable)"
        
        return cell
    }
}

// MARK: NFCNDEFReaderSessionDelegate

extension RFIDTableViewController : NFCReaderSessionDelegate {
    
    func readerSession(_ session: NFCReaderSession, didInvalidateWithError error: Error) {
        print("Error reading RFID-Tag: \(error.localizedDescription)")
    }
    
    func readerSession(_ session: NFCReaderSession, didDetect tags: [NFCTag]) {
        print("\(tags.count) new RFID-Tags detected:")
        
        for tag in tags {
            let rfidTag = tag as! NFCISO15693Tag
            
            print("- Is available: \(rfidTag.isAvailable)")
            print("- Type: \(rfidTag.type)")
            print("- IC Manufacturer Code: \(rfidTag.icManufacturerCode)")
            print("- IC Serial Number: \(rfidTag.icSerialNumber)")
            print("- Identifier: \(rfidTag.identifier)")
            
            // Uncomment to send a custom command. Not sure, yet what to send here.
//            rfidTag.sendCustomCommand(commandConfiguration: NFCISO15693CustomCommandConfiguration(manufacturerCode: rfidTag.icManufacturerCode,
//                                                                                                  customCommandCode: 0,
//                                                                                                  requestParameters: nil),
//                                      completionHandler: { (data, error) in
//                                        guard error != nil else {
//                                            return print("Error sending custom command: \(String(describing: error))")
//                                        }
//
//                                        print("Data: \(data)")
//            })
        }
        
        // Add the new tags to our found tags
        self.rfidTags.append(tags as! [NFCISO15693Tag])
        
        // Reload our table-view on the main-thread to display the new data-set
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func readerSessionDidBecomeActive(_ session: NFCReaderSession) {
        print("RFID-Tag (\(session)) session did become active")
    }
}

