//
//  MenuViewController.swift
//  clickFinder
//
//  Created by Patrick on 31.03.19.
//  Copyright © 2019 Ray Wenderlich. All rights reserved.
//

import Foundation
import UIKit

class MenuViewController: UIViewController {
    
    var menuShowing = false
    
    @IBOutlet weak var LeadingContraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    
    @IBAction func openMenu(_ sender: Any) {
        if (menuShowing) {
            LeadingContraint.constant = -105
        } else {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
                self.view.layoutIfNeeded()
            })
            LeadingContraint.constant = 0
        }
        menuShowing = !menuShowing
    }
    
}
