//
//  API.swift
//  UbikeTracer
//
//  Created by nickLin on 2017/7/21.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit



extension WebService {

    func redZones(handle:@escaping (([[String:Any]]?)->Void) ) {
        let url = "https://opendata2017.herokuapp.com/getDataPoint"
        request(method: .GET, url: url) { (data, res, error) in
            guard error == nil else {
                handle(nil)
                return
            }

            guard let dic = data?.dic , let points = dic["gps_point"] as? [[String: Any]] else {
                handle(nil)
                return
            }

            handle(points)
            return
            
        }
    }

}
