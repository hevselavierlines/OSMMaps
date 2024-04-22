//
//  DrawView.swift
//  OSMMaps
//
//  Created by Manuel Baumgartner on 12/01/2016.
//  Copyright © 2016 FH Hagenberg. All rights reserved.
//

import UIKit
/**
 The view that draws the map on the screen
 - Author: Manuel Baumgartner
 */
class DrawView: UIView {
    var mapElems = [MapElement]()
    var matrix = Matrix()
    var loadAble = false
    var zoom = CGFloat(1)
    var drawRect : CGRect?
    var image = UIImage()
    var imageRect : CGRect?
    var loadPos : CGPoint?
    var origImageRect : CGRect?
    var loadRect : CGRect?
    var loading = false
    var currMap = "malta"
    /**
     Called when the draw is drawn for the first time to avoid nil errors.
     */
    func firstDraw() {
        loadAble = true
        imageRect = nil
        image = drawPicture()
        setNeedsDisplay()
    }
    /**
     Loading a map with the current bounds.
     */
    func loadBounds() {
        var loadRect = CGRect(x: drawRect!.origin.x - 400, y: drawRect!.origin.y - 400, width: drawRect!.size.width + 800, height: drawRect!.size.height + 800)
        loadRect = matrix.inverse()!.multiply(loadRect)
        loadData(currMap, bounds: loadRect)
    }
    
    /**
     Redraws the view by drawing on the image in background queue firstly.
     */
    func redraw() {
        if(!loading) {
            loading = true
            loadBounds()
        }
    }
    /**
     Gets the map bounds for the reset function.
     - Returns: The current map bounds as CGRect
     */
    func getMapBounds() -> CGRect{
        var middle = CGRect()
        if(mapElems.count > 0) {
            middle = mapElems[0].path!.bounds()
            for var i = 1; i < mapElems.count; i++ {
                middle = middle.union(mapElems[i].path!.bounds())
            }
        }
        return middle
    }
    /**
     Moves the loaded image.
     - Parameter px: move x coordinate
     - Parameter py: move y coordinate
     */
    func moveImage(px: CGFloat, py: CGFloat) {
        imageRect?.origin.x += px
        imageRect?.origin.y += py
        
        if(loadPos != nil) {
            loadPos!.x += px
            loadPos!.y += py
        }
    }
    /**
     Translates the map with an affine matrix operation
     - Parameter px: the translation in x direction
     - Parameter py: the translation in y direciton
     */
    func translate(px: CGFloat, py: CGFloat) {
        matrix = Matrix.translate(px, ty: py).multiply(matrix)
        for var i = 0; i < mapElems.count; i++ {
            mapElems[i].path!.applyMatrix(Matrix.translate(px, ty: py))
        }
    }
    /**
     Zooms into the uiimage object that is used for showing the map while a background queue loads the new map.
     - Parameter factor: the zoom factor
     - Parameter around: the zoom hotspot
     */
    func zoomImage(factor: CGFloat, var around: CGPoint) {
        around.x += 400
        around.y += 400
        
        imageRect!.origin = origImageRect!.origin
        imageRect!.size = origImageRect!.size
        if factor > 1 {
            let zoomfac = factor - 1
            imageRect!.origin.x -= (zoomfac / 2) * origImageRect!.width
            imageRect!.origin.y -= (zoomfac / 2) * origImageRect!.height
            imageRect!.size.width += (zoomfac * origImageRect!.width)
            imageRect!.size.height += (zoomfac * origImageRect!.height)
            
        } else {
            let zoomfac = 1 - factor
            imageRect!.origin.x += (zoomfac / 2) * origImageRect!.width
            imageRect!.origin.y += (zoomfac / 2) * origImageRect!.height
            imageRect!.size.width -= (zoomfac * origImageRect!.width)
            imageRect!.size.height -= (zoomfac * origImageRect!.height)
        }
    }
    /**
     Zooms into the uiimage with the centre as hotspot
     - Parameter factor: the zoom factor
     */
    func zoomImage(factor: CGFloat) {
        var centre = CGPoint(x: 0, y: 0)
        if(drawRect != nil) {
            centre = CGPoint(x: drawRect!.width / 2, y: drawRect!.height / 2)
        }
        zoomImage(factor, around:centre)
    }
    /**
     Zooming in the centre of the map.
     - Parameter factor: The added zoom factor
     */
    func zoom(factor: CGFloat) {
        var centre = CGPoint(x: 0, y: 0)
        if(drawRect != nil) {
            centre = CGPoint(x: drawRect!.width / 2, y: drawRect!.height / 2)
        }
        zoom(factor, around:centre)
    }
    /**
     Zooming with an anchor point
     - Parameter factor: The added zoom factor
     - Parameter around: The zooming centre point
     */
    func zoom(factor: CGFloat, var around: CGPoint) {
        around.x += 400
        around.y += 400
        zoom *= factor
        let zoomMatrix = Matrix.translate(around.x, ty: around.y)
                        .multiply(Matrix.scale(factor, sy: factor))
                        .multiply(Matrix.translate(-around.x, ty: -around.y))
        matrix = zoomMatrix.multiply(matrix)
        for var i = 0; i < mapElems.count; i++ {
            mapElems[i].path!.applyMatrix(zoomMatrix)
        }
    }
    /**
     Resets the matrix to show the complete map.
     */
    func reset() {
        let resetMatrix = matrix.inverse()
        for var i = 0; i < mapElems.count; i++ {
            mapElems[i].path!.applyMatrix(resetMatrix!)
        }
        normalise()
    }
    /**
     Get the matrix to show the complete map and apply this matrix.
     */
    func normalise() {
        let mapBounds = getMapBounds()
        let moveMatrix = Matrix.translate(400, ty: 400)
        let ztfMatrix = Matrix.zoomToFit(mapBounds, _windowBounds: UIScreen.mainScreen().bounds)
        matrix = moveMatrix.multiply(ztfMatrix)
        for var i = 0; i < mapElems.count; i++ {
            mapElems[i].path!.applyMatrix(matrix)
            //matrix.multiply(mapElems[i].path!)
        }
        
        zoom = 1
    }
    /**
     Load the map data from the data file.
     - Parameter _mapSource: the map source (filename without .dat)
     - Parameter bounds: The bounding rectangle.
     */
    func loadData(_mapSource : String, bounds : CGRect?) {
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            var nElems = [MapElement]()
            var loadLevel = 1
            if(bounds != nil) {
                if(bounds!.width < 50000) {
                    loadLevel = 4
                } else if(bounds!.width < 100000) {
                    loadLevel = 3
                } else if(bounds!.width < 500000) {
                    loadLevel = 2
                }
            }
            
            let bundle = NSBundle.mainBundle()
            let myFilePath = bundle.pathForResource(_mapSource, ofType: "dat")!
            let inputStream = NSInputStream(fileAtPath: myFilePath)
            if(inputStream != nil) {
                var buffer = [UInt8](count: 23, repeatedValue: 0)
                inputStream!.open()
                var count = 1
                while(count > 0) {
                    count = inputStream!.read(&buffer, maxLength: buffer.count)
                    if(count > 0) {
                        let level = Int8(bitPattern: buffer[0])
                        var minX : Int32 = 0
                        minX = Int32(buffer[1]) << 24
                        minX = Int32(buffer[2]) << 16 | minX
                        minX = Int32(buffer[3]) << 8  | minX
                        minX = Int32(buffer[4])       | minX
                        
                        var minY : Int32 = 0
                        minY = Int32(buffer[5]) << 24
                        minY = Int32(buffer[6]) << 16 | minY
                        minY = Int32(buffer[7]) << 8  | minY
                        minY = Int32(buffer[8])       | minY
                        
                        var maxX : Int32 = 0
                        maxX = Int32(buffer[9]) << 24
                        maxX = Int32(buffer[10]) << 16 | maxX
                        maxX = Int32(buffer[11]) << 8  | maxX
                        maxX = Int32(buffer[12])       | maxX
                        
                        var maxY : Int32 = 0
                        maxY = Int32(buffer[13]) << 24
                        maxY = Int32(buffer[14]) << 16 | maxY
                        maxY = Int32(buffer[15]) << 8  | maxY
                        maxY = Int32(buffer[16])       | maxY
                        
                        var type = Int16(buffer[17]) << 8
                        type = Int16(buffer[18]) | type
                        
                        var size : Int = 0
                        size = Int(buffer[19]) << 24
                        size = Int(buffer[20]) << 16 | size
                        size = Int(buffer[21]) << 8  | size
                        size = Int(buffer[22])       | size
                        var buf = [UInt8](count: size, repeatedValue: 0)
                        inputStream!.read(&buf, maxLength: buf.count)
                        
                        
                        var inBounds = true
                        if(bounds != nil) {
                            let currRect = CGRect(x: Int(minX), y: Int(minY), width: Int(maxX - minX), height: Int(maxY - minY))
                            if CGRectIntersectsRect(bounds!, currRect) {
                                inBounds = true
                            } else {
                                inBounds = false
                            }
                            
                        }
                        if inBounds {
                            
                            if(level < 0) {
                                if(Int(level) >= -loadLevel) {
                                    let mapElement = MapElement(_level : level, _type : type)
                                    let bezier = Path()
                                    var coordX = Int32(buf[0]) << 24 | Int32(buf[1]) << 16 | Int32(buf[2]) << 8 | Int32(buf[3])
                                    var coordY = Int32(buf[4]) << 24 | Int32(buf[5]) << 16 | Int32(buf[6]) << 8 |
                                        Int32(buf[7])
                                    bezier.addPoint(coordX, y:coordY)
                                    //bezier.moveToPoint(CGPoint(x: Int(coordX), y: Int(coordY)))
                                    for var pos = 8;pos < buf.count; pos+=8 {
                                        coordX = Int32(buf[pos]) << 24
                                        coordX = Int32(buf[pos+1]) << 16 | coordX
                                        coordX = Int32(buf[pos+2]) << 8  | coordX
                                        coordX = Int32(buf[pos+3])       | coordX
                                        
                                        coordY = Int32(buf[pos+4]) << 24
                                        coordY = Int32(buf[pos+5]) << 16 | coordY
                                        coordY = Int32(buf[pos+6]) << 8  | coordY
                                        coordY = Int32(buf[pos+7])       | coordY
                                        bezier.addPoint(coordX, y:coordY)
                                        //bezier.addLineToPoint(CGPoint(x: Int(coordX), y: Int(coordY)))
                                    }
                                    mapElement.setPath(bezier)
                                    nElems.append(mapElement)
                                }
                            } else {
                                if(Int(level) <= loadLevel) {
                                    var pos = 0
                                    while(pos < buf.count) {
                                        let mapElement = MapElement(_level : level, _type : type)
                                        let bezier = Path()
                                        var rings = Int(buf[pos]) << 24
                                        rings = Int(buf[pos+1]) << 16   | rings
                                        rings = Int(buf[pos+2]) << 8    | rings
                                        rings = Int(buf[pos+3])         | rings
                                        pos += 4
                                        var coordX = Int32(0)
                                        var coordY = Int32(0)
                                        coordX = Int32(buf[pos]) << 24
                                        coordX = Int32(buf[pos+1]) << 16 | coordX
                                        coordX = Int32(buf[pos+2]) << 8  | coordX
                                        coordX = Int32(buf[pos+3])       | coordX
                                        
                                        coordY = Int32(buf[pos+4]) << 24
                                        coordY = Int32(buf[pos+5]) << 16 | coordY
                                        coordY = Int32(buf[pos+6]) << 8  | coordY
                                        coordY = Int32(buf[pos+7])       | coordY
                                        bezier.addPoint(coordX, y:coordY)
                                        //bezier.moveToPoint(CGPoint(x: Int(coordX), y: Int(coordY)))
                                        pos += 8
                                        for var i=1; i < rings; i++ {
                                            var coordX = Int32(buf[pos]) << 24
                                            coordX = Int32(buf[pos+1]) << 16 | coordX
                                            coordX = Int32(buf[pos+2]) << 8  | coordX
                                            coordX = Int32(buf[pos+3])       | coordX
                                            
                                            var coordY = Int32(buf[pos+4]) << 24
                                            coordY = Int32(buf[pos+5]) << 16 | coordY
                                            coordY = Int32(buf[pos+6]) << 8  | coordY
                                            coordY = Int32(buf[pos+7])       | coordY
                                            bezier.addPoint(coordX, y:coordY)
                                            //bezier.addLineToPoint(CGPoint(x: Int(coordX), y: Int(coordY)))
                                            pos += 8
                                        }
                                        //bezier.closePath()
                                        mapElement.setPath(bezier)
                                        nElems.append(mapElement)
                                    }
                                }
                            }
                        }
                    }
                }
                inputStream!.close()
            }
            self.mapElems.removeAll()
            self.mapElems = nElems
            if bounds == nil {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.normalise()
                    self.firstDraw()
                    self.loading = false
                })
            } else {
                for var i = 0; i < self.mapElems.count; i++ {
                    self.mapElems[i].path!.applyMatrix(self.matrix)
                    //matrix.multiply(mapElems[i].path!)
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.loadPos = nil
                    self.loading = false
                    self.firstDraw()
                })
            }
        })
        
    }
    /**
     Draw the map on a UIImage object.
     - Returns: The UIImage object
     */
    func drawPicture() -> UIImage{
        loadRect = drawRect
        
        if(imageRect == nil) {
            imageRect = CGRect(x: drawRect!.origin.x - 400, y: drawRect!.origin.y - 400, width: drawRect!.size.width + 800, height: drawRect!.size.height + 800)
            origImageRect = CGRectMake(imageRect!.origin.x, imageRect!.origin.y, imageRect!.size.width, imageRect!.size.height)
        }
        let point = CGPoint(x: 0, y: 1)
        let scale = matrix.scale()
        let loadImageRect = CGRect(x: drawRect!.origin.x - 400, y: drawRect!.origin.y - 400, width: drawRect!.size.width + 800, height: drawRect!.size.height + 800)
        UIGraphicsBeginImageContext(loadImageRect.size)
        let canvasRect = CGRectMake(loadImageRect.origin.x - 1000, loadImageRect.origin.y - 1000, loadImageRect.width + 2000, loadImageRect.height + 2000)
        if(loadAble) {
            let context = UIGraphicsGetCurrentContext()
            for var i = 0; i < mapElems.count; i++ {
                CGContextSetStrokeColorWithColor(context, mapElems[i].getColor().CGColor)
                mapElems[i].path!.draw(context!, canvas: canvasRect)
            }
        }
        imageRect = loadImageRect
        if(loadPos != nil) {
            imageRect?.origin.x += loadPos!.x
            imageRect?.origin.y += loadPos!.y
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    /**
     Draw the UIImage on the screen
     - Parameter rect: The view rectangle
     */
    override func drawRect(rect: CGRect) {
        drawRect = rect
        loadRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: rect.size.height)
        if(imageRect != nil) {
            image.drawInRect(imageRect!)
        } else {
            image.drawInRect(rect)
        }
    }
}
