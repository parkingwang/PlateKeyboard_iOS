//
//  PWHandler.swift
//  VehicleKeyboardDemo
//
//  Created by 杨志豪 on 2018/6/28.
//  Copyright © 2018年 yangzhihao. All rights reserved.
//

import UIKit

@objc public protocol PWHandlerDelegate{
    @objc func plateDidChange(plate: String, complete: Bool)
    @objc func plateInputComplete(plate: String)
    @objc optional func plateKeyBoardShow()
    @objc optional func plateKeyBoardHidden()
}

public class PWHandler: NSObject, PWKeyBoardViewDeleagte, UITextFieldDelegate {
    
    //格子中字体的颜色
    @objc public var textColor = UIColor.black
    //格子中字体的大小
    @objc public var textFontSize: CGFloat = 17
    //设置主题色（会影响格子的边框颜色、按下去时提示栏颜色、确定按钮可用时的颜色）
    @objc public var mainColor = UIColor(red: 65 / 256.0, green: 138 / 256.0, blue: 249 / 256.0, alpha: 1)
    //当前格子中的输入内容
    @objc public  var plateNumber = ""
    //每个格子的背景色
    @objc public var itemColor = UIColor.white
    //格子之间的间距
    @objc public var itemSpacing: CGFloat = 0
    //边框颜色
    @objc public var cellBorderColor = UIColor(red: 216/256.0, green: 216/256.0, blue: 216/256.0, alpha: 1)
    
    //每个格子的圆角(ps:仅在有间距时生效)
    @objc public var cornerRadius: CGFloat = 2
    
    @objc public weak var delegate: PWHandlerDelegate?
    
    let identifier = "PWInputCollectionViewCell"
    
    var maxCount = 7
    var selectIndex = 0
    @objc public var inputTextfield: UITextField!

    var selectView = UIView()
    var isSetKeyboard = false//预设值时不设置为第一响应对象
    var view = UIView()
    
    public override init() {
        super.init()
        
        inputCollectionView.addObserver(self, forKeyPath: "hidden", options: .new, context: nil);
    }
  
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        DDLog("change_%@", change);
        selectView.isHidden = (change![NSKeyValueChangeKey.newKey] != nil);
    }
    
    /*
     将车牌输入框绑定到 UITextField
     **/
    @objc public func bindTextField(_ textField: UITextField, showSearch: Bool = false) {
        textField.font = UIFont.systemFont(ofSize: 13)
        
        if textField.leftView == nil && showSearch == true {
            textField.leftView = {
                let view: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 40))
                
                let imgView = UIImageView(frame:CGRect(x: 0, y: 0, width: 15, height: 15));
                imgView.image = UIImage.named("search_bar");
                imgView.contentMode = UIView.ContentMode.scaleAspectFit;
                imgView.center = view.center;
                view.addSubview(imgView);
              
                return view;
            }()
            textField.leftViewMode = UITextField.ViewMode.always; //此处用来设置leftview现实时机
            textField.placeholder = " 请输入车牌号码";
        }
        
        inputTextfield = textField
        inputTextfield.inputView = keyboardView
        inputTextfield.inputAccessoryView = {
            let switchWidth: CGFloat = 70.0
            
            let view: UIView = {
                let view: UIView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
                view.backgroundColor = UIColor.white;
                
                view.layer.borderWidth = 1;
                view.layer.borderColor = cellBorderColor.cgColor;
                return view;
            }()
            
            inputCollectionView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - switchWidth, height: 50)
            view.addSubview(inputCollectionView)
            
            switchBtn.frame = CGRect(x: UIScreen.main.bounds.width - switchWidth, y: 0, width: switchWidth, height: 50)
            view.addSubview(switchBtn)
            return view;
        }()
        
        setBackgroundView()
    }
    
    @objc private func handleActionBtn(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected;
        changeInputType(isNewEnergy: sender.isSelected)
    }
    
    /*
     将车牌输入框绑定到一个你自己创建的UIView(建议绑定到 UITextField)
     **/
    @objc public func setKeyBoardView(view: UIView, showSearch: Bool = true){
        self.view = view
        //        inputCollectionView.frame = view.bounds;
        
        if view.isKind(of: UITextField.classForCoder()) {
            inputTextfield = (view as! UITextField);
            
        } else {
            inputTextfield = UITextField(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
            if view.isKind(of: UIButton.classForCoder()) == true {
                if let title = (view as! UIButton).titleLabel!.text {
                    inputTextfield.placeholder = "  " + title;
                    (view as! UIButton).setTitle("", for: .normal)

                }
            }
            view.addSubview(inputTextfield)
        }
        
        bindTextField(inputTextfield, showSearch: showSearch);
                
//        view.translatesAutoresizingMaskIntoConstraints = false
        if view.isKind(of: UITextField.classForCoder()) == false {
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(tap:)))
            view.addGestureRecognizer(tap)
            
            //监听键盘
            NotificationCenter.default.addObserver(self, selector: #selector(plateKeyBoardShow), name:UIResponder.keyboardDidShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(plateKeyBoardHidden), name:UIResponder.keyboardWillHideNotification, object: nil)
        }
        
    }
    
    @objc lazy var inputCollectionView: UICollectionView = {
        let view: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.register(UINib(nibName: identifier, bundle: Bundle(for: PWHandler.self)), forCellWithReuseIdentifier: identifier)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight];
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        view.isScrollEnabled = false
        
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    @objc lazy var keyboardView: PWKeyBoardView = {
        let view: PWKeyBoardView = PWKeyBoardView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        view.mainColor = mainColor
        view.delegate = self

        return view
    }()
    
    /*
     手动弹出键盘
     **/
    @objc public func vehicleKeyBoardBecomeFirstResponder(){
//        DDLog(plateNumber, inputTextfield.text ?? "--")
        changeInputType(isNewEnergy: switchBtn.isSelected)
        inputTextfield.becomeFirstResponder()
    }
    
    /*
     手动隐藏键盘
     **/
    @objc public func vehicleKeyBoardEndEditing(){
//        DDLog(plateNumber, inputTextfield.text ?? "--")
        UIApplication.shared.keyWindow?.endEditing(true)
    }
    
    /*
     检查是否是符合新能源车牌的规则
     **/
    @objc public func checkNewEnginePlate() ->Bool{
        for i in 0..<plateNumber.count {
            let listModel =  KeyboardEngine.generateLayout(keyboardType: PWKeyboardType.civilAndArmy, inputIndex: i, presetNumber: KeyboardEngine.subString(str: plateNumber, start: 0, length: i), numberType:.newEnergy,isMoreType:false);
            var result = false
            for j in 0..<listModel.rowArray().count {
                for k in 0..<listModel.rowArray()[j].count{
                    let key = listModel.rowArray()[j][k]
                    if KeyboardEngine.subString(str: plateNumber, start: i, length: 1) == key.text,key.enabled {
                        result = true
                    }
                }
            }
            if !result {
                return false
            }
        }
        return true
    }
 
    /*
     检查输入车牌的完整
     **/
    @objc public func isComplete()-> Bool{
        return plateNumber.count == maxCount
    }
    
    @objc public func setPlate(plate: String, type: PWKeyboardNumType){
        plateNumber = plate;
        var numType = type;
        selectIndex = plate.count
        if  numType == .auto, plateNumber.count > 0, KeyboardEngine.subString(str: plateNumber, start: 0, length: 1) == "W" {
            numType = .wuJing
        } else if numType == .auto, plateNumber.count == 8 {
            numType = .newEnergy
        }
        keyboardView.numType = numType
        let isNewEnergy = (keyboardView.numType == .newEnergy)
        isSetKeyboard = true
        changeInputType(isNewEnergy: isNewEnergy)
    }
    
    @objc public func changeInputType(isNewEnergy: Bool){
        let keyboardView = inputTextfield.inputView as! PWKeyBoardView
        keyboardView.numType = isNewEnergy ? .newEnergy : .auto
        var numType = keyboardView.numType
        if  plateNumber.count > 0,KeyboardEngine.subString(str: plateNumber, start: 0, length: 1) == "W" {
            numType = .wuJing
        }
        maxCount = (numType == .newEnergy || numType == .wuJing) ? 8 : 7
        if plateNumber.count > maxCount {
            plateNumber = KeyboardEngine.subString(str: plateNumber, start: 0, length: plateNumber.count - 1)
        } else if maxCount == 8,plateNumber.count == 7 {
            selectIndex = 7
        }
        if selectIndex > (maxCount - 1) {
            selectIndex = maxCount - 1
        }
        keyboardView.updateText(text: plateNumber, isMoreType: false, inputIndex: selectIndex)
        inputTextfield.text = plateNumber;

        updateCollection()
    }
    
    private func setBackgroundView(){
        if itemSpacing <= 0 {
            let backgroundView = UIView(frame: inputCollectionView.bounds)
            backgroundView.isUserInteractionEnabled = false
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.layer.borderWidth = 1
            backgroundView.layer.borderColor = cellBorderColor.cgColor
            backgroundView.layer.masksToBounds = true
            backgroundView.layer.cornerRadius = cornerRadius
            
//            view.addSubview(backgroundView)
//            inputCollectionView.addSubview(backgroundView)
            setNSLayoutConstraint(subView: backgroundView, superView: view)
            selectView.isUserInteractionEnabled = false
        }
//        view.addSubview(selectView)
        inputCollectionView.addSubview(selectView)
    }
    
    private func setNSLayoutConstraint(subView: UIView, superView: UIView){
        if !superView.subviews.contains(subView) {
            return;
        }
        if (superView.constraints.count > 0) {
            let topCos = NSLayoutConstraint(item: subView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
            let leftCos = NSLayoutConstraint(item: subView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0)
            let rightCos = NSLayoutConstraint(item: subView, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: 0)
            let bottomCos = NSLayoutConstraint(item: subView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: superView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0)
            superView.addConstraints([topCos,leftCos,rightCos,bottomCos])
        }
    }
    
    @objc func plateKeyBoardShow(){
        if inputTextfield.isFirstResponder {
            delegate?.plateKeyBoardShow?()
        }
    }
    
    @objc func plateKeyBoardHidden(){
        if inputTextfield.isFirstResponder {
            delegate?.plateKeyBoardHidden?()
        }
    }
    
    @objc func tapAction(tap:UILongPressGestureRecognizer){
        let tapPoint = tap.location(in: view)
        let indexPath = inputCollectionView.indexPathForItem(at: tapPoint)
        if indexPath != nil {
            collectionView(inputCollectionView, didSelectItemAt: indexPath!)
        }
    }
    
    
    func updateCollection(){
        inputCollectionView.reloadData()
        if !inputTextfield.isFirstResponder,!isSetKeyboard {
            inputTextfield.becomeFirstResponder()
        }
        isSetKeyboard = false
    }
    
    func selectComplete(char: String, inputIndex: Int) {
        
        var isMoreType = false
        if char == "删除" , plateNumber.count >= 1 {
            plateNumber = KeyboardEngine.subString(str: plateNumber, start: 0, length: plateNumber.count - 1)
            selectIndex = plateNumber.count
        } else  if char == "确定"{
            UIApplication.shared.keyWindow?.endEditing(true)
            delegate?.plateInputComplete(plate: plateNumber)
            return
        } else if char == "更多" {
            isMoreType = true
        } else if char == "返回" {
            isMoreType = false
        } else {
            if plateNumber.count <= inputIndex{
                plateNumber += char
            } else {
                let plateMStr = NSMutableString(string: plateNumber)
                plateMStr.replaceCharacters(in: NSRange(location: inputIndex, length: 1), with: char)
                plateNumber = NSString.init(format: "%@", plateMStr) as String
            }
            let keyboardView = inputTextfield.inputView as! PWKeyBoardView
            let numType = keyboardView.numType == .newEnergy ? PWKeyboardNumType.newEnergy : KeyboardEngine.detectNumberTypeOf(presetNumber: plateNumber)
            maxCount = (numType == .newEnergy || numType == .wuJing) ? 8 : 7
            if maxCount > plateNumber.count || selectIndex < plateNumber.count - 1 {
                selectIndex += 1;
            }
        }
        keyboardView.updateText(text: plateNumber, isMoreType: isMoreType, inputIndex: selectIndex)
        inputTextfield.text = plateNumber
        updateCollection()
        if (!isMoreType){
            delegate?.plateDidChange(plate:plateNumber,complete:plateNumber.count == maxCount)
        }
    }
    
    func getPlateChar(index: Int) -> String{
        if plateNumber.count > index {
            let plateMStr = plateNumber as NSString
            let char = plateMStr.substring(with: NSRange(location: index, length: 1))
            return char
        }
        return ""
    }
    
    func corners(view: UIView, index: Int){
        if itemSpacing > 0 {
            view.layer.cornerRadius = cornerRadius
        } else {
            //当格子之间没有间距时，第一个的左边和最后一个的右边会切圆角，其他都是直角
            view.addRounded(cornevrs: UIRectCorner.allCorners, radii: CGSize(width: 0, height: 0))
            if index == 0{
                view.addRounded(cornevrs: UIRectCorner(rawValue: UIRectCorner.RawValue(UInt8(UIRectCorner.topLeft.rawValue) | UInt8(UIRectCorner.bottomLeft.rawValue))), radii: CGSize(width: 2, height: 2))
            } else if index == maxCount - 1 {
                view.addRounded(cornevrs: UIRectCorner(rawValue: UIRectCorner.RawValue(UInt8(UIRectCorner.topRight.rawValue) | UInt8(UIRectCorner.bottomRight.rawValue))), radii: CGSize(width: 2, height: 2))
            }
        }
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        inputCollectionView.removeObserver(self, forKeyPath: "hidden")

    }
    
    
    lazy var switchBtn: UIButton = {
        let view: UIButton = UIButton(type: .custom)
//                view.setImage(UIImage(named: "plateNumberSwitch_N"), for: .normal)
//                view.setImage(UIImage(named: "plateNumberSwitch_H"), for: .selected)
        view.setImage(UIImage.named("plateNumberSwitch_N"), for: .normal)
        view.setImage(UIImage.named("plateNumberSwitch_H"), for: .selected)
        
        view.imageEdgeInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        view.imageView?.contentMode = .scaleAspectFit
        
        view.layer.borderWidth = 1;
        view.layer.borderColor = cellBorderColor.cgColor;
        view.addTarget(self, action: #selector(handleActionBtn(_:)), for: .touchUpInside)
        return view;
    }()
    
}

extension PWHandler: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    //MARK:- collectionViewDelegate
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectIndex = indexPath.row > plateNumber.count ? plateNumber.count : indexPath.row
        keyboardView.updateText(text: plateNumber, isMoreType: false, inputIndex: selectIndex)
        updateCollection()
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return maxCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: ((collectionView.frame.size.width - CGFloat(maxCount - 1) * itemSpacing ) / CGFloat(maxCount)) - 0.01, height: collectionView.frame.height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! PWInputCollectionViewCell
        cell.charLabel.text = getPlateChar(index: indexPath.row)
        cell.charLabel.textColor = textColor
        cell.charLabel.font = UIFont.systemFont(ofSize: textFontSize)
        cell.backgroundColor = itemColor
        if indexPath.row == selectIndex {
            //给cell加上选中的边框
            selectView.layer.borderWidth = 2
            selectView.layer.borderColor = mainColor.cgColor
            selectView.frame = cell.frame
            var rightSpace :CGFloat = (maxCount - 1) == selectIndex ? 0 : 0.5
            if itemSpacing > 0 {
                rightSpace = 0
            }
            selectView.center = CGPoint(x: cell.center.x + rightSpace, y: cell.center.y)
            corners(view: selectView, index: selectIndex)
        }
        if itemSpacing > 0 {
            cell.layer.borderWidth = 1
            cell.layer.borderColor = cellBorderColor.cgColor
        }
        corners(view: cell, index: indexPath.row)
        cell.layer.masksToBounds = true
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return itemSpacing
    }
    
}
