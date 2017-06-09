# 📱 iOS11 NFC-Example
A quick example showing how to use the Core NFC API in iOS 11 and Swift 4.

## Prerequisites
* Xcode 9 Beta (tested with B1)
* iOS 11 device (iPhone 7 / iPhone 7 Plus)
* NFC capability-key added to your project's `.entitlements` file
```xml
<key>com.apple.developer.nfc.readersession.formats</key>
<array>
    <string>NDEF</string>
</array>
```
* Provisioning Profile entitled with the `NFC Tag Reading` capability:
<img src="https://abload.de/img/bildschirmfoto2017-06kguc2.png" width="500" alt="iOS Developer Center: NFC Capability" />

## Getting Started
First, import the `CoreNFC` framework. Note: Xcode 9 B1 will throw an error if you select a Simulator instead of
a device. Apple will probably guard that in later Beta versions and provide a `isSupported` method.
```swift
import CoreNFC
```
Next, create 2 properties: Your session and an array of discovered tag-messages:
```swift
// Reference the NFC session
private var nfcSession: NFCNDEFReaderSession!
    
// Reference the found NFC messages
private var nfcMessages: [[NFCNDEFMessage]] = []
```
After that, assign your `nfcSession`:
```swift
// Create the NFC Reader Session when the app starts
self.nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
```
Finally, write an extension that implements the `NFCNDEFReaderSessionDelegate`:
```swift
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
        
        // Reload our table-view to display the new data-set
        self.tableView.reloadData()
    }
}
```
Optionally, since we use a `UITableView` to display the discovered messages, prepare your table-view delegates:
```swift
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
```
That's it! Run the app on your device and scan your NFC NDEF-Tag.

## Author
Hans Knöchel ([@hansemannnn](https://twitter.com/hansemannnn))
