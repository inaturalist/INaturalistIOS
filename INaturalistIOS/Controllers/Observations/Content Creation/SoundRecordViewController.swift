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

    var micImage: UIImage?
    var pauseImage: UIImage?

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
        timerLabel.font = UIFont.boldSystemFont(ofSize: 19)
        timerLabel.textColor = UIColor.inatTint()

        if let mic = FAKIonIcons.micAIcon(withSize: 50),
           let pause = FAKIonIcons.pauseIcon(withSize: 50),
           let circle = FAKIonIcons.recordIcon(withSize: 75) {
            mic.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.white)
            pause.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.white)
            circle.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.inatTint())

            self.micImage = UIImage(stackedIcons: [circle, mic], imageSize: CGSize(width: 75, height: 75))?
                .withRenderingMode(.alwaysOriginal)
            self.pauseImage = UIImage(stackedIcons: [circle, pause], imageSize: CGSize(width: 75, height: 75))?
                .withRenderingMode(.alwaysOriginal)
        }

        meter = RecorderLevelView()
        meter.accessibilityTraits = [.updatesFrequently]

        recordButton = UIButton(type: .system)
        recordButton.setImage(self.micImage, for: .normal)
        recordButton.accessibilityLabel = NSLocalizedString(
            "Record",
            comment: "Accessibility Label for Record/Pause Button"
        )
        recordButton.addTarget(self, action: #selector(recordPressed), for: .touchUpInside)
        recordButton.isEnabled = false
        recordButton.tintColor = UIColor.inatTint()

        doneButton = UIButton(type: .system)
        let saveTitle = NSLocalizedString("Save Recording", comment: "Done button for recording observation sounds")
        doneButton.setTitle(saveTitle, for: .normal)
        doneButton.addTarget(self, action: #selector(donePressed), for: .touchUpInside)
        doneButton.tintColor = UIColor.inatTint()
        doneButton.isEnabled = false

        let bottomStack = UIStackView(arrangedSubviews: [recordButton, doneButton])
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        bottomStack.distribution = .fillEqually
        bottomStack.axis = .vertical
        bottomStack.spacing = 20
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
            meter.trailingAnchor.constraint(equalTo: stack.trailingAnchor)
        ])

        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelPressed))
        self.navigationItem.leftBarButtonItem = cancel

        self.title = NSLocalizedString("Recording Sound", comment: "Title for sound recording screen")

        recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession.setCategory(.playAndRecord)
            try recordingSession.setMode(.default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.prepareRecording()
                    } else {
                        let title = NSLocalizedString(
                            "No Microphone Permissions",
                            // swiftlint:disable:next line_length
                            comment: "title of alert when user tries to record a sound observation without granting mic permissions"
                        )
                        let message = NSLocalizedString(
                            // swiftlint:disable:next line_length
                            "If you wish to record a sound observation, you will need to give the iNaturalist app permission to use the microphone.",
                            comment: "message of alert when mic permission is missing"
                        )
                        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

                        let cancel = NSLocalizedString("Cancel", comment: "")
                        alert.addAction(UIAlertAction(title: cancel, style: .cancel, handler: { _ in

                            self.recorderDelegate?.cancelled(recorder: self)

                        }))

                        let openSettings = NSLocalizedString(
                            "Open Settings",
                            comment: "button to open settings when user needs to adjust mic permissions"
                        )
                        alert.addAction(UIAlertAction(title: openSettings, style: .default, handler: { _ in

                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }

                        }))

                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        } catch let error {
            let title = NSLocalizedString(
                "Failed to Setup Sound Recording",
                comment: "title of alert when sound recording setup fails"
            )
            let message = error.localizedDescription
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

            let cancel = NSLocalizedString("OK", comment: "")
            alert.addAction(UIAlertAction(title: cancel, style: .default, handler: { _ in

                self.recorderDelegate?.cancelled(recorder: self)

            }))
        }

        // notifications about interruptions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )

    }

    @objc func audioInterruption(note: Notification) {
        guard let userInfo = note.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            if #available(iOS 10.3, *) {
                if let suspended = userInfo[AVAudioSessionInterruptionWasSuspendedKey] as? NSNumber {
                    if suspended.boolValue {
                        // app was previously suspended, not actively interruped
                        // ignore this notification, don't update the UI
                        return
                    }
                }
            }

            // interruption began
            self.timer?.invalidate()
            timerLabel.text = NSLocalizedString("Paused", comment: "")
        case .ended:
            // interruption ended
            timerLabel.text = NSLocalizedString("Resuming", comment: "")
            timer = Timer.scheduledTimer(
                timeInterval: 0.1,
                target: self,
                selector: #selector(timerCallback),
                userInfo: nil,
                repeats: true
            )
        default: ()
        }
    }

    @objc func recordPressed() {
        if let recorder = self.audioRecorder, recorder.isRecording {
            recordButton.setImage(self.micImage, for: .normal)
            recordButton.accessibilityLabel = NSLocalizedString(
                "Record",
                comment: "Accessibility Label for Record Button (when recording audio)"
            )

            pauseRecording()
        } else {
            recordButton.setImage(self.pauseImage, for: .normal)
            recordButton.accessibilityLabel = NSLocalizedString(
                "Pause",
                comment: "Accessibility Label for Pause Button (when recording audio)"
            )

            startRecording()
        }
    }

    @objc func cancelPressed() {
        self.recorderDelegate?.cancelled(recorder: self)
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
        let mediaStore = MediaStore()
        let soundUrl = mediaStore.mediaUrlForKey(self.soundUUIDString)

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

            timer = Timer.scheduledTimer(
                timeInterval: 0.1,
                target: self,
                selector: #selector(timerCallback),
                userInfo: nil,
                repeats: true
            )

            self.audioRecorder = recorder

            self.recordButton.isEnabled = true
        } catch let error {
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
        finishRecording(success: flag, error: nil)
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        finishRecording(success: false, error: error)
    }

}

