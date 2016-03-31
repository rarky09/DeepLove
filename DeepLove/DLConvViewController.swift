//
//  DLConvViewController.swift
//  DeepLove
//
//  Created by Rei on 2016/02/21.
//  Copyright © 2016年 piyory. All rights reserved.
//

import UIKit
import Metal

class DLConvViewController: UIViewController {
    @IBOutlet weak var imgView1: UIImageView!
    @IBOutlet weak var imgView2: UIImageView!

    var metalManager: DLMetalManager!
    var networkManager: DLNetworkManager!
    var width:Int!
    var height:Int!

    override func viewDidLoad() {
        super.viewDidLoad()
        metalManager = DLMetalManager.init()
        
        networkManager = DLNetworkManager.init(layers: [], metalManager: metalManager)

        
        // 10 * 10 * 3
        let image = UIImage(named: "tomato.jpg")
        width = Int(image!.size.width)
        height = Int(image!.size.height)
        
        let pixelArray = imageToArray(image)
        let layers = setupLayers()
        
        let timer = Timer.init()

        // separate RGB
        
        let split = networkManager.splitChannel(pixelArray,width: width, height: height)
        
        // conv1: input:[10,10,3], weight[3,3,90] -> output[10,10,30]
        let convout1 =  networkManager.sendConvLayer(split, config: layers[0])

        // pool1: maxpool[3,3]
        let poolout1 = networkManager.sendPoolLayer(convout1, config: layers[1])

        // conv2: input:[10,10,30], weight[3,3,300] -> output[10,10,10]
        let convout2 =  networkManager.sendConvLayer(poolout1, config: layers[2])
        
        // pool2: maxpool[3,3] stride 2
        let poolout2 = networkManager.sendPoolLayer(convout2, config: layers[3])

        // fullcon 250 -> 100
        let flat:[Float] = Array(poolout2.flatten())
        let linout = networkManager.sendLinearLayer(flat, config: layers[4])

        // fullcon 100 -> 10
        let linout2 = networkManager.sendLinearLayer(linout, config: layers[5])
        print(timer.stop())

    }
    
    func setupLayers() -> [DLLayer]{
        
        let inSize = MTLSize(width: width, height: height, depth: 3)
        let outSize = MTLSize(width: width, height: height, depth: 30)

        let weight1 = createUnitMatrix(9, length: inSize.depth * outSize.depth)
        let bias1 = createUnitMatrix(100, length: outSize.depth)
        let conv1 = Conv.init(name: "conv1", inSize: inSize, outSize: outSize, weight: weight1, weightSize: MTLSize(width: 3, height: 3, depth: weight1.count), bias:bias1, padding: 1, stride: 1)

        let pool1 = Pool.init(name: "pool1", inSize: conv1.outSize, outSize: MTLSize(width: 10, height: 10, depth: 30), poolSize: 3, padding: 1, stride: 1)

        let weight2 = createUnitMatrix(9, length: 300)
        let bias2 = createUnitMatrix(100, length: 10)
        let conv2 = Conv.init(name: "conv2", inSize: pool1.outSize, outSize: MTLSize(width: 10, height: 10, depth: 10), weight: weight2, weightSize: MTLSize(width: 3, height: 3, depth: 300), bias:bias2, padding: 1, stride: 1)

        let pool2 = Pool.init(name: "pool2", inSize: conv2.outSize, outSize: MTLSize(width: 5, height: 5, depth: 10), poolSize: 3, padding: 1, stride: 2)

        let weight3:[Float] = Array.init(count: 25000, repeatedValue: 0.1)
        let bias3:[Float] = Array.init(count: 100, repeatedValue: 1)
        let linear1 = Linear.init(name: "lin1", inVecSize: 250, outVecSize: 100, weight: weight3, bias: bias3)

        let weight4:[Float] = Array.init(count: 1000, repeatedValue: 0.1)
        let bias5:[Float] = Array.init(count: 10, repeatedValue: 1)
        let linear2 = Linear.init(name: "lin1", inVecSize: 100, outVecSize: 10, weight: weight4, bias: bias5)

        return [conv1,pool1,conv2, pool2, linear1, linear2]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }
    
}
