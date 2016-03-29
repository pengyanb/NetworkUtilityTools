//
//  TcpClientMessageBlockBehavior.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 27/11/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit

class TcpClientMessageBlockBehavior: UIDynamicBehavior {
    private var isPullingLeft = false
    private var isPullingRight = false
    private lazy var gravity : UIGravityBehavior = {
        let lazilyCreatedGravity = UIGravityBehavior()
        lazilyCreatedGravity.angle = CGFloat.init((-1) * M_PI / 2.0)
        return lazilyCreatedGravity
    }()
    
    /*
    private lazy var pullLeftGravity : UIGravityBehavior = {
        let lazilyCreatedGravity = UIGravityBehavior()
        lazilyCreatedGravity.angle = CGFloat.init(M_PI)
        return lazilyCreatedGravity
    }()
    
    private lazy var pullRightGravity : UIGravityBehavior = {
        let lazilyCreatedGravity = UIGravityBehavior()
        lazilyCreatedGravity.angle = CGFloat.init(0)
        return lazilyCreatedGravity
    }()*/
    
    private lazy var collider : UICollisionBehavior = {
        let lazilyCreatedCollider = UICollisionBehavior()
        //lazilyCreatedCollider.translatesReferenceBoundsIntoBoundary = true
        return lazilyCreatedCollider
    }()
    private lazy var messageBlockBehvior : UIDynamicItemBehavior = {
        let lazilyCreatedMessageBlockBehvior = UIDynamicItemBehavior()
        lazilyCreatedMessageBlockBehvior.allowsRotation = false
        lazilyCreatedMessageBlockBehvior.elasticity = 0.2
        lazilyCreatedMessageBlockBehvior.friction = 0
        lazilyCreatedMessageBlockBehvior.resistance = 0
        return lazilyCreatedMessageBlockBehvior
    }()
    override init() {
        super.init()
        addChildBehavior(gravity)
        addChildBehavior(collider)
        addChildBehavior(messageBlockBehvior)
        isPullingLeft = false
        isPullingRight = false
    }
    func addBarrier(path: UIBezierPath, named name:String){
        collider.removeBoundaryWithIdentifier(name)
        collider.addBoundaryWithIdentifier(name, forPath: path)
    }
    func addMessageBlock(messageBlock: UIView){
        dynamicAnimator?.referenceView?.addSubview(messageBlock)
        gravity.addItem(messageBlock)
        collider.addItem(messageBlock)
        messageBlockBehvior.addItem(messageBlock)
        /*
        if isPullingLeft{
            pullLeftGravity.addItem(messageBlock)
        }
        if isPullingRight{
            pullRightGravity.addItem(messageBlock)
        }*/
    }
    func removeMessageBlock(messageBlock:UIView){
        gravity.removeItem(messageBlock)
        collider.removeItem(messageBlock)
        messageBlockBehvior.removeItem(messageBlock)
        /*
        if isPullingLeft{
            pullLeftGravity.removeItem(messageBlock)
        }
        if isPullingRight{
            pullRightGravity.removeItem(messageBlock)
        }*/
        //messageBlock.removeFromSuperview()
    }
}










