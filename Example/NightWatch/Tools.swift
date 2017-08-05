//
//  Tools.swift
//  UbikeTracer
//
//  Created by nickLin on 2017/7/21.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit

// MARK: - 列印出程式碼的檔案名 Func 名 列數 及原本的名稱
public func print<T>(msg: T,file: String = #file,method: String = #function,line: Int = #line)
{
    // build setting - Other Swift Flags - Debug  Add ( -D  DEBUG )
    #if DEBUG
        Swift.print("\((file as NSString).lastPathComponent)[\(line)], \(method): \(msg)")
    #endif
}

