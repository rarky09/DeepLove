//
//  DLMetalDevice.swift
//  DeepLove
//
//  Created by Rei on 2016/02/20.
//  Copyright © 2016年 piyory. All rights reserved.
//

import Foundation
import Metal


class DLMetalDevice {
    var device: MTLDevice!
    var commandQueue:MTLCommandQueue!
    var commandBuffer:MTLCommandBuffer!
    var library:MTLLibrary!
    var functions = [String:MTLFunction]()
    var computeCommandEncoder:MTLComputeCommandEncoder!
    var computePipelineState: MTLComputePipelineState!

    init() {
        self.device = MTLCreateSystemDefaultDevice()
        self.commandQueue = device.newCommandQueue()
        self.library = device.newDefaultLibrary()
        self.functions["linear"] = library.newFunctionWithName("linear")
        self.functions["softmax"] = library.newFunctionWithName("softmax")
        self.functions["conv"] = library.newFunctionWithName("conv")
        self.functions["splitchannel"] = library.newFunctionWithName("splitchannel")
        self.functions["maxpool"] = library.newFunctionWithName("maxpool")
    }
}
