//
//  Renderer.swift
//  PDF Test
//
//  Created by Stephen Gerstacker on 2022-09-09.
//

import Foundation
import QuartzCore

#if os(macOS)
import AppKit
typealias NativeColor = NSColor
typealias NativeFont = NSFont
typealias NativeImage = NSImage
#else
import UIKit
typealias NativeColor = UIColor
typealias NativeFont = UIFont
typealias NativeImage = UIImage
#endif

class Renderer {
    
    private let contextBounds = CGRect(x: 0.0, y: 0.0, width: 576.0, height: 700.0)
    private var remainingFrame: CGRect
    
    private var isDrawingFlipped: Bool = false
    private var isTextFlipped: Bool = false

    init() {
        remainingFrame = contextBounds.insetBy(dx: 36.0, dy: 36.0)
    }
    
    func renderPDF() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test.pdf")
        
        var mediaBox = contextBounds
        let attributes = [
            kCGPDFContextAuthor: "Stephen H. Gerstacker",
            kCGPDFContextTitle: "Some Stuff",
            kCGPDFContextCreator: "Some App"
        ]
        
        let context = CGContext(url as CFURL, mediaBox: &mediaBox, attributes as CFDictionary)!
        
        context.beginPDFPage(nil)
        
        isDrawingFlipped = true
        isTextFlipped = true
        
        draw(in: context)
        
        context.endPDFPage()
        context.closePDF()
        
        return url
    }
    
    #if os(macOS)
    func renderImage() -> NSImage {
        let image = NSImage(size: contextBounds.size)
        
        image.lockFocus()
        
        let context = NSGraphicsContext.current!.cgContext
        context.setFillColor(NativeColor.white.cgColor)
        context.fill(contextBounds)
        
        isDrawingFlipped = true
        isTextFlipped = true
        
        draw(in: context)
        
        image.unlockFocus()
        
        return image
    }
    #else
    func renderImage() -> UIImage {
        UIGraphicsBeginImageContext(contextBounds.size)
        
        let context = UIGraphicsGetCurrentContext()!
        
        context.setFillColor(NativeColor.white.cgColor)
        context.fill(contextBounds)
        
        isDrawingFlipped = false
        isTextFlipped = true
        
        draw(in: context, isFlipped: false)
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    #endif
    
    private func drawText(_ text: String, font: NativeFont, frame: CGRect, context: CGContext) {
        let textAttributed = NSAttributedString(string: text)
        let textRange = CFRange(location: 0, length: text.count)
        
        let cfText = CFAttributedStringCreateMutableCopy(kCFAllocatorDefault, text.count, textAttributed)!
        CFAttributedStringSetAttribute(cfText, textRange, kCTFontAttributeName, font)
        
        let framesetter = CTFramesetterCreateWithAttributedString(cfText)
        
        let finalFrame: CGRect
        
        if isTextFlipped {
            finalFrame = CGRect(x: frame.origin.x, y: contextBounds.height - frame.origin.y - frame.height, width: frame.width, height: frame.height)
        } else {
            finalFrame = frame
        }
        let path = CGMutablePath()
        path.addRect(finalFrame)
        
        let ctFrame = CTFramesetterCreateFrame(framesetter, textRange, path, nil)
        
        CTFrameDraw(ctFrame, context)
    }
    
    private func measureText(_ text: String, font: NativeFont, maxSize: CGSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)) -> CGSize {
        let textAttributed = NSAttributedString(string: text)
        let textRange = CFRange(location: 0, length: text.count)
        
        let cfText = CFAttributedStringCreateMutableCopy(kCFAllocatorDefault, text.count, textAttributed)!
        CFAttributedStringSetAttribute(cfText, textRange, kCTFontAttributeName, font)
        
        let framesetter = CTFramesetterCreateWithAttributedString(cfText)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, textRange, nil, maxSize, nil)
        
        return size
    }
    
    private func draw(in context: CGContext, isFlipped: Bool = false) {
        let font = NativeFont.boldSystemFont(ofSize: 24.0)
        
        // Fill in the remaining frame
        drawing(context) {
            context.setFillColor(NativeColor.systemYellow.cgColor)
            context.fill(contextBounds)
            
            context.setFillColor(NativeColor.lightGray.cgColor)
            context.fill(remainingFrame)
            
            context.setStrokeColor(NativeColor.gray.cgColor)
            context.setLineDash(phase: 5.0, lengths: [5.0])
            context.strokeLineSegments(between: [CGPoint(x: contextBounds.minX, y: contextBounds.midY), CGPoint(x: contextBounds.maxX, y: contextBounds.midY)])
            
            context.setStrokeColor(NativeColor.gray.cgColor)
            context.setLineDash(phase: 5.0, lengths: [5.0])
            context.strokeLineSegments(between: [CGPoint(x: contextBounds.midX, y: contextBounds.minY), CGPoint(x: contextBounds.midX, y: contextBounds.maxY)])
        }
        
        // Draw top text and frame
        let topText = "Top Texting"
        let topTextSize = measureText(topText, font: font)
        let topTextFrame = CGRect(origin: remainingFrame.origin, size: topTextSize)
        
        textRendering(context) {
            drawText(topText, font: font, frame: topTextFrame, context: context)
        }
        
        drawing(context) {
            context.setStrokeColor(NativeColor.systemRed.cgColor)
            context.stroke(topTextFrame)
        }
        
        // Draw top-right text and frame
        let topRightText = "Top Right Texting"
        let topRightTextSize = measureText(topRightText, font: font)
        let topRightTextFrame = CGRect(x: remainingFrame.midX, y: 0.0, width: topRightTextSize.width, height: topRightTextSize.height)
        
        textRendering(context) {
            drawText(topRightText, font: font, frame: topRightTextFrame, context: context)
        }
        
        drawing(context) {
            context.setStrokeColor(NativeColor.systemGreen.cgColor)
            context.stroke(topRightTextFrame)
        }
        
        // Draw bottom text and frame
        let bottomText = "Bottom Texting"
        let bottomTextSize = measureText(bottomText, font: font)
        let bottomTextFrame = CGRect(x: remainingFrame.minX, y: remainingFrame.maxY - bottomTextSize.height, width: bottomTextSize.width, height: bottomTextSize.height)
        
        textRendering(context) {
            drawText(bottomText, font: font, frame: bottomTextFrame, context: context)
        }
        
        drawing(context) {
            context.setStrokeColor(NativeColor.systemBlue.cgColor)
            context.stroke(bottomTextFrame)
        }
        
        // Draw middle over and frame
        let middleOverText = "Middle Over"
        let middleOverTextSize = measureText(middleOverText, font: font)
        let middleOverTextFrame = CGRect(x: remainingFrame.minX, y: remainingFrame.midY - middleOverTextSize.height, width: middleOverTextSize.width, height: middleOverTextSize.height)
        
        textRendering(context) {
            drawText(middleOverText, font: font, frame: middleOverTextFrame, context: context)
        }
        
        drawing(context) {
            context.setStrokeColor(NativeColor.systemBrown.cgColor)
            context.stroke(middleOverTextFrame)
        }
        
        // Draw middle under and frame
        let middleUnderText = "Middle Under"
        let middleUnderTextSize = measureText(middleUnderText, font: font)
        let middleUnderTextFrame = CGRect(x: remainingFrame.midX, y: remainingFrame.midY, width: middleUnderTextSize.width, height: middleUnderTextSize.height)
        
        textRendering(context) {
            drawText(middleUnderText, font: font, frame: middleUnderTextFrame, context: context)
        }
        
        drawing(context) {
            context.setStrokeColor(NativeColor.systemBrown.cgColor)
            context.stroke(middleUnderTextFrame)
        }
        
        // Draw mutli-line text
        let multilineText = "This is multiline\ntext showing here"
        let multilineTextSize = measureText(multilineText, font: font)
        let multilineTextFrame = CGRect(x: remainingFrame.midX, y: remainingFrame.maxY - multilineTextSize.height, width: multilineTextSize.width, height: multilineTextSize.height)
        
        textRendering(context) {
            drawText(multilineText, font: font, frame: multilineTextFrame, context: context)
        }
        
        drawing(context) {
            context.setStrokeColor(NativeColor.systemCyan.cgColor)
            context.stroke(multilineTextFrame)
        }
    }
    
    private func drawing(_ context: CGContext, block: () -> Void) {
        context.saveGState()
        
        if isDrawingFlipped {
            context.translateBy(x: 0.0, y: contextBounds.height)
            context.scaleBy(x: 1.0, y: -1.0)
        }
        
        block()
        
        context.restoreGState()
    }
    
    private func textRendering(_ context: CGContext, block: () -> Void) {
        context.saveGState()
        
        if !isDrawingFlipped && isTextFlipped {
            context.translateBy(x: 0.0, y: contextBounds.height)
            context.scaleBy(x: 1.0, y: -1.0)
        }
        
        block()
        
        context.restoreGState()
    }
}
