//
//  UIImage+Resize.swift
//  MyLocations
//
//  Created by Chad on 1/26/18.
//  Copyright © 2018 Chad Williams. All rights reserved.
//

import UIKit

extension UIImage {
  // resize thumbnails using aspect fill
  func resized(withBounds bounds: CGSize) -> UIImage {
    let horizontalRatio = bounds.width / size.width
    let verticalRatio = bounds.height / size.height
    let ratio = max(horizontalRatio, verticalRatio)
    let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
    
    UIGraphicsBeginImageContextWithOptions(bounds, true, 0)
    let originPoint = CGPoint(x: min((bounds.width - newSize.width), CGPoint.zero.x), y: min((bounds.height - newSize.height), CGPoint.zero.y))
    draw(in: CGRect(origin: originPoint, size: newSize))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    return newImage!
  }
  
  /*
  // resize thumbnails using aspect fit
  func resized(withBounds bounds: CGSize) -> UIImage {
    let horizontalRatio = bounds.width / size.width
    let verticalRatio = bounds.height / size.height
    let ratio = min(horizontalRatio, verticalRatio)
    let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
    
    UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
    draw(in: CGRect(origin: CGPoint.zero, size: newSize))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    return newImage!
  }
 */
  
  
}
