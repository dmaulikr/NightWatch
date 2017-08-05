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
                    let station = try StationModel(dict: item)
                    
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
