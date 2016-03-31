//
//  DLDataUtility.swift
//  DeepLove
//
//  Created by Rei on 2016/02/20.
//  Copyright © 2016年 piyory. All rights reserved.
//

import UIKit
import SwiftyJSON


class Timer {
    var time: NSDate!
    init(){
        time = NSDate()
    }

    func stop() -> NSTimeInterval{
        let elapsed = NSDate().timeIntervalSinceDate(time)
        return elapsed
    }

}

func printMatrix(arr:[[Float]], size: Int) {
    for k in 0..<arr.count{
        for i in 0..<size {
            for j in 0..<size {
                print(arr[k][10 * i + j],terminator: "")
                if(j < size - 1){
                    print(", ",terminator: "")
                }
            }
            print("")
        }
        print("")
    }
    
}

func readJson(name:String) -> JSON? {
    var json:JSON!
    if let path = NSBundle.mainBundle().pathForResource(name, ofType: "json") {
        if let data = NSData(contentsOfFile: path) {
            json = JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: nil)
        }
    } else {
        print("invalid filename")
    }
    return json
}
    
func jsonToUint8Array(json:JSON) -> [UInt8] {
    var array:[UInt8] = Array.init(count: json.count, repeatedValue: 0)
    for (index, value) in json {
            array[Int(index)!] = value.uInt8Value
        }
    return array
}
    
func jsonToFloatArray(json:JSON) -> [Float] {
    var array: [Float] = Array.init(count: json.count, repeatedValue: 0)
    for (index, value) in json {
        array[Int(index)!] = value.floatValue
    }
    return array
}


func createUnitMatrix(size:Int, length: Int) -> [[Float]] {
    let w1: [Float] =  Array.init(count: size, repeatedValue: 1)
    var weights: [[Float]] = Array()
    for i in 0..<length {
        weights += [w1]
    }
    return weights
}


