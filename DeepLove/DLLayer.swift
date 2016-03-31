//
//  DLLayer.swift
//  DeepLove
//
//  Created by Rei on 2016/02/20.
//  Copyright © 2016年 piyory. All rights reserved.
//

import Foundation
import Metal


class DLLayer {
    
    var name:String
    var inSize: MTLSize!
    var outSize: MTLSize!
    
    init(name:String, inSize: MTLSize, outSize: MTLSize){
        self.name = name
        self.inSize = inSize
        self.outSize = outSize
    }
}

class Linear:DLLayer {
    var weight:[Float]!
    var bias:[Float]!
    
    init(name: String, inVecSize: Int, outVecSize: Int, weight: [Float], bias: [Float]) {
        self.weight = weight
        self.bias = bias
        let inSize = MTLSize.init(width: inVecSize, height: 1, depth: 1)
        let outSize = MTLSize.init(width: outVecSize, height: 1, depth: 1)
        super.init(name: name, inSize: inSize, outSize: outSize)
    }
}

class Conv: DLLayer {
    var weight:[[Float]]!
    var bias:[[Float]]!
    var padding:Int!
    var stride:Int!
    var weightSize:MTLSize!

    init(name: String, inSize: MTLSize, outSize: MTLSize, weight: [[Float]], weightSize:MTLSize, bias: [[Float]], padding: Int, stride: Int) {
        self.weight = weight
        self.weightSize = weightSize
        self.bias = bias
        self.padding = padding
        self.stride = stride
        super.init(name: name, inSize: inSize, outSize: outSize)
        if(stride > 1){
            assert(outSize.width == Int((inSize.width - 1) / stride) + 1  , "size mismatch for Conv")
        } else {
            assert(outSize.width == inSize.width - 2 * Int(weightSize.width / 2)  + 2 * padding , "size mismatch for Conv")
        }
    }

}

class Pool: DLLayer {
    var padding:Int!
    var stride: Int!
    var poolSize:Int!
    
    init(name: String, inSize: MTLSize, outSize: MTLSize, poolSize:Int, padding: Int, stride: Int) {
        self.poolSize = poolSize
        self.padding = padding
        self.stride = stride
        super.init(name: name, inSize: inSize, outSize: outSize)
        assert(outSize.width == Int((inSize.width - 1) / stride) + 1 , "size mismatch for Pool")
        assert(padding == Int(poolSize / 2) , "size mismatch for Pool pad")
    }
    
}


