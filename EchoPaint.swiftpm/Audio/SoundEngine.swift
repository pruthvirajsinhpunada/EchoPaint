//
//  SoundEngine.swift
//  EchoPaint
//
//  AVFoundation-based sonification engine
//

import AVFoundation
import Foundation

/// Audio engine that generates continuous tones mapped to screen position
class SoundEngine: ObservableObject {
    
    // MARK: - Properties
    
    private var audioEngine: AVAudioEngine?
    private var toneNode: AVAudioSourceNode?
    
    private var currentFrequency: Float = 440.0
    private var currentPan: Float = 0.0
    private var currentAmplitude: Float = 0.0
    private var targetAmplitude: Float = 0.0
    
    // Waveform parameters
    private var phase: Float = 0.0
    private var isOnExistingLine: Bool = false
    
    // Frequency range (Hz)
    private let minFrequency: Float = 200.0
    private let maxFrequency: Float = 2000.0
    
    // Audio format
    private var sampleRate: Float = 44100.0
    
    @Published var isRunning: Bool = false
    
    // MARK: - Initialization
    
    init() {
        setupAudioSession()
        setupAudioEngine()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Setup
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        
        guard let engine = audioEngine else { return }
        
        let mainMixer = engine.mainMixerNode
        let outputFormat = mainMixer.outputFormat(forBus: 0)
        sampleRate = Float(outputFormat.sampleRate)
        
        // Create tone generator node
        let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 2)!
        
        toneNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            
            let bufferList = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let leftBuffer = bufferList[0]
            let rightBuffer = bufferList[1]
            
            guard let leftData = leftBuffer.mData?.assumingMemoryBound(to: Float.self),
                  let rightData = rightBuffer.mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }
            
            // Smooth amplitude changes to avoid clicks
            let ampStep: Float = 0.001
            
            for frame in 0..<Int(frameCount) {
                // Smooth amplitude transition
                if self.currentAmplitude < self.targetAmplitude {
                    self.currentAmplitude = min(self.currentAmplitude + ampStep, self.targetAmplitude)
                } else if self.currentAmplitude > self.targetAmplitude {
                    self.currentAmplitude = max(self.currentAmplitude - ampStep, self.targetAmplitude)
                }
                
                // Generate waveform
                let sample: Float
                if self.isOnExistingLine {
                    // Sawtooth wave (harmonic-rich) when on existing line
                    sample = self.currentAmplitude * (2.0 * (self.phase / (2.0 * .pi)) - 1.0)
                } else {
                    // Pure sine wave on empty canvas
                    sample = self.currentAmplitude * sin(self.phase)
                }
                
                // Apply stereo panning
                // Pan: -1 = full left, 0 = center, 1 = full right
                let leftGain = sqrt(0.5 * (1.0 - self.currentPan))
                let rightGain = sqrt(0.5 * (1.0 + self.currentPan))
                
                leftData[frame] = sample * leftGain
                rightData[frame] = sample * rightGain
                
                // Advance phase
                self.phase += 2.0 * .pi * self.currentFrequency / self.sampleRate
                if self.phase >= 2.0 * .pi {
                    self.phase -= 2.0 * .pi
                }
            }
            
            return noErr
        }
        
        guard let toneNode = toneNode else { return }
        
        engine.attach(toneNode)
        engine.connect(toneNode, to: mainMixer, format: format)
    }
    
    // MARK: - Control
    
    func start() {
        guard let engine = audioEngine, !engine.isRunning else { return }
        
        do {
            try engine.start()
            isRunning = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func stop() {
        targetAmplitude = 0.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.audioEngine?.stop()
            self?.isRunning = false
        }
    }
    
    // MARK: - Sound Control
    
    /// Update tone parameters based on touch position
    /// - Parameters:
    ///   - normalizedX: 0.0 (left) to 1.0 (right)
    ///   - normalizedY: 0.0 (bottom) to 1.0 (top)
    ///   - onExistingLine: Whether finger is over an existing drawn line
    func updateTone(normalizedX: CGFloat, normalizedY: CGFloat, onExistingLine: Bool) {
        // Map Y position to frequency (bottom = low, top = high)
        currentFrequency = minFrequency + Float(normalizedY) * (maxFrequency - minFrequency)
        
        // Map X position to stereo pan
        currentPan = Float(normalizedX * 2.0 - 1.0)
        
        // Set target amplitude
        targetAmplitude = 0.3
        
        // Update waveform type
        isOnExistingLine = onExistingLine
    }
    
    /// Begin playing tone (finger touched)
    func beginTone() {
        start()
        targetAmplitude = 0.3
    }
    
    /// End playing tone (finger lifted)
    func endTone() {
        targetAmplitude = 0.0
    }
    
    /// Play clear confirmation sweep
    func playClearSweep() {
        start()
        targetAmplitude = 0.3
        currentFrequency = maxFrequency
        isOnExistingLine = false
        
        // Sweep from high to low
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.currentFrequency -= 50
            
            if self.currentFrequency <= self.minFrequency {
                timer.invalidate()
                self.targetAmplitude = 0.0
            }
        }
    }
    
    /// Play resonant chord when shape is closed - the "wow" feature
    /// Uses a major chord (root + major 3rd + perfect 5th) with natural decay
    func playShapeClosedChord() {
        // Create a separate audio engine instance for chord playback
        // to avoid interfering with the continuous tone
        let chordEngine = AVAudioEngine()
        let mainMixer = chordEngine.mainMixerNode
        let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 2)!
        
        // Chord frequencies (E4 major chord - warm, celebratory sound)
        let root: Float = 329.63       // E4
        let majorThird: Float = 415.30 // G#4
        let perfectFifth: Float = 493.88 // B4
        
        var chordPhases: [Float] = [0, 0, 0]
        var envelope: Float = 0.0
        let attackTime: Float = 0.05
        let decayTime: Float = 0.8
        var elapsedTime: Float = 0.0
        let totalDuration: Float = attackTime + decayTime
        
        let chordNode = AVAudioSourceNode { [sampleRate = self.sampleRate] _, _, frameCount, audioBufferList -> OSStatus in
            let bufferList = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let leftBuffer = bufferList[0]
            let rightBuffer = bufferList[1]
            
            guard let leftData = leftBuffer.mData?.assumingMemoryBound(to: Float.self),
                  let rightData = rightBuffer.mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }
            
            for frame in 0..<Int(frameCount) {
                // Calculate envelope (attack + decay)
                if elapsedTime < attackTime {
                    // Attack phase - quick rise
                    envelope = elapsedTime / attackTime
                } else if elapsedTime < totalDuration {
                    // Decay phase - gradual fade with slight curve for resonance
                    let decayProgress = (elapsedTime - attackTime) / decayTime
                    envelope = (1.0 - decayProgress) * (1.0 - decayProgress) // Quadratic decay for resonance
                } else {
                    envelope = 0.0
                }
                
                // Generate chord (sum of three sine waves)
                let sample1 = sin(chordPhases[0]) * 0.33
                let sample2 = sin(chordPhases[1]) * 0.28 // Slightly quieter third
                let sample3 = sin(chordPhases[2]) * 0.33
                
                let sample = (sample1 + sample2 + sample3) * envelope * 0.5
                
                // Stereo spread - slightly pan each note for richness
                leftData[frame] = sample * 0.95 + sample1 * 0.05 * envelope * 0.5
                rightData[frame] = sample * 0.95 + sample3 * 0.05 * envelope * 0.5
                
                // Advance phases
                chordPhases[0] += 2.0 * .pi * root / sampleRate
                chordPhases[1] += 2.0 * .pi * majorThird / sampleRate
                chordPhases[2] += 2.0 * .pi * perfectFifth / sampleRate
                
                // Wrap phases
                for i in 0..<3 {
                    if chordPhases[i] >= 2.0 * .pi {
                        chordPhases[i] -= 2.0 * .pi
                    }
                }
                
                elapsedTime += 1.0 / sampleRate
            }
            
            return noErr
        }
        
        chordEngine.attach(chordNode)
        chordEngine.connect(chordNode, to: mainMixer, format: format)
        
        do {
            try chordEngine.start()
            
            // Stop after chord duration
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(totalDuration) + 0.1) {
                chordEngine.stop()
            }
        } catch {
            print("Failed to play shape closed chord: \(error)")
        }
    }
}
