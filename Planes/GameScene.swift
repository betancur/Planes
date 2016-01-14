//
//  GameScene.swift
//  Planes
//
//  Created by José Alejandro Betancur on 1/11/16.
//  Copyright (c) 2016 KZ Labs. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene {
    
    let motionManager = CMMotionManager()
    var xAcceleration = CGFloat(0)
    
    let plane = SKSpriteNode(imageNamed: "Avion")
    let smokeTrail = SKEmitterNode(fileNamed: "smokeTrail")!
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        backgroundColor = UIColor(red: 0.42, green: 0.58, blue: 0.26, alpha: 1)
        
        /* Avión */
        plane.position = CGPoint(x: size.width/2, y: 20 + plane.size.height)
        plane.zPosition = 100
        
        addChild(plane)
        
        createShadow("Avion")
        
        setupPlayer()
        setupCoreMotion()
        
        smokeTrail.position = CGPoint(x:plane.position.x, y: 20 + plane.position.y - (plane.size.height/2))
        smokeTrail.zPosition = 10
        smokeTrail.targetNode = self
        addChild(smokeTrail)
        
    }
    
    func createShadow(tipo:String){
        let planeShadow = SKSpriteNode(imageNamed: tipo)
        planeShadow.color = SKColor.blackColor()
        planeShadow.colorBlendFactor = 1
        planeShadow.alpha = 0.4
        
        planeShadow.position = CGPoint(x: 15, y: -15)
        planeShadow.zPosition = -1
        planeShadow.name = "shadow"
        
        plane.addChild(planeShadow)
    }
    
    func setupCoreMotion() {
        motionManager.accelerometerUpdateInterval = 0.2
        let queue = NSOperationQueue()
        motionManager.startAccelerometerUpdatesToQueue(queue, withHandler:
        {
        accelerometerData, error in
        guard let accelerometerData = accelerometerData else {
        return
        }
        let acceleration = accelerometerData.acceleration
        self.xAcceleration = (CGFloat(acceleration.x) * 0.75) + (self.xAcceleration * 0.25)
        })
    }
    
    func updatePlayer() {
            // Set velocity based on core motion
            plane.physicsBody?.velocity.dx = xAcceleration * 1000.0
            // Wrap plane around edges of screen
            //var planePosition = convertPoint(plane.position, fromNode: fgNode)
            var planePosition = plane.position
            if planePosition.x < -plane.size.width/2 {
                planePosition = CGPoint(x: size.width + plane.size.width/2, y: 0.0)
                plane.position.x = planePosition.x
            } else if planePosition.x > size.width + plane.size.width/2 {
                    planePosition = CGPoint(x: -plane.size.width/2, y: 0.0)
                    plane.position.x = planePosition.x
            }
        
        // Update Trail
        smokeTrail.position = CGPoint(x:plane.position.x, y: 20 + plane.position.y - (plane.size.height/2))
        
            // update look
            //print(xAcceleration * 1000.0)
            if ((xAcceleration * 1000.0) > 50) {
                plane.texture = SKTexture(imageNamed: "Avion-right")
                plane.removeAllChildren()
                createShadow("Avion-right")
            } else if ((xAcceleration * 1000.0) < -50) {
                plane.texture = SKTexture(imageNamed: "Avion-left")
                plane.removeAllChildren()
                createShadow("Avion-left")
            } else {
                plane.texture = SKTexture(imageNamed: "Avion")
                plane.removeAllChildren()
                createShadow("Avion")
            }
    }
    
    func setupPlayer() {
        plane.physicsBody = SKPhysicsBody(circleOfRadius:
        plane.size.width * 0.3)
        plane.physicsBody!.dynamic = true
        plane.physicsBody!.allowsRotation = false
        plane.physicsBody!.categoryBitMask = 0
        plane.physicsBody!.collisionBitMask = 0
        plane.physicsBody!.affectedByGravity = false
    }
    
    
    override func update(currentTime: NSTimeInterval) {
        updatePlayer()
    }
}
