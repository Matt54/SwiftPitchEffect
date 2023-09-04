//
//  PitchEffectExtensionMainView.swift
//  PitchEffectExtension
//
//  Created by Matt Pfeiffer on 9/4/23.
//

import SwiftUI

struct PitchEffectExtensionMainView: View {
    var parameterTree: ObservableAUParameterGroup
    
    var body: some View {
        VStack {
            ParameterSlider(param: parameterTree.global.midiNoteNumber)
                .padding()
            MomentaryButton(
                "Play note",
                param: parameterTree.global.sendNote
            )
        }
    }
}
