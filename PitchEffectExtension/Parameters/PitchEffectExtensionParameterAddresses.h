//
//  PitchEffectExtensionParameterAddresses.h
//  PitchEffectExtension
//
//  Created by Matt Pfeiffer on 9/4/23.
//

#pragma once

#include <AudioToolbox/AUParameters.h>

#ifdef __cplusplus
namespace PitchEffectExtensionParameterAddress {
#endif

typedef NS_ENUM(AUParameterAddress, PitchEffectExtensionParameterAddress) {
    sendNote = 0,
    midiNoteNumber = 1
};

#ifdef __cplusplus
}
#endif
