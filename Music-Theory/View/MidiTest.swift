import SwiftUI
import CoreData
import AVFoundation
import CoreMIDI

struct MidiTest: View {
    
    func test() {

        //import CoreMIDI

        var client = MIDIClientRef()
        var outputPort = MIDIPortRef()

        MIDIClientCreate("MIDI Client" as CFString, nil, nil, &client)
        MIDIOutputPortCreate(client, "MIDI Output Port" as CFString, &outputPort)
        
        //Find the MIDI endpoint that you want to send MIDI events to:
        
        var destination = MIDIEndpointRef()
        let count = MIDIGetNumberOfDestinations()
        for i in 0..<count {
            let endpoint = MIDIGetDestination(i)
            var name: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &name)
            if let endpointName = name?.takeUnretainedValue() as String?, endpointName == "Name of Your MIDI Endpoint" {
                destination = endpoint
                break
            }
        }
        
//        let noteOn = MIDINoteMessage(channel: 0, note: 60, velocity: 64, releaseVelocity: 0, duration: 0)
//        let packetList = MIDIPacketList(numPackets: 1, packet: MIDIPacket(timeStamp: 0, length: 11, data: noteOn.bytes))
//        MIDISend(outputPort, destination, &packetList)
//        
//        let noteOff = MIDINoteMessage(channel: 0, note: 60, velocity: 0, releaseVelocity: 0, duration: 0.5)
//        let packetList = MIDIPacketList(packet: MIDIPacket(timeStamp: 0, data: noteOff.bytes))
//        MIDISend(outputPort, destination, &packetList)

    }
    
    var body: some View {
        Text("Midi")
        Button(action: {
            test()
        }) {
            Image(systemName: "music.note")
        }

    }
}


