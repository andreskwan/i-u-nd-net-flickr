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
    let longitudeText: Observable<String?> = Observable("")
    let isValidLatitude = Observable<Bool>(false)
    let isValid = Observable<Bool>(false)
    
    init() {
        
        /*
         How to avoid repeting code?
         what if I need to reuse a map
         */
        latitudeText
            .map{ (latNumber) -> Bool in
                guard let latNumber = latNumber where latNumber.characters.count > 0 else {
                    return false
                }
                let isLowValid = Constants.Flickr.SearchLatRange.min <= Double(latNumber)
                let isHighValid = Constants.Flickr.SearchLatRange.max >= Double(latNumber)
                return isLowValid && isHighValid
            }.bindTo(isValidLatitude)
        
        longitudeText.observe{ (longitude) in
            self.isValid = Observable(self.isValidCoordinate(longitude, interval: Constants.Flickr.SearchLonRange))
        }//.disposeIn(DisposeBag)
    }
    
    func isValidCoordinate(latNumber: String?, interval: (min: Double, max: Double)) -> Bool {
        guard let latNumber = latNumber where latNumber.characters.count > 0 else {
            return false
        }
        let isLowValid = interval.min <= Double(latNumber)
        let isHighValid = interval.max >= Double(latNumber)
        return isLowValid && isHighValid
    }
    
    
}