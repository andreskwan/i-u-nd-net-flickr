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
    
    
    init() {
        latitudeText.observe{ text in
            print(text)
        }
    }
    
}