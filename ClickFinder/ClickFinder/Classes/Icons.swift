//
//  Icons.swift
//
//  ClickFinder
//
//  Created by Ivan Pavic (ivan.pavic@student.supsi.ch) and Patrick Valnegri(patrick.valnegri@student.supsi.ch) on 30.03.19.
//  Copyright © 2019. All rights reserved.
//

import Foundation
import UIKit

/*
 This enum is used to manage the default photo of a beacon when the user add a new beacon
 without taking a picturo of it or without selecting an image from the gallery
 */
enum Icons: Int {
    case bag = 0
    case brain
    case cat
    case glasses
    case key
    case wallet
    
    func image() -> UIImage? {
        return UIImage(named: "\(self.name())")
    }
    
    func name() -> String {
        switch self {
        case .bag: return "Icon_Bag"
        case .brain: return "Icon_Brain"
        case .cat: return "Icon_Cat"
        case .glasses: return "Icon_Glasses"
        case .key: return "Icon_Key"
        case .wallet: return "Icon_Wallet"
        }
    }
    
    static func icon(forTag tag: Int) -> Icons {
        return Icons(rawValue: tag) ?? .bag
    }
    
    static let allIcons: [Icons] = {
        var all = [Icons]()
        var index: Int = 0
        while let icon = Icons(rawValue: index) {
            all += [icon]
            index += 1
        }
        return all.sorted { $0.rawValue < $1.rawValue }
    }()
}
