//
//  PrefsViewController.swift
//  PingThing
//
//  Created by Huw Rowlands on 2.6.2015.
//  Copyright (c) 2015 DiUS Computing Pty Ltd. All rights reserved.
//

import Cocoa

class PrefsViewController: NSViewController {
    @IBOutlet weak var targetHostTextField: NSTextField!
    @IBOutlet weak var saveHostButton: NSButton!
    @IBOutlet weak var statusTextField: NSTextField!
    @IBOutlet weak var intervalTextField: NSTextField!
    @IBOutlet weak var startStopButton: NSButtonCell!
    
    var currentStatus: Status? {
        didSet {
            if let status = currentStatus {
                statusTextField.stringValue = status.rawValue
                switch status {
                case .Success:
                    statusTextField.textColor = NSColor(calibratedRed: 0, green: 149/255.0, blue: 0, alpha: 1)
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
    
    var pingHelper: PingHelper?
    
    @IBAction func intervalTextFieldChanged(sender: NSTextField) {
        if let helper = pingHelper {
            helper.interval = intervalTextField.doubleValue
            helper.start()
            savePrefs(fromPingHelper: helper)
        }
    }
    
    @IBAction func quit(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }
    
    @IBAction func targetHostTextFieldChanged(sender: NSTextField) {
        saveHostButton.performClick(self)
    }
    
    @IBAction func saveHostButtonPressed(sender: NSButton) {
        if let helper = pingHelper {
            statusTextField.stringValue = "Starting…"
            statusTextField.textColor = NSColor.blackColor()
            helper.host = targetHostTextField.stringValue
            helper.start()
            savePrefs(fromPingHelper: helper)
        }
    }
    
    @IBAction func startStopButtonPressed(sender: NSButtonCell) {
        if let helper = pingHelper {
            if helper.running {
                helper.stop()
            } else {
                helper.start()
            }
        }
    }
    
    @IBAction func launchAtLoginCheckbox(sender: NSButton) {
        println("Launch at login checkbox checked")
        println("Value: \(sender.state)")
    }
    
    override func viewWillAppear() {
        if let appDelegate = NSApplication.sharedApplication().delegate as? AppDelegate {
            pingHelper = appDelegate.pingHelper
        }
        
        if let helper = pingHelper {
            listenToPings(onPingHelper: helper)
            updateStatus(fromHelper: helper)
            targetHostTextField.stringValue = helper.host
            intervalTextField.doubleValue = helper.interval
        }
    }
    
    override func viewWillDisappear() {
        if let helper = pingHelper {
            NSNotificationCenter.defaultCenter().removeObserver(helper)
        }
    }
    
    private func updateStatus(fromHelper helper: PingHelper) {
        self.currentStatus = helper.status
        self.startStopButton.title = helper.running ? "Stop" : "Start"
    }
    
    private func listenToPings(onPingHelper helper: PingHelper) {
        NSNotificationCenter.defaultCenter().addObserverForName(StatusChangedNotification,
            object: helper,
            queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                if let strongSelf = self {
                    strongSelf.updateStatus(fromHelper: helper)
                }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(PingStartedNotification,
            object: helper,
            queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                if let strongSelf = self {
                    strongSelf.updateStatus(fromHelper: helper)
                }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(PingStoppedNotification,
            object: helper,
            queue: NSOperationQueue.mainQueue()) { [weak self] notification in
                if let strongSelf = self {
                    strongSelf.updateStatus(fromHelper: helper)
                }
        }
    }
    
    private func savePrefs(fromPingHelper helper: PingHelper, usingDefaults defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
        defaults.setObject(helper.host, forKey: TargetHostUserDefaultsKey)
        defaults.setObject(helper.interval, forKey: PingIntervalUserDefaultsKey)
        defaults.synchronize()
    }
    
}
