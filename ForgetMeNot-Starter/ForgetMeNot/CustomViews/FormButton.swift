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
        setTitleColor(Colors.background, for: .normal)
        backgroundColor = .black
        titleLabel?.font = UIFont(name: Fonts.font, size: 20)
        layer.cornerRadius = frame.size.height/2
    }
}
