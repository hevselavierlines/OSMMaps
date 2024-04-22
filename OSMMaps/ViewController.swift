//
//  ViewController.swift
//  OSMMaps
//
//  Created by Manuel Baumgartner on 12/01/2016.
//  Copyright © 2016 FH Hagenberg. All rights reserved.
//

import UIKit
/**
 * The main view controller does the main work for the app.
 * This main view contains a view called DrawView that does all the drawing for the map.
 */
class ViewController: UIViewController {
    @IBOutlet weak var btMapsel: UIBarButtonItem!
    @IBOutlet weak var drawView: DrawView!
    var oldPoint : CGPoint? = nil
    var firstPoint : CGPoint? = nil
    var currMap = "malta"
    var zoomSum = CGFloat(1.0)
    @IBAction func panGesture(sender: UIPanGestureRecognizer) {
        if(sender.state == UIGestureRecognizerState.Began) {
            oldPoint = sender.locationInView(drawView)
            firstPoint = sender.locationInView(drawView)
        } else if(sender.state == UIGestureRecognizerState.Ended) {
            oldPoint = nil
            let point = sender.locationInView(drawView)
            let transX = point.x - firstPoint!.x
            let transY = point.y - firstPoint!.y
            drawView.translate(transX, py: transY)
            drawView.redraw()
        } else {
            let point = sender.locationInView(drawView)
            let transX = point.x - oldPoint!.x
            let transY = point.y - oldPoint!.y
            drawView.moveImage(transX, py: transY)
            drawView.setNeedsDisplay()
            oldPoint = point
        }
    }
    @IBAction func loadBounds(sender: AnyObject) {
        drawView.loadBounds()
    }
    /**
     * This function zooms into the map and is typically called after the plus button press
     */
    @IBAction func zoomIn(sender: AnyObject) {
        drawView.zoom(1.5)
        drawView.redraw()
    }
    /**
     * This function zooms out of the map and is typically called after the minus button press
     */
    @IBAction func zoomOut(sender: AnyObject) {
        drawView.zoom(0.5)
        drawView.redraw()
    }
    /**
     * This function restets the map to show the complete map according to it's borders.
     */
    @IBAction func reset(sender: AnyObject) {
        drawView.reset()
        drawView.redraw()
    }
    /**
     The zoom gesture recogniser call via the UIPinchGestureRecognizer
     
     - Parameter sender: The parameter of the gesutre
     */
    @IBAction func zoomGesture(sender: UIPinchGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            zoomSum = 1.0
        } else if sender.state == UIGestureRecognizerState.Changed {
            drawView.zoomImage(sender.scale)
            drawView.setNeedsDisplay()
        } else if sender.state == UIGestureRecognizerState.Ended {
            drawView.zoom(sender.scale)
            drawView.redraw()
        }
    }
    /**
     * When the view has been loaded the first map is drawn.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        drawView.loadData(currMap, bounds: nil)
    }
    /**
     * This function changes the current map to another one
     * A actionsheet shows a list of the available maps.
     */
    @IBAction func changeMap(sender: AnyObject) {
        let alert = UIAlertController(title: "Map Selector", message: "Please select a map", preferredStyle: UIAlertControllerStyle.ActionSheet)
        alert.addAction(UIAlertAction(title: "Malta", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) in
            self.currMap = "malta"
            self.drawView.currMap = "malta"
            self.btMapsel.title = "Malta"
            self.drawView.loadData(self.currMap, bounds: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Ireland", style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction) in
            self.currMap = "ireland"
            self.drawView.currMap = "ireland"
            self.btMapsel.title = "Ireland"
            self.drawView.loadData(self.currMap, bounds: nil)
        }))
        
        
        alert.addAction(UIAlertAction(title: "Isle of Man", style: UIAlertActionStyle.Default, handler: { (action:UIAlertAction) in
            self.currMap = "isleofman"
            self.drawView.currMap = "isleofman"
            self.btMapsel.title = "Isle of Man"
            self.drawView.loadData(self.currMap, bounds: nil)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    override func viewDidAppear(animated: Bool) {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

