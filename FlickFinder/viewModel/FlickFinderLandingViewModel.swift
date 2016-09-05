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

public protocol Editable {
    func index() -> Int
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
    var isValidSearch = Observable<Bool>(false)
    
    //colors
    let latitudeTextColor: Observable<UIColor?> = Observable(UIColor.blackColor())
    let longitudeTextColor: Observable<UIColor?> = Observable(UIColor.blackColor())
    
    var coordinates : [Coordinate] = []
    
    enum Fields : Int, Editable {
        case LatitudeText
        case LongitudeText
        case LatitudeLabelText
        case LongitudeLabelText
        case IsValidLatitude //are these booleans needed?
        case IsValidLongitude
        case LatitudTextColor
        case LongitudeTextColor
        
        func index() -> Int {
            return self.rawValue
        }
    }
    
    init() {
        coordinates = [Coordinate.Lat, Coordinate.Long]
        let propertiesArray = [latitudeText, longitudeText, latitudeLabelText, longitudeLabelText, isValidLatitude, isValidLongitude, latitudeTextColor, longitudeTextColor]
        let fieldsArray: [Editable] = [Fields.LatitudeText, Fields.LongitudeText, Fields.LatitudeLabelText, Fields.LongitudeLabelText, Fields.IsValidLatitude, Fields.IsValidLongitude, Fields.LatitudTextColor, Fields.LongitudeTextColor]
        
        /*
         what if I create an array of observables, instead of an array of enum? 
         or a observableCollection? 
         
         How to create compositions 
         Obs.map{func1()}.map{func2()}
         
         can be done?
         */
        coordinates.forEach{isValid(coordinate: $0)}
        coordinates.forEach{validateField($0)}
        
        let colorValidation = isValidLongitude.skip(2)
            .map{(isValid: Bool) -> UIColor in
                return isValid ? UIColor.blackColor() : UIColor.redColor()
        }
        
        //        colorValidation.bindTo(labelColor)
        colorValidation.bindTo(longitudeTextColor)
        
        //Dependency between fields 
        //take a look to the age field
        isValidLatitude.map{ $0 && self.isValidLongitude.value }.bindTo(isValidSearch)
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
            textColorObs = latitudeTextColor
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
    
    
    func bboxString() -> String {
        let latMin = Double(latitudeText.value!)! - 0.5
        let latMax = Double(latitudeText.value!)! + 0.5
        let longMin = Double(longitudeText.value!)! - 0.5
        let longMax = Double(longitudeText.value!)! + 0.5
        return "\(longMin), \(latMin), \(longMax), \(latMax), "
    }
    
    
}