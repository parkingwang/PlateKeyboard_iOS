//
//  UIView+PWCorners.swift
//  VehicleKeyboardDemo
//
//  Created by 杨志豪 on 2018/7/6.
//  Copyright © 2018年 yangzhihao. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func addRounded(cornevrs: UIRectCorner, radii: CGSize){
        let rounded = UIBezierPath(roundedRect: bounds, byRoundingCorners: cornevrs, cornerRadii: radii)
        let shape = CAShapeLayer()
        shape.path = rounded.cgPath
        self.layer.mask = shape;
    }
}

extension UIImage {
//    // 把颜色转成UIImage
//    static func color(_ color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage{
//        let rect: CGRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
//        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
//        
//        let context: CGContext = UIGraphicsGetCurrentContext()!
//        context.setFillColor(color.cgColor)
//        context.fill(rect)
//        
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsGetCurrentContext()
//        return image!
//    }

    /// 获取 PWBundle.bundle 文件图片
    static func named(_ name: String) -> UIImage?{
        let filePath: String = "PWBundle.bundle/Image/\(name)"
        return UIImage(named: filePath)
    }

    
}
