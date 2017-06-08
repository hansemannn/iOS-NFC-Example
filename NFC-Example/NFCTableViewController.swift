//
//  NFCTableViewController.swift
//  NFC-Example
//
//  Created by Hans Knöchel on 08.06.17.
//  Copyright © 2017 Hans Knoechel. All rights reserved.
//

import UIKit
import CoreNFC

// #warning: Ensure to set a use valid app-id / provisioning profile that includes NFC capabilities

class NFCTableViewController: UITableViewController {
    
    // Reference the NFC session
    private var nfcSession: NFCNDEFReaderSession!
    
    // Reference the found NFC messages
    private var nfcMessages: [[NFCNDEFMessage]] = []
    
    // Start the search when tapping the "Start Search" button
    @IBAction func startNFCSearchButtonTapped(_ sender: Any) {
        self.nfcSession.begin()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create the NFC Reader Session when the app starts
        self.nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
    }
}

// MARK: UITableViewDelegate / UITableViewDataSource

extension NFCTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.nfcMessages.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.nfcMessages[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(self.nfcMessages[section].count) Messages"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NFCTableCell", for: indexPath)
        let nfcTag = self.nfcMessages[indexPath.section][indexPath.row]
        
        cell.textLabel?.text = "\(nfcTag.records.count) Records"
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}

// MARK: NFCNDEFReaderSessionDelegate

extension NFCTableViewController : NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("Error reading NFC: \(error.localizedDescription)")
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print("New NFC Tag detected:")
        
        for message in messages {
            for record in message.records {
                print("Type name format: \(record.typeNameFormat)")
                print("Payload: \(record.payload)")
                print("Type: \(record.type)")
                print("Identifier: \(record.identifier)")
            }
        }
        
        self.nfcMessages.append(messages)
        self.tableView.reloadData()
    }
}
