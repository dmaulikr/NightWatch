//
//  StationManager.swift
//  UbikeTracer
//
//  Created by rosa on 2017/7/21.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation
import GameKit

enum SuccessOrFailure: Error {
    case success
    case failure
}

typealias ApiResult = (_ result : SuccessOrFailure ) -> Void

open class StationManager {
    
    static let sharedInstance = StationManager()
    
    var stations: [StationModel] = []
    
    func getStations(completion: @escaping ApiResult) {
        WebService.shard.redZones { (arr) in
            guard let arr = arr else {
            completion(SuccessOrFailure.failure)
                return
            }
            var stations: [StationModel] = []
            for item in arr {
                do {
                    var station = try StationModel(dict: item)
                    
                    
                    
                    let rs = GKMersenneTwisterRandomSource()
                    let v = abs(station.name.hash)
                    rs.seed = UInt64(v)
                    
                    let rd = GKRandomDistribution(randomSource: rs, lowestValue: 0, highestValue: 50)

                        let dir = rd.nextInt() >= (rd.highestValue / 2) ? 1.0 : -1.0
                        station.predict30MinChange = Int(Double(station.numberOfBikes + station.numberOfSpaces) * dir * (Double(rd.nextInt()) / 200.0))
                
                        
                    stations.append(station)
                } catch (let error) {
                    print(error.localizedDescription)
                }
            }
            self.stations = stations
            completion(SuccessOrFailure.success)
        }
    }
}
