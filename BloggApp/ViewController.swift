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
        // create file to store recordings
        let documents = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,
                                                            .UserDomainMask, true)[0]
        let filename = "SpeechToTextRecording.wav"
        let filepath = NSURL(fileURLWithPath: documents + "/" + filename)
        
        // set up session and recorder
        let session = AVAudioSession.sharedInstance()
        var settings = [String: AnyObject]()
        settings[AVSampleRateKey] = NSNumber(float: 44100.0)
        settings[AVNumberOfChannelsKey] = NSNumber(int: 1)
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            recorder = try AVAudioRecorder(URL: filepath, settings: settings)
        } catch {
            failure("Audio Recording", message: "Error setting up session/recorder.")
        }
        
        // ensure recorder is set up
        guard let recorder = recorder else {
            failure("AVAudioRecorder", message: "Could not set up recorder.")
            return
        }
        
        // prepare recorder to record
        recorder.delegate = self
        recorder.meteringEnabled = true
        recorder.prepareToRecord()
        
        // disable play and transcribe buttons
        playRecordingButton.enabled = false
        transcribeButton.enabled = false
        
        instantiateSTT()
    }
    
    func instantiateSTT() {
        
        // identify credentials file
        let bundle = NSBundle(forClass: self.dynamicType)
        guard let credentialsURL = bundle.pathForResource("Credentials", ofType: "plist") else {
            failure("Loading Credentials", message: "Unable to locate credentials file.")
            return
        }
        
        // load credentials file
        let dict = NSDictionary(contentsOfFile: credentialsURL)
        guard let credentials = dict as? Dictionary<String, String> else {
            failure("Loading Credentials", message: "Unable to read credentials file.")
            return
        }
        
        // read SpeechToText username
        guard let user = credentials["SpeechToTextUsername"] else {
            failure("Loading Credentials", message: "Unable to read Speech to Text username.")
            return
        }
        
        // read SpeechToText password
        guard let password = credentials["SpeechToTextPassword"] else {
            failure("Loading Credentials", message: "Unable to read Speech to Text password.")
            return
        }
        
        stt = SpeechToText(username: user, password: password)
    }
    
    @IBAction func startStopRecording() {
        
        // ensure recorder is set up
        guard let recorder = recorder else {
            failure("Start/Stop Recording", message: "Recorder not properly set up.")
            return
        }
        
        // stop playing previous recording
        if let player = player {
            if (player.playing) {
                player.stop()
            }
        }
        
        // start/stop recording
        if (!recorder.recording) {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setActive(true)
                recorder.record()
                startStopRecordingButton.setTitle("Stop Recording", forState: .Normal)
                playRecordingButton.enabled = false
                transcribeButton.enabled = false
            } catch {
                failure("Start/Stop Recording", message: "Error setting session active.")
            }
        } else {
            do {
                recorder.stop()
                let session = AVAudioSession.sharedInstance()
                try session.setActive(false)
                startStopRecordingButton.setTitle("Start Recording", forState: .Normal)
                playRecordingButton.enabled = true
                transcribeButton.enabled = true
            } catch {
                failure("Start/Stop Recording", message: "Error setting session inactive.")
            }
        }
    }
    
    @IBAction func playRecording() {
        
        // ensure recorder is set up
        guard let recorder = recorder else {
            failure("Play Recording", message: "Recorder not properly set up")
            return
        }
        
        // play saved recording
        if (!recorder.recording) {
            do {
                player = try AVAudioPlayer(contentsOfURL: recorder.url)
                player?.play()
            } catch {
                failure("Play Recording", message: "Error creating audio player.")
            }
        }
    }
    
    @IBAction func transcribe() {
        
        // ensure recorder is set up
        guard let recorder = recorder else {
            failure("Transcribe", message: "Recorder not properly set up.")
            return
        }
        
        // ensure SpeechToText service is set up
        guard let stt = stt else {
            failure("Transcribe", message: "SpeechToText not properly set up.")
            return
        }
        
        // load data from saved recording
        guard let data = NSData(contentsOfURL: recorder.url) else {
            failure("Transcribe", message: "Error retrieving saved recording data.")
            return
        }
        
        // transcribe recording
        let settings = SpeechToTextSettings(contentType: .WAV)
        stt.transcribe(data, settings: settings, failure: failureData) { results in
            self.showResults(results)
        }
    }
    
    @IBAction func startStopStreamingDefault(sender: UIButton) {
        
        // stop if already streaming
        if (isStreamingDefault) {
            stopStreamingDefault?()
            startStopStreamingDefaultButton.setTitle("Start Streaming (Default)", forState: .Normal)
            isStreamingDefault = false
            return
        }
        
        // set streaming
        isStreamingDefault = true
        
        // change button title
        startStopStreamingDefaultButton.setTitle("Stop Streaming (Default)", forState: .Normal)
        
        // ensure SpeechToText service is up
        guard let stt = stt else {
            failure("STT Streaming (Default)", message: "SpeechToText not properly set up.")
            return
        }
        
        // configure settings for streaming
        var settings = SpeechToTextSettings(contentType: .L16(rate: 44100, channels: 1))
        settings.continuous = true
        settings.interimResults = true
        
        // start streaming from microphone
        stopStreamingDefault = stt.transcribe(settings, failure: failureDefault) { results in
            self.showResults(results)
        }
    }
    
    @IBAction func startStopStreamingCustom(sender: UIButton) {
        
        // stop if already streaming
        if (isStreamingCustom) {
            captureSession?.stopRunning()
            stopStreamingCustom?()
            startStopStreamingCustomButton.setTitle("Start Streaming (Custom)", forState: .Normal)
            isStreamingCustom = false
            return
        }
        
        // set streaming
        isStreamingCustom = true
        
        // change button title
        startStopStreamingCustomButton.setTitle("Stop Streaming (Custom)", forState: .Normal)
        
        // ensure SpeechToText service is up
        guard let stt = stt else {
            failure("STT Streaming (Custom)", message: "SpeechToText not properly set up.")
            return
        }
        
        // ensure there is at least one audio input device available
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeAudio)
        guard !devices.isEmpty else {
            let domain = "swift.ViewController"
            let code = -1
            let description = "Unable to access the microphone."
            let userInfo = [NSLocalizedDescriptionKey: description]
            let error = NSError(domain: domain, code: code, userInfo: userInfo)
            failureCustom(error)
            return
        }
        
        // create capture session
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else {
            return
        }
        
        // add microphone as input to capture session
        let microphoneDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        let microphoneInput = try? AVCaptureDeviceInput(device: microphoneDevice)
        if captureSession.canAddInput(microphoneInput) {
            captureSession.addInput(microphoneInput)
        }
        
        // configure settings for streaming
        var settings = SpeechToTextSettings(contentType: .L16(rate: 44100, channels: 1))
        settings.continuous = true
        settings.interimResults = true
        
        // create a transcription output
        let outputOpt = stt.createTranscriptionOutput(settings, failure: failureCustom) {
            results in
            self.showResults(results)
        }
        
        // access tuple elements
        guard let output = outputOpt else {
            isStreamingCustom = false
            startStopStreamingCustomButton.setTitle("Start Streaming (Custom)", forState: .Normal)
            return
        }
        let transcriptionOutput = output.0
        stopStreamingCustom = output.1
        
        // add transcription output to capture session
        if captureSession.canAddOutput(transcriptionOutput) {
            captureSession.addOutput(transcriptionOutput)
        }
        
        // start streaming
        captureSession.startRunning()
    }
    
    func failure(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default) { action in }
        alert.addAction(ok)
        presentViewController(alert, animated: true) { }
    }
    
    func failureData(error: NSError) {
        let title = "Speech to Text Error:\nTranscribe"
        let message = error.localizedDescription
        failure(title, message: message)
    }
    
    func failureDefault(error: NSError) {
        let title = "Speech to Text Error:\nStreaming (Default)"
        let message = error.localizedDescription
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default) { action in
            self.stopStreamingDefault?()
            self.startStopStreamingDefaultButton.enabled = true
            self.startStopStreamingDefaultButton.setTitle("Start Streaming (Default)",
                                                          forState: .Normal)
            self.isStreamingDefault = false
        }
        alert.addAction(ok)
        presentViewController(alert, animated: true) { }
    }
    
    func failureCustom(error: NSError) {
        let title = "Speech to Text Error:\nStreaming (Custom)"
        let message = error.localizedDescription
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default) { action in
            self.startStopStreamingCustomButton.enabled = true
            self.startStopStreamingCustomButton.setTitle("Start Streaming (Custom)",
                                                         forState: .Normal)
            self.isStreamingCustom = false
        }
        alert.addAction(ok)
        presentViewController(alert, animated: true) { }
    }
    
    func showResults(results: [SpeechToTextResult]) {
        var text = ""
        
        for result in results {
            if let transcript = result.alternatives.last?.transcript where result.final == true {
                let title = titleCase(transcript)
                text += String(title.characters.dropLast()) + "." + " "
            }
        }
        
        if results.last?.final == false {
            if let transcript = results.last?.alternatives.last?.transcript {
                text += titleCase(transcript)
            }
        }
        
        self.transcriptionField.text = text
    }
    
    func titleCase(s: String) -> String {
        let first = String(s.characters.prefix(1)).uppercaseString
        return first + String(s.characters.dropFirst())
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(animated: Bool) {
        

    }
               
        
    }



