//
//  TcpClientMessageBlockView.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 27/11/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit
import Foundation

class TcpClientMessageBlockView: UIView {
    
    //MARK: - Variables
    var imageName:String?{
        didSet{
            self.resizeSelf()
        }
    }
    var isleftAligned:Bool = true{
        didSet{
            if isleftAligned == true
            {
                isRightAligned = false
            }
        }
    }
    var isRightAligned:Bool = false{
        didSet{
            if isRightAligned == true{
                isleftAligned = false
            }
        }
    }
    var messageBlockRightAlignedBackgroundColor = UIColor.greenColor()
    var messageBlockLeftAlignedBackgroundColor = UIColor.whiteColor()
    var messageBlockCenterAlignedBackgroundColor = UIColor.darkGrayColor()
    
    var messageBlockRightAlignedForegroundColor = UIColor.blackColor()
    var messageBlockLeftAlignedForegroundColor = UIColor.blackColor()
    var messageBlockCenterAlignedForegroundColor = UIColor.whiteColor()
    var message:String?{
        didSet{
            self.resizeSelf()
        }
    }
    
    lazy var paragraphStyle:NSMutableParagraphStyle = {
        let pStyle = NSMutableParagraphStyle.init()
        pStyle.alignment = NSTextAlignment.Left
        return pStyle
    }()
    
    var messageFont:UIFont{
        get{
            if self.isleftAligned
            {
                return UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            }
            else if self.isRightAligned{
                return UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            }
            else{
                return UIFont.systemFontOfSize(16)
            }
        }
    }
    
    //MARK: -private variables
    private var attributedMessage:NSAttributedString?{
        get{
            if let msg = message{
                var foregroundColor = UIColor.blackColor()
                
                if isleftAligned{
                    foregroundColor = messageBlockLeftAlignedForegroundColor
                    paragraphStyle.alignment = .Left
                }
                else if isRightAligned{
                    foregroundColor = messageBlockRightAlignedForegroundColor
                    paragraphStyle.alignment = .Left
                }
                else {
                    foregroundColor = messageBlockCenterAlignedForegroundColor
                    paragraphStyle.alignment = .Center
                }
                let attributedText = NSAttributedString.init(
                    string: msg,
                    attributes: [
                        NSParagraphStyleAttributeName:paragraphStyle,
                        NSFontAttributeName:messageFont,
                        NSForegroundColorAttributeName: foregroundColor,
                        NSStrokeColorAttributeName:foregroundColor,
                        NSStrokeWidthAttributeName:0]
                    
                )
                return attributedText
            }
            else
            {
                return nil
            }
        }
    }
    
    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.init(white: 1, alpha: 0)
        
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.init(white: 1, alpha: 0)
    }
    
    //MARK: - Drawing related
    func resizeSelf()->CGSize{
        //print("[resizeSelf called]")
        var msgHeight:CGFloat?
        var iconHeight:CGFloat?
        
        if imageName != nil{
            iconHeight = self.bounds.size.width * (DRAWING_CONSTANTS.ICON_SIZE_MULTIPLIER + DRAWING_CONSTANTS.VERTICAL_PADDING_MULTIPLIER)
        }
        if message != nil{
            if let attributedMsg = attributedMessage{
                let msgRect:CGRect = attributedMsg.boundingRectWithSize(
                    CGSize.init(width: self.bounds.size.width * DRAWING_CONSTANTS.MESSAGE_BLOCK_WIDTH_MULTIPLIER - DRAWING_CONSTANTS.MESSAGE_BLOCK_INNER_PADDING * 2,
                        height: 10000),
                    options: [NSStringDrawingOptions.UsesLineFragmentOrigin, NSStringDrawingOptions.UsesFontLeading], context: nil)
                msgHeight =  msgRect.size.height + ( (imageName == nil) ? 0 : (self.bounds.size.height * DRAWING_CONSTANTS.VERTICAL_PADDING_MULTIPLIER + DRAWING_CONSTANTS.MESSAGE_BLOCK_INNER_PADDING * 2.5) )
            }
        }

        if msgHeight != nil && iconHeight != nil{
            self.bounds.size.height =  iconHeight! > msgHeight! ? iconHeight! : msgHeight!
            //print("case 1: \(self.bounds.size)")
            //print("iconHeight: \(iconHeight!) msgHeight: \(msgHeight!)")
            self.setNeedsDisplay()
        }
        else if msgHeight != nil{
            self.bounds.size.height =  msgHeight!
            //print("case 2: \(self.bounds.size)")
            //print("msgHeight: \(msgHeight!)")
            self.setNeedsDisplay()
        }
        else if iconHeight != nil{
            self.bounds.size.height = iconHeight!
            //print("case 3: \(self.bounds.size)")
            //print("iconHeight: \(iconHeight!)")
            self.setNeedsDisplay()
        }
        self.bounds.size = CGSize(width: ceil(self.bounds.size.width) , height: ceil(self.bounds.size.height))
        //print("resizeSelf: \(self.bounds.size)")
        return self.bounds.size
    }
    private struct DRAWING_CONSTANTS{
        static let ICON_SIZE_MULTIPLIER:CGFloat                     = 0.1
        static let VERTICAL_PADDING_MULTIPLIER:CGFloat              = 0.05
        static let HORIZTONAL_PADDING_MULTIPLIER:CGFloat            = 0.025
        static let MESSAGE_BLOCK_WIDTH_MULTIPLIER:CGFloat           = 0.7
        static let MESSAGE_BLOCK_HEIGHT_MULTIPLIER:CGFloat          = 0.95
        static let VIEW_CORNER_RADIUS:CGFloat                       = 5.0
        static let FONT_SCALE_MULTIPLIER:CGFloat                    = 0.04
        static let MESSAGE_BLOCK_INNER_PADDING:CGFloat              = 10
    }
    func drawImage(imageName:String, var inRect imageRect:CGRect)
    {
        imageRect = CGRect(x: ceil(imageRect.origin.x), y: ceil(imageRect.origin.y), width: ceil(imageRect.size.width), height: ceil(imageRect.size.height))
        if let gContext:CGContextRef = UIGraphicsGetCurrentContext()
        {
            CGContextSaveGState(gContext)
            let roundedRectPath = UIBezierPath(roundedRect: imageRect, cornerRadius: DRAWING_CONSTANTS.VIEW_CORNER_RADIUS)
            roundedRectPath.addClip()
            UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0).setFill()
            UIRectFill(imageRect)
            UIImage(named: imageName)?.drawInRect(imageRect)
            CGContextRestoreGState(gContext)
        }
    }
    func drawTrianglePointerForImageRect(imageRect:CGRect, withhorizontalPadding horizontalPadding:CGFloat)
    {
        var trianglePath:UIBezierPath?
        if isleftAligned{
            let firstCorner = CGPoint(
                x: ceil(imageRect.origin.x + imageRect.size.width + horizontalPadding + 1),
                y: ceil(imageRect.origin.y + (imageRect.size.height / 2.0) - (horizontalPadding / 2.0)))
            let secondCorner = CGPoint(
                x: ceil(imageRect.origin.x + imageRect.size.width + horizontalPadding + 1),
                y: ceil(imageRect.origin.y + (imageRect.size.height / 2.0) + (horizontalPadding / 2.0)))
            let thirdCorner = CGPoint(
                x: ceil(imageRect.origin.x + imageRect.size.width + (horizontalPadding * 0.1)),
                y: ceil(imageRect.origin.y + (imageRect.size.height / 2.0)))
            trianglePath = UIBezierPath()
            trianglePath?.moveToPoint(firstCorner)
            trianglePath?.addLineToPoint(secondCorner)
            trianglePath?.addLineToPoint(thirdCorner)
            trianglePath?.closePath()
        }
        else if isRightAligned{
            let firstCorner = CGPoint(
                x: ceil(imageRect.origin.x - horizontalPadding - 1),
                y: ceil(imageRect.origin.y + (imageRect.size.height / 2.0) - (horizontalPadding / 2.0)))
            let secondCorner = CGPoint(
                x: ceil(imageRect.origin.x - horizontalPadding - 1),
                y: ceil(imageRect.origin.y + (imageRect.size.height / 2.0) + (horizontalPadding / 2.0)))
            let thiredCorner = CGPoint(
                x: ceil(imageRect.origin.x - (horizontalPadding * 0.1)),
                y: ceil(imageRect.origin.y + (imageRect.size.height / 2.0)))
            trianglePath = UIBezierPath()
            trianglePath?.moveToPoint(firstCorner)
            trianglePath?.addLineToPoint(secondCorner)
            trianglePath?.addLineToPoint(thiredCorner)
            trianglePath?.closePath()
        }
        if let path = trianglePath{
            if let gContext:CGContextRef = UIGraphicsGetCurrentContext(){
                CGContextSaveGState(gContext)
                path.addClip()
                var backColor:UIColor?
                if isleftAligned{
                    backColor = messageBlockLeftAlignedBackgroundColor
                }
                else if isRightAligned{
                    backColor = messageBlockRightAlignedBackgroundColor
                }
                else{
                    backColor = messageBlockCenterAlignedBackgroundColor
                }
                if backColor != nil{
                    backColor!.setFill()
                }
                path.fill()
                CGContextRestoreGState(gContext)
            }
        }
    }
    func drawMessageBlock(var blockRect blockRect:CGRect, var messageRect:CGRect)
    {
        blockRect = CGRect(x: ceil(blockRect.origin.x), y: ceil(blockRect.origin.y), width: ceil(blockRect.size.width), height: ceil(blockRect.size.height))
        messageRect = CGRect(x: ceil(messageRect.origin.x), y: ceil(messageRect.origin.y), width: ceil(messageRect.size.width), height: ceil(messageRect.size.height))
        //print("drawMessageBlock: \(attributedMessage?.string)")
        //print("blockRect: \(blockRect)")
        //print("messageRect: \(messageRect)")
        if let attriMessage = attributedMessage{
            if let gContext = UIGraphicsGetCurrentContext(){
                CGContextSaveGState(gContext)
                let path = UIBezierPath(roundedRect: blockRect, cornerRadius: DRAWING_CONSTANTS.VIEW_CORNER_RADIUS)
                path.addClip()
                var backColor:UIColor?
                if isleftAligned{
                    backColor = messageBlockLeftAlignedBackgroundColor
                }
                else if isRightAligned{
                    backColor = messageBlockRightAlignedBackgroundColor
                }
                else{
                    backColor = messageBlockCenterAlignedBackgroundColor
                }
                backColor?.setFill()
                path.fill()
                //print("BackColor: \(backColor)")
                attriMessage.drawInRect(messageRect)
                CGContextRestoreGState(gContext)
            }
        }
    }
    func drawViewBorder(rect:CGRect)
    {
        if let gContext = UIGraphicsGetCurrentContext(){
            CGContextSaveGState(gContext)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: DRAWING_CONSTANTS.VIEW_CORNER_RADIUS)
            UIColor.blackColor().setStroke()
            path.stroke()
            CGContextRestoreGState(gContext)
        }
    }
    override func drawRect(rect: CGRect) {
        // Drawing code
        //CGContextSaveGState(UIGraphicsGetCurrentContext())
        //drawViewBorder(rect)
        var imgRect:CGRect?
        var isCenterAligned = false
        if let imgName = imageName{
            if isleftAligned {
                imgRect = CGRect.init(
                    x: rect.origin.x + rect.size.width * DRAWING_CONSTANTS.HORIZTONAL_PADDING_MULTIPLIER,
                    y: rect.origin.y + rect.size.height * DRAWING_CONSTANTS.VERTICAL_PADDING_MULTIPLIER,
                    width: rect.size.width * DRAWING_CONSTANTS.ICON_SIZE_MULTIPLIER,
                    height: rect.size.width * DRAWING_CONSTANTS.ICON_SIZE_MULTIPLIER)
            }
            else if isRightAligned {
                imgRect = CGRect.init(
                    x: rect.size.width - rect.size.width * (DRAWING_CONSTANTS.HORIZTONAL_PADDING_MULTIPLIER + DRAWING_CONSTANTS.ICON_SIZE_MULTIPLIER),
                    y: rect.origin.y + rect.size.height * DRAWING_CONSTANTS.VERTICAL_PADDING_MULTIPLIER,
                    width: rect.size.width * DRAWING_CONSTANTS.ICON_SIZE_MULTIPLIER,
                    height: rect.size.width * DRAWING_CONSTANTS.ICON_SIZE_MULTIPLIER)
            }
            else
            {
                isCenterAligned = true
            }
            if let imageRect = imgRect{
                self.drawImage(imgName, inRect: imageRect)
                drawTrianglePointerForImageRect(imageRect, withhorizontalPadding: rect.size.width * DRAWING_CONSTANTS.HORIZTONAL_PADDING_MULTIPLIER)
            }
        }
        
        if let attriMessage = attributedMessage{
            var messageBlockRect = CGRect(
                x: rect.origin.x + rect.size.width * (DRAWING_CONSTANTS.HORIZTONAL_PADDING_MULTIPLIER * 2 + DRAWING_CONSTANTS.ICON_SIZE_MULTIPLIER ),
                y: rect.origin.y + (isCenterAligned ? 0 : rect.size.height * DRAWING_CONSTANTS.VERTICAL_PADDING_MULTIPLIER),
                width: rect.size.width * DRAWING_CONSTANTS.MESSAGE_BLOCK_WIDTH_MULTIPLIER,
                height: 10000 )
            
            var expectedMsgBlockRect:CGRect = attriMessage.boundingRectWithSize(CGSize(width: (messageBlockRect.size.width - DRAWING_CONSTANTS.MESSAGE_BLOCK_INNER_PADDING * 2), height: 10000), options: [NSStringDrawingOptions.UsesLineFragmentOrigin, NSStringDrawingOptions.UsesFontLeading], context: nil)
            //print("[expectedMsgBlockRect: \(expectedMsgBlockRect)]")
            messageBlockRect.size.height = expectedMsgBlockRect.size.height + (isCenterAligned ? 0 : DRAWING_CONSTANTS.MESSAGE_BLOCK_INNER_PADDING * 2 )
            messageBlockRect.size.width = expectedMsgBlockRect.size.width + DRAWING_CONSTANTS.MESSAGE_BLOCK_INNER_PADDING * 2
            if let imageRect = imgRect{
                if (expectedMsgBlockRect.size.height + DRAWING_CONSTANTS.MESSAGE_BLOCK_INNER_PADDING * 2) < imageRect.size.height{
                    messageBlockRect.size.height = imageRect.size.height
                    expectedMsgBlockRect.size.height = imageRect.size.height - DRAWING_CONSTANTS.MESSAGE_BLOCK_INNER_PADDING * 2
                }
            }
            var realMsgBlockRect: CGRect? //Move the messageRect to correct origin
            if isleftAligned{
                realMsgBlockRect = CGRect(origin: CGPoint(x: messageBlockRect.origin.x + DRAWING_CONSTANTS.MESSAGE_BLOCK_INNER_PADDING, y: messageBlockRect.origin.y + DRAWING_CONSTANTS.MESSAGE_BLOCK_INNER_PADDING), size: expectedMsgBlockRect.size)
            }
            else if isRightAligned{
                if messageBlockRect.size.width < (rect.size.width * DRAWING_CONSTANTS.MESSAGE_BLOCK_WIDTH_MULTIPLIER){
                    realMsgBlockRect = CGRect(origin: CGPoint(x: messageBlockRect.origin.x + (rect.size.width * DRAWING_CONSTANTS.MESSAGE_BLOCK_WIDTH_MULTIPLIER ) - expectedMsgBlockRect.size.width - DRAWING_CONSTANTS.MESSAGE_BLOCK_INNER_PADDING, y: messageBlockRect.origin.y + DRAWING_CONSTANTS.MESSAGE_BLOCK_INNER_PADDING), size: expectedMsgBlockRect.size)
                    messageBlockRect.origin.x = realMsgBlockRect!.origin.x - DRAWING_CONSTANTS.MESSAGE_BLOCK_INNER_PADDING
                }
                else
                {
                    realMsgBlockRect = CGRect(origin: CGPoint(x: messageBlockRect.origin.x + DRAWING_CONSTANTS.MESSAGE_BLOCK_INNER_PADDING, y: messageBlockRect.origin.y + DRAWING_CONSTANTS.MESSAGE_BLOCK_INNER_PADDING), size: expectedMsgBlockRect.size)
                }
            }
            else{
                realMsgBlockRect = CGRect(origin: CGPoint(x: messageBlockRect.origin.x + DRAWING_CONSTANTS.MESSAGE_BLOCK_INNER_PADDING, y: messageBlockRect.origin.y), size: CGSize(width: rect.size.width * DRAWING_CONSTANTS.MESSAGE_BLOCK_WIDTH_MULTIPLIER - DRAWING_CONSTANTS.MESSAGE_BLOCK_INNER_PADDING * 2, height: expectedMsgBlockRect.size.height))
                messageBlockRect.size.width = rect.size.width * DRAWING_CONSTANTS.MESSAGE_BLOCK_WIDTH_MULTIPLIER
                messageBlockRect.size.height = expectedMsgBlockRect.size.height
            }
            if realMsgBlockRect != nil{
                drawMessageBlock(blockRect: messageBlockRect, messageRect: realMsgBlockRect!)
            }
        }
    }
}



















