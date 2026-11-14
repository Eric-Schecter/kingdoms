import AVFoundation
import AudioToolbox
import Foundation
struct Note { let time: Double; let duration: Double; let voice: Int; let pitch: UInt8; let velocity: UInt8 }
let bank = URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
let output = CommandLine.arguments[1]
for cue in ["morale", "luck", "panic"] {
 let engine = AVAudioEngine()
 let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
 let reverb = AVAudioUnitReverb(); reverb.loadFactoryPreset(.largeHall); reverb.wetDryMix = 24
 engine.attach(reverb); engine.connect(engine.mainMixerNode, to: reverb, format: format)
 engine.connect(reverb, to: engine.outputNode, format: format)
 var voices: [AVAudioUnitSampler] = []
 for program: UInt8 in [48,60,10,47,0] {
  let s = AVAudioUnitSampler(); engine.attach(s); engine.connect(s, to: engine.mainMixerNode, format: format)
  try s.loadSoundBankInstrument(at: bank, program: program, bankMSB: voices.count == 4 ? UInt8(kAUSampler_DefaultPercussionBankMSB) : UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: 0)
  s.volume = voices.count == 0 ? 0.68 : 0.55
  voices.append(s)
 }
 var notes: [Note] = []
 func add(_ t: Double,_ d: Double,_ v: Int,_ pitches: [Int],_ vel: UInt8) {
  for p in pitches { notes.append(Note(time:t,duration:d,voice:v,pitch:UInt8(p),velocity:vel)) }
 }
 if cue == "morale" {
  for (t,p) in [(0.0,62),(0.18,69),(0.38,74)] { add(t,0.34,1,[p,p-12],110) }
  add(0.38,0.55,0,[50,57,62,66],85); add(0.38,0.25,3,[38],95)
 } else if cue == "luck" {
  for (t,p) in [(0.0,81),(0.09,85),(0.18,88),(0.30,93)] { add(t,0.4,2,[p],110) }
  add(0.30,0.4,4,[81],70)
 } else {
  add(0,0.3,1,[55,58],85); add(0.3,0.55,1,[49,52],85)
 }
 struct Event { let frame:Int64; let note:Note; let on:Bool }
 var events:[Event]=[]
 for n in notes { events.append(Event(frame:Int64(n.time*44100),note:n,on:true)); events.append(Event(frame:Int64((n.time+n.duration)*44100),note:n,on:false)) }
 events.sort { $0.frame < $1.frame }
 try engine.enableManualRenderingMode(.offline, format:format, maximumFrameCount:512)
 try engine.start()
 let file = try AVAudioFile(forWriting: URL(fileURLWithPath: output + "/proc-" + cue + ".wav"), settings:format.settings)
 let buffer=AVAudioPCMBuffer(pcmFormat:format,frameCapacity:512)!
 var cursor:Int64=0; var index=0
 while cursor < 79380 {
  while index < events.count && events[index].frame <= cursor {
   let e=events[index]; let s=voices[e.note.voice]
   if e.on { s.startNote(e.note.pitch, withVelocity:e.note.velocity,onChannel:0) } else { s.stopNote(e.note.pitch,onChannel:0) }
   index += 1
  }
  let next=index < events.count ? events[index].frame : 79380
  let count=AVAudioFrameCount(min(512,max(1,next-cursor)))
  let status=try engine.renderOffline(count,to:buffer)
  if status == .success { try file.write(from:buffer); cursor += Int64(count) }
 }
 engine.stop()
 print("Rendered proc cue")
}
