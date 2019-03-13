//
//  AuthTextField.swift
//  clickFinder
//
//  Created by Patrick on 10.03.19.
//  Copyright © 2019 Ray Wenderlich. All rights reserved.
//

import Foundation
import UIKit

class AuthTextField: UITextField {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupField()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupField()
    }
    
    
    private func setupField() {
        borderStyle = .none
        layer.cornerRadius = frame.size.height/2
        tintColor = Colors.background
        textColor = Colors.background
        font = UIFont(name: Fonts.font, size: 16)
        backgroundColor = UIColor.white.withAlphaComponent(0.7)
        autocorrectionType = .no
        clipsToBounds = true
        
        _ = self.placeholder != nil ? self.placeholder! : ""
        let placerHolderFont = UIFont(name: Fonts.font, size: 16)
        attributedPlaceholder = NSAttributedString(string: placeholder!,
                                attributes: [NSAttributedString.Key.foregroundColor: Colors.background,
                                             NSAttributedString.Key.font: placerHolderFont])
        
        let indentView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        leftView = indentView
        leftViewMode = .always
        
        
        
    }
    
}

