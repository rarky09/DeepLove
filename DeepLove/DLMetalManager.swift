//
//  DLMetalManager.swift
//  DeepLove
//
//  Created by Rei on 2016/02/20.
//  Copyright © 2016年 piyory. All rights reserved.
//

import UIKit
import Metal

class DLMetalManager {
    var metal: DLMetalDevice!
    var outputBuffer: MTLBuffer!
    var outputTexture: MTLTexture!

    
    init() {
        self.metal = DLMetalDevice.init()
    }
    
    func setupCommandBufferWithFunction(function:String) {
        metal.commandBuffer = metal.commandQueue.commandBuffer()
        metal.computeCommandEncoder = metal.commandBuffer.computeCommandEncoder()
        metal.computePipelineState = try! metal.device.newComputePipelineStateWithFunction(metal.functions[function]!)
        metal.computeCommandEncoder.setComputePipelineState(metal.computePipelineState)
    }
    
    func setBytesBuffer<T>(inputData:[T], Index:Int) -> MTLBuffer {
        let buffer = metal.device.newBufferWithBytes(inputData, length:inputData.count * sizeof(T), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        metal.computeCommandEncoder.setBuffer(buffer, offset: 0, atIndex: Index)
        return buffer
    }
    
    func createTextureFromPixel(pixel:[UInt8], width:Int, height:Int) -> MTLTexture {
        let region = MTLRegionMake2D(0, 0, width, height)
        let descriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm, width: width, height: height, mipmapped: false)
        let texture = metal.device.newTextureWithDescriptor(descriptor)
        texture.replaceRegion(region, mipmapLevel: 0, withBytes: pixel, bytesPerRow: width * 4)
        return texture
    }


    func setTexture(texture:MTLTexture, index:Int) -> MTLTexture{
        metal.computeCommandEncoder.setTexture(texture, atIndex: index)
        return texture
    }
    
    func populateTextureArray(data:[[Float]], texture:MTLTexture, region:MTLRegion) {
        for (index,value) in data.enumerate() {
            texture.replaceRegion(region, mipmapLevel: 0, slice: index, withBytes: value, bytesPerRow: region.size.width * sizeof(Float), bytesPerImage: region.size.width * region.size.height * sizeof(Float))
        }
    }
    
    func returnTextureArray(texture:MTLTexture) -> [[Float]] {
        let w = texture.width
        let h = texture.height
        let l = texture.arrayLength
                
        let region = MTLRegionMake2D(0, 0, w, h)
        var resultArray: [[Float]] = Array.init(count: l, repeatedValue: [0])
        for i in 0...l - 1 {
            var result = [Float](count: w * h, repeatedValue: 0)
            texture.getBytes(&result, bytesPerRow: w * sizeof(Float), bytesPerImage: w * h * sizeof(Float), fromRegion: region, mipmapLevel: 0, slice: i)
            resultArray[i] = result
        }
        return resultArray
    }

    func createTextureArray(width: Int, height: Int, length: Int) -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.R32Float, width: width, height: height, mipmapped: false)
        if (length > 1) {
            descriptor.textureType = .Type2DArray
            descriptor.arrayLength = length
        }
        return metal.device.newTextureWithDescriptor(descriptor)
    }

    func getResult(outputSize:Int) -> [Float]{
        let data = NSData(bytesNoCopy: outputBuffer.contents(), length: outputSize * sizeof(Float), freeWhenDone: false)
        var resultArray = [Float](count: outputSize , repeatedValue: 0)
        data.getBytes(&resultArray, length:outputSize * sizeof(Float))
        return(resultArray)
    }

    func setMetalThreadGroup(threadWidth: MTLSize, totalGroups: MTLSize){
        metal.computeCommandEncoder.dispatchThreadgroups(totalGroups, threadsPerThreadgroup: threadWidth)
        metal.computeCommandEncoder.endEncoding()
    }

    func executeCurrentCommand() {
        metal.commandBuffer.commit()
        metal.commandBuffer.waitUntilCompleted()
    }

}