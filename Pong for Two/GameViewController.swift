//
//  GameViewController.swift
//  Pong for Two
//
//  Created by Fernando Castor on 04/10/15.
//  Copyright (c) 2015 Fernando Castor. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let scene = GameScene(size:self.view.frame.size)
    scene.scaleMode = SKSceneScaleMode.AspectFill
    
    let skView = self.view as! SKView
    skView.showsFPS = true
    skView.showsNodeCount = true
    /* Sprite Kit applies additional optimizations to improve rendering performance */
    skView.ignoresSiblingOrder = true
    
    skView.presentScene(scene)
  }
  
  override func shouldAutorotate() -> Bool {
    return true
  }
  
  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
      return .AllButUpsideDown
    } else {
      return .All
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Release any cached data, images, etc that aren't in use.
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
}
