//
//  PrefsViewController.swift
//  PingThing
//
//  Created by Huw Rowlands on 2.6.2015.
//  Copyright (c) 2015 DiUS Computing Pty Ltd. All rights reserved.
//

import Cocoa

class PrefsViewController: NSViewController {
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var saveHostButton: NSButton!
    @IBOutlet weak var statusTextField: NSTextField!
    @IBOutlet weak var startStopButton: NSButtonCell!
    
    var currentStatus: Status? {
        didSet {
            if let status = currentStatus {
                statusTextField.stringValue = status.rawValue
                switch status {
                case .Success:
                    statusTextField.textColor = NSColor.greenColor()
                case .Failure:
                    statusTextField.textColor = NSColor.orangeColor()
                case .Error:
                    statusTextField.textColor = NSColor.redColor()
                default:
                    statusTextField.textColor = NSColor.blackColor()
                }
            }
        }
    }
    
    @IBAction func quit(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }
    
    @IBAction func textFieldChanged(sender: NSTextField) {
        saveHostButton.performClick(self)
    }
    
    @IBAction func saveHostButtonPressed(sender: NSButton) {
        statusTextField.stringValue = "Starting…"
        statusTextField.textColor = NSColor.blackColor()
        AppDelegate.pingHelper.host = textField.stringValue
        
        let prefs = NSUserDefaults.standardUserDefaults()
        prefs.setObject(AppDelegate.pingHelper.host, forKey: TargetHostUserDefaultsKey)
        prefs.synchronize()
    }
    
    @IBAction func startStopButtonPressed(sender: NSButtonCell) {
        if AppDelegate.pingHelper.running {
            AppDelegate.pingHelper.stop()
        } else {
            AppDelegate.pingHelper.start()
        }
    }
    
    @IBAction func launchAtLoginCheckbox(sender: NSButton) {
        println("Launch at login checkbox checked")
        println("Value: \(sender.state)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        listenToPings(onPingHelper: AppDelegate.pingHelper)
        updateStatusFromHelper()
        textField.stringValue = AppDelegate.pingHelper.host
        
    }
    
    override func viewWillDisappear() {
        NSNotificationCenter.defaultCenter().removeObserver(AppDelegate.pingHelper)
    }
    
    private func updateStatusFromHelper() {
        self.currentStatus = AppDelegate.pingHelper.status
        self.startStopButton.title = AppDelegate.pingHelper.running ? "Stop" : "Start"
    }
    
    private func listenToPings(onPingHelper pingHelper: PingHelper) {
        NSNotificationCenter.defaultCenter().addObserverForName(PingReceivedNotification,
            object: pingHelper,
            queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                if let strongSelf = self {
                    strongSelf.updateStatusFromHelper()
                }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(PingStartedNotification,
            object: pingHelper,
            queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                if let strongSelf = self {
                    strongSelf.updateStatusFromHelper()
                }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(PingStoppedNotification,
            object: pingHelper,
            queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                if let strongSelf = self {
                    strongSelf.updateStatusFromHelper()
                }
        }
    }
    
}