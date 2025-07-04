//
//  AdRadarWidgetBundle.swift
//  AdRadarWidget
//
//  Created by Guilio Del Fava on 2025/06/12.
//

import WidgetKit
import SwiftUI

@main
struct AdRadarWidgetBundle: WidgetBundle {
    var body: some Widget {
        AdRadarWidget()
        AdRadarWidgetControl()
        AdRadarWidgetLiveActivity()
    }
}
