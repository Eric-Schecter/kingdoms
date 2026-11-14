import AVFoundation
import AudioToolbox
import Foundation
struct Note { let time: Double; let duration: Double; let voice: Int; let pitch: UInt8; let velocity: UInt8 }
let bank = URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
let output = CommandLine.arguments[1]
for win in [true, false] {
 let engine = AVAudioEngine()
 let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
 let reverb = AVAudioUnitReverb(); reverb.loadFactoryPreset(.largeHall); reverb.wetDryMix = 24
 engine.attach(reverb); engine.connect(engine.mainMixerNode, to: reverb, format: format)
 engine.connect(reverb, to: engine.outputNode, format: format)
 var voices: [AVAudioUnitSampler] = []
 for program: UInt8 in [48,60,56,47,0] {
  let s = AVAudioUnitSampler(); engine.attach(s); engine.connect(s, to: engine.mainMixerNode, format: format)
  try s.loadSoundBankInstrument(at: bank, program: program, bankMSB: voices.count == 4 ? UInt8(kAUSampler_DefaultPercussionBankMSB) : UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: 0)
  s.volume = voices.count == 0 ? 0.68 : 0.55
  voices.append(s)
 }
 var notes: [Note] = []
 func add(_ t: Double,_ d: Double,_ v: Int,_ pitches: [Int],_ vel: UInt8) {
  for p in pitches { notes.append(Note(time:t,duration:d,voice:v,pitch:UInt8(p),velocity:vel)) }
 }
 if win {
  // D major: brisk brass pickup, dominant preparation, broad tonic cadence.
  for (t,p) in [(0.0,62),(0.28,66),(0.56,69),(0.95,74),(1.6,73),(1.95,76),(2.4,74)] {
   add(t,t == 2.4 ? 2.15 : 0.25,2,[p],100); add(t,0.3,1,[p-12],85)
  }
  add(0,0.85,0,[50,57,62,66],70); add(0.95,0.6,0,[55,62,67,71],78)
  add(1.6,0.7,0,[45,57,61,64],83); add(2.4,2.6,0,[38,50,57,62,66,69],88)
  add(2.4,2.2,1,[50,57,66],95)
  for t in [0.0,0.56,0.95,1.6,2.1,2.25,2.4] { add(t,0.5,3,[t < 2.4 ? 45 : 38],90) }
  add(2.4,1.5,4,[49],70)
 } else {
  // C minor: restrained horns, descending strings, low final chord.
  for (t,p) in [(0.0,67),(0.7,63),(1.4,62),(2.2,60)] { add(t,t == 2.2 ? 2.5 : 0.65,1,[p,p-12],76) }
  add(0,1.25,0,[48,55,60,63],70); add(1.4,0.7,0,[43,53,59,62],75)
  add(2.2,2.8,0,[36,48,55,60,63],78)
  add(0,0.8,3,[36],65); add(2.2,1.3,3,[36],82)
  add(2.2,1.5,4,[36],65)
 }
 struct Event { let frame:Int64; let note:Note; let on:Bool }
 var events:[Event]=[]
 for n in notes { events.append(Event(frame:Int64(n.time*44100),note:n,on:true)); events.append(Event(frame:Int64((n.time+n.duration)*44100),note:n,on:false)) }
 events.sort { $0.frame < $1.frame }
 try engine.enableManualRenderingMode(.offline, format:format, maximumFrameCount:512)
 try engine.start()
 let file = try AVAudioFile(forWriting: URL(fileURLWithPath: output + (win ? "/result-victory.wav" : "/result-defeat.wav")), settings:format.settings)
 let buffer=AVAudioPCMBuffer(pcmFormat:format,frameCapacity:512)!
 var cursor:Int64=0; var index=0
 while cursor < 352800 {
  while index < events.count && events[index].frame <= cursor {
   let e=events[index]; let s=voices[e.note.voice]
   if e.on { s.startNote(e.note.pitch, withVelocity:e.note.velocity,onChannel:0) } else { s.stopNote(e.note.pitch,onChannel:0) }
   index += 1
  }
  let next=index < events.count ? events[index].frame : 352800
  let count=AVAudioFrameCount(min(512,max(1,next-cursor)))
  let status=try engine.renderOffline(count,to:buffer)
  if status == .success { try file.write(from:buffer); cursor += Int64(count) }
 }
 engine.stop()
 print("Rendered \(win ? "victory" : "defeat") orchestra")
}
