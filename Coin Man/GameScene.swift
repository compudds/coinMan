//
//  GameScene.swift
//  Coin Man
//
//  Created by zappycode on 6/14/17.
//  Copyright © 2017 Nick Walter. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var coinMan : SKSpriteNode?
    var sound : SKSpriteNode?
    //var soundCoin : SKSpriteNode?
    var soundOn : SKSpriteNode?
    var soundOff : SKSpriteNode?
    var coinTimer : Timer?
    var coin2Timer : Timer?
    var bombTimer : Timer?
    var ceil : SKSpriteNode?
    var scoreLabel : SKLabelNode?
    var yourScoreLabel : SKLabelNode?
    var finalScoreLabel : SKLabelNode?
    var highScoreLabel : SKLabelNode?
    var gameOverNumber = 0
    var speakerOn = 1
    var speakerOnLabel : SKLabelNode?
    
    var touchPositionX = Int()
    var touchPositionY = Int()
    
    let coinManCategory : UInt32 = 0x1 << 1
    let coinCategory : UInt32 = 0x1 << 2
    let coin2Category : UInt32 = 0x1 << 3
    let bombCategory : UInt32 = 0x1 << 4
    let groundAndCeilCategory : UInt32 = 0x1 << 5
    
    var score = 0
    var highScore = 0
    var previousHighScore = 0
    
    var player: AVAudioPlayer?
    
    func playCoinSound() {
        
        guard let url = Bundle.main.url(forResource: "coin", withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let player = player else { return }
            
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func playBombSound() {
        
        guard let url = Bundle.main.url(forResource: "bomb", withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let player = player else { return }
            
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        
        print("Game Over Number: \(gameOverNumber)")
        
        let mute = SKSpriteNode(imageNamed: "mute")
        mute.physicsBody?.affectedByGravity = false
        mute.name = "mute1"
        mute.position = CGPoint(x: 0, y: 610)
        addChild(mute)
        
        soundOff = childNode(withName: "mute1") as? SKSpriteNode
        
        let speaker = SKSpriteNode(imageNamed: "speaker")
        speaker.physicsBody?.affectedByGravity = false
        speaker.name = "speaker1"
        speaker.position = CGPoint(x: 0, y: 610)
        addChild(speaker)
        
        soundOn = childNode(withName: "speaker1") as? SKSpriteNode
        
        touchSpeaker()
        
        coinMan = childNode(withName: "coinMan") as? SKSpriteNode
        coinMan?.physicsBody?.categoryBitMask = coinManCategory
        coinMan?.physicsBody?.contactTestBitMask = coinCategory | bombCategory | coin2Category
        coinMan?.physicsBody?.collisionBitMask = groundAndCeilCategory
        var coinManRun : [SKTexture] = []
        for number in 1...5 {
            coinManRun.append(SKTexture(imageNamed: "frame-\(number)"))
        }
        coinMan?.run(SKAction.repeatForever(SKAction.animate(with: coinManRun, timePerFrame: 0.09)))
        
        ceil = childNode(withName: "ceil") as? SKSpriteNode
        ceil?.physicsBody?.categoryBitMask = groundAndCeilCategory
        ceil?.physicsBody?.collisionBitMask = coinManCategory
        
        scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode
        highScoreLabel = childNode(withName: "highScoreLabel") as? SKLabelNode
        speakerOnLabel = childNode(withName: "speakerOn") as? SKLabelNode
        
        let defaults = UserDefaults.standard
        if let high = defaults.string(forKey: defaultsKeys.keyOne) {
            print(high) // Some String Value
            previousHighScore = Int(high)!
            highScore = previousHighScore
            highScoreLabel?.text = "High: \(previousHighScore)"
            
        }
        
        //restartGame()
        startTimers()
        createGrass()
        
    }
    
    func createGrass() {
        let sizingGrass = SKSpriteNode(imageNamed: "grass")
        let numberOfGrass = Int(size.width / sizingGrass.size.width) + 1
        for number in 0...numberOfGrass {
            let grass = SKSpriteNode(imageNamed: "grass")
            grass.physicsBody = SKPhysicsBody(rectangleOf: grass.size)
            grass.physicsBody?.categoryBitMask = groundAndCeilCategory
            grass.physicsBody?.collisionBitMask = coinManCategory
            grass.physicsBody?.affectedByGravity = false
            grass.physicsBody?.isDynamic = false
            addChild(grass)
            
            let grassX = -size.width / 2 + grass.size.width / 2 + grass.size.width * CGFloat(number)
            grass.position = CGPoint(x: grassX, y: -size.height / 2 + grass.size.height / 2 - 18)
            let speed = 100.0
            let firstMoveLeft = SKAction.moveBy(x: -grass.size.width - grass.size.width * CGFloat(number), y: 0, duration: TimeInterval(grass.size.width + grass.size.width * CGFloat(number)) / speed)
            
            let resetGrass = SKAction.moveBy(x: size.width + grass.size.width, y: 0, duration: 0)
            let grassFullMove = SKAction.moveBy(x: -size.width - grass.size.width, y: 0, duration: TimeInterval(size.width + grass.size.width) / speed)
            let grassMovingForver = SKAction.repeatForever(SKAction.sequence([grassFullMove,resetGrass]))
            
            grass.run(SKAction.sequence([firstMoveLeft,resetGrass,grassMovingForver]))
        }
    }
    
    func startTimers() {
        coinTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            self.createCoin()
        })
        
        coin2Timer = Timer.scheduledTimer(withTimeInterval: 7, repeats: true, block: { (timer) in
            self.createCoin2()
        })
        
        bombTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { (timer) in
            self.createBomb()
        })
    }
    
    func restartGame() {
        
        if scene?.isPaused == false {
            coinMan?.physicsBody?.applyForce(CGVector(dx: 0, dy: 100_000))
        }
        
        score = 0
        //node.removeFromParent()
        finalScoreLabel?.removeFromParent()
        yourScoreLabel?.removeFromParent()
        scene?.isPaused = false
        scoreLabel?.text = "Score: \(score)"
        startTimers()
        gameOverNumber = 0
        print("Game Over Number: \(gameOverNumber)")
    }
    
    func touchSpeaker() {  //touch: CGPoint) {
        
        print("Touch Position: \(touchPositionX), \(touchPositionY)")
        
        if (touchPositionX >= 170 && touchPositionX <= 200 && touchPositionY >= 80 && touchPositionY <= 110) {
            
            print("Speaker On \(speakerOn)")
            
            if speakerOn == 1 {
                
                speakerOn = 0
                
                soundOff!.alpha = 1
                
                soundOn!.alpha = 0
                
                speakerOnLabel?.text = "Off"
                
            } else {
                
                speakerOn = 1
                
                soundOn!.alpha = 1
                
                soundOff!.alpha = 0
                
                speakerOnLabel?.text = "On"
                
            }
            
        }
        
        if speakerOn == 1 {
            
            soundOn!.alpha = 1
            
            soundOff!.alpha = 0
            
            speakerOnLabel?.text = "On"
            
        } else {
            
            soundOff!.alpha = 1
            
            soundOn!.alpha = 0
            
            speakerOnLabel?.text = "Off"
            
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        let touch = touches.first
        
        let position = touch!.location(in: view)
        let fromx = Int(position.x)
        let fromy = Int(position.y)
        touchPositionX = fromx
        touchPositionY = fromy
        
        touchSpeaker()
        
        if scene?.isPaused == false {
            coinMan?.physicsBody?.applyForce(CGVector(dx: 0, dy: 100_000))
            
        }
        
        
        if let location = touch?.location(in: self) {
            let theNodes = nodes(at: location)
            
            for node in theNodes {
                if node.name == "play" {
                    // Restart the game
                    score = 0
                    node.removeFromParent()
                    finalScoreLabel?.removeFromParent()
                    yourScoreLabel?.removeFromParent()
                    scene?.isPaused = false
                    scoreLabel?.text = "Score: \(score)"
                    startTimers()
                    gameOverNumber = 0
                    touchSpeaker()
                }
            }
        }
        
        print("Game Over Number: \(gameOverNumber)")
        
    }
    
    func createCoin() {
        let coin = SKSpriteNode(imageNamed: "coin")
        coin.physicsBody = SKPhysicsBody(rectangleOf: coin.size)
        coin.physicsBody?.affectedByGravity = false
        coin.physicsBody?.categoryBitMask = coinCategory
        coin.physicsBody?.contactTestBitMask = coinManCategory
        coin.physicsBody?.collisionBitMask = 0
        addChild(coin)
        
        let sizingGrass = SKSpriteNode(imageNamed: "grass")
        
        let maxY = size.height / 2 - coin.size.height / 2
        let minY = -size.height / 2 + coin.size.height / 2 + sizingGrass.size.height
        let range = maxY - minY
        let coinY = maxY - CGFloat(arc4random_uniform(UInt32(range)))
        
        coin.position = CGPoint(x: size.width / 2 + coin.size.width / 2, y: coinY)
        
        let moveLeft = SKAction.moveBy(x: -size.width - coin.size.width, y: 0, duration: 4)
        
        coin.run(SKAction.sequence([moveLeft, SKAction.removeFromParent()]))
    }
    
    func createCoin2() {
        let coin2 = SKSpriteNode(imageNamed: "coin2")
        coin2.physicsBody = SKPhysicsBody(rectangleOf: coin2.size)
        coin2.physicsBody?.affectedByGravity = false
        coin2.physicsBody?.categoryBitMask = coin2Category
        coin2.physicsBody?.contactTestBitMask = coinManCategory
        coin2.physicsBody?.collisionBitMask = 0
        addChild(coin2)
        
        let sizingGrass = SKSpriteNode(imageNamed: "grass")
        
        let maxY = size.height / 2 - coin2.size.height / 2
        let minY = -size.height / 2 + coin2.size.height / 2 + sizingGrass.size.height
        let range = maxY - minY
        let coinY = maxY - CGFloat(arc4random_uniform(UInt32(range)))
        
        coin2.position = CGPoint(x: size.width / 2 + coin2.size.width / 2, y: coinY)
        
        let moveLeft = SKAction.moveBy(x: -size.width - coin2.size.width, y: 0, duration: 2)
        
        coin2.run(SKAction.sequence([moveLeft, SKAction.removeFromParent()]))
    }
    
    func createBomb() {
        let bomb = SKSpriteNode(imageNamed: "bomb")
        bomb.physicsBody = SKPhysicsBody(rectangleOf: bomb.size)
        bomb.physicsBody?.affectedByGravity = false
        bomb.physicsBody?.categoryBitMask = bombCategory
        bomb.physicsBody?.contactTestBitMask = coinManCategory
        bomb.physicsBody?.collisionBitMask = 0
        addChild(bomb)
        
        let sizingGrass = SKSpriteNode(imageNamed: "grass")
        
        let maxY = size.height / 2 - bomb.size.height / 2
        let minY = -size.height / 2 + bomb.size.height / 2 + sizingGrass.size.height
        let range = maxY - minY
        let bombY = maxY - CGFloat(arc4random_uniform(UInt32(range)))
        
        bomb.position = CGPoint(x: size.width / 2 + bomb.size.width / 2, y: bombY)
        
        let moveLeft = SKAction.moveBy(x: -size.width - bomb.size.width, y: 0, duration: 4)
        
        bomb.run(SKAction.sequence([moveLeft, SKAction.removeFromParent()]))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        
        if contact.bodyA.categoryBitMask == coinCategory {
            contact.bodyA.node?.removeFromParent()
            if self.speakerOn == 1 {
                playCoinSound()
            }
            score += 1
            scoreLabel?.text = "Score: \(score)"
            
        }
        if contact.bodyB.categoryBitMask == coinCategory {
            contact.bodyB.node?.removeFromParent()
            if self.speakerOn == 1 {
                playCoinSound()
            }
            score += 1
            scoreLabel?.text = "Score: \(score)"
            
        }
        
        if contact.bodyA.categoryBitMask == coin2Category {
            contact.bodyA.node?.removeFromParent()
            if self.speakerOn == 1 {
                playCoinSound()
            }
            score += 5
            scoreLabel?.text = "Score: \(score)"
            
        }
        if contact.bodyB.categoryBitMask == coin2Category {
            contact.bodyB.node?.removeFromParent()
            if self.speakerOn == 1 {
                playCoinSound()
            }
            score += 5
            scoreLabel?.text = "Score: \(score)"
            
        }
        
        if contact.bodyA.categoryBitMask == bombCategory {
            contact.bodyA.node?.removeFromParent()
            gameOver()
            
        }
        if contact.bodyB.categoryBitMask == bombCategory {
            contact.bodyB.node?.removeFromParent()
            gameOver()
            
        }
        
        
    }
    
    func gameOver() {
        
        gameOverNumber = 1
        
        if self.speakerOn == 1 {
            playBombSound()
        }
        
        scene?.isPaused = true
        
        coinTimer?.invalidate()
        coin2Timer?.invalidate()
        bombTimer?.invalidate()
        
        yourScoreLabel = SKLabelNode(text: "Your Score:")
        yourScoreLabel?.position = CGPoint(x: 0, y: 200)
        yourScoreLabel?.fontSize = 100
        yourScoreLabel?.zPosition = 1
        if yourScoreLabel != nil {
            addChild(yourScoreLabel!)
        }
        
        finalScoreLabel = SKLabelNode(text: "\(score)")
        finalScoreLabel?.position = CGPoint(x: 0, y: 0)
        finalScoreLabel?.fontSize = 200
        finalScoreLabel?.zPosition = 1
        if finalScoreLabel != nil {
            addChild(finalScoreLabel!)
            
            if highScore == 0 {
                
                if score > highScore {
                    let defaults = UserDefaults.standard
                    defaults.set("\(score)", forKey: defaultsKeys.keyOne)
                    highScoreLabel?.text = "High: \(score)"
                }
                
            } else {
                
                if score > previousHighScore {
                    let defaults = UserDefaults.standard
                    defaults.set("\(score)", forKey: defaultsKeys.keyOne)
                    highScoreLabel?.text = "High: \(score)"
                }
                
            }
            
            
            
        }
        
        let playButton = SKSpriteNode(imageNamed: "play")
        playButton.position = CGPoint(x: 0, y: -200)
        playButton.name = "play"
        playButton.zPosition = 1
        addChild(playButton)
        
        print("Game Over Number: \(gameOverNumber)")
        
    }

    struct defaultsKeys {
        static let keyOne = "high"
    }
    
}
