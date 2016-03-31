//
//  DLImageUtility.swift
//  DeepLove
//
//  Created by Rei on 2016/02/20.
//  Copyright © 2016年 piyory. All rights reserved.
//

import UIKit
import SwiftyJSON
import MetalKit

struct Pixel {
    var r:UInt8 = 0
    var g:UInt8 = 0
    var b:UInt8 = 0
    var a:UInt8 = 0
}

let bytesPerPixel = 4
let bitsPerComponent = 8
let bitsPerPixel = 32
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.ByteOrder32Big.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue)

func testMonoArray(length:Int) ->[UInt8]{
    var res = Array.init(count: length, repeatedValue: UInt8.init())
    for i in 0...length - 1{
        res[i] = UInt8(i)
    }
    return res
}

func arrayToMonoPixels(array:[UInt8]) -> [Pixel] {
    let pixel = Pixel.init()
    var pixelData = Array.init(count: array.count, repeatedValue: pixel)
    for (index, value) in array.enumerate() {
        pixelData[index] = Pixel(r: value, g: value, b: value, a: value)
    }
    return pixelData
}

func arrayToColorPixels(array:[UInt8], width:Int, height:Int) -> [Pixel] {
    let pixel = Pixel.init()
    let size = width * height
    var pixelData = Array.init(count: size, repeatedValue: pixel)
    for (i, _) in pixelData.enumerate() {
        pixelData[i] = Pixel(r:array[4 * i], g: array[4 * i + 1], b:array[4 * i + 2], a: array[4 * i + 3])
    }
    return pixelData
}
    

func pixelsToImage(pixels:[Pixel], width:Int, height:Int) -> UIImage {
    var data = pixels
    let bytesPerRow = width * Int(sizeof(Pixel))
    let providerRef = CGDataProviderCreateWithCFData(NSData(bytes: &data, length: data.count * sizeof(Pixel)))
     let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.NoneSkipLast.rawValue)
    let cgImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow,colorSpace,bitmapInfo,
        providerRef,nil,true, CGColorRenderingIntent.RenderingIntentDefault)
    return UIImage(CGImage: cgImage!)
}

func imageToArray(image: UIImage?) -> [UInt8] {
    let data = CGDataProviderCopyData(CGImageGetDataProvider(image?.CGImage))
    let length = CFDataGetLength(data)
    var rawData = [UInt8](count: length, repeatedValue: 0)
    CFDataGetBytes(data, CFRange(location: 0, length: length), &rawData)
    return rawData
}

func textureToArray(texture: MTLTexture, channel: Int) -> [Float] {
    let imageByteCount = texture.width * texture.height * channel
    let bytesPerRow = texture.width * channel * 4
    var src = [Float](count: imageByteCount, repeatedValue: 0)
    let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
    texture.getBytes(&src, bytesPerRow: bytesPerRow, fromRegion: region, mipmapLevel: 0)
    return src
}



func textureArrayToArray(texture: MTLTexture, channel: Int, index:Int) -> [UInt8] {
    let imageByteCount = texture.width * texture.height * channel
    let bytesPerRow = texture.width * channel
    var src = [UInt8](count: imageByteCount, repeatedValue: 0)
    let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
    texture.getBytes(&src, bytesPerRow: bytesPerRow, bytesPerImage: imageByteCount, fromRegion: region, mipmapLevel: 0, slice: index)
    return src
}


func getRValue(arr:[UInt8]) {
    for(index, value) in arr.enumerate(){
        if (index % 4 == 0){
            print(value)
        }
    }
}


func arrayToUint8(array:[Float]) -> [UInt8] {
    var res: [UInt8] = Array.init(count: array.count, repeatedValue: 0)
    for (index, value) in array.enumerate() {
        if (value < 0){
            res[index] = 0
        } else if (value > 1) {
            res[index] = 255
        } else {
            res[index] = UInt8(value * 255)
        }
    }
    return res
}


func grayScaleImage(Image:UIImage) -> UIImage {
    let imageRect = CGRectMake(0, 0, Image.size.width, Image.size.height);
    let colorSpace = CGColorSpaceCreateDeviceGray();
    let width = Int(Image.size.width)
    let height = Int(Image.size.height)
    let context = CGBitmapContextCreate(nil, width, height, 8, 0, colorSpace, .allZeros)
    CGContextDrawImage(context, imageRect, Image.CGImage!)
    let imageRef = CGBitmapContextCreateImage(context)
    let newImage = UIImage(CGImage: imageRef!)
    return newImage
}
