//
//  GCameraButton.swift
//  CustomCam
//
//  Created by Giri on 18/10/21.
//

import Foundation
import UIKit

protocol gcamButtonDelegate: AnyObject {
    func imageCapture()
    func videoCapture(isRecording:Bool)
}
@IBDesignable
class GCameraButton: UIButton {
    //create a new layer to render the various circles
    var pathLayer:CAShapeLayer!
    let animationDuration = 0.4
    weak var delegate: gcamButtonDelegate?
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    //common set up code
    func setup() {
        //add a shape layer for the inner shape to be able to animate it
        self.pathLayer = CAShapeLayer()
        
        //show the right shape for the current state of the control
        self.pathLayer.path = self.currentInnerPath().cgPath
        
        //don't use a stroke color, which would give a ring around the inner circle
        self.pathLayer.strokeColor = nil
        
        //set the color for the inner shape
        self.pathLayer.fillColor = UIColor.white.cgColor
        
        //add the path layer to the control layer so it gets drawn
        self.layer.addSublayer(self.pathLayer)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //clear the title
        self.setTitle("", for:.normal)
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))  //Long function will call when user long press on button.
        self.addGestureRecognizer(longGesture)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector (handleTap))  //Tap function will call when user tap on button
        tapGesture.numberOfTapsRequired = 1
        self.addGestureRecognizer(tapGesture)
    }
    @objc func handleTap(gestureRecognizer: UILongPressGestureRecognizer) {
        self.alpha = 0.2
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveLinear], animations: {self.alpha = 1.0}, completion: nil)
        delegate?.imageCapture()
    }
    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began ||  gestureRecognizer.state == .ended {
            //Create the animation to restore the color of the button
            let colorChange = CABasicAnimation(keyPath: "fillColor")
            colorChange.duration = animationDuration;
            colorChange.toValue = gestureRecognizer.state == .began ?  UIColor.red.cgColor : UIColor.white.cgColor
            
            //make sure that the color animation is not reverted once the animation is completed
            colorChange.fillMode = CAMediaTimingFillMode.forwards
            colorChange.isRemovedOnCompletion = false
            
            //indicate which animation timing function to use, in this case ease in and ease out
            colorChange.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            
            //add the animation
            self.pathLayer.add(colorChange, forKey:"darkColor")
            
            delegate?.videoCapture(isRecording: gestureRecognizer.state == .began)
        }
    }
    
    override func prepareForInterfaceBuilder()    {
        //clear the title
        self.setTitle("", for:.normal)
    }
    override func draw(_ rect: CGRect) {
        //always draw the outer ring, the inner control is drawn during the animations
        let outerRing = UIBezierPath(ovalIn: CGRect(x:3, y:3, width:60, height:60))
        outerRing.lineWidth = 6
        UIColor.white.setStroke()
        outerRing.stroke()
    }
    
    func currentInnerPath () -> UIBezierPath {
        return innerCirclePath()
    }
    
    func innerCirclePath () -> UIBezierPath {
        return UIBezierPath(roundedRect: CGRect(x:8, y:8, width:50, height:50), cornerRadius: 25)
    }
}
