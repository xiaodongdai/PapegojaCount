//
//  ViewController.swift
//  HelloWorld
//
//  Created by XIAODONG Dai on 2017-11-09.
//  Copyright © 2017 XIAODONG Dai. All rights reserved.
//

import UIKit
import AVFoundation
class ViewController: UIViewController {
    enum Status {
        case INIT
        case RUNNING
        case REPEATING
        case STOPPED
    }

    @IBOutlet weak var textShortestHistroy: UITextField!
    @IBOutlet weak var textTimeLastRubric: UITextField!
    @IBOutlet weak var textShortestTime: UITextField!
    @IBOutlet weak var textInput: UITextField!
    var audioPlayer : AVQueuePlayer!
    var arrayOfAccents: [String] = ["eng_gbr_queenelizabeth", "eng_ind_deepa", "eng_aus_lisa", "eng_gbr_peter", "eng_usa_willhappy"]
    //var arrayOfAccents: [String] = ["eng_usa_willhappy"]
    //var arrayOfSigns: [String] = ["plus", "minus", "multiplied_by", "divided_by"]
    var arrayOfSigns: [String] = ["plus", "minus"]
    var result: UInt32 = 0
    var num1: UInt32 = 0
    var num2: UInt32 = 0
    var sign: UInt32 = 0
    var accentIdx: UInt32 = 0
    var startTime: NSDate = NSDate()
    var arrayOfTimes: [Double] = []
    var status: Status = Status.INIT
    var shortestTime10 : Double = Double.greatestFiniteMagnitude
    var shortestHistoric: Double = Double.greatestFiniteMagnitude

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        shortestHistoric = UserDefaults.standard.double(forKey: "shortestTime10")
        print("shortestHistoric = \(shortestHistoric)")
        
        if(shortestHistoric != Double.greatestFiniteMagnitude) {
         textShortestHistroy.text = String(format: "%.2f", shortestHistoric)
        }
        
        // Do any additional setup after loading the view.
    }

    
    @IBAction func textFieldEditingDidChange(_ sender: UITextField) {
        let answer = Int(sender.text!)
        print("Answer is:\(String(describing: answer)), Result is:\(result)")
        if(UInt32(sender.text!) == result) {
            print("correct!")
            let endTime = NSDate()
            let timeInterval: Double = endTime.timeIntervalSince(startTime as Date)
            let resultInString = String(format: "Correct! Time used:%.2f", timeInterval)
            showToast(message: resultInString)
            startNewRubrik()
            sender.text = ""
            textTimeLastRubric.text = String(format: "%.2f", timeInterval)
            arrayOfTimes.append(timeInterval)
            // check shortest time for 10 in a row
            while(arrayOfTimes.count > 3) {
                // remove the first one
                arrayOfTimes.remove(at: 0)
            }
            
            let sum = arrayOfTimes.reduce(0, +)
            if(sum < shortestTime10 && arrayOfTimes.count == 3) {
                shortestTime10 = sum
                textShortestTime.text = String(format: "%.2f", sum)
                if(shortestTime10 < shortestHistoric) {
                    UserDefaults.standard.set(shortestTime10, forKey: "shortestTime10")
                    textShortestHistroy.text = textShortestTime.text
                }
                
            }
        } else if(String(sender.text!).count == String(result).count) {
            print("incorrect, repeating")
            status = Status.REPEATING
            sender.text = ""
            playRubrik(num1, sign, num2, accentIdx)
        }
    }
    
    func goodRubrik(_ num1: UInt32, _ num2: UInt32, _ sign: UInt32) -> Bool{
        switch sign {
        case 0: // +
            if(num1 + num2 > 100) {
                return false
            } else if(num1 < 10) {
                return false
            } else if(num2 < 10) {
                return false
            }
            result = num1 + num2
        case 1:
            if(num1 <= num2) {
                return false
            } else if(num1 < 10) {
                return false
            } else if(num2 < 10) {
                return false
            }
            result = num1 - num2
        case 2:
            if(num1 * num2 > 100) {
                return false
            } else if(num1 == 1) {
                return false
            } else if(num2 == 1) {
                return false
            }
            result = num1 * num2
        case 3:
            if(num1 % num2 != 0) {
                return false
            } else if(num2 == 1) {
                return false
            } else if(num1 == num2) {
                return false
            }
            result = num1 / num2
        default:
            print("wrong sign")
        }
        return true
    }
    
    func playRubrik(_ num1: UInt32,_ sign: UInt32, _ num2: UInt32, _ accentIdx: UInt32) {
        let arrayOfUrls = getUrlArray(num1: num1, sign: sign, num2: num2, accentId: accentIdx)
        let arrayOfPlayItems = arrayOfUrls.map {AVPlayerItem(asset: AVAsset(url: $0))}
        
        audioPlayer =  AVQueuePlayer(items: arrayOfPlayItems)
        audioPlayer.addObserver(
            self, forKeyPath:"currentItem", options:.initial, context:nil)
        audioPlayer.play()
    }
    
    func startNewRubrik() {
        num1 = arc4random_uniform(98) + 1
        num2 = arc4random_uniform(98) + 1
        sign = arc4random_uniform(UInt32(arrayOfSigns.count))
        
        while(!goodRubrik(num1, num2, sign)) {
            num1 = arc4random_uniform(98) + 1
            num2 = arc4random_uniform(98) + 1
        }
        accentIdx = arc4random_uniform(UInt32(arrayOfAccents.count) )
        playRubrik(num1, sign, num2, accentIdx)
    }
    
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        if(status != Status.RUNNING && status != Status.REPEATING) {
            status = Status.RUNNING
            sender.setTitle("Stop Game", for: .normal)
            startNewRubrik()
        } else {
            status = Status.STOPPED
            arrayOfTimes.removeAll()
            textShortestTime.text = ""
            textTimeLastRubric.text = ""
            sender.setTitle("Start Game", for: .normal)
        }
    }
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 150, y: self.view.frame.size.height-100, width: 300, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    func getUrlArray(num1: UInt32, sign: UInt32, num2: UInt32, accentId:UInt32 ) -> [URL] {
        let prefix = arrayOfAccents[Int(accentId)]
        var arrayOfUrls: [URL] = []
        arrayOfUrls.append(Bundle.main.url(forResource:prefix + "_" + String(num1), withExtension:"mp3",  subdirectory:"Audios/" + prefix)! )
        arrayOfUrls.append(Bundle.main.url(forResource:prefix + "_" + arrayOfSigns[Int(sign)], withExtension:"mp3",  subdirectory:"Audios/" + prefix)! )
        arrayOfUrls.append(Bundle.main.url(forResource:prefix + "_" + String(num2), withExtension:"mp3",  subdirectory:"Audios/" + prefix)! )
        return arrayOfUrls
    }
    
    // catch changes to status
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?)  {
        
        if(keyPath == "currentItem") {
            print("observeValue: \(String(describing: keyPath)) and player: \(String(describing: audioPlayer.currentItem))")
            if(audioPlayer.currentItem == nil) {
                print("finished!")
                if(status != Status.REPEATING) {
                    startTime = NSDate()
                }

                textInput.becomeFirstResponder()
            }
        }
        if (keyPath == "rate") {
            print("rate")
        }
        if (keyPath == "status") {
            print("status")
        }
    }
}

