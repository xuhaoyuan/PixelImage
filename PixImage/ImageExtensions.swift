//
//  ImageExtensions.swift
//  Pixelizator
//
//  Created by Greg on 1/11/19.
//  Copyright © 2019 GS. All rights reserved.
//

import UIKit

extension UIImage {
    
    func pixelize(pixelSize: CGFloat) -> UIImage {
        guard pixelSize != 0 else { return self }
        let downsizedImage = resize(scaleX: 1/pixelSize, scaleY: 1/pixelSize, interpolation: .none)
        let upsizedImage = downsizedImage.resize(scaleX: pixelSize, scaleY: pixelSize, interpolation: .none)
        return upsizedImage
    }
    
    func resize(scaleX: CGFloat, scaleY: CGFloat, interpolation: CGInterpolationQuality) -> UIImage {
   
        let resize = size.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
        UIGraphicsBeginImageContextWithOptions(resize, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        context.interpolationQuality = interpolation
        let rect = CGRect(origin: .zero, size: resize)
        draw(in: rect)
        guard let img = context.makeImage() else { return self }
        let resizedImage = UIImage(cgImage: img)
        UIGraphicsEndImageContext()
        return resizedImage
    }
}
