//
//  MapElement.swift
//  OSMMaps
//
//  Created by Manuel Baumgartner on 27/02/2016.
//  Copyright © 2016 FH Hagenberg. All rights reserved.
//

import Foundation
import UIKit
/**
 The map element class contains important level, type and path data as well as meta data.
 - Author: Manuel Baumgartner
 */
class MapElement {
    var level : Int8
    var type  : Int16
    var path  : Path?
    /**
     Initalise the elemtn with level and type
     - Parameter _level: The zoom level for the element in 8-bit integer
     - Parameter _type:  The type of the element in a 16-bit integer.
     */
    init(_level : Int8, _type : Int16) {
        level = _level
        type  = _type
    }
    /**
     Set the path of the map element.
     - Parameter _path:  The path from the file.
     */
    func setPath(_path : Path) {
        path = _path
        /*if(type >= 1010 && type <= 1021) {
            path?.lineWidth = 3
        }*/
    }
    
    func getPath() -> Path {
        return path!
    }
    /**
     Get the colour accordint to the type.
     - Returns: A UIColor object
     */
    func getColor() -> UIColor{
        if(type > 8000) {
            return UIColor.grayColor()
        } else if(type == 1010 || type == 1011 || type == 1020 || type == 1021) {
            //7284c9 114 132 201
            return UIColor(red: 0.447059, green: 0.517647, blue: 0.7882353, alpha: 1.0)
        } else if(type == 1030 || type == 1031) {
            return UIColor.redColor()
        } else if(type == 1040 || type == 1041) {
            //196 186 36
            return UIColor(red: 0.768627, green: 0.729412, blue: 0.141176, alpha: 1.0)
        } else if(type == 1080) {
            return UIColor.orangeColor()
        } else if(type >= 2000 && type < 3000) {
            return UIColor.blueColor()
        } else {
            return UIColor.blackColor()
        }
    }
}
