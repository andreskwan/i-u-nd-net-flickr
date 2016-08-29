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
    let isValidLongitude = Observable<Bool>(false)
    
    init() {
        
        /*
         How to avoid repeting code?
         what if I need to reuse a map
         */
        latitudeText.skip(2).observe{ (latitude) in
            Observable(self.isValidCoordinate(latitude, interval: Constants.Flickr.SearchLatRange)).bindTo(self.isValidLatitude)
        }
        
        longitudeText.skip(2).observe{ (longitude) in
            Observable(self.isValidCoordinate(longitude, interval: Constants.Flickr.SearchLonRange)).bindTo(self.isValidLongitude)
        }
    }
    
    func isValidCoordinate(coordinate: String?, interval: (min: Double, max: Double)) -> Bool {
        guard let coordinate = coordinate where coordinate.characters.count > 0 else {
            return false
        }
        print(coordinate)
        let isLowValid = interval.min <= Double(coordinate)
        let isHighValid = interval.max >= Double(coordinate)
        return isLowValid && isHighValid
    }
    
    
}