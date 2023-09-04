//
//  PitchEffectAudioUnit.swift
//  PitchEffectExtension
//
//  Created by Matt Pfeiffer on 9/4/23.
//

import AudioToolbox
import AVFoundation
import CoreMIDI

public class PitchEffectAudioUnit: AUAudioUnit {
    private var midiInputBus: AUAudioUnitBus!
    private var midiOutputBus: AUAudioUnitBus!
    private var sampleRate: Double = 44100.0
    
    public override var inputBusses: AUAudioUnitBusArray {
        return AUAudioUnitBusArray(audioUnit: self, busType: .input, busses: [midiInputBus])
    }
    
    public override var outputBusses: AUAudioUnitBusArray {
        return AUAudioUnitBusArray(audioUnit: self, busType: .output, busses: [midiOutputBus])
    }

    public override init(componentDescription: AudioComponentDescription,
                         options: AudioComponentInstantiationOptions = []) throws {
        try super.init(componentDescription: componentDescription, options: options)
        
        // Initialize your audio unit buses (MIDI in this case)
        let midiFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        midiInputBus = try AUAudioUnitBus(format: midiFormat)
        midiOutputBus = try AUAudioUnitBus(format: midiFormat)
    }
    
    public override func allocateRenderResources() throws {
        // Your resource allocation code here, if needed
        sampleRate = outputBusses[0].format.sampleRate
        try super.allocateRenderResources()
    }

    public override func deallocateRenderResources() {
        // Deallocate resources.
    }

    public override func startHardware() throws {
        // Start the hardware (if needed).
    }

    public override func stopHardware() {
        // Stop the hardware (if needed).
    }
    
    public override var internalRenderBlock: AUInternalRenderBlock {
        return { [unowned self] actionFlags, timestamp, frameCount, outputBusNumber, outputData, renderEvent, pullInputBlock in

            var currentEvent = renderEvent
            while currentEvent != nil {
                guard let event = currentEvent?.pointee else {
                    break
                }

                if event.head.eventType == .MIDI {
                    self.handleIncomingMIDIEvent(event)
                }

                currentEvent = UnsafePointer(event.head.next)
            }

            return noErr
        }
    }

    private func handleIncomingMIDIEvent(_ event: AURenderEvent) {
        let eventType = event.head.eventType

        if eventType == .MIDI {
            let midiEvent = event.MIDI
            let midiBytes = [midiEvent.data.0, midiEvent.data.1, midiEvent.data.2]

            if midiEvent.length >= 3 {
                let status = midiBytes[0]
                let channel = status & 0x0F
                let eventType = status & 0xF0

                // Handle Note On and Note Off events
                if eventType == 0x90 || eventType == 0x80 {
                    let originalNoteNumber = midiBytes[1]
                    let velocity = midiBytes[2]

                    // Output the original note immediately
                    outputMIDINote(status: status, noteNumber: originalNoteNumber, velocity: velocity, timestamp: midiEvent.eventSampleTime)

                    // Output the pitched-up note (one octave higher) after a 200 ms delay
                    let delayInSamples: AUEventSampleTime = AUEventSampleTime(44100 * 0.2) // Assuming 44.1kHz sample rate
                    outputMIDINote(status: status, noteNumber: originalNoteNumber + 12, velocity: velocity, timestamp: midiEvent.eventSampleTime + delayInSamples)
                }
                
            }
        }
    }
    
    private func outputMIDINote(status: UInt8, noteNumber: UInt8, velocity: UInt8, timestamp: AUEventSampleTime) {
        var newMIDIEvent = AUMIDIEvent()
        newMIDIEvent.eventSampleTime = timestamp
        newMIDIEvent.eventType = .MIDI
        newMIDIEvent.length = 3
        newMIDIEvent.data = (status, noteNumber, velocity)

        scheduleMIDIEvent(newMIDIEvent)
    }
    
    var nextOutputEvent: UnsafeMutablePointer<AURenderEvent>? = nil

    private func scheduleMIDIEvent(_ event: AUMIDIEvent) {
        // Make sure that midiOutputEventBlock is set
        guard let midiOutputEventBlock = self.midiOutputEventBlock else {
            // Handle the error
            return
        }
            
        // Extract the MIDI bytes from the event
        let bytes: [UInt8] = [event.data.0, event.data.1, event.data.2]
        let byteCount = Int(event.length) // Assuming length corresponds to the number of valid bytes
        
        bytes.withUnsafeBufferPointer { buffer in
            let pointer = buffer.baseAddress!
            
            // Send the MIDI event to the host
            let result = midiOutputEventBlock(event.eventSampleTime, event.cable, byteCount, pointer)
            if result != noErr {
                // Handle the error
            }
        }
    }
}
