//
//  StationModel.swift
//  UbikeTracer
//
//  Created by rosa on 2017/7/21.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import CoreLocation
import Foundation


struct StationModel {

    let coordinate: CLLocationCoordinate2D

}

extension StationModel {
    
    enum ParseDataError: Error { case Missingid, MissingName, MissingCoor, MissingData, MissingTime }
    
    init(dict: [String:Any] ) throws {
        
        guard let lat = dict["lat"] as? Double,
            let lng = dict["lng"] as? Double
        else { throw ParseDataError.MissingCoor }
        self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)

    }
}
