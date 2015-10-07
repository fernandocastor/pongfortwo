//
//  GameScene.swift
//  Pong for Two
//
//  Created by Fernando Castor on 04/10/15.
//  Copyright (c) 2015 Fernando Castor. All rights reserved.
//

import SpriteKit

/*
MISSING FEATURES

- Paddles working simultaneously

- To guarantee that the ball is not released on a semi-horizontal trajectory

- To change the angle of the ball depending on where it hits the paddle

- To create a blind spot where the paddles can't reach the ball

- To increase the speed of the ball as time passes

- To add multiple balls
*/

/*
WHY SKPhysicsContactDelegate?

An object that implements the SKPhysicsContactDelegate protocol can respond when two physics bodies are in contact with each other in a physics world. To receive contact messages, you set the contactDelegate property of a SKPhysicsWorld object. The delegate is called when a contact starts or ends.
*/
class GameScene: SKScene, SKPhysicsContactDelegate {
  
  let BALL_CATEGORY:UInt32 = 0x1 << 0
  let BOTTOM_CATEGORY:UInt32 = 0x1 << 1
  let TOP_CATEGORY:UInt32 = 0x1 << 2
  let PADDLE_CATEGORY:UInt32 = 0x1 << 3
  
  // It is necessary to specify a contactBitMask for
  // the world border. Otherwise, a bizarre bitmask
  // will be used and it will confound the game.
  let WORLD_CATEGORY:UInt32 = 0x1 << 4
  
  var ALL_SHAPES:UInt32 = 0
  
  let PADDLE1_CATEGORY_NAME = "paddle1"
  let PADDLE2_CATEGORY_NAME = "paddle2"
  let BALL_CATEGORY_NAME = "ball"
  
  var touchingBottomHalf = false
  var touchingTopHalf = false
  
  var playerOneScore = 0
  
  var playerTwoScore = 0
  
  var pointP2 = false
  var pointP1 = false
  
  let POINT_EXHIBITION_DURATION :NSTimeInterval = 1
  
  let COLLISION_RECTANGLE_HEIGHT : CGFloat = 30
  
  required init?(coder:NSCoder) {
    super.init(coder:coder)
  }
  
  override init (size:CGSize) {
    super.init(size:size)
    
  
  }
  
  /*
  Sets up paddle properties such as its scale (relative to the image file),
  its physics body, and multiple attributes related to it.
  */
  func setPhysicsPaddleProperties (paddle: SKSpriteNode) {
    
    paddle.physicsBody = SKPhysicsBody(rectangleOfSize: paddle.frame.size)
    
    paddle.physicsBody?.categoryBitMask = PADDLE_CATEGORY
    paddle.physicsBody?.friction = 0.5
    paddle.physicsBody?.linearDamping = 0
    paddle.physicsBody?.allowsRotation = true
    paddle.physicsBody?.dynamic = false
    
    paddle.physicsBody?.restitution = 0.0
    
  }
  
  override func didMoveToView(view: SKView) {
    self.backgroundColor = SKColor.blackColor()
    
    self.ALL_SHAPES = PADDLE_CATEGORY | BALL_CATEGORY | BOTTOM_CATEGORY | TOP_CATEGORY
    
    self.physicsWorld.gravity = CGVectorMake(0, 0)
    self.physicsWorld.contactDelegate = self
    
    let worldBorder = SKPhysicsBody(edgeLoopFromRect: self.frame)
    self.physicsBody = worldBorder
    self.physicsBody?.friction = 0
    self.physicsBody?.categoryBitMask = WORLD_CATEGORY
  
    let paddle1 = SKSpriteNode (imageNamed:"paddle")
    paddle1.name = PADDLE1_CATEGORY_NAME
    
    let paddle2 = SKSpriteNode(imageNamed:"paddle")
    paddle2.name = PADDLE2_CATEGORY_NAME
    
    // Y position starts on the lower part of the screen, not the top.
    // X position starts on the left, as one would expect.
    
    // The position of a node in the scene is relative to its center, not
    // its edge. Therefore, placing a paddle at Y-position 0 means that
    // its lower half will be invisible.
    let paddleXPosition = self.frame.width/2
    let paddle1YPosition = paddle1.size.height*2
    let paddle2YPosition = self.frame.height-paddle2.size.height*2
    paddle1.position = CGPointMake(paddleXPosition, paddle1YPosition)
    paddle2.position = CGPointMake(paddleXPosition, paddle2YPosition)
    
    paddle1.xScale = 0.5
    paddle1.yScale = 0.5
    paddle2.xScale = 0.5
    paddle2.yScale = 0.5
    
    self.addChild(paddle1)
    self.addChild(paddle2)
    
    // Physics body-related properties must be set AFTER the node
    // has been added to the scene. Otherwise, they will not work.
    
    self.setPhysicsPaddleProperties(paddle1)
    self.setPhysicsPaddleProperties(paddle2)
    
    let ball = SKSpriteNode(imageNamed:"ball")
    ball.name = BALL_CATEGORY_NAME
    
    ball.position = CGPointMake(self.frame.width/2, self.frame.height/2)
    ball.xScale = 0.4
    ball.yScale = 0.4
    
    self.addChild(ball)
    
    ball.physicsBody = SKPhysicsBody(circleOfRadius:ball.size.width/2)
    ball.physicsBody?.categoryBitMask = BALL_CATEGORY
    ball.physicsBody?.friction = 0.0
    ball.physicsBody?.linearDamping = 0
    ball.physicsBody?.angularDamping = 0
    ball.physicsBody?.allowsRotation = true
    ball.physicsBody?.dynamic = true
    ball.physicsBody?.restitution = 1
    
    ball.physicsBody?.applyImpulse(self.getRandomImpulse())
    
    let bottomRect = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, COLLISION_RECTANGLE_HEIGHT)
    let bottom = SKNode()
    self.addChild(bottom)
    bottom.physicsBody = SKPhysicsBody(edgeLoopFromRect: bottomRect)
    bottom.physicsBody?.categoryBitMask = self.BOTTOM_CATEGORY
    
    let topRect = CGRectMake(self.frame.origin.x, self.frame.height - COLLISION_RECTANGLE_HEIGHT/2, self.frame.size.width, COLLISION_RECTANGLE_HEIGHT)
    let top = SKNode()
    self.addChild(top)
    top.physicsBody = SKPhysicsBody(edgeLoopFromRect: topRect)
    top.physicsBody?.categoryBitMask = self.TOP_CATEGORY
    
    // Necessary to allow for both players to touch the screen simultaneously.
    self.view?.multipleTouchEnabled = true
    self.view?.userInteractionEnabled = true
    
    // This line specifies the other physics bodies with which the ball
    // may collide and in which we are interested.
    ball.physicsBody?.contactTestBitMask = self.BOTTOM_CATEGORY | self.TOP_CATEGORY
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    /* Called when a touch begins */
    
    for touch in touches {
      let location = touch.locationInNode(self)
      
      // Touch was on the bottom half of the screen, i.e., player 1.
      if (location.y < self.frame.height/2) {
        self.touchingBottomHalf = true
      }
        // Touch was on the top half of the screen, i.e., player 1.
      else {
        self.touchingTopHalf = true
      }
    }
  }
  
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    for touch in touches {
      let location = touch.locationInNode(self)
      let prevLocation = touch.previousLocationInNode(self)
      if (location.y < self.frame.height/2) {
        if self.touchingBottomHalf {
          let paddle1 = self.childNodeWithName(self.PADDLE1_CATEGORY_NAME) as! SKSpriteNode
          paddle1.position.x = paddle1.position.x + (location.x - prevLocation.x)
        }
      } else {
        if self.touchingTopHalf {
          let paddle2 = self.childNodeWithName(self.PADDLE2_CATEGORY_NAME) as! SKSpriteNode
          paddle2.position.x = paddle2.position.x + (location.x - prevLocation.x)
        }
      }
    }
    
  }
  
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    for touch in touches {
      let location = touch.locationInNode(self)
      
      // Touch was on the bottom half of the screen, i.e., player 1.
      if (location.y < self.frame.height/2) {
        self.touchingBottomHalf = false
      }
        // Touch was on the top half of the screen, i.e., player 1.
      else {
        self.touchingTopHalf = false
      }
    }
    
  }
  
  // This is the method that handles collisions. It is defined by the
  // SKPhysicsContactDelegate
  func didBeginContact(contact:SKPhysicsContact) {
    var firstBody = contact.bodyA
    var secondBody = contact.bodyB
    


    if (firstBody.categoryBitMask >= secondBody.categoryBitMask) {
      firstBody = contact.bodyB
      secondBody = contact.bodyA
    }
    
    //  0000000010 = 2
    
    //  1111111111 -> padrão do categoryBitMask
    //  1111111111 -> padrão do collisionBitMask
    //  0000000000 -> padrão do contactBitMask
    
    //  0000000001 = 1
    //  0000000010 -> bottom
    //  0000000100 -> top
    // |0000000110 
    //  0000000011 = 3
    // &0000000001
    
    
    // Ball reached a player area.
    let contact = (secondBody.categoryBitMask & (BOTTOM_CATEGORY | TOP_CATEGORY))
    
    if (firstBody.categoryBitMask == BALL_CATEGORY) &&  contact > 0 {
      if (secondBody.categoryBitMask == BOTTOM_CATEGORY) {
        let theBall = self.childNodeWithName(self.BALL_CATEGORY_NAME)!
        theBall.physicsBody?.velocity = CGVectorMake(0, 0);
        self.pointP2 = true
      }
      else if (secondBody.categoryBitMask == TOP_CATEGORY){
        let theBall = self.childNodeWithName(self.BALL_CATEGORY_NAME)!
        theBall.physicsBody?.velocity = CGVectorMake(0, 0);
        self.pointP1 = true
      }
    }
  }
  
  func didEndContact(contact: SKPhysicsContact) {
    self.resetBall()
    if self.pointP1 {
      self.pointP1 = false
      self.playerOneScore += 1
      self.showScore(forPlayer:1)
    }
    else if self.pointP2 {
      self.pointP2 = false
      self.playerTwoScore += 1
      self.showScore(forPlayer: 2)
    }
  }
  
  func showScore(forPlayer player: Int) {
    var pontos = 0
    var yPos : CGFloat = 0.0
    if player == 1 {
        pontos = self.playerOneScore
        yPos = self.frame.size.height/4
    }
    else if player == 2 {
        pontos = self.playerTwoScore
        yPos = 3*self.frame.size.height/4
    }
    let newPhaseLabel:SKLabelNode = SKLabelNode(text:"PONTOS: \(pontos)")
    newPhaseLabel.fontSize = 36
    newPhaseLabel.fontColor = UIColor.redColor()
    newPhaseLabel.fontName = "Times"
    newPhaseLabel.position = CGPointMake(CGRectGetMidX(self.frame), yPos)
    self.addChild(newPhaseLabel)
    let fadeInAction = SKAction.fadeInWithDuration(POINT_EXHIBITION_DURATION)
    let fadeOutAction = SKAction.fadeOutWithDuration(POINT_EXHIBITION_DURATION)
    newPhaseLabel.runAction(SKAction.sequence([fadeInAction, fadeOutAction, SKAction.removeFromParent()]))
  }
  
  // Brings the ball back to the center of the screen, before making it move
  // again.
  func resetBall() {
    let ball = self.childNodeWithName(self.BALL_CATEGORY_NAME)
    if let theBall = ball as SKNode? {
      theBall.physicsBody?.velocity = CGVectorMake(0, 0);
      let fadeOutAction = SKAction.fadeOutWithDuration(POINT_EXHIBITION_DURATION)
      let fadeInAction = SKAction.fadeInWithDuration(POINT_EXHIBITION_DURATION)
      let moveAction = SKAction.moveTo(CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame)), duration:0)
      let impulseAction = SKAction.applyImpulse(self.getRandomImpulse(), duration:POINT_EXHIBITION_DURATION/10)
      theBall.runAction(SKAction.sequence([fadeOutAction,moveAction,fadeInAction, impulseAction]))
    }
  }
  
  func getRandomImpulse() -> CGVector {
    let x : CGFloat = 1//random(min:-2, max: 2)
    let y : CGFloat = -2 //random(min:-2, max: 2)
    
    return CGVectorMake(x, y)
  }
  
  override func update(currentTime: CFTimeInterval) {
    /* Called before each frame is rendered */
  }
  
  func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
  }
  
  func random(min min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
  }
  
}
