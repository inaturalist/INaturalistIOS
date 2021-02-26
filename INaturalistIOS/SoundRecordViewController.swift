//
//  SoundRecordViewController.swift
//  iNaturalist
//
//  Created by Alex Shepard on 2/3/21.
//  Copyright © 2021 iNaturalist. All rights reserved.
//

import UIKit
import AVFoundation
import FontAwesomeKit

@objc protocol SoundRecorderDelegate {
    func recordedSound(recorder: SoundRecordViewController, uuidString: String)
    func cancelled(recorder: SoundRecordViewController)
}


class SoundRecordViewController: UIViewController {
    var timerLabel: UILabel!
    var recordButton: UIButton!
    var doneButton: UIButton!
    var meter: RecorderLevelView!
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder?
    var timer: Timer?
    var soundUUIDString: String!
    
    var micAttrString: NSAttributedString?
    var pauseAttrString: NSAttributedString?
    
    @objc weak var recorderDelegate: SoundRecorderDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // this will be the UUID for the saved observation sound
        // which is a key for the MediaStore and also for uploading
        // to the API
        self.soundUUIDString = UUID().uuidString.lowercased()
        
        self.view.backgroundColor = .white
        
        timerLabel = UILabel()
        timerLabel.accessibilityTraits = [.updatesFrequently]
        timerLabel.text = ""
        
        
        if let micIcon = FAKIonIcons.micAIcon(withSize: 50) {
            micIcon.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.inatTint())
            micAttrString = micIcon.attributedString()
        }
        
        if let pauseIcon = FAKIonIcons.pauseIcon(withSize: 50) {
            pauseIcon.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.inatTint())
            pauseAttrString = pauseIcon.attributedString()
        }
        
        
        meter = RecorderLevelView()
        meter.accessibilityTraits = [.updatesFrequently]
        
        recordButton = UIButton(type: .system)
        recordButton.setAttributedTitle(micAttrString, for: .normal)
        recordButton.accessibilityLabel = NSLocalizedString("Record", comment: "Accessibility Label for Record/Pause Button")
        recordButton.addTarget(self, action: #selector(recordPressed), for: .touchUpInside)
        recordButton.isEnabled = false
        
        doneButton = UIButton(type: .system)
        doneButton.setTitle(NSLocalizedString("Done", comment: "Done button for recording observation sounds"), for: .normal)
        doneButton.addTarget(self, action: #selector(donePressed), for: .touchUpInside)
        doneButton.tintColor = UIColor.inatTint()
        doneButton.isEnabled = false
        
        let bottomStack = UIStackView(arrangedSubviews: [recordButton, doneButton])
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        bottomStack.distribution = .fillEqually
        bottomStack.axis = .horizontal
        bottomStack.spacing = 40
        bottomStack.alignment = .center

        let stack = UIStackView(arrangedSubviews: [timerLabel, meter, bottomStack])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.distribution = .fillEqually
        stack.axis = .vertical
        stack.spacing = 0
        stack.alignment = .center
                
        self.view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: self.view.topAnchor),
            stack.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            meter.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            meter.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
        ])
        
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord)
            try recordingSession.setMode(.default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.prepareRecording()
                    } else {
                        let title = NSLocalizedString("No Microphone Permissions", comment: "title of alert when user tries to record a sound observation without granting mic permissions")
                        let message = NSLocalizedString("If you wish to record a sound observation, you will need to give the iNaturalist app permission to use the microphone.", comment: "message of alert when mic permission is missing")
                        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                        
                        let cancel = NSLocalizedString("Cancel", comment: "")
                        alert.addAction(UIAlertAction(title: cancel, style: .cancel, handler: { _ in
                            
                            self.recorderDelegate?.cancelled(recorder: self)
                        
                        }))
                        
                        let openSettings = NSLocalizedString("Open Settings", comment: "button to open settings when user needs to adjust mic permissions")
                        alert.addAction(UIAlertAction(title: openSettings, style: .default, handler: { _ in
                            
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.openURL(url)
                            }
                            
                        }))
                        
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        } catch (let error) {
            let title = NSLocalizedString("Failed to Setup Sound Recording", comment: "title of alert when sound recording setup fails")
            let message = error.localizedDescription
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            let cancel = NSLocalizedString("OK", comment: "")
            alert.addAction(UIAlertAction(title: cancel, style: .default, handler: { _ in
                
                self.recorderDelegate?.cancelled(recorder: self)
            
            }))
        }
        
        
    }
    
    
    @objc func recordPressed() {
        if let recorder = self.audioRecorder, recorder.isRecording {
            recordButton.setAttributedTitle(micAttrString, for: .normal)
            recordButton.accessibilityLabel = NSLocalizedString("Record", comment: "Accessibility Label for Record Button (when recording audio)")

            pauseRecording()
        } else {
            recordButton.setAttributedTitle(pauseAttrString, for: .normal)
            recordButton.accessibilityLabel = NSLocalizedString("Pause", comment: "Accessibility Label for Pause Button (when recording audio)")

            startRecording()
        }
    }
    
    
    
    @objc func donePressed() {
        finishRecording(success: true, error: nil)
        self.recorderDelegate?.recordedSound(recorder: self, uuidString: self.soundUUIDString)
    }
    

    func startRecording() {
        if let recorder = self.audioRecorder {
            recorder.record()
        }
    }
    
    func prepareRecording() {
        
        let mm = MediaStore()
        let soundUrl = mm.mediaUrlForKey(self.soundUUIDString)
        print("sound path is \(soundUrl)")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            let recorder = try AVAudioRecorder(url: soundUrl, settings: settings)
            recorder.delegate = self
            recorder.isMeteringEnabled = true
            recorder.prepareToRecord()
            
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(timerCallback), userInfo: nil, repeats: true)
            
            self.audioRecorder = recorder
            
            self.recordButton.isEnabled = true
        } catch (let error) {
            finishRecording(success: false, error: error)
        }
    }

    func pauseRecording() {
        self.audioRecorder?.pause()
    }
    
    func finishRecording(success: Bool, error: Error?) {
        if !success {
            
            let title = NSLocalizedString("Failed to Record", comment: "title of alert when sound recording fails")
            let message = error?.localizedDescription ?? ""
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            let cancel = NSLocalizedString("OK", comment: "")
            alert.addAction(UIAlertAction(title: cancel, style: .default, handler: { _ in
                
                self.recorderDelegate?.cancelled(recorder: self)
            
            }))

            print("RECORDING FAILED")
            return
        }
        
        self.timer?.invalidate()
        
        self.audioRecorder?.stop()
        self.audioRecorder = nil
    }

    @objc func timerCallback() {
        if let recorder = self.audioRecorder {
            recorder.updateMeters()
            
            recorder.peakPower(forChannel: 0)
                        
            let lowPassResults = pow(10, (0.05 * recorder.peakPower(forChannel: 0)))
            let timerBaseText = NSLocalizedString("%.1f sec", comment: "elapsed time on recording screen, in seconds")
            let timerText = String(format: timerBaseText, recorder.currentTime)
            
            
            DispatchQueue.main.async {
                self.meter.level = lowPassResults
                self.timerLabel.text = timerText
                if recorder.currentTime > 1.0 {
                    self.doneButton.isEnabled = true
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.audioRecorder?.stop()
        self.timer?.invalidate()
    }
    
}


extension SoundRecordViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false, error: nil)
            self.recorderDelegate?.recordedSound(recorder: self, uuidString: self.soundUUIDString)
        }
    }
    
}


class RecorderLevelView: UIView {
    
    public var level: Float = 0.0 {
        didSet {
            // clamped to { 0.0, 1.0 }
            if level < 0.0 { level = 0.0 }
            if level > 1.0 { level = 1.0 }
            
            let baseString = NSLocalizedString("Recording Level %f", comment: "Accessibility label for sound recorder")
            self.accessibilityLabel = String(format: baseString, level)
            
            let scaledLevel = level * 30
            // anything less than 0.01 is basically nothing
            if (scaledLevel < 0.01) { return }
            for i in 0..<30 {
                DispatchQueue.main.async {
                    if i <= Int(scaledLevel) {
                        self.levelViews[i].backgroundColor = .green
                    } else {
                        self.levelViews[i].backgroundColor = .black
                    }
                }
            }
        }
    }
    
    var levelViews = [UIView]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        for _ in 0..<30 {
            let levelView = UIView(frame: .zero)
            levelView.backgroundColor = .black
            levelViews.append(levelView)
        }
        
        let stack = UIStackView(arrangedSubviews: levelViews)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.distribution = .fillEqually
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center
        
        self.addSubview(stack)
        
        for levelView in levelViews {
            NSLayoutConstraint.activate([
                levelView.widthAnchor.constraint(equalToConstant: 20),
                levelView.heightAnchor.constraint(equalToConstant: 40),
                levelView.centerYAnchor.constraint(equalTo: stack.centerYAnchor),
            ])
        }
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: self.topAnchor),
            stack.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("Interface Builder is not supported!")
    }
    

    
}
