//
//  GameScene.swift
//  FlappyBird
//
//  Created by pmst on 15/10/4.
//  Copyright (c) 2015年 pmst. All rights reserved.
//

import SpriteKit

enum 图层: CGFloat {
    //设置从里到外
    case 背景
    case 障碍物    //障碍物在背景和前景的中间夹着
    case 前景
    case 游戏角色
}

enum 游戏状态 {
    case 主菜单
    case 教程
    case 游戏
    case 跌落
    case 显示分数
    case 结束
}

struct 物理层 {
    static let 无: UInt32        = 0
    static let 游戏角色: UInt32 = 0b1  //1
    static let 障碍物: UInt32  = 0b10  //2
    static let 地面: UInt32   = 0b100  //4
}

class GameScene: SKScene, SKPhysicsContactDelegate{//遵守碰撞协议
    
    let k前景地面数 = 2
    let k地面移动速度: CGFloat = -150.0//地面左右移动的速度
    let k底部障碍最小乘数: CGFloat = 0.1
    let k底部障碍最大乘数: CGFloat = 0.6
    let k缺口参数: CGFloat = 3.5
    
    let k首次生成障碍延迟: NSTimeInterval = 1.75
    let k每次重生障碍延迟: NSTimeInterval = 1.5
    
    let 世界单位 = SKNode()
    var 游戏区域起始点: CGFloat = 0
    var 游戏区域的高度: CGFloat = 0
    let 主角 = SKSpriteNode(imageNamed: "Bird0")
    let 帽子 = SKSpriteNode(imageNamed: "Sombrero")
    
    var 上一次更新时间: NSTimeInterval = 0
    var dt: NSTimeInterval = 0
    
    //
    let k重力: CGFloat = -1500.0  //每秒钟下降1500个像素
    var 速度 = CGPoint.zero
    var k上冲速度: CGFloat = 400.0
    
    var 撞击了地面: Bool = false
    var 撞击了障碍物: Bool = false
    var 当前游戏状态: 游戏状态 = .游戏
    
    //获取声音
    // MARK: - 音乐
    let dingAction = SKAction.playSoundFileNamed("ding.wav", waitForCompletion: false)
    let flapAction = SKAction.playSoundFileNamed("flapping.wav", waitForCompletion: false)
    let whackAction = SKAction.playSoundFileNamed("whack.wav", waitForCompletion: false)
    let fallingAction = SKAction.playSoundFileNamed("falling.wav", waitForCompletion: false)
    let hitGroundAction = SKAction.playSoundFileNamed("hitGround.wav", waitForCompletion: false)
    let popAction = SKAction.playSoundFileNamed("pop.wav", waitForCompletion: false)
    let coinAction = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)

    /**
     连续///自动为函数添加注释
     
     - parameter view: <#view description#>
     */
    override func didMoveToView(view: SKView) {
        //关掉系统重力，使用自己的重力系统,要不然他会自动接管游戏的重力
        physicsWorld.gravity = CGVectorMake(0, 0)
        
        //设置碰撞代理
        physicsWorld.contactDelegate  = self
        addChild(世界单位)
        设置背景()
        设置前景()
        设置主角()
        设置帽子()
        无限重生障碍()
    }
    
    //MARK: 设置相关方法
    func 设置背景() {
        let 背景 = SKSpriteNode(imageNamed: "Background")
        背景.anchorPoint = CGPoint(x: 0.5,y:1.0) //中心点位置
        背景.position = CGPoint(x: size.width/2, y: size.height)
        背景.zPosition = 图层.背景.rawValue
        世界单位.addChild(背景)
        
        游戏区域起始点 = size.height - 背景.size.height
        游戏区域的高度 = 背景.size.height
        
        //生成地面的碰撞体积,背景的左下点，右下点就是地面
        let 左下 = CGPoint(x: 0, y: 游戏区域起始点)
        let 右下 = CGPoint(x: size.width, y: 游戏区域起始点)
        
        self.physicsBody = SKPhysicsBody(edgeFromPoint: 左下, toPoint: 右下)
        self.physicsBody?.categoryBitMask = 物理层.地面
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.contactTestBitMask = 物理层.游戏角色
    }
    
    func 设置主角() {
        主角.position = CGPoint(x: size.width*0.2, y: 游戏区域的高度*0.4+游戏区域起始点)
        主角.zPosition = 图层.游戏角色.rawValue  //为图层添加元素
        
        //为主角添加碰撞体积
        let offsetX = 主角.size.width * 主角.anchorPoint.x
        let offsetY = 主角.size.height * 主角.anchorPoint.y
        
        let path = CGPathCreateMutable()
        
        CGPathMoveToPoint(path, nil, 4 - offsetX, 15 - offsetY)
        CGPathAddLineToPoint(path, nil, 12 - offsetX, 23 - offsetY)
        CGPathAddLineToPoint(path, nil, 14 - offsetX, 23 - offsetY)
        CGPathAddLineToPoint(path, nil, 21 - offsetX, 29 - offsetY)
        CGPathAddLineToPoint(path, nil, 34 - offsetX, 29 - offsetY)
        CGPathAddLineToPoint(path, nil, 39 - offsetX, 25 - offsetY)
        CGPathAddLineToPoint(path, nil, 39 - offsetX, 14 - offsetY)
        CGPathAddLineToPoint(path, nil, 37 - offsetX, 7 - offsetY)
        CGPathAddLineToPoint(path, nil, 34 - offsetX, 2 - offsetY)
        CGPathAddLineToPoint(path, nil, 24 - offsetX, 1 - offsetY)
        CGPathAddLineToPoint(path, nil, 11 - offsetX, 1 - offsetY)
        CGPathAddLineToPoint(path, nil, 5 - offsetX, 1 - offsetY)
        
        CGPathCloseSubpath(path)
        
        主角.physicsBody = SKPhysicsBody(polygonFromPath: path)
        主角.physicsBody?.categoryBitMask = 物理层.游戏角色
        主角.physicsBody?.collisionBitMask = 0
        主角.physicsBody?.contactTestBitMask = 物理层.障碍物 | 物理层.地面  //主角可能会碰撞到的物体
        世界单位.addChild(主角)
    }
    
    func 设置前景() {
        //通过循环添加多个前景，模拟出小鸟一直在飞行的效果
        for i in 0..<k前景地面数 {
            let 前景 = SKSpriteNode(imageNamed: "Ground")
            前景.anchorPoint = CGPoint(x: 0, y: 1.0)
            //当i为0时，前景在屏幕，当i为1时，前景被已到了屏幕的外边
            前景.position = CGPoint(x: CGFloat(i) * 前景.size.width, y: 游戏区域起始点)
            前景.zPosition = 图层.前景.rawValue
            
            前景.name = "前景"
            世界单位.addChild(前景)//将前景添加到世界单位中去
        }
        
    }
    
    func 设置帽子() {
        帽子.position = CGPoint(x: 31-帽子.size.width/2, y: 29-帽子.size.height/2)
        主角.addChild(帽子)
    }
    
    //游戏流程
    func 创建障碍物(图片名: String) -> SKSpriteNode {
        let 障碍物 = SKSpriteNode(imageNamed: 图片名)
        障碍物.zPosition = 图层.障碍物.rawValue
        
        //为障碍物添加碰撞体积
        let offsetX = 障碍物.size.width * 障碍物.anchorPoint.x
        let offsetY = 障碍物.size.height * 障碍物.anchorPoint.y
        
        let path = CGPathCreateMutable()
        
        CGPathMoveToPoint(path, nil, 5 - offsetX, 308 - offsetY)
        CGPathAddLineToPoint(path, nil, 49 - offsetX, 308 - offsetY)
        CGPathAddLineToPoint(path, nil, 51 - offsetX, 278 - offsetY)
        CGPathAddLineToPoint(path, nil, 49 - offsetX, 210 - offsetY)
        CGPathAddLineToPoint(path, nil, 46 - offsetX, 117 - offsetY)
        CGPathAddLineToPoint(path, nil, 46 - offsetX, 61 - offsetY)
        CGPathAddLineToPoint(path, nil, 47 - offsetX, 2 - offsetY)
        CGPathAddLineToPoint(path, nil, 4 - offsetX, 2 - offsetY)
        
        CGPathCloseSubpath(path)
        
        障碍物.physicsBody = SKPhysicsBody(polygonFromPath: path)
        障碍物.physicsBody?.categoryBitMask = 物理层.障碍物
        障碍物.physicsBody?.collisionBitMask = 0
        障碍物.physicsBody?.contactTestBitMask = 物理层.游戏角色  //他可能碰到的只有游戏角色
        return 障碍物
    }
    
    func 生成障碍() {//障碍的初始位置
        let 底部障碍 = 创建障碍物("CactusBottom")
        let 起始X坐标 = size.width + 底部障碍.size.width/2
        
        let Y坐标最小值 = (游戏区域起始点 - 底部障碍.size.height/2) + 游戏区域的高度 * k底部障碍最小乘数
        let Y坐标最大值 = (游戏区域起始点 - 底部障碍.size.height/2) + 游戏区域的高度 * k底部障碍最大乘数

        底部障碍.position = CGPointMake(起始X坐标, CGFloat.random(min: Y坐标最小值, max:  Y坐标最大值))
        底部障碍.name = "顶部障碍"
        世界单位.addChild(底部障碍)
        
        let 顶部障碍 = 创建障碍物("CactusTop")
        顶部障碍.zRotation = CGFloat(180).degreesToRadians()
        顶部障碍.position = CGPoint(x: 起始X坐标, y: 底部障碍.position.y + 底部障碍.size.height/2 + 顶部障碍.size.height/2 + 主角.size.height * k缺口参数)
        顶部障碍.name = "顶部障碍"
        世界单位.addChild(顶部障碍)
        
        let X轴移动距离 = -(size.width + 底部障碍.size.width)
        let 移动持续时间 = X轴移动距离 / k地面移动速度
        
        let 移动的动作队列 = SKAction.sequence([
            SKAction.moveByX(X轴移动距离, y: 0, duration: NSTimeInterval(移动持续时间)),
            SKAction.removeFromParent()
            ])
        顶部障碍.runAction(移动的动作队列)
        底部障碍.runAction(移动的动作队列)
    }
    
    func 无限重生障碍() {
        let 首次延迟 = SKAction.waitForDuration(k首次生成障碍延迟)
        let 重生障碍 = SKAction.runBlock(生成障碍)//函数作为参数，这样的写法仅仅试用于没有参数的函数
        let 每次重生间隔 = SKAction.waitForDuration(k每次重生障碍延迟)
        
        let 重生的动作队列 = SKAction.sequence([重生障碍,每次重生间隔])
        let 无限重生 = SKAction.repeatActionForever(重生的动作队列)
        
        let 总得动作队列 = SKAction.sequence([首次延迟,无限重生])
        runAction(总得动作队列, withKey: "重生")
    }
    
    func 停止重生障碍() {
        removeActionForKey("重生")
        
        世界单位.enumerateChildNodesWithName("顶部障碍", usingBlock: { 匹配单位, _ in
            匹配单位.removeAllActions()
        })
        世界单位.enumerateChildNodesWithName("底部障碍", usingBlock: { 匹配单位, _ in
            匹配单位.removeAllActions()
        })
    }
    
    func 主角飞一下() {
        速度 = CGPoint(x: 0, y: k上冲速度)
    }
    //当用户点击屏幕的时候会触发
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        runAction(flapAction)
        
        switch 当前游戏状态 {
        case .主菜单:
            break
        case .教程:
            break
        case .显示分数:
            break
        case .游戏:
            主角飞一下()
            break
        case .结束:
            break
        case .跌落:
            break
        }
        
        //模拟帽子上下翻飞的效果
        let 向上移动 = SKAction.moveByX(0, y: 12, duration: 0.15)
        向上移动.timingMode = .EaseInEaseOut  //淡入淡出效果
        let 向下移动 = 向上移动.reversedAction()  //向上移动的反向，直接用这个方法
        帽子.runAction(SKAction.sequence([向上移动,向下移动]))
    }
    
    //MARK: GENGXI,每隔一段时间自动更新主角数据
    override func update(当前时间: CFTimeInterval) {
        /* Called before each frame is rendered */
        if 上一次更新时间 > 0 {
            dt = 当前时间 - 上一次更新时间
        }else {
            dt = 0
        }
        上一次更新时间 = 当前时间//更新  上一次更新时间
        
        //根据当前所处的游戏状态来坐相应的操作
        switch 当前游戏状态 {
        case .主菜单:
            break
        case .教程:
            break
        case .显示分数:
            break
        case .游戏:
            更新主角()
            更新前景()
            撞击障碍物检查()
            撞击地面检查()
            break
        case .结束:
            break
        case .跌落:
            更新主角()
            撞击地面检查()
            break
        }
    }
    
    func 更新主角() {
        let 加速度 = CGPoint(x: 0, y: k重力)//只有y轴上有加速度，x轴上没有
        速度 = 速度 + 加速度 * CGFloat(dt)
        主角.position = 主角.position + 速度 * CGFloat(dt)//更新主角位置
        
        //检测主角撞击地面
        if 主角.position.y - 主角.size.height/2 < 游戏区域起始点 {
            主角.position = CGPoint(x: 主角.position.x, y: 游戏区域起始点 + 主角.size.height/2)
        }
    }
    
    func 更新前景() {
        世界单位.enumerateChildNodesWithName("前景", usingBlock: {匹配单位, _ in
            if let 前景 = 匹配单位 as? SKSpriteNode {
                let 地面移动速度 = CGPoint(x: self.k地面移动速度, y: 0)
                前景.position += 地面移动速度 * CGFloat(self.dt)
                
                if 前景.position.x < -前景.size.width {//前景已经完全移出了屏幕
                    前景.position += CGPoint(x: 前景.size.width * CGFloat(self.k前景地面数), y: 0)//把前景移到x轴两倍位置处
                }
            }
        })
    }
    
    
    func 撞击障碍物检查() {
        if 撞击了障碍物 {
            撞击了障碍物 = false
            切换到跌落状态()
        }
    }
    
    func 撞击地面检查() {
        if 撞击了地面 {
            撞击了地面 = false
            速度 = CGPoint.zero
            主角.zRotation = CGFloat(-90).degreesToRadians() //撞击后旋转90度
            主角.position = CGPoint(x: 主角.position.x, y: 游戏区域起始点+主角.size.width/2)  //由于转了90度，原来的高就是现在的宽度
            runAction(hitGroundAction)//撞击地面音效
            切换到显示分数状态()
        }
    }
    
    //MARK: 游戏状态
    func 切换到跌落状态() {
        当前游戏状态 = .跌落
        
        runAction(SKAction.sequence([
            //摔倒的音效
            whackAction,
            SKAction.waitForDuration(0.1),
            //跌落的音效
            fallingAction,
            ]))
        主角.removeAllActions()
        停止重生障碍()
    }
    
    //显示分数
    func 切换到显示分数状态() {
        当前游戏状态 = .显示分数
        主角.removeAllActions()
        停止重生障碍()
    }
    
    //MARK: 物理引擎，碰撞代理,代理跟接口差不多，继承接口，可以使用里面的方法，自己随意更改
    func didBeginContact(碰撞双方: SKPhysicsContact) {
        //被撞对象只有两个,一个是地面，一个是柱子对应bodyA,bodyB
        let 被撞对象 = 碰撞双方.bodyA.categoryBitMask == 物理层.游戏角色 ? 碰撞双方.bodyB : 碰撞双方.bodyA
        
        if 被撞对象.categoryBitMask == 物理层.地面 {
            撞击了地面 = true
        }
        if 被撞对象.categoryBitMask == 物理层.障碍物 {
            撞击了障碍物 = true
        }
    }
    
}
