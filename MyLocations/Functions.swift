//
//  Functions.swift
//  MyLocations
//
//  Created by Chad on 1/16/18.
//  Copyright © 2018 Chad Williams. All rights reserved.
//

import Foundation

func afterDelay(_ seconds: Double, run: @escaping () -> Void) {
  DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: run)
}
