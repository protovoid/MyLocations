//
//  String+AddText.swift
//  MyLocations
//
//  Created by Chad on 1/30/18.
//  Copyright © 2018 Chad Williams. All rights reserved.
//

extension String {
  mutating func add(text: String?, separatedBy separator: String = "") {
    if let text = text {
      if !isEmpty {
        self += separator
      }
      self += text
    }
  }
}
