//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

///使用关联属性来对值进行存储，避免每次都进行计算
private var AssociateHasRasterImageKey: String = "AssociateHasRasterImageKey"

public extension ZMAssetOriginal {
    var hasRasterImage: Bool {
        get {
            if let hasRasterImage = objc_getAssociatedObject(self, &AssociateHasRasterImageKey) as? Bool {
                return hasRasterImage
            } else {
                let hasRasterImage = hasImage() && UTType(mimeType: mimeType)?.isSVG == false
                objc_setAssociatedObject(self, &AssociateHasRasterImageKey, hasRasterImage, .OBJC_ASSOCIATION_RETAIN)
                return hasRasterImage
            }
        }
    }
}

fileprivate extension ZMImageAsset {
    var isRaster: Bool {
        return UTType(mimeType: mimeType)?.isSVG == false
    }
}

public extension ZMGenericMessage {
    var hasRasterImage: Bool {
        return hasImage() && image.isRaster
    }
}

public extension ZMEphemeral {
    var hasRasterImage: Bool {
        return hasImage() && image.isRaster
    }
}

