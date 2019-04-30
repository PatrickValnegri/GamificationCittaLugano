//
//  IconCell.swift
//
//  ClickFinder
//
//  Created by Ivan Pavic (ivan.pavic@student.supsi.ch) and Patrick Valnegri(patrick.valnegri@student.supsi.ch) on 30.03.19.
//  Copyright © 2019. All rights reserved.
//

import UIKit

class IconCell: UICollectionViewCell {
    
    @IBOutlet weak var imgIcon: UIImageView!
    
    var icon: Icons? {
        didSet {
            guard let icon = icon else { return }
            imgIcon.image = icon.image()
        }
    }
    
}
