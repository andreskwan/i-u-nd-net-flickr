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
    //textFields
    let latitudeText: Observable<String?> = Observable("")
    let longitudeText: Observable<String?> = Observable("")
    
    //labels
    let latitudeLabelText: Observable<String?> = Observable("Latitude")
    let longitudeLabelText: Observable<String?> = Observable("Longitude")
    
    //boolean for validation
    let isValidLatitude = Observable<Bool>(false)
    let isValidLongitude = Observable<Bool>(false)
    
    //colors
    let latitudTextColor: Observable<UIColor?> = Observable(UIColor.blackColor())
    let longitudeTextColor: Observable<UIColor?> = Observable(UIColor.blackColor())
    
    var coordinates : [Coordinate] = []
    
    
    init() {
        coordinates = [Coordinate.Lat, Coordinate.Long]
        
        /*
         what if I create an array of observables, instead of an array of enum?
         or a observableCollection?
         
         How to create compositions
         Obs.map{func1()}.map{func2()}
         
         can be done?
         */
//        coordinates.forEach{isValid(coordinate: $0)}
//        coordinates.forEach{validateField($0)}
        
        longitudeText.skip(2).map{self.isValid(coordinate: $0, interval: Constants.Flickr.SearchLonRange)}
            .bindTo(isValidLongitude)
        latitudeText.skip(2).map{self.isValid(coordinate: $0, interval: Constants.Flickr.SearchLatRange)}
            .bindTo(isValidLatitude)
        
        isValidLongitude.skip(2)
            .map{(isValid: Bool) -> UIColor in
                return isValid ? UIColor.blackColor() : UIColor.redColor()
        }.bindTo(longitudeTextColor)
        
        //        colorValidation.bindTo(labelColor)
        
        isValidLatitude.skip(2)
            .map{(isValid: Bool) -> UIColor in
                return isValid ? UIColor.blackColor() : UIColor.redColor()
        }.bindTo(latitudTextColor)
        
        let validLabelText = "Latitude"
        let invalidLabelText = "-90 <= lat <= 90"
        
        isValidLatitude.skip(2)
            .map{(isValid: Bool) -> String in
                return isValid ? validLabelText : invalidLabelText
            }.bindTo(latitudeLabelText)
    }
    
//    func validateField(validator: Bool) -> UIColor {
//        return validator ? UIColor.blackColor() : UIColor.redColor()
//        
//        //            .bindTo(textColorObs)
//        
//        //        validator.skip(2)
//        //            .map{(isValid: Bool) -> String in
//        //                return isValid ? validLabelText : invalidLabelText
//        //            }
//        //            .bindTo(textObs)
//    }
    
    /*
     FRP version
     */
    func isValid(coordinate text: String?, interval: (min:Double, max:Double)) -> Bool {
        
        guard let coordinateText = text where (coordinateText.characters.count > 0) && (coordinateText != "-") else {
            return false
        }
        guard let coordinate = Double(coordinateText) else {
            return false
        }
        print(coordinate)
        let isLowValid = interval.min <= coordinate
        let isHighValid = interval.max >= coordinate
        
        return isLowValid && isHighValid
    }
    
    /*
     should return boolean
     true for coordinate inside the valid interval
     false for outside
     
     not should produce side effects like bindTo
     this is not a FRP
     
     goal is to remove the binding
     
     use a map to associate this bolean
     
     func name
     - isCoordinateInsideValidInterval
     - injection - params should be
     - string for coordinate
     - corresponding interval
     */
    func isValid(coordinate coordinate: Coordinate) -> Observable<Bool> {
        let coordinateObs: Observable<String?>
        var validator: Observable<Bool>
        let interval: (min: Double, max: Double)
        let isValidCoordinate: Observable<Bool>
        
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
        
        coordinateObs.map{ coordinate -> Observable<Bool> in
            guard let coordinate = coordinate where coordinate.characters.count > 0 else {
                return Observable<Bool>(false)
            }
            print(coordinate)
            let isLowValid = interval.min <= Double(coordinate)!
            let isHighValid = interval.max >= Double(coordinate)!
            
            validator = Observable<Bool>(isLowValid && isHighValid)
            return validator
        }//.bindTo(validator)
        
        return validator
    }
    
    /*
     params
     - coordinateObs
     - corresponding validator
     
     validator helps to set
     - text of the labels
     - color of the text of the labels
     
     so should be two functions
     one that returns string
     one that returns UIColor
     
     */
    func validateField(coordinate: Coordinate){
        let textObs: Observable<String?>
        let textColorObs: Observable<UIColor?>
        let validator: Observable<Bool>
        let invalidLabelText: String
        let validLabelText: String
        
        switch coordinate {
        case .Lat:
            textObs = latitudeLabelText
            textColorObs = latitudTextColor
            validator = isValidLatitude
            validLabelText = "Latitude"
            invalidLabelText = "-90 <= lat <= 90"
        case .Long:
            textObs = longitudeLabelText
            textColorObs = longitudeTextColor
            validator = isValidLongitude
            validLabelText = "Longitud"
            invalidLabelText = "-180 <= long <= 180"
        }
        
        validator.skip(2)
            .map{(isValid: Bool) -> UIColor in
                return isValid ? UIColor.blackColor() : UIColor.redColor()
            }
            .bindTo(textColorObs)

        validator.skip(2)
            .map{(isValid: Bool) -> String in
                return isValid ? validLabelText : invalidLabelText
            }
            .bindTo(textObs)
    }
    
    
}