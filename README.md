# 📱 iOS11 NFC-Example
###### Last Update: June 14, 2017 | iOS 11 Beta 1

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
<img src="https://abload.de/img/68747470733a2f2f6162606s1g.png" width="500" alt="iOS Developer Center: NFC Capability" />

## Understanding NDEF-Records

In order to work with NFC-tags, it is fundamental to understand the NDEF (NFC Data Exchange Format) specification.
Whenever `CoreNFC` discovers a new tag, the `didDetectNDEFs` delegate method will provide an array of NDEF messages
(`[NFCNDEFMessage]`). Usually, there is only one NDEF message included, but the specification keeps it flexible to provide
multiple messages at the same time. 

Every `NFCNDEFMessage` includes an array of payload-records (`[NFCNDEFPayload]`) that hold the actual information
the developer is interested in. There are currently four (undocumented) properties in the `CoreNFC` framework to access those:

1. `typeNameFormat`: The type name format (TNF) describes the data-structure of the related record. There are seven types that can be used via the enumeration `NFCTypeNameFormat`:
    1. `.empty`: There record is empty and does not contain any information
    2. `.nfcWellKnown`: The payload is known and defined by the Record Type Definition (RTD), for example RTD Text / URI.
    3. `.media`: The payload includes a final / intermediate chunk of data defined by the mime-type ([RFC2046](http://www.faqs.org/rfcs/rfc2046.html))
    4. `.absoluteURI`: The record contains an absolute URI resource ([RFC3986](http://www.faqs.org/rfcs/rfc3986.html))
    5. `.nfcExternal`: The record contains a value that uses an external RTD name specifiction
    6. `.unknown`: The record type is unknown, the type length has to be set to `0`.
    7. `.unchanged`: The record payload is the intermediate or even final chunk of data. This can be used when there is a large number of data that is splitted into multiple chunks of data.
2. `type`: The Record Type Definition (RTD) of the record. iOS 11 describes it as a `Data` type, Android has constants (like [`RTD_TEXT`](https://developer.android.com/reference/android/nfc/NdefRecord.html#RTD_TEXT)), so either later iOS 11 beta versions will expose similar ones as well, or the developer needs to create enumerations for it. I will try keep this updated during the Beta cycles!
3. `identifier`: A unique identifier of the record.
4. `payload`: The actual payload of the record. Accessing it depends on the specified `typeNameFormat` as described above.

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
        
        // Reload our table-view on the main-thread to display the new data-set
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
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
        let numberOfMessages = self.nfcMessages[section].count
        let headerTitle = numberOfMessages == 1 ? "One Message" : "\(numberOfMessages) Messages"
        
        return headerTitle
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NFCTableCell", for: indexPath) as! NFCTableViewCell
        let nfcTag = self.nfcMessages[indexPath.section][indexPath.row]
        
        cell.textLabel?.text = "\(nfcTag.records.count) Records"
        
        return cell
    }
}
```
That's it! Run the app on your device and scan your NFC NDEF-Tag.

### Example Output
```
New NFC Messages (1) detected:
 - 2 Records:
   - TNF (TypeNameFormat): NFC Well Known
   - Payload: google.com
   - Type: 1 bytes
   - Identifier: 0 bytes

   - TNF (TypeNameFormat): NFC Well Known
   - Payload: enTest
   - Type: 1 bytes
   - Identifier: 0 bytes
```

## User Experiences
Initial tests of another user (thanks [@tinue](https://github.com/tinue)) shown these following results:
1. Scanning an NDEF-tag usually works once directly after rebooting the iPhone. From then on, it may or may not work, usually it doesn't work and another reboot is required. This was seen with Beta 1 of iOS 11.
2. If the RFID-tag is fresh (empty), or does not contain an NDEF-tag (e.g. a credit-card), the reader times out (error 201).
3. If the RFID-tag contains encrypted sectors, the reader throws error 200 (`readerSessionInvalidationErrorUserCanceled`).

## RFID Functionality
In this example, we used the `NFCNDEFReaderSession` to handle NDEF NFC-chips. There actually is another class inside
`CoreNFC`, called `NFCISO15693ReaderSession`. [ISO15693](https://de.wikipedia.org/wiki/ISO_15693) is the specification
for RFID-tags, and it comes along with own delegates and a class describing an RFID-tag (`NFCISO15693Tag`).

I have played around with that API as well and added the `RFID` button to the current implementation, so you can switch
between NFC- and RFID-detection. You can even send custom commands to the RFID-chip as demonstrated in the
`readerSession:didDetectTags:` delegate and the `NFCISO15693CustomCommandConfiguration` class.

Unfortunately, iOS 11 Beta 1 will throw a `Feature not supported` error, since the
API might not be finished, yet. It will likely result in another value inside the `com.apple.developer.nfc.readersession.formats`
entitlements key as well. Using something like `ISO15693` or `RFID` will not work so far and prevent the build from finishing.
Let's see what Apple will publish in the upcoming Beta versions of iOS 11! 🙂

## References
I used the following resources to get started with NDEF NFC-tags:
- [x] [https://flomio.com/2012/05/ndef-basics/](https://flomio.com/2012/05/ndef-basics/)
- [x] [https://learn.adafruit.com/adafruit-pn532-rfid-nfc/ndef](https://learn.adafruit.com/adafruit-pn532-rfid-nfc/ndef)
- [x] [https://developer.android.com/reference/android/nfc/NdefRecord.html](https://developer.android.com/reference/android/nfc/NdefRecord.html)
- [x] [https://gototags.com/nfc/ndef/](https://gototags.com/nfc/ndef/)

## Cross-Platform Usage
If you are using a cross-platform solution for your application, [Appcelerator Titanium](http://www.appcelerator.com/mobile-app-development-products/) has an open source [NFC module](https://github.com/appcelerator-modules/ti.nfc) for both Android and iOS (Beta).

## Author
Hans Knöchel ([@hansemannnn](https://twitter.com/hansemannnn))
