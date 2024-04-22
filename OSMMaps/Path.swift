//
//  Path.swift
//  OSMMaps
//
//  Created by Manuel Baumgartner on 29/02/2016.
//  Copyright © 2016 FH Hagenberg. All rights reserved.
//

import Foundation
import UIKit
/**
 The path class supports both polygons and polylines.
 It contains all the points in an array and stores the current bounds.
 - Author: Manuel Baumgartner
 */
class Path {
    var points = [CGPoint]()
    var top = CGFloat(0)
    var left = CGFloat(0)
    var right = CGFloat(0)
    var bottom = CGFloat(0)
    /**
     * Extend the current path by adding a new point.
     * The new bounds are calculated automatically.
     - Parameter point:  point The new point.
     */
    func addPoint(point : CGPoint) {
        if(points.count == 0) {
            top = point.y
            bottom = point.y
            left = point.x
            right = point.x
        } else {
            if(point.x < left) {
                left = point.x
            }
            if(point.y < top) {
                top = point.y
            }
            if(point.x > right) {
                right = point.x
            }
            if(point.y > bottom) {
                bottom = point.y
            }
        }
        points.append(point)
    }
    
    /**
     Get the bounds as CGRect object.
     - Returns: the CGRect bounds
     */
    func bounds() -> CGRect {
        return CGRect(x:left, y:top, width:right-left, height:bottom-top)
    }
    /**
     Add a new point in Int32 format
     - Parameter x:  the x coordiante
     - Parameter y:  the y coordinate
     */
    func addPoint(x:Int32, y:Int32) {
        addPoint(CGPoint(x: Int(x), y: Int(y)))
    }
    /**
     Apply a transformation matrix on the path.
     - Parameter matrix:  The current transformation matrix.
     */
    func applyMatrix(matrix : Matrix) {
        for var i = 0; i < points.count; i++ {
            points[i] = matrix.multiply(points[i])
        }
    }
    /**
     Draw the path on the given canvas with the given context.
     - Parameter context:  the drawing context
     - Parameter canvas:  the drawing canvas
     */
    func draw(context : CGContext, canvas : CGRect) {
        if points.count > 1 {
            var pathStarted = false
            CGContextBeginPath(context)
            var lastPoint = CGPoint(x: 8000, y: 8000)
            for var i = 0; i < points.count - 1; i++ {
                let point = points[i]
                if(canvas.contains(point)) {
                    if(pathStarted) {
                        if(abs(point.x - lastPoint.x) + abs(point.y - lastPoint.y) >= 5.0) {
                                lastPoint = point
                                CGContextAddLineToPoint(context, point.x, point.y)
                        }
                    } else {
                        CGContextMoveToPoint(context, point.x, point.y)
                        pathStarted = true
                        lastPoint = point
                    }
                }
            }
            if(pathStarted && canvas.contains(points[points.count-1])) {
                CGContextAddLineToPoint(context, points[points.count - 1].x, points[points.count - 1].y)
            }
            CGContextStrokePath(context)
        }
    }
}
