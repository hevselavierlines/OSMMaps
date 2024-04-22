//
//  Matrix.swift
//  OSMMaps
//
//  Created by Manuel Baumgartner on 12/01/2016.
//  Copyright © 2016 FH Hagenberg. All rights reserved.
//

import Foundation
import UIKit
/**
 All the transformations are performed with a matrix.
 The operations on the matrix are also saved here.
 In general the CGAffineTransform class is used.
 - Author: Manuel Baumgartner
 */
class Matrix {
    var transformMatrix = CGAffineTransform()
    /*
    A C tx
    B D ty
    0 0 1
    */
    /**
     Create a new translate matrix
     - Parameter tx: translation in x direction
     - Parameter ty: translation in y direction
     - Returns: The transformation translation matrix
     */
    static func translate(tx:CGFloat, ty:CGFloat) -> Matrix {
        return Matrix(a: 1, b: 0, c: tx, d: 0, e: 1, f: ty)
    }
    /**
     Create a new scale matrix
     - Parameter sx: scale for the width
     - Parameter sy: scale for the height
     - Returns: The transformation scale matrix
     */
    static func scale(sx:CGFloat, sy:CGFloat) -> Matrix {
        return Matrix(a: sx, b: 0, c: 0, d: 0, e: sy, f: 0)
    }
    /**
     Create a new rotation matrix
     - Parameter _degree: rotation angle in degrees
     - Returns: The transformation rotation matrix
     */
    static func rotate(_degree:CGFloat) -> Matrix {
        let angle = _degree * 0.0174533
        return Matrix(a: cos(angle), b: sin(angle), c: 0, d: -sin(angle), e: cos(angle), f: 0)
    }
    /**
     Create a new rotation matrix with a anchor point.
     - Parameter _degree: rotation angle in degrees
     - Parameter _x: rotation anchor point x coordinate
     - Parameter _y: rotation anchor point y coordiante
     - Returns: The transformation rotation matrix
     */
    static func rotatePoint(_degree:CGFloat, _x:CGFloat, _y:CGFloat) -> Matrix {
        var matrix = Matrix.translate(_x, ty: _y)
        matrix = matrix.multiply(Matrix.rotate(_degree))
        matrix = matrix.multiply(Matrix.translate(-_x, ty: -_y))
        return matrix
    }
    /**
     Create a new reclection matrix on the x-axis
     - Returns: The transformation rotation matrix.
     */
    static func reflectX() -> Matrix {
        return Matrix(a: 1, b: 0, c: 0, d: 0, e: -1, f: 0)
    }
    /**
     Gets the zoom factor in x direction
     - Parameter _map: The map rectangle
     - Parameter _window: The window rectangle
     - Returns: The zoom factor
     */
    static func getZoomFactorX(_map : CGRect, _window: CGRect) -> CGFloat {
        return _window.width / _map.width
    }
    /**
     Gets the zoom factor in y direction
     - Parameter _map: The map rectangle
     - Parameter _window: The window rectangle
     - Returns: The zoom factor
     */
    static func getZoomFactorY(_map : CGRect, _window : CGRect) -> CGFloat {
        return _window.height / _map.height
    }
    /*
    public static Matrix zoomToFit(java.awt.Rectangle _world, java.awt.Rectangle _win) {
    Matrix transM = Matrix.translate(-_world.getCenterX(), -_world.getCenterY());
    CGFloat sc1 = getZoomFactorX(_world, _win);
    CGFloat sc2 = getZoomFactorY(_world, _win);
    CGFloat sc = Math.min(sc1, sc2);
    Matrix scaleM = Matrix.scale(sc);
    Matrix mirror = Matrix.mirrorX();
    Matrix trans2 = Matrix.translate(_win.getCenterX(), _win.getCenterY());
    
    Matrix end = trans2;
    end = end.multiply(mirror);
    end = end.multiply(scaleM);
    end = end.multiply(transM);
    
    return end;
    }
    public static double getZoomFactorX(java.awt.Rectangle _world, java.awt.Rectangle _win) {
    return ((double)_win.width / _world.width);
    }
    
    public static double getZoomFactorY(java.awt.Rectangle _world, java.awt.Rectangle _win) {
    return ((double)_win.height / _world.height);
    }
    */
    /**
     Combined operation to get the matrix that fits the complete map on the screen
     - Parameter _mapBounds: the map rectangle
     - Parameter _windowBounds: the window rectangle
     - Returns: The zoom to fix matrix
     */
    static func zoomToFit(_mapBounds:CGRect, _windowBounds: CGRect) -> Matrix {
        let scale = min(getZoomFactorX(_mapBounds, _window: _windowBounds), getZoomFactorY(_mapBounds, _window: _windowBounds))
        let transM = Matrix.translate(-_mapBounds.width / 2 - _mapBounds.origin.x, ty: -_mapBounds.height / 2 - _mapBounds.origin.y)
        let scaleM = Matrix.scale(scale, sy: scale)
        let mirror = Matrix.reflectX()
        let trans2 = Matrix.translate(_windowBounds.width / 2, ty: _windowBounds.height / 2)
        
        var end = trans2
        end = end.multiply(mirror)
        end = end.multiply(scaleM)
        end = end.multiply(transM)
        return end
    }
    init() {
        transformMatrix = CGAffineTransformIdentity;
    }
    init(_m11:CGFloat, _m12:CGFloat, _m13:CGFloat,
        _m21:CGFloat,_m22:CGFloat,_m23:CGFloat,
        _m31:CGFloat,_m32:CGFloat,_m33:CGFloat) {
            transformMatrix.a = CGFloat(_m11)
            transformMatrix.b = CGFloat(_m21)
            transformMatrix.c = CGFloat(_m12)
            transformMatrix.d = CGFloat(_m22)
            transformMatrix.tx = CGFloat(_m31)
            transformMatrix.ty = CGFloat(_m32)
    }
    /**
     * A B C        A C tx
     * D E F        B D ty
     */
    init(a:CGFloat,b:CGFloat,c:CGFloat,d:CGFloat,e:CGFloat,f:CGFloat) {
        transformMatrix.a = CGFloat(a)
        transformMatrix.b = CGFloat(d)
        transformMatrix.c = CGFloat(b)
        transformMatrix.d = CGFloat(e)
        transformMatrix.tx = CGFloat(c)
        transformMatrix.ty = CGFloat(f)
    }
    init(_cgMatrix:CGAffineTransform) {
        transformMatrix = _cgMatrix
    }
    /**
     Calculates the inverse matrix of the current one.
     - Returns: The inverse matrix as optional (in rarely cases no inverse matrix available)
     */
    func inverse() -> Matrix? {
        let transform2 = CGAffineTransformInvert(transformMatrix)
        return Matrix(_cgMatrix: transform2)
    }
    /**
     Multiplies the current matrix with another one.
     - Parameter _other: the matrix to multiply
     - Returns: The result of the multiplication
     */
    func multiply(_other: Matrix) -> Matrix {
        let a = transformMatrix
        let b = _other.transformMatrix
        var res = CGAffineTransform()
        res.a = a.a * b.a + a.c * b.c + a.tx * 0;
        res.c = a.a * b.c + a.c * b.d + a.tx * 0;
        res.tx = a.a * b.tx + a.c * b.ty + a.tx * 1;
        
        res.b = a.b * b.a + a.d * b.b + a.ty * 0;
        res.d = a.b * b.c + a.d * b.d + a.ty * 0;
        res.ty = a.b * b.tx + a.d * b.ty + a.ty * 1;
        return Matrix(_cgMatrix: res)
    }
    /**
     * Uses the current matrix on a UIBezierPath
     */
    func multiply(_path: UIBezierPath) {
        _path.applyTransform(transformMatrix)
    }
    /**
     * Uses the current matrix on a CGPathRef
     */
    func multiply(_path: CGPathRef) -> CGPathRef {
        return CGPathCreateCopyByTransformingPath(_path, &transformMatrix)!
    }
    /**
     * Uses the current matrix on a CGPoint
     */
    func multiply(_point: CGPoint) -> CGPoint {
        return CGPointApplyAffineTransform(_point, transformMatrix)
    }
    
    /**
     Uses the current matrix on a CGRect
     - Parameter _rect: The source rect
     - Returns: The new transformed rect
     */
    func multiply(_rect: CGRect) -> CGRect {
        return CGRectApplyAffineTransform(_rect, transformMatrix)
    }
    /**
     Gets the current scale.
     - Returns: The scale in 72 DPI.
     */
    func scale() -> CGFloat {
        var rect = CGRectMake(0, 0, 0, 1)
        rect = inverse()!.multiply(rect)
        
        return rect.height * 72.0
    }

}