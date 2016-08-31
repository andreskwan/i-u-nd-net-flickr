//
//  FlickFinderLandingViewModel.swift
//  FlickFinder
//
//  Created by Andres Kwan on 8/27/16.
//  Copyright © 2016 Udacity. All rights reserved.
//

import Foundation
import ReactiveKit

enum Coordinate {
    case Lat
    case Long
}

class FlicFinderLandingViewModel {
    let latitudeText: Observable<String?> = Observable("")
    let longitudeText: Observable<String?> = Observable("")
    let isValidLatitude = Observable<Bool>(false)
    let isValidLongitude = Observable<Bool>(false)
    let latitudTextColor: Observable<UIColor?> = Observable(UIColor.blackColor())
    let longitudeTextColor: Observable<UIColor?> = Observable(UIColor.blackColor())
    
    
    var coordinates : [Coordinate] = []
    
    init() {
        coordinates = [Coordinate.Lat, Coordinate.Long]
        coordinates.forEach{isValid(coordinate: $0)}
//        coordinates.forEach(<#T##body: (Coordinate) throws -> Void##(Coordinate) throws -> Void#>)
        let colorValidation = isValidLongitude.skip(2)
            .map{(isValid: Bool) -> UIColor in
                return isValid ? UIColor.blackColor() : UIColor.redColor()
        }
        
//        colorValidation.bindTo(labelColor)
        colorValidation.bindTo(longitudeTextColor)
    }
    
    func isValid(coordinate coordinate: Coordinate) {
        let coordinateObs: Observable<String?>
        let validator: Observable<Bool>
        let interval: (min: Double, max: Double)
        
        switch coordinate {
        case .Lat:
            coordinateObs = latitudeText
            validator = isValidLatitude
            interval = Constants.Flickr.SearchLatRange
        case .Long:
            coordinateObs = longitudeText
            validator = isValidLongitude
            interval = Constants.Flickr.SearchLonRange
        }

        coordinateObs.map{ coordinate in
            guard let coordinate = coordinate where coordinate.characters.count > 0 else {
                return false
            }
            print(coordinate)
            let isLowValid = interval.min <= Double(coordinate)!
            let isHighValid = interval.max >= Double(coordinate)!
            return isLowValid && isHighValid
        }.bindTo(validator)
    }
}