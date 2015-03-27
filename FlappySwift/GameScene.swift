//
//  GameScene.swift
//  FlappySwift
//
//  Created by Sean Livingston on 3/26/15.
//  Copyright (c) 2015 Sean Livingston. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    let totalGroundPieces = 5
    
    var groundPieces = [SKSpriteNode]()
    let groundSpeed: CGFloat = 3.5
    var moveObstacleAction: SKAction!
    var moveGroundForeverAction: SKAction!
    let groundResetXCoord: CGFloat = -164
    
    var bird: SKSpriteNode!
    var birdAtlas = SKTextureAtlas(named: "bird")
    var birdFrames = [SKTexture]()
    
    // Simulated jumping physics
    var isJumping = false
    var touchDetected = false
    var jumpStartTime: CGFloat = 0.0
    var jumpCurrentTime: CGFloat = 0.0
    var jumpEndTime: CGFloat = 0.0
    let jumpDuration: CGFloat = 0.35
    let jumpVelocity: CGFloat = 500.0
    var currentVelocity: CGFloat = 0.0
    var jumpInertiaTime: CGFloat!
    var fallInertiaTime: CGFloat!
    
    // Obstacles
    var tikis = [SKNode]()
    let heightBetweenObstacles = 907
    let timeBetweenObstacles = 3.0
    let bottomtikiMaxYPos = 308
    let bottomtikiMinYPos = -76
    let tikiXStartPos: CGFloat = 830
    let tikiXDestroyPos: CGFloat = -187
    var moveObstacleForeverAction: SKAction!
    var tikiTimer: NSTimer!
    
    // Collision categories
    let category_bird: UInt32 = 1 << 0
    let category_ground: UInt32 = 1 << 1
    let category_tiki: UInt32 = 1 << 2
    let category_score: UInt32 = 1 << 3
    
    // Delta Time
    var lastUpdateTimeInterval: CFTimeInterval = -1.0
    var deltaTime: CGFloat = 0.0
    
    
    override func didMoveToView(view: SKView) {
        initSetup()
        setupScenery()
        setupBird()
        startGame()
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        touchDetected = true
        isJumping = true
        
        
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        groundMovement()
        
        // Calculate the Delta Time
        deltaTime = CGFloat(currentTime - lastUpdateTimeInterval)
        lastUpdateTimeInterval = currentTime
        
        // Prevents problems with an anomoly that occurs when Delta Time is too long - Apple does the same thing in their code
        
        if deltaTime > 1 {
            
            deltaTime = 1.0 / 60.0
            lastUpdateTimeInterval = currentTime
        }
        
        if touchDetected {
            touchDetected = false
            jumpStartTime = CGFloat(currentTime)
            currentVelocity = jumpVelocity
        }
        
        if isJumping {
            
            // How long have we been jumping
            var currentDuration = CGFloat(currentTime) - jumpStartTime
            
            // Time to end the jump
            if currentDuration >= jumpDuration {
                isJumping = false
                jumpEndTime = CGFloat(currentTime)
            } else {
                /* Rotate the bird to a certain euler angle over a certain period of time */
                if bird.zRotation < 0.5 {
                    bird.zRotation += 2.0 * CGFloat(deltaTime)
                }
                
                // Move the bird up
                bird.position = CGPointMake(bird.position.x, bird.position.y + (currentVelocity * CGFloat(deltaTime)))
                
                // We don't decrease velocity until after the initial jump inertia has taken place
                
                if CGFloat(currentDuration) > jumpInertiaTime {
                    currentVelocity -= (currentVelocity * CGFloat(deltaTime)) * 2
                }
            }
        } else {
            // Rotate the bird to a certain euler angle over a certain period of time
            if bird.zRotation > -1.0 {
                bird.zRotation -= 2.0 * CGFloat(deltaTime)
            }
            
            // Move the bird down
            bird.position = CGPointMake(bird.position.x, bird.position.y - (currentVelocity * CGFloat(deltaTime)))
            
            // Only start increasing velocity after floating for a little bit
            if CGFloat(currentTime) - jumpEndTime > fallInertiaTime {
                currentVelocity += currentVelocity * CGFloat(deltaTime)
            }
        }
        
    }
    
    func initSetup() {
        jumpInertiaTime = CGFloat(jumpDuration) * 0.7
        fallInertiaTime = CGFloat(jumpDuration) * 0.3
        moveObstacleAction = SKAction.moveByX(-groundSpeed, y: 0, duration: 0.02)
        
        moveObstacleForeverAction = SKAction.repeatActionForever(SKAction.sequence([moveObstacleAction]))
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0)
    }
    
    func setupScenery() {
        var bg = SKSpriteNode(imageNamed: "sky")
        bg.position = CGPointMake(bg.size.width / 2, bg.size.height / 2)
        self.addChild(bg)
        
        var hills = SKSpriteNode(imageNamed: "hills")
        hills.position = CGPointMake(hills.size.width / 2 , 300)
        self.addChild(hills)
        
        // Add groud sprites
        for var x = 0; x < totalGroundPieces; x++ {
            var sprite = SKSpriteNode(imageNamed: "groundpiece")
            sprite.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
            sprite.physicsBody?.dynamic = false
            sprite.physicsBody?.categoryBitMask = category_ground
            sprite.zPosition = 5
            self.addChild(sprite)
//            var sprite = SKSpriteNode(imageNamed: "groundpiece")
//            groundPieces.append(sprite)
//            
//            var wSpacing = sprite.size.width / 2
//            var hSpacing = sprite.size.height / 2
//            
//            if x == 0 {
//                sprite.position = CGPointMake(wSpacing, hSpacing)
//            } else {
//                sprite.position = CGPointMake((wSpacing * 2) + groundPieces[x - 1].position.x, groundPieces[x - 1].position.y)
//            }
//            
//            self.addChild(sprite)
        }
    }
    
    func setupBird() {
        var totalImgs = birdAtlas.textureNames.count
        
        for var x = 1; x < totalImgs; x++ {
            var textureName = "bird-0\(x)"
            var texture = birdAtlas.textureNamed(textureName)
            birdFrames.append(texture)
        }
        
        bird = SKSpriteNode(texture: birdFrames[0])
        self.addChild(bird)
        bird.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
        bird.runAction(SKAction.repeatActionForever(SKAction.animateWithTextures(birdFrames, timePerFrame: 0.2, resize: false, restore: true)))
    }
    
    func startGame() {
        for sprite in groundPieces {
            sprite.runAction(moveGroundForeverAction)
        }
    }
    
    func groundMovement() {
        for var x = 0; x < groundPieces.count; x++ {
            if groundPieces[x].position.x <= groundResetXCoord {
                if x != 0 {
                    groundPieces[x].position = CGPointMake(groundPieces[x - 1].position.x + groundPieces[x].size.width, groundPieces[x].position.y)
                } else {
                    groundPieces[x].position = CGPointMake(groundPieces[groundPieces.count - 1].position.x + groundPieces[x].size.width, groundPieces[x].position.y)
                }
            }
        }
    }
    
    func createTikiSet(time: NSTimer) {
        var tikiSet = SKNode()
        
        // We want to pick a random tiki graphic
        var rand = arc4random() % (3 - 1 + 1) + 1
        var spriteName = "tiki-bottom-0\(rand)"
        
        // Setup tikis and score collider
        var bottomTiki = SKSpriteNode(imageNamed: spriteName)
        tikiSet.addChild(bottomTiki)
        var yPos = Int(arc4random()) % (bottomtikiMaxYPos - bottomtikiMinYPos)
        bottomTiki.position = CGPointMake(0, CGFloat(yPos))
        bottomTiki.physicsBody = SKPhysicsBody(rectangleOfSize: bottomTiki.size)
        bottomTiki.physicsBody?.dynamic = false
        bottomTiki.physicsBody?.categoryBitMask = category_tiki
        bottomTiki.physicsBody?.contactTestBitMask = category_bird
        
        // Top Tiki
        spriteName = "tiki-top-0\(rand)"
        var topTiki = SKSpriteNode(imageNamed: spriteName)
        topTiki.position = CGPointMake(0, bottomTiki.position.y + CGFloat(heightBetweenObstacles))
        tikiSet.addChild(topTiki)
        topTiki.physicsBody = SKPhysicsBody(rectangleOfSize: topTiki.size)
        topTiki.physicsBody?.dynamic = false
        topTiki.physicsBody?.categoryBitMask = category_tiki
        topTiki.physicsBody?.contactTestBitMask = category_bird
        
        tikis.append(tikiSet)
        tikiSet.zPosition = 4
        tikiSet.runAction(moveObstacleForeverAction)
        self.addChild(tikiSet)
        tikiSet.position = CGPointMake(tikiXStartPos, tikiSet.position.y)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
