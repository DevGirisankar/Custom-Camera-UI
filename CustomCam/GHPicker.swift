//
//  GHPicker.swift
//  CustomCam
//
//  Created by Giri on 21/10/21.
//

import Foundation
import UIKit

protocol GHPickerDelegate: AnyObject {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
}
@IBDesignable
class GHPicker: UIView {
    var cameraModePicker: UIPickerView!
    weak var delegate : GHPickerDelegate?
    var captureModesList : [String]? {
        didSet {
            cameraModePicker.reloadAllComponents()
        }
    }
    private  var rotationAngle: CGFloat! = -90  * (.pi/180)
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
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
        guard let list = captureModesList else {return 0}
        return list.count
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        guard let list = captureModesList else {return UIView.init()}
        pickerView.subviews[1].isHidden = true
        let modeView = UIView()
        modeView.frame = CGRect(x: 0, y: 0, width: 100, height: self.bounds.height)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: self.bounds.height))
        label.textColor = pickerView.selectedRow(inComponent: component) == row ? .yellow : .white
        label.text = list[row]
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 14)
        modeView.addSubview(label)
        modeView.transform = CGAffineTransform(rotationAngle: 90 * (.pi/180))
        return modeView
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerView.reloadAllComponents()
        delegate?.pickerView(pickerView, didSelectRow: row, inComponent: component)
    }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { // height is width as we rotated
        return 100
    }
}
