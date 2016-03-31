//
//  DLNetworkManager.swift
//  DeepLove
//
//  Created by Rei on 2016/02/20.
//  Copyright © 2016年 piyory. All rights reserved.
//

import UIKit


class DLNetworkManager {
    var layers: [DLLayer]!
    var currentInput: [Float]!
    var currentOutput: [Float]!
    var metalManager: DLMetalManager!
    
    init(layers:[DLLayer], metalManager: DLMetalManager) {
        self.layers = layers
        self.metalManager = metalManager
    }
    
    func sendLinearLayer(data:[Float], config:DLLayer) -> [Float] {
        let layer = config as! Linear
        metalManager.setupCommandBufferWithFunction("linear")
        let outVector:[Float] = Array.init(count: layer.outSize.width, repeatedValue: 0)
        metalManager.setBytesBuffer(data, Index: 0)
        metalManager.outputBuffer = metalManager.setBytesBuffer(outVector, Index: 1)
//        let weightTexture = metalManager.createTextureArray(layer.inSize.width, height: layer.outSize.width, length:1)
//        let weightRegion = MTLRegionMake2D(0, 0, layer.inSize.width, layer.outSize.width)
//        metalManager.populateTextureArray([layer.weight], texture: weightTexture, region: weightRegion)
//        metalManager.setTexture(weightTexture, index: 2)
        metalManager.setBytesBuffer(layer.weight, Index: 2)
        metalManager.setBytesBuffer(layer.bias, Index: 3)
        let params: [Int32] = [Int32(layer.inSize.width) ,Int32(layer.outSize.width)]
        metalManager.setBytesBuffer(params, Index: 4)
        
        let threadWidth =  MTLSize.init(width: 32, height: 1, depth: 1)
        let totalGroups =  MTLSize.init(width: (layer.outSize.width / threadWidth.width) + 1, height: 1, depth: 1)
        metalManager.setMetalThreadGroup(threadWidth, totalGroups: totalGroups)
        metalManager.executeCurrentCommand()
        currentOutput = metalManager.getResult(layer.outSize.width)
        return(currentOutput)
    }
    
    func sendSoftMaxLayer(data:[Float]) {
    }

    func splitChannel(pixel:[UInt8], width:Int, height:Int) -> [[Float]]{
        metalManager.setupCommandBufferWithFunction("splitchannel")

        let intexture =  metalManager.createTextureFromPixel(pixel, width: width, height: height)
        let outtexture = metalManager.createTextureArray(width, height: height, length: 3)
        metalManager.setTexture(intexture, index: 0)
        metalManager.setTexture(outtexture, index: 1)
        
        let threadWidth =  MTLSize.init(width: 16, height: 16, depth: 1)
        let totalGroups =  MTLSize.init(width: Int(width / threadWidth.width) + 1 , height: Int(height / threadWidth.height) + 1, depth: 3)
        metalManager.setMetalThreadGroup(threadWidth, totalGroups: totalGroups)
        metalManager.executeCurrentCommand()
        
        let data =  metalManager.returnTextureArray(outtexture)
        return data
    }
    
    func sendConvLayer(data:[[Float]], config: DLLayer) -> [[Float]]{
        let layer = config as! Conv
        metalManager.setupCommandBufferWithFunction("conv")
        
        let inTexture = metalManager.createTextureArray(layer.inSize.width + 2 * layer.padding, height: layer.inSize.width + 2 * layer.padding, length: layer.inSize.depth)
        let paddingRegion = MTLRegionMake2D(layer.padding, layer.padding, layer.inSize.width, layer.inSize.height)
        metalManager.populateTextureArray(data, texture: inTexture, region: paddingRegion)
        
        let outTexture = metalManager.createTextureArray(layer.outSize.width, height: layer.outSize.width, length: layer.outSize.depth)
        
        let weightTexture = metalManager.createTextureArray(layer.weightSize.width, height: layer.weightSize.height, length: layer.weightSize.depth)
        let weightRegion = MTLRegionMake2D(0, 0, layer.weightSize.width, layer.weightSize.height)
        metalManager.populateTextureArray(layer.weight, texture: weightTexture, region: weightRegion)
        
        let biasTexture = metalManager.createTextureArray(layer.outSize.width, height: layer.outSize.width, length: layer.outSize.depth)
        let biasRegion = MTLRegionMake2D(0, 0, layer.outSize.width, layer.outSize.height)
        metalManager.populateTextureArray(layer.bias, texture: biasTexture, region: biasRegion)
        let params: [Int32] = [Int32(layer.padding), Int32(layer.stride)]

        metalManager.setTexture(inTexture, index: 0)
        metalManager.setTexture(outTexture, index: 1)
        metalManager.setTexture(weightTexture, index: 2)
        metalManager.setTexture(biasTexture, index: 3)
        metalManager.setBytesBuffer(params, Index: 4)
        
        let threadWidth =  MTLSize.init(width: 8, height: 8, depth: 2)
        let totalGroups =  MTLSize.init(width: Int(layer.outSize.width / threadWidth.width) + 1 , height: Int(layer.outSize.height / threadWidth.height) + 1, depth: Int(layer.outSize.depth / threadWidth.depth) + 1)
        
        metalManager.setMetalThreadGroup(threadWidth, totalGroups: totalGroups)
        metalManager.executeCurrentCommand()
        
        return metalManager.returnTextureArray(outTexture)
    }
    
    func sendPoolLayer(data:[[Float]], config: DLLayer) -> [[Float]]{
        let layer = config as! Pool
        metalManager.setupCommandBufferWithFunction("maxpool")
        
        let inTexture = metalManager.createTextureArray(layer.inSize.width + 2 * layer.padding, height: layer.inSize.width + 2 * layer.padding, length: layer.inSize.depth)
        let paddingRegion = MTLRegionMake2D(layer.padding, layer.padding, layer.inSize.width, layer.inSize.height)
        metalManager.populateTextureArray(data, texture: inTexture, region: paddingRegion)
        let outTexture = metalManager.createTextureArray(layer.outSize.width, height: layer.outSize.width, length: layer.outSize.depth)
        let params: [Int32] = [Int32(layer.poolSize) ,Int32(layer.padding), Int32(layer.stride)]

        metalManager.setTexture(inTexture, index: 0)
        metalManager.setTexture(outTexture, index: 1)
        metalManager.setBytesBuffer(params, Index: 2)
        let threadWidth =  MTLSize.init(width: 8, height: 8, depth: 2)
        let totalGroups =  MTLSize.init(width: Int(layer.outSize.width / threadWidth.width) + 1 , height: Int(layer.outSize.height / threadWidth.height) + 1, depth: Int(layer.outSize.depth / threadWidth.depth) + 1)

        metalManager.setMetalThreadGroup(threadWidth, totalGroups: totalGroups)
        metalManager.executeCurrentCommand()
        
        return metalManager.returnTextureArray(outTexture)

    }


}