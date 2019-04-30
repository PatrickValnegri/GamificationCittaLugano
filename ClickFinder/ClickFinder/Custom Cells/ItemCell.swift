//
//  ItemCell.swift
//
//  ClickFinder
//
//  Created by Ivan Pavic (ivan.pavic@student.supsi.ch) and Patrick Valnegri(patrick.valnegri@student.supsi.ch) on 30.03.19.
//  Copyright © 2019. All rights reserved.
//

import UIKit

class ItemCell: UITableViewCell {
    
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblLocation: UILabel!
    
    var item: Item? = nil {
        didSet {
            if let item = item {
                imgIcon.image = item.photo
                lblName.text = item.name
                lblLocation.text = "Major: \(item.majorValue), Minor: \(item.minorValue)"
                
            } else {
                imgIcon.image = nil
                lblName.text = ""
                lblLocation.text = ""
            }
        }
    }
}
