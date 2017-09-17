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
    
    func initializeNFCSession() {
        // Create the NFC Reader Session when the app starts
        self.nfcSession = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: false)
        self.nfcSession.alertMessage = "You can scan NFC-tags by holding them behind the top of your iPhone."
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register our table-cell to display the records
        self.tableView.register(NFCTableViewCell.self, forCellReuseIdentifier: "NFCTableCell")
        
        self.initializeNFCSession()
    }
    
    class func formattedTypeNameFormat(from typeNameFormat: NFCTypeNameFormat) -> String {
        switch typeNameFormat {
        case .empty:
            return "Empty"
        case .nfcWellKnown:
            return "NFC Well Known"
        case .media:
            return "Media"
        case .absoluteURI:
            return "Absolute URI"
        case .nfcExternal:
            return "NFC External"
        case .unchanged:
            return "Unchanged"
        default:
            return "Unknown"
        }
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
        let numberOfMessages = self.nfcMessages[section].count
        let headerTitle = numberOfMessages == 1 ? "One Message" : "\(numberOfMessages) Messages"
        
        return headerTitle
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
        let records = nfcTag.records.map({ String(describing: String(data: $0.payload, encoding: .utf8)!) })
        
        let alertTitle = " \(nfcTag.records.count) Records found in Message"
        let alert = UIAlertController(title: alertTitle, message: records.joined(separator: "\n"), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: NFCNDEFReaderSessionDelegate

extension NFCTableViewController : NFCNDEFReaderSessionDelegate {
    
    // Called when the reader-session expired, you invalidated the dialog or accessed an invalidated session
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("NFC-Session invalidated: \(error.localizedDescription)")
        // initialize a new session
        self.initializeNFCSession()
    }
    
    // Called when a new set of NDEF messages is found
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print("New NFC Messages (\(messages.count)) detected:")
        
        for message in messages {
            print(" - \(message.records.count) Records:")
            for record in message.records {
                print("\t- TNF (TypeNameFormat): \(NFCTableViewController.formattedTypeNameFormat(from: record.typeNameFormat))")
                print("\t- Payload: \(String(data: record.payload, encoding: .utf8)!)")
                print("\t- Type: \(record.type)")
                print("\t- Identifier: \(record.identifier)\n")
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
