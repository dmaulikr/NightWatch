//
//  JsonExtension.swift
//  UbikeTracer
//
//  Created by nickLin on 2017/7/21.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit



extension Data {
    @nonobjc var arrayDic : [[String:Any]]?{
        do {
            return try JSONSerialization.jsonObject(with: self, options: .mutableContainers ) as? [[String:Any]]
        } catch let error as NSError {
            print(msg:error)
        }
        return nil
    }
    @nonobjc var dic : [String:Any]?{
        do {
            return try JSONSerialization.jsonObject(with: self, options: .mutableContainers ) as? [String:Any]
        } catch let error as NSError {
            print(msg:error)
        }
        return nil
    }
    @nonobjc var array : [Any]?{
        do {
            return try JSONSerialization.jsonObject(with: self, options: .mutableContainers ) as? [Any]
        } catch let error as NSError {
            print(msg:error)
        }
        return nil
    }

    @nonobjc var string : String? {
        return String(data: self, encoding: .utf8)
    }


}

extension Dictionary {
    @nonobjc var json:Data?{
        guard JSONSerialization.isValidJSONObject(self) else { return nil }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return jsonData
        } catch {
            return nil
        }
    }
}

extension Array {
    @nonobjc var json:Data?{
        guard JSONSerialization.isValidJSONObject(self) else { return nil }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return jsonData
        } catch {
            return nil
        }
    }
}

extension String {
    @nonobjc var ArrayDic : [[String:Any]]?{
        return self.data?.arrayDic
    }
    @nonobjc var Array : [Any]?{
        return self.data?.array
    }
    @nonobjc var Dic : [String:Any]?{
        return self.data?.dic
    }
    @nonobjc var data : Data?{
        return self.data(using: .utf8)
    }
}



extension Collection where Self : ExpressibleByDictionaryLiteral{

    func log(file: String = #file,method: String = #function,line: Int = #line){
        Swift.print("\((file as NSString).lastPathComponent)[\(line)], \(method) : 總共有 key / Value \(count) 筆")
        enumerated().forEach{print($0)}
    }

}

extension Array where Element : Collection , Element: ExpressibleByDictionaryLiteral {

    func log(file: String = #file,method: String = #function,line: Int = #line){
        Swift.print("\((file as NSString).lastPathComponent)[\(line)], \(method) : 總共有 \(count) 筆")
        enumerated().forEach
            {
                print("第 \($0.offset) 筆")
                print("總共有 key / Value \($0.element.count) 筆")
                $0.element.forEach
                    {
                        print($0)
                }
                print("-------------------\n")
        }
    }
}

