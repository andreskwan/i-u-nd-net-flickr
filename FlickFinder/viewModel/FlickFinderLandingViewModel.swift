//
//  FlickFinderLandingViewModel.swift
//  FlickFinder
//
//  Created by Andres Kwan on 8/27/16.
//  Copyright © 2016 Udacity. All rights reserved.
//

import Foundation
import ReactiveKit

class FlicFinderLandingViewModel {
    let latitudeText: Observable<String?> = Observable("")
    let isValidLatitude = Observable<Bool>(false)
    
    init() {
        latitudeText
            .map{ (latNumber) -> Bool in
                guard let latNumber = latNumber where latNumber.characters.count > 0 else {
                    return false
                }
                let isLowValid = Constants.Flickr.SearchLatRange.minLat <= Double(latNumber)
                let isHighValid = Constants.Flickr.SearchLatRange.maxLat >= Double(latNumber)
                return isLowValid && isHighValid
            }.bindTo(isValidLatitude)
    }
    
}