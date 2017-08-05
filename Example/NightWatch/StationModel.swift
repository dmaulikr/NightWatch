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
    
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let numberOfSpaces: Int
    let numberOfBikes: Int
    let updateTime: Date
    var distance: Double = 0.0
    
    var bikesHistory: [Int] = []
    
    var predict30MinChange: Int = 0
    
    
    var fullPercent: Double {
        return Double(self.numberOfBikes) / (Double(self.numberOfSpaces) + Double(self.numberOfBikes))
    }

}

extension StationModel {
    
    enum ParseDataError: Error { case Missingid, MissingName, MissingCoor, MissingData, MissingTime }
    
    init(dict: [String:Any] ) throws {
        
        guard let id = dict["sno"] as? String else { throw ParseDataError.Missingid }
        self.id = id
        
        guard let name = dict["sna"] as? String else { throw ParseDataError.MissingName }
        self.name = name
        
        guard let latStr = dict["lat"] as? String,
            let lngStr = dict["lng"] as? String,
        let lat = Double(latStr),
        let lng = Double(lngStr) else { throw ParseDataError.MissingCoor }
        self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        
        guard let spacesStr = dict["bemp"] as? String,
            let bikesStr = dict["sbi"] as? String,
            let spaces = Int(spacesStr),
            let bikes = Int(bikesStr) else { throw ParseDataError.MissingData }
        self.numberOfSpaces = spaces
        self.numberOfBikes = bikes
        
        guard let time = dict["mday"] as? String else { throw ParseDataError.MissingTime }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        dateFormatter.timeZone = TimeZone.current
        let date = dateFormatter.date(from: time)!
        self.updateTime = date
        
    }
}
