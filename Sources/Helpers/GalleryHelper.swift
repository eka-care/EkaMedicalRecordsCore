//
//  GalleryHelper.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 24/01/25.
//

import UIKit

public final class GalleryHelper {
  public func convertImagesToData(images: [UIImage], compressionQuality: CGFloat = 1.0) -> [Data] {
    return images.compactMap { image in
      image.jpegData(compressionQuality: compressionQuality)
    }
  }
}
