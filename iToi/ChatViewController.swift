//
//  ChatViewController.swift
//  iToi
//
//  Created by Raj on 2/24/16.
//  Copyright © 2016 Raj. All rights reserved.
//

import UIKit


var dateFormatter : DateFormatter = {
    let formatter =  DateFormatter()
    formatter.dateFormat = "dd/MMM/yyyy HH:mm"
    return formatter
}()


class ChatViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    let chatService = ChatManager()
    var messages = [[String:AnyObject?]]()
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var statusUpdate: UILabel!
    var pickedImage: UIImageView =  UIImageView()
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var connectionLabel: UILabel!
    
    @IBOutlet weak var messageTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        chatService.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        imagePicker.delegate = self
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension

        // Set up keyboard dismissal
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        if messages.count > 1{
            scrollToNewMessage()

        }
        
//         NSTimer.scheduledTimerWithTimeInterval(300, target: self, selector: #selector(ChatViewController.onSendMessage(_:)), userInfo: nil, repeats: true)
        
    }
    
    @IBAction func onSendMessage(_ sender: AnyObject) {
        if messageTextField.text != nil && messageTextField.text != ""{
            
            // Grab message and clear text field
            let messageText = messageTextField.text!
            messageTextField.text = "Hello Again !"
            
            let messageDictionary : [String:AnyObject] = ["Sender": chatService.myPeerId.displayName as AnyObject, "Message": messageText as AnyObject, "Time": dateFormatter.string(from: Date()) as AnyObject]
             messages.append(messageDictionary)
            
            let messageData : Data = NSKeyedArchiver.archivedData(withRootObject: messageDictionary)
            // Send the message out
            chatService.sendMessage(messageData)
            
            tableView.reloadData()
            
            // Scroll to bottom of messages
            scrollToNewMessage()
        }
    }
    
    
    @IBAction func sendImage(_ sender: AnyObject) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
           
            pickedImage.image = image
           // let imageData =  UIImagePNGRepresentation(image)
            
            let imageData = UIImageJPEGRepresentation(image, 0.3)
            
            let messageDictionary : [String:AnyObject] = ["Sender": chatService.myPeerId.displayName as AnyObject, "Message": imageData! as AnyObject, "Time": dateFormatter.string(from: Date()) as AnyObject]
             messages.append(messageDictionary)
            
            let messageData : Data = NSKeyedArchiver.archivedData(withRootObject: messageDictionary)
            
            // Send the message out
            chatService.sendMessage(messageData)
           
            tableView.reloadData()
            
            // Scroll to bottom of messages
            scrollToNewMessage()
        }
    
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: TableView Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell") as! ChatCell
        let messageData = messages[indexPath.row]
        
        let sender = messageData["Sender"] as! String
        
        let timestamp = messageData["Time"] as! String
        
        if sender ==  UIDevice.current.name{
            cell.sender.textAlignment = NSTextAlignment.right
            cell.message.textAlignment = NSTextAlignment.right
        }
        else{
            cell.sender.textAlignment = NSTextAlignment.left
            cell.message.textAlignment = NSTextAlignment.left
        }
        
       cell.sender.text = sender + "  " + timestamp
        
        if let messageType = messageData["Message"] {
            
            if messageType is String {
                cell.message.text =  messageType as? String
                cell.transferredImage.image = nil
            } else {
                // Image
                if let imageType =  UIImage(data: messageType as! Data) {
                     cell.transferredImage.image = imageType
                     cell.message.text = nil
                } else {
                    // Text
                    cell.message.text = String(data: messageType as! Data, encoding: String.Encoding.utf8)
                    cell.transferredImage.image = nil
            }
          }
        }
        return cell

}
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func scrollToNewMessage(){
        tableView.scrollToRow(
            at: IndexPath(row: self.messages.count - 1, section: 0),
            at: UITableViewScrollPosition.bottom,
            animated: true)
    }
}

extension ChatViewController : ChatServiceDelegate {
    
    func connectedDevicesChanged(_ manager: ChatManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            if connectedDevices.count > 0 {
            self.connectionLabel.text = "Connections:😀 \(connectedDevices)"
            } else {
                self.connectionLabel.text = "Connections:😕"
            }
        }
    }
    
    func messageReceived(_ manager: ChatManager, message: Data){
        
        DispatchQueue.main.async(execute: {
           self.statusUpdate.text = "Receiving"
            
        })
        
        OperationQueue.main.addOperation {
            let messageDictionary:[String: AnyObject] = (NSKeyedUnarchiver.unarchiveObject(with: message)) as! [String: AnyObject]
            self.messages.append(messageDictionary)
            self.tableView.reloadData()
            self.scrollToNewMessage()
            self.statusUpdate.text = ""
        }
    }
    
}
