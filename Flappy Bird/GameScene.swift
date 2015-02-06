//
//  GameScene.swift
//  Flappy Bird
//
//  Created by Yu Andrew - andryu on 1/21/15.
//  Copyright (c) 2015 Andrew Yu. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // constants
    let pipesAndBgMoveSpeed: CGFloat = 100  //pixels per sec
    let gravityVector: CGFloat = -6
    let impulseVector: CGFloat = 50
    
    // bit mask categories
    let birdGroup: UInt32 = 1
    let objectsGroup: UInt32 = 2
    let gapGroup: UInt32 = 4
    
    var gameOver = false
    var score = 0
    
    var bird: SKSpriteNode!
    var ground: SKNode!
    var bg: SKSpriteNode!
    var movingObjects = SKNode()    //includes bg, bird, pipes, gap
    var scoreLabel = SKLabelNode(text: "Score: 0")
    var gameOverLabel = SKLabelNode(text: "Game Over! Tap anywhere to play again!")
    
    override func didMoveToView(view: SKView) {
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0, dy: gravityVector)
        self.addChild(movingObjects)
        setupBackground()
        setupGround()
        setupBird()
        setupPipesAndGap()
        setupScoreLabel()
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        if !gameOver {
            bird.physicsBody?.velocity = CGVectorMake(0, 0)
            bird.physicsBody?.applyImpulse(CGVectorMake(0, impulseVector))
        } else {
            resetGame()
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
    }
    
    // background setup
    func setupBackground() {
        let bgTexture = SKTexture(imageNamed: "bg.png")
        
        let moveBgAction = SKAction.moveByX(-bgTexture.size().width, y: 0, duration: NSTimeInterval(bgTexture.size().width/pipesAndBgMoveSpeed))
        let bringBackBgAction = SKAction.moveByX(bgTexture.size().width, y: 0, duration: 0)
        let moveBgsForeverAction = SKAction.repeatActionForever(SKAction.sequence([moveBgAction, bringBackBgAction]))
        
        for i in 0...2 {
            bg = SKSpriteNode(texture: bgTexture)
            bg.position = CGPoint(x: bgTexture.size().width/2 + bgTexture.size().width * CGFloat(i), y: CGRectGetMidY(self.frame))
            bg.size.height = self.frame.size.height
            
            bg.runAction(moveBgsForeverAction)
            movingObjects.addChild(bg)
        }
    }
    
    // ground setup
    func setupGround() {
        ground = SKNode()
        ground.position = CGPointMake(0, 0)
        ground.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, 1))
        ground.physicsBody?.dynamic = false
        ground.physicsBody?.categoryBitMask = objectsGroup
        
        self.addChild(ground)
    }
    
    // bird setup
    func setupBird() {
        let wingUpTexture = SKTexture(imageNamed: "wing-up.png")
        let wingDownTexture = SKTexture(imageNamed: "wing-down.png")
        
        bird = SKSpriteNode(texture: wingUpTexture)
        bird.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame))
        bird.zPosition = 1
        
        let flapOnceAction = SKAction.animateWithTextures([wingUpTexture, wingDownTexture], timePerFrame: 0.1)
        let flapForeverAction = SKAction.repeatActionForever(flapOnceAction)
        bird.runAction(flapForeverAction)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height/2)
        bird.physicsBody?.dynamic = true
        bird.physicsBody?.allowsRotation = false
        
        bird.physicsBody?.categoryBitMask = birdGroup
        bird.physicsBody?.contactTestBitMask = objectsGroup | gapGroup
        bird.physicsBody?.collisionBitMask = 3
        
        movingObjects.addChild(bird)
    }
    
    // pipes setup
    func setupPipesAndGap() {
        let makeMorePipesAction = SKAction.runBlock() {
            self.setupPairOfPipesWithGap()
        }
        let waitAction = SKAction.waitForDuration(NSTimeInterval(self.frame.size.width/2/pipesAndBgMoveSpeed))
        //let waitAction = SKAction.waitForDuration(4)
        
        movingObjects.runAction(SKAction.repeatActionForever(SKAction.sequence([makeMorePipesAction, waitAction])))
    }
    
    func setupPairOfPipesWithGap() {
        let pipeDownTexture = SKTexture(imageNamed: "pipe-down.png")
        let pipeUpTexture = SKTexture(imageNamed: "pipe-up.png")
        var pipeDown = SKSpriteNode(texture: pipeDownTexture)
        var pipeUp = SKSpriteNode(texture: pipeUpTexture)
        var gap = SKNode()
        
        // suppose neutral Y positions for two pipes are their open ends placed in the center of screen
        // with a gap between two ends
        let gapHeightBetweenTwoPipes = bird.size.height * 4
        let neutralYForPipeDown = pipeDownTexture.size().height/2 + CGRectGetMidY(self.frame) + gapHeightBetweenTwoPipes/2
        let neutralYForPipeUp = -pipeUpTexture.size().height/2 + CGRectGetMidY(self.frame) - gapHeightBetweenTwoPipes/2
        
        // two pipes can be placed up and down 1/4 of screen height from neutral position
        let oneForthScreenHeight = self.frame.size.height * 1/4
        let randomWithinOneForthRange = Int(arc4random_uniform(UInt32(oneForthScreenHeight*2))) - Int(oneForthScreenHeight)
        
        pipeDown.position = CGPoint(x: self.frame.size.width, y: neutralYForPipeDown + CGFloat(randomWithinOneForthRange))
        pipeUp.position = CGPoint(x: self.frame.size.width, y: neutralYForPipeUp + CGFloat(randomWithinOneForthRange))
        gap.position = CGPoint(x: self.frame.size.width, y: CGRectGetMidY(self.frame) + CGFloat(randomWithinOneForthRange))

        let moveRightToLeftAction = SKAction.moveByX(-self.frame.size.width * 2, y: 0, duration: NSTimeInterval(self.frame.size.width*2/pipesAndBgMoveSpeed))
        let removeAction = SKAction.removeFromParent()
        let moveAndRemoveActions = SKAction.sequence([moveRightToLeftAction, removeAction])
        pipeDown.runAction(moveAndRemoveActions)
        pipeUp.runAction(moveAndRemoveActions)
        gap.runAction(moveAndRemoveActions)
        
        pipeDown.physicsBody = SKPhysicsBody(rectangleOfSize: pipeDown.size)
        pipeDown.physicsBody?.dynamic = false
        pipeDown.physicsBody?.categoryBitMask = objectsGroup
        
        pipeUp.physicsBody = SKPhysicsBody(rectangleOfSize: pipeUp.size)
        pipeUp.physicsBody?.dynamic = false
        pipeUp.physicsBody?.categoryBitMask = objectsGroup
        
        gap.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: pipeUp.size.width, height: gapHeightBetweenTwoPipes))
        gap.physicsBody?.dynamic = false
        gap.physicsBody?.categoryBitMask = gapGroup
        
        movingObjects.addChild(pipeDown)
        movingObjects.addChild(pipeUp)
        movingObjects.addChild(gap)
    }
    
    // scoreLabel setup
    func setupScoreLabel() {
        scoreLabel.fontName = "HelveticaNeue-Bold"
        scoreLabel.fontColor = UIColor.whiteColor()
        scoreLabel.fontSize = 30
        scoreLabel.position = CGPoint(x: 380, y: self.frame.height-40)
        scoreLabel.zPosition = 1
        self.addChild(scoreLabel)
    }
    
    // SKPhysicsContactDelegate methods
    func didBeginContact(contact: SKPhysicsContact) {
        // game over
        if contact.bodyA.categoryBitMask != gapGroup && contact.bodyB.categoryBitMask != gapGroup {
            if !gameOver {
                gameOver = true
                movingObjects.speed = 0
                setupGameOverLabel()
            }
        }
    }
    
    // gameOverLabel setup
    func setupGameOverLabel() {
        gameOverLabel.fontName = "HelveticaNeue-Bold"
        gameOverLabel.fontColor = UIColor.whiteColor()
        gameOverLabel.fontSize = 20
        gameOverLabel.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame))
        gameOverLabel.zPosition = 2
        self.addChild(gameOverLabel)
    }
    
    func didEndContact(contact: SKPhysicsContact) {
        // add point to score
        if contact.bodyA.categoryBitMask == gapGroup || contact.bodyB.categoryBitMask == gapGroup {
            if !gameOver {
                score++
                scoreLabel.text = "Score: \(score)"
            }
        }
    }
    
    // game reset
    func resetGame() {
        gameOver = false
        score = 0
        scoreLabel.text = "Score: 0"
        gameOverLabel.removeFromParent()
        movingObjects.removeAllChildren()
        setupBird()
        setupBackground()
        movingObjects.speed = 1
    }
}
