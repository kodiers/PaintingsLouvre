//
//  Paintings.swift
//  PaintingsLouvre
//
//  Created by Viktor Yamchinov on 28/12/2018.
//  Copyright © 2018 Viktor Yamchinov. All rights reserved.
//

import Foundation

struct Painting: Codable {
    var title: String
    var artist: String
    var year: String
    var url: URL
}
