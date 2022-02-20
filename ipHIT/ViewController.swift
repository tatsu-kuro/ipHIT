//
//  ViewController.swift
//  ipHIT
//
//  Created by 黒田建彰 on 2022/02/15.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func unwind(_ segue: UIStoryboardSegue) {
        print ("unwind")
        UIApplication.shared.isIdleTimerDisabled = false//スリープする
    }
}

