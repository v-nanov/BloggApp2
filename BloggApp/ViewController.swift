//
//  ViewController.swift
//  BloggApp
//
//  Created by Heber Andrade on 08/04/16.
//  Copyright © 2016 Heber Andrade. All rights reserved.
//

import UIKit
import AVFoundation


import WatsonDeveloperCloud

class ViewController: UIViewController, AVAudioRecorderDelegate {
    @IBOutlet weak var printLabelLocotions: UILabel!
    @IBOutlet weak var printHashtagLabel: UILabel!
    
    
    //Speech to Text Integration
    @IBOutlet weak var startStopRecordingButton: UIButton!
    @IBOutlet weak var playRecordingButton: UIButton!
    @IBOutlet weak var transcribeButton: UIButton!
    @IBOutlet weak var startStopStreamingDefaultButton: UIButton!
    @IBOutlet weak var startStopStreamingCustomButton: UIButton!
    @IBOutlet weak var transcriptionField: UITextView!
    
    var stt: SpeechToText?
    var player: AVAudioPlayer? = nil
    var recorder: AVAudioRecorder!
    var isStreamingDefault = false
    var stopStreamingDefault: (Void -> Void)? = nil
    var isStreamingCustom = false
    var stopStreamingCustom: (Void -> Void)? = nil
    var captureSession: AVCaptureSession? = nil
    
    //Slut Speech to tex
    
    
    
    
    @IBAction func fastLocation(sender: AnyObject) {
      
        let requestURL = NSMutableURLRequest(URL: NSURL(string: "http://hashtaggenerator201.eu-gb.mybluemix.net/events?lat=55.6118668&lng=12.9772628&distance=1000")!)
        
        let response = NSHTTPURLResponse()
      
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(requestURL, completionHandler: {data, response, error -> Void in
            let error = error
            let response = response
            let data = data
            if  data != nil && error == nil {
                let res = response as! NSHTTPURLResponse!
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    do {
                        let jsonData:AnyObject? = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
                        
                        if let counter = jsonData!["entity"] as? [AnyObject] {
                            let type1 = counter[0]
                            let tag = counter[1]
                            
                            
                        }
                        
                        
                        
                        print("Success")
                    } catch let error as NSError {
                        print("Failed To load")
                    } catch {
                        // Something else happened.
                        // Insert your domain, code, etc. when constructing the error.
                        
                    }
                } else {
                    print("Connection Error")
                }
                
            } else {
                print("Error")
            }
        })
        task.resume()
    
        
        func httpGet(requestURL: NSURLRequest, callback: (String?, NSError?) -> Void) {
            let task = NSURLSession.sharedSession().dataTaskWithRequest(requestURL) { data, respond, error in
                guard error == nil && data != nil else {
                    callback(nil, error)
                    return
                }
                
                callback(String(data: data!, encoding: NSUTF8StringEncoding), nil)
            }
            task.resume()
        }
        
        
        httpGet(requestURL) { string, error in
            guard error == nil && string != nil else {
                print(error?.localizedDescription)
                return
            }
            
            print(string!)
        }
    
        

        
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
               
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

