//
//  CamButton.swift
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
    
    override var isSelected:Bool {
        didSet {
            //change the inner shape to match the state
            let morph = CABasicAnimation(keyPath: "path")
            morph.duration = animationDuration;
            morph.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            
            //change the shape according to the current state of the control
            morph.toValue = self.currentInnerPath().cgPath
            
            //ensure the animation is not reverted once completed
            morph.fillMode = CAMediaTimingFillMode.forwards
            morph.isRemovedOnCompletion = false
            
            //add the animation
            self.pathLayer.add(morph, forKey:"")
        }
    }
    

    override func draw(_ rect: CGRect) {
        //always draw the outer ring, the inner control is drawn during the animations
        let outerRing = UIBezierPath(ovalIn: CGRect(x:3, y:3, width:60, height:60))
        outerRing.lineWidth = 6
        UIColor.white.setStroke()
        outerRing.stroke()
    }
    
    func currentInnerPath () -> UIBezierPath {
        //choose the correct inner path based on the control state
        var returnPath:UIBezierPath;
        if (self.isSelected)  {
            returnPath = self.innerSquarePath()
        } else {
            returnPath = self.innerCirclePath()
        }
        returnPath = self.innerCirclePath() // TODO:= override
        return returnPath
    }
    
    func innerCirclePath () -> UIBezierPath {
        return UIBezierPath(roundedRect: CGRect(x:8, y:8, width:50, height:50), cornerRadius: 25)
    }
    
    func innerSquarePath () -> UIBezierPath{
        return UIBezierPath(roundedRect: CGRect(x:18, y:18, width:30, height:30), cornerRadius: 4)
    }
}
//@IBDesignable
//class GHPicker: UIPickerView {
//
//    override init(frame: CGRect) {
//
//        super.init(frame: frame)
//
//        self.setup()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//
//        self.setup()
//    }
//
//    //common set up code
//    func setup() {
//        translatesAutoresizingMaskIntoConstraints = false
//        transform = CGAffineTransform(rotationAngle: -90 * (.pi / 180))
//    }
//    override class func awakeFromNib() {
//        super.awakeFromNib()
//
//    }
//}
@IBDesignable
class GHPicker: UIView {
    var cameraModePicker: UIPickerView!
    let captureModesList = ["DEFAULT","SEPIA","WARM","COOL","VIVID", "NOIR"]
    var rotationAngle: CGFloat! = -90  * (.pi/180)

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
        cameraModePicker = UIPickerView()
        cameraModePicker.dataSource = self
        cameraModePicker.delegate = self
        self.addSubview(cameraModePicker)
        cameraModePicker.transform = CGAffineTransform(rotationAngle: rotationAngle)
        cameraModePicker.frame = CGRect(x: -70, y: 0, width: self.bounds.width+100, height:  self.bounds.height)
    }
    override class func awakeFromNib() {
        super.awakeFromNib()

    }
}
extension GHPicker: UIPickerViewDataSource,UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return captureModesList.count
    }
    //Here we need to display a label , you can add any custom UI here.
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
    
        pickerView.subviews[1].isHidden = true
        let modeView = UIView()
        modeView.frame = CGRect(x: 0, y: 0, width: 100, height: self.bounds.height)
        let modeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: self.bounds.height))
        modeLabel.textColor = pickerView.selectedRow(inComponent: component) == row ? .yellow : .white
        modeLabel.text = captureModesList[row]
        modeLabel.font = UIFont.boldSystemFont(ofSize: 14)
        modeLabel.textAlignment = .center
        modeView.addSubview(modeLabel)
        modeView.transform = CGAffineTransform(rotationAngle: 90 * (.pi/180))
        return modeView
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerView.reloadAllComponents()
    }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { // height is width as we rotated
      return 60
    }

}
