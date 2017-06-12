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
        
        self.tableView.register(NFCTableViewCell.self, forCellReuseIdentifier: "NFCTableCell")
        
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "NFCTableCell", for: indexPath) as! NFCTableViewCell
        let nfcTag = self.nfcMessages[indexPath.section][indexPath.row]
        
        cell.textLabel?.text = "\(nfcTag.records.count) Records"
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nfcTag = self.nfcMessages[indexPath.section][indexPath.row]
        
        let alert = UIAlertController(title: " \(nfcTag.records.count) Records found", message: "TODO: Display record-details?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: NFCNDEFReaderSessionDelegate

extension NFCTableViewController : NFCNDEFReaderSessionDelegate {
    
    // Called when the reader-session expired, you invalidated the dialog or accessed an invalidated session
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("Error reading NFC: \(error.localizedDescription)")
    }
    
    // Called when a new set of NDEF messages is found
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
        
        // Add the new messages to our found messages
        self.nfcMessages.append(messages)
        
        // Reload our table-view on the main-thread to display the new data-set
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
