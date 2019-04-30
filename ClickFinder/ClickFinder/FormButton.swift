//
//  BaseViewController.swift
//  clickFinder
//
//  Created by Patrick on 10.03.19.
//  Copyright © 2019 Ray Wenderlich. All rights reserved.
//

import Foundation
import UIKit

class FormButton : UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupButton()
    }

    private func setupButton() {
        setTitleColor(UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1), for: .normal)
        backgroundColor = UIColor(red: 13/255, green: 71/255, blue: 161/255, alpha: 1)
        titleLabel?.font = UIFont(name: Fonts.font, size: 20)
        layer.cornerRadius = frame.size.height/2
    }
}
