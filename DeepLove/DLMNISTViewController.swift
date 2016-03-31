//
//  DLMNISTViewController.swift
//  DeepLove
//
//  Created by Rei on 2016/02/20.
//  Copyright © 2016年 piyory. All rights reserved.
//

import UIKit
import SwiftyJSON


class DLMNISTViewController: UIViewController {
    var metalManager: DLMetalManager!
    var networkManger: DLNetworkManager!
    @IBOutlet weak var testView: UIImageView!
    @IBOutlet weak var predLabel: UILabel!
    var inputVector: [Float]!
    var weightVector1: [Float]!
    var weightVector2: [Float]!
    var weightVector3: [Float]!
    var biasVector1: [Float]!
    var biasVector2: [Float]!
    var biasVector3: [Float]!
    var json: JSON!
    var layer1: Linear!
    var layer2: Linear!
    var layer3: Linear!

    override func viewDidLoad() {
        super.viewDidLoad()
        metalManager = DLMetalManager.init()
        loadParams()
        json = readJson("mnist100")
        layer1 = Linear.init(name: "layer1", inVecSize: 784, outVecSize: 512, weight: weightVector1, bias: biasVector1)
        layer2 = Linear.init(name: "layer2", inVecSize: 512, outVecSize: 512, weight: weightVector2, bias: biasVector2)
        layer3 = Linear.init(name: "layer3", inVecSize: 512, outVecSize: 10, weight: weightVector3, bias: biasVector3)
        networkManger = DLNetworkManager.init(layers: [layer1, layer2, layer3], metalManager: metalManager)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    
    @IBAction func reloadButtonTapped(sender: AnyObject) {
        
        let randomIndex = Int(arc4random() % 100)
        let mnistjson = json![randomIndex]["data"]
        let mnistArray = jsonToUint8Array(mnistjson)
        let pixels = arrayToMonoPixels(mnistArray)
        let image = pixelsToImage(pixels, width: 28, height: 28)
        testView.image = image
        
        inputVector = jsonToFloatArray(mnistjson)
        let out1 = networkManger.sendLinearLayer(inputVector, config: layer1)
        let out2 = networkManger.sendLinearLayer(out1, config: layer2)
        let out3 = networkManger.sendLinearLayer(out2, config: layer3)
        predLabel.text = "pred:" + String(out3.indexOf(out3.maxElement()!)!)

    }
    func loadParams() {
        let weightjson = readJson("weights")
        weightVector1 = jsonToFloatArray(weightjson![0]["element"])
        biasVector1 = jsonToFloatArray(weightjson![1]["element"])
        weightVector2 = jsonToFloatArray(weightjson![2]["element"])
        biasVector2 = jsonToFloatArray(weightjson![3]["element"])
        weightVector3 = jsonToFloatArray(weightjson![4]["element"])
        biasVector3 = jsonToFloatArray(weightjson![5]["element"])
    }

}
