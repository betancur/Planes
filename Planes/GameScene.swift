//
//  GameScene.swift
//  Planes
//
//  Created by José Alejandro Betancur on 1/11/16.
//  Copyright (c) 2016 KZ Labs. All rights reserved.
//

import SpriteKit
import CoreMotion


struct PhysicsCategory {
    static let None:  UInt32 = 0
    static let Bullet:   UInt32 = 0b1 // 1
    static let Enemy: UInt32 = 0b10 // 2
    static let Player:   UInt32 = 0b100 // 4
}


/// Juego al estilo 1942
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let motionManager = CMMotionManager()
    var xAcceleration = CGFloat(0)
    
    /// Avión del Jugador
    let plane = SKSpriteNode(imageNamed: "Avion")
    let smokeTrail = SKEmitterNode(fileNamed: "smokeTrail")!
    
    /// Cargar el atlas del terreno
    let terrainAtlas = SKTextureAtlas(named:"terreno.atlas")
    
    
    
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        backgroundColor = UIColor(red: 0.42, green: 0.58, blue: 0.26, alpha: 1)
        
        physicsWorld.contactDelegate = self
        
        /* Avión */
        plane.position = CGPoint(x: size.width/2, y: 20 + plane.size.height)
        plane.zPosition = 100
        
        addChild(plane)
        
        createShadow(tipo: "Avion")
        
        setupPlayer()
        setupCoreMotion()
        
        smokeTrail.position = CGPoint(x:plane.position.x, y: 20 + plane.position.y - (plane.size.height/2))
        smokeTrail.zPosition = 10
        smokeTrail.targetNode = self
        addChild(smokeTrail)

        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run(spawnTerrain),
                               SKAction.wait(forDuration: 1.0)])))
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run(spawnEnemy),
                               SKAction.wait(forDuration: 1.0)])))
        
    }
    
    /**
      # Creación de la sombra
     En esta función adicionamos la sombra al avión, tomando la imagen y aplicandole un factor de blend en el Color.
     
      - parameter tipo: Identifica hacia que lado esta girado el avión. [left, right, normal]
     */
    func createShadow(tipo:String){
        let planeShadow = SKSpriteNode(imageNamed: tipo)
        planeShadow.color = SKColor.black
        planeShadow.colorBlendFactor = 1
        planeShadow.alpha = 0.1
        planeShadow.setScale(0.7)
        
        planeShadow.position = CGPoint(x: 70, y: -100)
        planeShadow.zPosition = -1
        planeShadow.name = "shadow"
        
        plane.addChild(planeShadow)
    }
    
    // TODO: Incluir formas de juego del AppleTV, ya que no soporta CoreMotion
    
    func setupCoreMotion() {
        motionManager.accelerometerUpdateInterval = 0.2
        let queue = OperationQueue()
        motionManager.startAccelerometerUpdates(to: queue, withHandler:
        {
        accelerometerData, error in
        guard let accelerometerData = accelerometerData else {
        return
        }
        let acceleration = accelerometerData.acceleration
        self.xAcceleration = (CGFloat(acceleration.x) * 0.75) + (self.xAcceleration * 0.25)
        })
    }
    
    // MARK: Actualización del Jugador
    
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
                createShadow(tipo: "Avion-right")
            } else if ((xAcceleration * 1000.0) < -50) {
                plane.texture = SKTexture(imageNamed: "Avion-left")
                plane.removeAllChildren()
                createShadow(tipo: "Avion-left")
            } else {
                plane.texture = SKTexture(imageNamed: "Avion")
                plane.removeAllChildren()
                createShadow(tipo: "Avion")
            }
    }
    
    func setupPlayer() {
        plane.physicsBody = SKPhysicsBody(circleOfRadius:plane.size.width * 0.3)
        plane.physicsBody!.isDynamic = true
        plane.physicsBody!.allowsRotation = false
        plane.physicsBody!.categoryBitMask = PhysicsCategory.Player
        plane.physicsBody!.collisionBitMask = PhysicsCategory.None
        plane.physicsBody!.affectedByGravity = false
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        updatePlayer()
    }

// MARK: Enemigos y Terreno
    func spawnTerrain(){

        let range: Range<Int> = 1..<6
        let itemStyle = randomInRange(range: range)
        
        let terrainItem = SKSpriteNode(texture:terrainAtlas.textureNamed("terrain-\(itemStyle)"))
        terrainItem.anchorPoint = CGPoint.zero
        terrainItem.position = CGPoint(x: random(min: 0, max:size.width-terrainItem.size.width) , y: size.height)
        
        addChild(terrainItem)
        
//        
//        terrainItem.zPosition = (CGFloat(itemStyle+1) * 2.0)

        let actionMove = SKAction.moveBy(x: 0, y: -size.height-terrainItem.size.height, duration: 7.0)
        let actionRemove = SKAction.removeFromParent()
        
        terrainItem.run(SKAction.sequence([actionMove,actionRemove]))
        
    }
    
    func spawnEnemy(){
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        
        let enemyBodyTexture = SKTexture(imageNamed: "enemy-outline")
        enemy.physicsBody = SKPhysicsBody(texture: enemyBodyTexture, size:enemyBodyTexture.size())
        enemy.physicsBody!.isDynamic = true
        enemy.physicsBody!.categoryBitMask = PhysicsCategory.Enemy
        enemy.physicsBody!.collisionBitMask = PhysicsCategory.None
        enemy.physicsBody!.affectedByGravity = false
        
        
        enemy.zPosition = random(min: 90.0, max: 110.0)

        enemy.position = CGPoint(x: random(min: 0+enemy.size.width, max:size.width-enemy.size.width) , y: size.height + enemy.size.height)

        addChild(enemy)
        
        // Path
        
        let enemyPath = CGMutablePath()
        
        //ControlPoints
        
        let cp1x = random(min: 0+enemy.size.width, max:size.width-enemy.size.width)
        let cp1y = random(min: 0+enemy.size.height, max:size.height-enemy.size.height)
        
        let cp2x = random(min: 0+enemy.size.width, max:size.width-enemy.size.width)
        let cp2y = random(min: 0, max:cp1y)
        
        let xEnd = random(min: 0+enemy.size.width, max:size.width-enemy.size.width)
        
    
        enemyPath.move(to: CGPoint(x: enemy.position.x, y: enemy.position.y))
        enemyPath.addCurve(to: CGPoint(x: xEnd, y: -enemy.size.height), control1: CGPoint(x: cp1x, y: cp1y), control2: CGPoint(x: cp2x, y: cp2y))

        let followPath = SKAction.follow(enemyPath, asOffset: false, orientToPath: true, duration: 3.0)
        let actionRemove = SKAction.removeFromParent()

        enemy.run(SKAction.sequence([followPath,actionRemove]))
    }
    
// MARK: Touches - Proyectiles
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let bullet = SKSpriteNode(imageNamed: "Bullet")
        bullet.name = "bullet"
    
        bullet.physicsBody = SKPhysicsBody(rectangleOf:bullet.size)
        bullet.physicsBody!.isDynamic = true
        bullet.physicsBody!.categoryBitMask = PhysicsCategory.Bullet
        bullet.physicsBody!.collisionBitMask = PhysicsCategory.None
        bullet.physicsBody!.affectedByGravity = false
    
        bullet.physicsBody!.contactTestBitMask = PhysicsCategory.Enemy
    
        bullet.position = CGPoint(x: plane.position.x, y: plane.position.y+plane.size.height/2)
        
        bullet.zPosition = 80
    
        run(SKAction.playSoundFileNamed("Shoot.wav", waitForCompletion: false))
    
        addChild(bullet)
        
        let actionMove = SKAction.moveTo(y: size.height+bullet.size.height, duration: 2)
        let actionRemove = SKAction.removeFromParent()
        
        bullet.run(SKAction.sequence([actionMove,actionRemove]))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {

        var enemyBody: SKPhysicsBody
        
        // Verificar cual es el enemigo.
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            enemyBody = contact.bodyB
        } else {
            enemyBody = contact.bodyA
        }
        
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if collision == PhysicsCategory.Enemy | PhysicsCategory.Bullet {
            run(SKAction.playSoundFileNamed("Explosion.wav", waitForCompletion: false))
            
            explosion(pos: (enemyBody.node?.position)!)
        
            if contact.bodyA.node?.name != nil {
               contact.bodyA.node!.removeFromParent()
            }
            if contact.bodyB.node?.name != nil {
                contact.bodyB.node!.removeFromParent()
            }
        }
        
    }

    func explosion(pos: CGPoint) {
        let exploxionEffect = SKEmitterNode(fileNamed: "ExplosionParticle.sks")!
        exploxionEffect.position = pos
        exploxionEffect.zPosition = 50
        addChild(exploxionEffect)
        
        run(SKAction.wait(forDuration: 2), completion: { exploxionEffect.removeFromParent() })
    }

// MARK: Utilidades

    func randomInRange(range: Range<Int>) -> Int {
        let count = UInt32(range.endIndex - range.startIndex)
        return  Int(arc4random_uniform(count)) + range.startIndex
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(UInt32.max))
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        assert(min < max)
        return random() * (max - min) + min
    }
}
