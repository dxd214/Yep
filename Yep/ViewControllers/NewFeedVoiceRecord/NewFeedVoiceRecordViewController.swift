//
//  NewFeedVoiceRecordViewController.swift
//  Yep
//
//  Created by nixzhu on 15/11/25.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation

class NewFeedVoiceRecordViewController: UIViewController {

    @IBOutlet weak var voiceRecordSampleView: VoiceRecordSampleView!

    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var voiceRecordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!

    enum State {
        case Default
        case Recording
        case FinishRecord
    }
    var state: State = .Default {
        willSet {
            switch newValue {

            case .Default:

                voiceRecordButton.hidden = false
                let image =  UIImage(named: "button_voice_record")
                voiceRecordButton.setImage(image, forState: .Normal)

                playButton.hidden = true
                resetButton.hidden = true

            case .Recording:

                voiceRecordButton.hidden = false
                let image =  UIImage(named: "button_voice_record_stop")
                voiceRecordButton.setImage(image, forState: .Normal)

                playButton.hidden = true
                resetButton.hidden = true

            case .FinishRecord:

                voiceRecordButton.hidden = true
                playButton.hidden = false
                resetButton.hidden = false
            }
        }
    }

    var voiceFileURL: NSURL?

    var displayLink: CADisplayLink!

    var sampleValues: [CGFloat] = [] {
        didSet {
            let count = sampleValues.count
            let frequency = 10
            let minutes = count / frequency / 60
            let seconds = count / frequency - minutes * 60
            let subSeconds = count - seconds * frequency - minutes * 60 * frequency

            timeLabel.text = String(format: "%02d:%02d.%d", minutes, seconds, subSeconds)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("New Voice", comment: "")

        displayLink = CADisplayLink(target: self, selector: "checkVoiceRecordValue")
        displayLink.frameInterval = 6 // 频率为每秒 10 次
        displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)

        state = .Default
    }

    // MARK: - Actions

    @IBAction func cancel(sender: UIBarButtonItem) {

        dismissViewControllerAnimated(true, completion: { [weak self] in

            YepAudioService.sharedManager.endRecord()

            if let voiceFileURL = self?.voiceFileURL {
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(voiceFileURL)
                } catch let error {
                    println("delete voiceFileURL error: \(error)")
                }
            }
        })
    }

    func checkVoiceRecordValue() {

        if let audioRecorder = YepAudioService.sharedManager.audioRecorder {

            if audioRecorder.recording {
                audioRecorder.updateMeters()
                let normalizedValue = pow(10, audioRecorder.averagePowerForChannel(0)/40)
                let value = CGFloat(normalizedValue)

                sampleValues.append(value)
                voiceRecordSampleView.appendSampleValue(value)
            }
        }
    }

    @IBAction func voiceRecord(sender: UIButton) {

        if state == .Recording {
            YepAudioService.sharedManager.endRecord()

        } else {
            let audioFileName = NSUUID().UUIDString
            if let fileURL = NSFileManager.yepMessageAudioURLWithName(audioFileName) {

                voiceFileURL = fileURL

                YepAudioService.sharedManager.beginRecordWithFileURL(fileURL, audioRecorderDelegate: self)
                
                state = .Recording
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

// MARK: AVAudioRecorderDelegate

extension NewFeedVoiceRecordViewController: AVAudioRecorderDelegate {

    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {

        state = .FinishRecord

        println("finished recording \(flag)")
    }

    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder, error: NSError?) {

        state = .Default

        println("\(error?.localizedDescription)")
    }
}
