//
//  ViewController.swift
//  NetTop
//
//  Created by Huanming Hu  on 2017/8/19.
//  Copyright © 2017年 huhuanming. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    var am = 0
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    @IBOutlet var statusMenu: NSMenu!
    
    @IBAction func quitClick(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    
    var applicationMap: Dictionary<String, NTApplication> = [:]
    
    var processMap: Dictionary<String, String> = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statusItem.title = "NetTop"
        statusItem.menu = statusMenu

        for app in NSWorkspace.shared.runningApplications {
            if app.bundleIdentifier != nil {
                let bundleIdentifier = app.bundleIdentifier ?? ""
                self.applicationMap[bundleIdentifier] = NTApplication(bundleIdentifier: bundleIdentifier, name: app.localizedName ?? bundleIdentifier, icon: app.icon!, bytesIn: 0, bytesOut: 0)
                self.processMap[String(app.processIdentifier)] = bundleIdentifier
            }
        }
        self.runTester()
    }
    
    func runTester(){
        let task = Process()
             task.launchPath = "/usr/bin/nettop"
             //task.arguments = ["-t", "wifi", "-t", "wired", "-P", "-L", "1"]
             task.arguments = ["-P","-L", "-S","1"]
        let pipe = Pipe()
        task.standardOutput = pipe
        let outHandle = pipe.fileHandleForReading
        outHandle.waitForDataInBackgroundAndNotify()

        var obs1 : NSObjectProtocol!
        obs1 = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable,
           object: outHandle, queue: nil) {  notification -> Void in
            let data = outHandle.availableData
            if data.count > 0 {
                if let str = String(data: data, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) {
                    //print("got output: \(str)")
                     let stringArray = str.split(separator: "\n")
                     for i in 0...(stringArray.count-1) {
                        let string = stringArray[i]
                    
                        let infos = string.components(separatedBy: ",")
                       
                        let processId = infos[1]
                        if(processId == "Google Chrome H.3033"){
                             print(processId)
                            print(infos[4])
                            let dif = (Int(infos[4]) ?? 0) - self.am
                            print(dif)
                            self.am = Int(infos[4]) ?? 0
                            
                        }
                       
                    }
                }
                outHandle.waitForDataInBackgroundAndNotify()
            } else {
                print("EOF on stdout from process")
                NotificationCenter.default.removeObserver(obs1 as Any)
            }
        }

        var obs2 : NSObjectProtocol!
        obs2 = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification,
                   object: task, queue: nil) { notification -> Void in
                    print("terminated")
                    NotificationCenter.default.removeObserver(obs2 as Any)
            }
        task.launch()
    }
    
    func updateTrafficData() {
        let task = Process()
        task.launchPath = "/usr/bin/nettop"
        //task.arguments = ["-t", "wifi", "-t", "wired", "-P", "-L", "1"]
        task.arguments = ["-P","-L", "1"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        task.launch()
        
        pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: pipe.fileHandleForReading , queue: nil) {
            notification in
            
            let output = pipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            print(outputString)
            let stringArray = outputString.split(separator: "\n")
            //print(stringArray)
            print(">>>>>>>>>>>>>>>>")
            if stringArray.count < 2 {
                DispatchQueue.main.async {
                    self.updateTrafficData()
                }
                return
            }
            
            /*
            self.statusMenu.removeAllItems()
            
            for i in 1...(stringArray.count-1) {
                
                let string = stringArray[i]
                let infos = string.components(separatedBy: ",")
                let processId = infos[1].components(separatedBy: ".").last!
                let bytesIn = infos[4]
                let bytesOut = infos[5]
                print(bytesIn)
                
                if let bundleIdentifier = self.processMap[processId] {
                    if let app = self.applicationMap[bundleIdentifier] {
                        print(app.name)
                        if(app.name == "Safari Networking"){
                            
                             print(bytesIn)
                                print(bytesOut)
                        }
                        let menuItem = NSMenuItem.init(title: "\(app.name) \(Float(bytesIn)! / 1024 / 1024) Mib \(Float(bytesOut)! / 1024 / 1024) Mib", action: nil, keyEquivalent: "")
                        self.statusMenu.addItem(menuItem)
                    }
                }
            }
            */
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: {
                self.updateTrafficData()
            })
        }
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

