//
//  ContentView.swift
//  Maytrix
//  Matrix01 — SwiftUI port of index.html
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - Audio Manager

final class AudioManager: ObservableObject {
    @Published var bgMusicOn  = false
    @Published var ageMusicOn = false

    private var bgPlayer:         AVAudioPlayer?
    private var ageMusicPlayer:   AVAudioPlayer?
    private var villainPlayer:    AVAudioPlayer?
    private var thunderPlayer:    AVAudioPlayer?
    private var narratorPlayer:   AVAudioPlayer?
    private var screamPlayer:     AVAudioPlayer?
    private var spookyPlayer:     AVAudioPlayer?
    private var laughPlayer:      AVAudioPlayer?
    private var whisperPlayer:    AVAudioPlayer?
    private var shotgunPlayer:    AVAudioPlayer?
    private var fourVoicesPlayer: AVAudioPlayer?
    private var grenadePlayer:    AVAudioPlayer?

    private var thunderOn       = false
    private var thunderGapTask: DispatchWorkItem?
    private var introPlayed     = false

    func setup() {
        // Search bundle by full filename to handle special characters
        bgPlayer         = load("Untitled 4.mp3")
        ageMusicPlayer   = load("age-music.mp3")
        villainPlayer    = load("villain-intro.mp3")
        thunderPlayer    = load("thunder.mp3")
        narratorPlayer   = load("ElevenLabs_2026-03-01T21_40_40_Ezekiel \u{2013} raspy narrator_pvc_sp77_s40_sb75_se50_b_m2.mp3")
        screamPlayer     = load("a-whoa-female-scream-soun-wwpmi5wq.wav")
        spookyPlayer     = load("Spooky,_creepy,_eeri-1758049336211.mp3")
        laughPlayer      = load("freesound_community-succubus-laughter-71829 (1).mp3")
        whisperPlayer    = load("a_women_whispering_H-#2-1758097415704.mp3")
        shotgunPlayer    = load("kakaist-sound-shotgun-sfx-318127.mp3")
        fourVoicesPlayer = load("freesound_community-four_voices_whispering_2_wecho-6755.mp3")
        grenadePlayer    = load("grenade-sound.mp3")

        bgPlayer?.numberOfLoops       = -1;  bgPlayer?.volume       = 0.50
        ageMusicPlayer?.numberOfLoops = -1;  ageMusicPlayer?.volume = 0.75
        villainPlayer?.volume  = 0.80
        thunderPlayer?.volume  = 0.30
        narratorPlayer?.volume = 0.90
        screamPlayer?.volume   = 0.85

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        // Try auto-starting age music immediately
        startAgeMusic()
    }

    // Looks up a file in the bundle by exact filename (handles special chars)
    private func load(_ filename: String) -> AVAudioPlayer? {
        let all = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil) ?? []
        guard let url = all.first(where: { $0.lastPathComponent == filename }) else { return nil }
        return try? AVAudioPlayer(contentsOf: url)
    }

    // MARK: Age gate audio
    func startAgeMusic() {
        ageMusicPlayer?.play()
        if !introPlayed { introPlayed = true; villainPlayer?.play() }
        startThunder()
        ageMusicOn = true
    }

    func stopAgeMusic() {
        ageMusicPlayer?.pause(); ageMusicPlayer?.currentTime = 0
        villainPlayer?.pause();  villainPlayer?.currentTime  = 0
        stopThunder()
        ageMusicOn = false
    }

    func toggleAgeMusic() { ageMusicOn ? stopAgeMusic() : startAgeMusic() }

    // MARK: Thunder loop  (thunder → narrator → scream → gap → thunder …)
    private func startThunder() {
        thunderOn = true
        thunderPlayer?.currentTime = 0
        thunderPlayer?.play()
        pollThunder()
    }

    private func stopThunder() {
        thunderOn = false
        thunderGapTask?.cancel(); thunderGapTask = nil
        thunderPlayer?.stop();  thunderPlayer?.currentTime  = 0
        narratorPlayer?.stop(); narratorPlayer?.currentTime = 0
        screamPlayer?.stop();   screamPlayer?.currentTime   = 0
    }

    private func pollThunder() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self, self.thunderOn else { return }
            if !(self.thunderPlayer?.isPlaying ?? false) {
                self.narratorPlayer?.currentTime = 0; self.narratorPlayer?.play()
                self.pollNarrator()
            } else { self.pollThunder() }
        }
    }

    private func pollNarrator() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self, self.thunderOn else { return }
            if !(self.narratorPlayer?.isPlaying ?? false) {
                self.screamPlayer?.currentTime = 0; self.screamPlayer?.play()
                let task = DispatchWorkItem { [weak self] in
                    guard let self, self.thunderOn else { return }
                    self.screamPlayer?.stop()
                    self.thunderPlayer?.currentTime = 0; self.thunderPlayer?.play()
                    self.pollThunder()
                }
                self.thunderGapTask = task
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 3...7), execute: task)
            } else { self.pollNarrator() }
        }
    }

    // MARK: Main game audio
    func enterGame() { stopAgeMusic(); startBgMusic() }

    func startBgMusic() { bgPlayer?.currentTime = 0; bgPlayer?.play(); bgMusicOn = true }
    func stopBgMusic()  { bgPlayer?.pause(); bgMusicOn = false }
    func toggleBgMusic() { bgMusicOn ? stopBgMusic() : startBgMusic() }

    // MARK: Spooky sounds on emoji tap
    func maybePlaySpooky() {
        let r = Double.random(in: 0...1)
        if r < 0.05 {
            fourVoicesPlayer?.currentTime = 0; fourVoicesPlayer?.play()
        } else if r < 0.15 {
            whisperPlayer?.currentTime = 0; whisperPlayer?.play()
            let dur = whisperPlayer?.duration ?? 3
            DispatchQueue.main.asyncAfter(deadline: .now() + dur) { [weak self] in
                self?.shotgunPlayer?.currentTime = 0; self?.shotgunPlayer?.play()
            }
        } else if r < 0.25 {
            laughPlayer?.currentTime = 0; laughPlayer?.play()
        } else if r < 0.55 {
            spookyPlayer?.currentTime = 0; spookyPlayer?.play()
        }
    }

    func playGrenade() { grenadePlayer?.currentTime = 0; grenadePlayer?.play() }
}

// MARK: - Pixel art data

private let GHOST_EVIL: [[Int]] = [
    [0,0,1,1,1,1,1,1,0,0],
    [0,1,1,1,1,1,1,1,1,0],
    [1,1,1,1,1,1,1,1,1,1],
    [1,2,2,1,1,1,1,2,2,1],
    [1,1,3,3,1,1,3,3,1,1],
    [1,1,3,3,1,1,3,3,1,1],
    [1,1,1,1,1,1,1,1,1,1],
    [1,4,1,4,1,4,1,4,1,1],
    [1,0,1,0,1,0,1,0,0,1],
    [0,0,1,0,0,0,1,0,0,0]
]

private let GHOST_NICE: [[Int]] = [
    [0,0,0,1,1,1,1,0,0,0],
    [0,0,1,1,1,1,1,1,0,0],
    [0,1,1,1,1,1,1,1,1,0],
    [1,1,1,2,2,2,2,1,1,1],
    [1,1,1,2,3,2,3,1,1,1],
    [1,1,1,2,2,2,2,1,1,1],
    [1,1,1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1,1,1],
    [1,0,1,0,0,1,1,0,0,1]
]

// MARK: - Models

final class MatrixRain: ObservableObject {
    var drops: [CGFloat] = []
    var cols: Int = 0
    let fontSize: CGFloat = 16

    private static let chars: [Character] = {
        var arr = [Character]()
        var i = 0x30A2
        while i <= 0x30F3 { arr.append(Character(UnicodeScalar(i)!)); i += 2 }
        for c in "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ@#$%&*" { arr.append(c) }
        return arr
    }()

    func tick(width: CGFloat, height: CGFloat) {
        let newCols = Int(width / fontSize)
        if newCols != cols {
            cols = newCols
            drops = (0..<cols).map { _ in CGFloat(Int.random(in: -100...0)) }
        }
        for i in 0..<drops.count {
            if drops[i] * fontSize > height && Float.random(in: 0...1) > 0.975 {
                drops[i] = 0
            } else {
                drops[i] += 1
            }
        }
    }

    func randomChar() -> Character { MatrixRain.chars.randomElement()! }
}

struct EmojiTarget: Identifiable {
    let id = UUID()
    var pos: CGPoint
    let emoji: String
    var life: Double = 0
    let maxLife: Double
}

struct GrenadeTarget: Identifiable {
    let id = UUID()
    var pos: CGPoint
}

struct BombTarget: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let speed: CGFloat
}

struct SnakeSeg { var x: CGFloat; var y: CGFloat }

struct PointFlash: Identifiable {
    let id = UUID()
    let text: String
    var pos: CGPoint
    var opacity: Double = 1
    var dy: CGFloat = 0
}

final class GameState: ObservableObject {
    @Published var playerScore  = 0
    @Published var ghostScore   = 0
    @Published var raceOver     = false
    @Published var playerWon    = false
    @Published var emojis:   [EmojiTarget]   = []
    @Published var grenades: [GrenadeTarget] = []
    @Published var bombs:    [BombTarget]    = []
    @Published var flashes:  [PointFlash]    = []
    @Published var horrorText: String?       = nil
    @Published var showBloody  = false
    @Published var bgVisible   = false
    @Published var bgOpacity: Double = 0

    // Ghost animation vars (non-published for perf)
    @Published var ghostPos     = CGPoint(x: 200, y: 300)
    @Published var ghostAlpha: Double = 0.7
    @Published var ghostIsEvil  = true
    var ghostTargetId: UUID?    = nil
    var ghostFloatT  = 0.0; var ghostPhaseT   = 0.0
    var ghostFlickerT = 0.0; var ghostFlipT   = 0.0

    // Snake
    @Published var snakeSegs: [SnakeSeg] = []
    @Published var snakeActive = false
    var snakeWobble  = 0.0
    var snakeTimeLeft = 20.0

    var horrorIndex = 0
    private let horrorTexts = [
        "The dark one will destroy your soul inside the horror train.\nHe will cut away at your brain.\nYour heart will be his supper.\nYou will be in pain — you will be his dinner.",
        "Before the dark one kills you, he will feed you nightmares.\nYou will dream horrors beyond your imagination.\nTears of blood will fall down your face for years.\nUntil you die, you will be trapped in a nightmare.",
        "He lives inside the dole.\nHe has possessed the dole — it's where it hides its soul.\nIf you find it and kill it, you might live to tell the tale.\nBut be warned, no one has survived — you will fail."
    ]
    private let emojiList = ["😠","😊","😢","😭","😲","😂","😤","😡"]

    func randEmoji() -> String { emojiList.randomElement()! }

    func checkRace() {
        guard !raceOver else { return }
        if playerScore >= 1000 { raceOver = true; playerWon = true }
        else if ghostScore >= 1000 { raceOver = true; playerWon = false }
    }

    func flash(_ text: String, at pos: CGPoint) {
        flashes.append(PointFlash(text: text, pos: pos))
    }

    func maybeHorror() {
        guard Double.random(in: 0...1) < 0.05 else { return }
        horrorText = horrorTexts[horrorIndex % horrorTexts.count]
        horrorIndex += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.horrorText = nil
        }
    }

    func reset() {
        playerScore = 0; ghostScore = 0; raceOver = false; playerWon = false
        emojis = []; grenades = []; bombs = []; flashes = []; horrorText = nil
        snakeActive = false; snakeSegs = []; ghostTargetId = nil
        bgOpacity = 0; bgVisible = false; showBloody = false
    }
}

// MARK: - Root

struct ContentView: View {
    @StateObject private var audio = AudioManager()
    @State private var ageCleared = false

    var body: some View {
        Group {
            if ageCleared {
                MainGameView()
            } else {
                AgeGateView(onEnter: {
                    audio.enterGame()
                    ageCleared = true
                })
            }
        }
        .environmentObject(audio)
        .onAppear { audio.setup() }
    }
}

// MARK: - Age Gate

private struct AgeDrip: Identifiable {
    let id = UUID()
    var x: CGFloat
    var startY: CGFloat
    var length: CGFloat
    var speed: CGFloat
    var width: CGFloat
    var startTime: Date
}

struct AgeGateView: View {
    let onEnter: () -> Void
    @EnvironmentObject private var audio: AudioManager

    @State private var ageText       = ""
    @State private var errorMsg      = ""
    @State private var boltPath:     [(CGPoint, CGPoint)] = []
    @State private var boltOpacity:  Double  = 0
    @State private var skullBreath:  CGFloat = 0
    @State private var drips: [AgeDrip] = []

    private let warningLines = [
        "W A R N I N G", "TO ALL WHO DARE ENTER", "",
        "I warn you stranger,", "you are about to enter", "your worst nightmare.", "",
        "Sounds that you will fear,", "sounds that will chase you",
        "forever — so go ahead,", "drink your beer.",
        "It might be your last", "if you chose to enter here.", "",
        "You enter at your own risk.", "So clench your fist,",
        "don't get so scared you", "fall and crack your disk.", "",
        "This is just a warning", "to all who dare enter.",
        "You have been warned.", "You enter at your own risk."
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                // Animated blood drips
                TimelineView(.animation) { tl in
                    Canvas { ctx, size in
                        let now = tl.date
                        for drip in drips {
                            let elapsed = CGFloat(now.timeIntervalSince(drip.startTime))
                            let tipY = drip.startY + elapsed * drip.speed
                            guard tipY < size.height + drip.length + 20 else { continue }
                            var stem = Path()
                            stem.move(to: CGPoint(x: drip.x, y: tipY - drip.length))
                            stem.addLine(to: CGPoint(x: drip.x, y: tipY))
                            ctx.stroke(stem,
                                       with: .color(.init(red: 0.55, green: 0, blue: 0, opacity: 0.82)),
                                       style: StrokeStyle(lineWidth: drip.width, lineCap: .round))
                            let r = drip.width * 1.4
                            let bulb = Path(ellipseIn: CGRect(x: drip.x - r, y: tipY - r * 0.5,
                                                               width: r * 2, height: r * 2.2))
                            ctx.fill(bulb, with: .color(.init(red: 0.5, green: 0, blue: 0, opacity: 0.88)))
                        }
                    }
                }
                .ignoresSafeArea()

                // Lightning bolt — 4 DOF layers matching HTML (widest/blurriest → sharp)
                ZStack {
                    Canvas { ctx, _ in
                        var p = Path()
                        for (a, b) in boltPath { p.move(to: a); p.addLine(to: b) }
                        ctx.stroke(p, with: .color(.white),
                                   style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    }
                    .blur(radius: 22).opacity(0.16 * boltOpacity)

                    Canvas { ctx, _ in
                        var p = Path()
                        for (a, b) in boltPath { p.move(to: a); p.addLine(to: b) }
                        ctx.stroke(p, with: .color(Color(red: 0.82, green: 0.65, blue: 1)),
                                   style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    }
                    .blur(radius: 9).opacity(0.38 * boltOpacity)

                    Canvas { ctx, _ in
                        var p = Path()
                        for (a, b) in boltPath { p.move(to: a); p.addLine(to: b) }
                        ctx.stroke(p, with: .color(Color(red: 0.90, green: 0.80, blue: 1)),
                                   style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    }
                    .blur(radius: 2).opacity(0.70 * boltOpacity)

                    Canvas { ctx, _ in
                        var p = Path()
                        for (a, b) in boltPath { p.move(to: a); p.addLine(to: b) }
                        ctx.stroke(p, with: .color(Color(red: 0.97, green: 0.94, blue: 1)),
                                   style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
                    }
                    .opacity(boltOpacity)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .blendMode(.screen)

                // Vignette
                RadialGradient(
                    colors: [.clear, Color.black.opacity(0.65)],
                    center: .center,
                    startRadius: geo.size.width * 0.28,
                    endRadius: geo.size.width * 0.9
                )
                .ignoresSafeArea()

                // Main side-by-side layout
                HStack(alignment: .top, spacing: 0) {
                    formPanel(geo: geo)
                        .frame(width: geo.size.width * 0.52)
                    skullPanel(geo: geo)
                        .frame(width: geo.size.width * 0.48)
                }

                // Music toggle — top right
                VStack {
                    HStack {
                        Spacer()
                        Button { audio.toggleAgeMusic() } label: {
                            Text(audio.ageMusicOn ? "♪" : "♫")
                                .font(.system(size: 16))
                                .foregroundColor(audio.ageMusicOn
                                    ? Color(red: 0.85, green: 0, blue: 0)
                                    : Color(red: 0.3, green: 0, blue: 0))
                                .frame(width: 34, height: 34)
                                .background(Color(red: 0.22, green: 0, blue: 0).opacity(0.82))
                                .overlay(Circle().stroke(
                                    audio.ageMusicOn
                                        ? Color(red: 0.6, green: 0, blue: 0)
                                        : Color(red: 0.22, green: 0, blue: 0), lineWidth: 1))
                                .clipShape(Circle())
                        }
                        .opacity(audio.ageMusicOn ? 0.9 : 0.5)
                        .padding(.trailing, 16)
                        .padding(.top, 56)
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            scheduleLightning()
            spawnInitialDrips()
            // skullPush: scale 1.0→1.14, opacity 0.82→1.0, period 5 s
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                skullBreath = 1
            }
        }
    }

    // MARK: Form panel (left)

    @ViewBuilder
    private func formPanel(geo: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Spacer().frame(height: geo.size.height * 0.13)

            Text("MATRIX01")
                .font(.custom("Courier New", size: min(geo.size.width * 0.068, 26)).bold())
                .foregroundColor(Color(red: 0, green: 1, blue: 0.25))
                .shadow(color: Color(red: 0, green: 1, blue: 0.25), radius: 8)
                .shadow(color: Color(red: 0, green: 0.67, blue: 0.16), radius: 22)
                .tracking(3)

            Text("> YOU MUST BE 18+ TO ENTER")
                .font(.custom("Courier New", size: 8.5))
                .foregroundColor(Color(red: 0, green: 0.33, blue: 0))

            VStack(alignment: .leading, spacing: 3) {
                ForEach([
                    "> Tap ♫ for dark music",
                    "> Tap emojis for sounds",
                    "> Grenades = 50 pts",
                    "> Race ghost to 1000"
                ], id: \.self) { line in
                    Text(line)
                        .font(.custom("Courier New", size: 9))
                        .foregroundColor(Color(red: 0, green: 0.67, blue: 0.16))
                }
            }
            .padding(.top, 2)

            TextField("AGE", text: $ageText)
                .font(.custom("Courier New", size: 17))
                .foregroundColor(Color(red: 0, green: 1, blue: 0.25))
                .keyboardType(.numberPad)
                .frame(width: 72)
                .padding(6)
                .background(Color.black)
                .overlay(Rectangle().stroke(Color(red: 0, green: 0.67, blue: 0.16), lineWidth: 1))
                .padding(.top, 8)

            Button("ENTER") { checkAge() }
                .font(.custom("Courier New", size: 13))
                .foregroundColor(Color(red: 0, green: 1, blue: 0.25))
                .padding(.horizontal, 18).padding(.vertical, 7)
                .background(Color.black)
                .overlay(Rectangle().stroke(Color(red: 0, green: 0.67, blue: 0.16), lineWidth: 1))

            if !errorMsg.isEmpty {
                Text(errorMsg)
                    .font(.custom("Courier New", size: 9.5))
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: geo.size.width * 0.44, alignment: .leading)
            }

            Spacer()
        }
        .padding(.leading, max(geo.size.width * 0.055, 16))
    }

    // MARK: Skull + warning panel (right)

    @ViewBuilder
    private func skullPanel(geo: GeometryProxy) -> some View {
        let panelW: CGFloat = geo.size.width * 0.48
        let skullW: CGFloat = panelW          // sharp base fills the panel
        let dof1W:  CGFloat = panelW * 1.10  // DOF1 overflows panel slightly
        let dof2W:  CGFloat = panelW * 1.20  // DOF2 wider for visible halo

        VStack(spacing: 4) {
            Spacer().frame(height: geo.size.height * 0.03)

            ZStack {
                // Base layer — sharp, full panel width, breathing
                Image("skull")
                    .resizable().scaledToFit()
                    .frame(width: skullW)
                    .opacity(0.88 + 0.12 * skullBreath)
                    .scaleEffect(1.0 + 0.08 * skullBreath)
                    .contrast(1.15)
                    .brightness(0.04)

                // DOF layer 1 — 8 px blur, ring-masked (clear centre 0–30 %, halo 30–80 %)
                Image("skull")
                    .resizable().scaledToFit()
                    .frame(width: dof1W)
                    .blur(radius: 8)
                    .opacity((0.88 + 0.12 * skullBreath) * 0.70)
                    .scaleEffect(1.0 + 0.08 * skullBreath)
                    .mask {
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear,               location: 0.00),
                                .init(color: .clear,               location: 0.30),
                                .init(color: .black.opacity(0.55), location: 0.52),
                                .init(color: .black.opacity(0.90), location: 0.70),
                                .init(color: .black,               location: 0.82),
                            ]),
                            center: UnitPoint(x: 0.5, y: 0.40),
                            startRadius: 0,
                            endRadius: dof1W * 0.50
                        )
                    }

                // DOF layer 2 — 22 px blur, tight ring-mask (clear 0–14 %, halo 14–65 %)
                Image("skull")
                    .resizable().scaledToFit()
                    .frame(width: dof2W)
                    .blur(radius: 22)
                    .opacity((0.88 + 0.12 * skullBreath) * 0.50)
                    .scaleEffect(1.0 + 0.08 * skullBreath)
                    .mask {
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear,               location: 0.00),
                                .init(color: .clear,               location: 0.14),
                                .init(color: .black.opacity(0.35), location: 0.30),
                                .init(color: .black.opacity(0.80), location: 0.50),
                                .init(color: .black,               location: 0.65),
                            ]),
                            center: UnitPoint(x: 0.5, y: 0.40),
                            startRadius: 0,
                            endRadius: dof2W * 0.46
                        )
                    }

                // Subtle edge fade — just darkens the extreme corners, not the skull face
                RadialGradient(
                    colors: [.clear, Color.black.opacity(0.55)],
                    center: UnitPoint(x: 0.5, y: 0.40),
                    startRadius: panelW * 0.50,
                    endRadius: panelW * 0.90
                )
                .frame(width: panelW * 1.20, height: panelW * 1.40)
                .allowsHitTesting(false)
            }
            .frame(width: panelW, height: geo.size.height * 0.52)
            .clipped()

            // 3D blood warning text
            ScrollView(showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    warningTextLayer(dx: 3, dy: 3, blur: 7,   opacity: 0.18)
                    warningTextLayer(dx: 2, dy: 2, blur: 3.5, opacity: 0.32)
                    warningTextLayer(dx: 1, dy: 1, blur: 1.5, opacity: 0.52)
                    warningTextLayer(dx: 0, dy: 0, blur: 0,   opacity: 1.0)
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 16)
            }
            .frame(maxHeight: geo.size.height * 0.38)

            Spacer()
        }
        .padding(.trailing, 8)
    }

    private func warningTextLayer(dx: CGFloat, dy: CGFloat, blur: CGFloat, opacity: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(warningLines.indices, id: \.self) { i in
                Text(warningLines[i].isEmpty ? " " : warningLines[i])
                    .font(.custom("Courier New", size: 10))
                    .foregroundColor(Color(red: 0.8, green: 0.04, blue: 0))
            }
        }
        .offset(x: dx, y: dy)
        .blur(radius: blur)
        .opacity(opacity)
    }

    // MARK: Logic

    private func checkAge() {
        guard let val = Int(ageText) else { errorMsg = "PLEASE ENTER YOUR AGE."; return }
        if val < 18 { errorMsg = "ACCESS DENIED.\nMUST BE 18+"; ageText = ""; return }
        onEnter()
    }

    private func spawnInitialDrips() {
        let w = UIScreen.main.bounds.width
        drips = (0..<20).map { _ in
            AgeDrip(
                x: CGFloat.random(in: 0...w),
                startY: CGFloat.random(in: -120...0),
                length: CGFloat.random(in: 20...70),
                speed: CGFloat.random(in: 35...100),
                width: CGFloat.random(in: 1.5...3.5),
                startTime: Date().addingTimeInterval(-Double.random(in: 0...3.5))
            )
        }
        scheduleRespawn()
    }

    private func scheduleRespawn() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.2...3.0)) {
            let h = UIScreen.main.bounds.height
            let w = UIScreen.main.bounds.width
            drips = drips.filter { d in
                let y = d.startY + CGFloat(Date().timeIntervalSince(d.startTime)) * d.speed
                return y < h + d.length + 30
            }
            for _ in 0..<Int.random(in: 1...3) {
                drips.append(AgeDrip(
                    x: CGFloat.random(in: 0...w),
                    startY: -20,
                    length: CGFloat.random(in: 20...70),
                    speed: CGFloat.random(in: 35...100),
                    width: CGFloat.random(in: 1.5...3.5),
                    startTime: Date()
                ))
            }
            scheduleRespawn()
        }
    }

    // MARK: - Lightning bolt (midpoint-displacement, 4 DOF layers matching HTML)

    private func scheduleLightning() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.4...2.4)) {
            boltPath = generateBolt()
            withAnimation(.easeOut(duration: 0.06)) { boltOpacity = 1.0 }
            let hold = Double.random(in: 0.09...0.22)
            DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
                withAnimation(.easeIn(duration: 0.18)) { boltOpacity = 0.0 }
            }
            // Occasional double-flash (matching HTML's 32 % re-strike chance)
            if Bool.random() {
                let d1 = hold + Double.random(in: 0.06...0.12)
                DispatchQueue.main.asyncAfter(deadline: .now() + d1) {
                    boltPath = generateBolt()
                    withAnimation(.easeOut(duration: 0.04)) { boltOpacity = 0.75 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.07...0.12)) {
                        withAnimation(.easeIn(duration: 0.15)) { boltOpacity = 0.0 }
                    }
                }
            }
            scheduleLightning()
        }
    }

    /// Generates a top-to-bottom lightning bolt using midpoint displacement
    /// x position: 42 %–94 % of screen width (matching HTML rx() = 42+rand*52 vw)
    private func generateBolt() -> [(CGPoint, CGPoint)] {
        let bounds = UIScreen.main.bounds
        let w = bounds.width, h = bounds.height
        let cx = CGFloat.random(in: 0.42...0.94) * w
        let sx = cx + CGFloat.random(in: -w * 0.05...w * 0.05)
        let ex = cx + CGFloat.random(in: -w * 0.14...w * 0.14)
        var segs: [(CGPoint, CGPoint)] = []
        boltSegments(sx, -10, ex, h + 10, r: 0.26, depth: 5, out: &segs)
        return segs
    }

    /// Recursive midpoint-displacement: matches JS boltSegs(x1,y1,x2,y2,r,d,out)
    private func boltSegments(_ x1: CGFloat, _ y1: CGFloat,
                               _ x2: CGFloat, _ y2: CGFloat,
                               r: CGFloat, depth: Int,
                               out: inout [(CGPoint, CGPoint)]) {
        guard depth > 0 else {
            out.append((CGPoint(x: x1, y: y1), CGPoint(x: x2, y: y2)))
            return
        }
        let len = max(1, hypot(x2 - x1, y2 - y1))
        let nx  = -(y2 - y1) / len
        let ny  =  (x2 - x1) / len
        let mx  = (x1 + x2) / 2 + nx * CGFloat.random(in: -1...1) * r * len
        let my  = (y1 + y2) / 2 + ny * CGFloat.random(in: -1...1) * r * len
        boltSegments(x1, y1, mx, my, r: r * 0.62, depth: depth - 1, out: &out)
        boltSegments(mx, my, x2, y2, r: r * 0.62, depth: depth - 1, out: &out)
        // Branch (depth ≥ 3, 50 % chance) — matching HTML's forked lightning
        if depth >= 3, CGFloat.random(in: 0...1) < 0.5 {
            let bx = mx + CGFloat.random(in: -55...55)
            let by = my + 20 + CGFloat.random(in: 0...55)
            boltSegments(mx, my, bx, by, r: r * 0.55, depth: depth - 2, out: &out)
        }
    }

}

// MARK: - Main Game

struct MainGameView: View {
    @StateObject private var rain = MatrixRain()
    @StateObject private var game = GameState()
    @EnvironmentObject private var audio: AudioManager
    @State private var now        = Date()
    @State private var screenSize = CGSize.zero

    private let gameTick  = Timer.publish(every: 1/30, on: .main, in: .common).autoconnect()
    private let emojiTick = Timer.publish(every: 0.70, on: .main, in: .common).autoconnect()
    private let clockTick = Timer.publish(every: 1,    on: .main, in: .common).autoconnect()

    private var timeString: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f.string(from: now)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                // ── Matrix Rain ──────────────────────────────────────────
                TimelineView(.animation) { _ in
                    Canvas { ctx, size in
                        let fs = rain.fontSize
                        for (i, drop) in rain.drops.enumerated() {
                            let x = CGFloat(i) * fs + fs / 2
                            let headY = drop * fs
                            // Trail — green, fading toward black
                            let trailLen = 20
                            for t in 1...trailLen {
                                let ty = (drop - CGFloat(t)) * fs
                                guard ty > -fs && ty < size.height + fs else { continue }
                                let op = Double(trailLen - t) / Double(trailLen) * 0.85
                                ctx.draw(
                                    Text(String(rain.randomChar()))
                                        .font(.custom("Courier New", fixedSize: fs - 2))
                                        .foregroundColor(Color(red: 0, green: 1, blue: 0.25, opacity: op)),
                                    at: CGPoint(x: x, y: ty), anchor: .center)
                            }
                            // Head — near-white
                            guard headY > -fs && headY < size.height + fs else { continue }
                            ctx.draw(
                                Text(String(rain.randomChar()))
                                    .font(.custom("Courier New", fixedSize: fs - 2))
                                    .foregroundColor(Color(red: 0.93, green: 1, blue: 0.93)),
                                at: CGPoint(x: x, y: headY), anchor: .center)
                        }
                    }
                }
                .blendMode(.screen)

                // ── Blood overlay ────────────────────────────────────────
                if game.showBloody {
                    ZStack {
                        RadialGradient(colors: [Color(red:0.70,green:0,blue:0),.clear],
                                       center: .init(x:0.15,y:0.05), startRadius:0, endRadius:200)
                        RadialGradient(colors: [Color(red:0.60,green:0,blue:0),.clear],
                                       center: .init(x:0.85,y:0.08), startRadius:0, endRadius:200)
                        RadialGradient(colors: [Color(red:0.59,green:0,blue:0),.clear],
                                       center: .init(x:0.48,y:0.98), startRadius:0, endRadius:250)
                        RadialGradient(colors: [Color(red:0.31,green:0,blue:0).opacity(0.92), Color(red:0.02,green:0,blue:0)],
                                       center: .center, startRadius:0, endRadius:600)
                    }
                    .ignoresSafeArea().allowsHitTesting(false)
                }

                // ── Snake ────────────────────────────────────────────────
                if game.snakeActive {
                    Canvas { ctx, size in
                        for (j, seg) in game.snakeSegs.enumerated() {
                            let t  = 1 - CGFloat(j) / CGFloat(max(1, game.snakeSegs.count))
                            let r  = CGFloat(180 + 75 * t) / 255
                            let g  = CGFloat(20 * t) / 255
                            let rad = 9 * t + 1
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: seg.x-rad, y: seg.y-rad, width: rad*2, height: rad*2)),
                                with: .color(Color(red: r, green: g, blue: 0, opacity: Double(t * 0.95))))
                        }
                    }
                    .allowsHitTesting(false)
                }

                // ── Ghost ────────────────────────────────────────────────
                Canvas { ctx, _ in drawGhost(ctx: ctx) }
                    .allowsHitTesting(false)

                // ── Emoji targets ────────────────────────────────────────
                ForEach(game.emojis) { e in
                    Text(e.emoji)
                        .font(.system(size: 22))
                        .opacity(0.25)
                        .shadow(color: .red.opacity(0.4), radius: 5)
                        .position(e.pos)
                        .onTapGesture { tappedEmoji(e, size: geo.size) }
                }

                // ── Grenades ─────────────────────────────────────────────
                ForEach(game.grenades) { g in
                    ZStack {
                        Text("💣").font(.system(size: 54)).blur(radius: 12).opacity(0.25)
                        Text("💣").font(.system(size: 40)).blur(radius:  4).opacity(0.55)
                        Text("💣").font(.system(size: 32))
                            .shadow(color: Color(red:0,green:1,blue:0.27), radius: 18)
                    }
                    .position(g.pos)
                    .onTapGesture { tappedGrenade(g) }
                }

                // ── Bombs ────────────────────────────────────────────────
                ForEach(game.bombs) { b in
                    Text("💣")
                        .font(.system(size: 36))
                        .shadow(color: .red,    radius:  8)
                        .shadow(color: .orange, radius: 20)
                        .overlay(
                            Circle()
                                .stroke(Color(red:1,green:0.27,blue:0), lineWidth: 4)
                                .frame(width: 58, height: 58)
                        )
                        .position(CGPoint(x: b.x, y: b.y))
                        .onTapGesture { tappedBomb(b) }
                }

                // ── Horror text ──────────────────────────────────────────
                if let ht = game.horrorText {
                    ZStack {
                        Text(ht)
                            .font(.custom("Courier New", size: 15).bold())
                            .foregroundColor(Color(red:0,green:0.87,blue:0.25))
                            .multilineTextAlignment(.center)
                            .blur(radius: 16).opacity(0.10)
                        Text(ht)
                            .font(.custom("Courier New", size: 15).bold())
                            .foregroundColor(Color(red:0,green:0.93,blue:0.27))
                            .multilineTextAlignment(.center)
                            .blur(radius: 7).opacity(0.28)
                        Text(ht)
                            .font(.custom("Courier New", size: 15).bold())
                            .foregroundColor(Color(red:0,green:1,blue:0.25))
                            .multilineTextAlignment(.center)
                            .shadow(color: Color(red:0,green:1,blue:0.25), radius: 6)
                            .padding(24)
                            .background(Color(red:0,green:0.03,blue:0).opacity(0.88))
                            .overlay(Rectangle().stroke(Color(red:0,green:1,blue:0.25).opacity(0.18), lineWidth:1))
                    }
                    .frame(maxWidth: geo.size.width * 0.62)
                    .allowsHitTesting(false)
                }

                // ── Title ────────────────────────────────────────────────
                if game.horrorText == nil {
                    VStack(spacing: 8) {
                        Text("MATRIX01")
                            .font(.custom("Courier New", size: min(geo.size.width * 0.12, 80)).bold())
                            .foregroundColor(Color(red:0,green:1,blue:0.25))
                            .shadow(color: Color(red:0,green:1,blue:0.25), radius: 10)
                            .shadow(color: Color(red:0,green:1,blue:0.25), radius: 30)
                            .shadow(color: Color(red:0,green:0.67,blue:0.16), radius: 60)
                            .tracking(8)
                        Text("Wake up, Neo...")
                            .font(.custom("Courier New", size: min(geo.size.width * 0.025, 18)))
                            .foregroundColor(Color(red:0,green:0.67,blue:0.16))
                            .shadow(color: Color(red:0,green:0.67,blue:0.16), radius: 8)
                            .tracking(10)
                    }
                    .allowsHitTesting(false)
                }

                // ── Point flashes ────────────────────────────────────────
                ForEach(game.flashes) { f in
                    Text(f.text)
                        .font(.custom("Courier New", size: 16))
                        .foregroundColor(Color(red:0,green:1,blue:0.25))
                        .opacity(f.opacity)
                        .position(CGPoint(x: f.pos.x, y: f.pos.y + f.dy))
                        .allowsHitTesting(false)
                }

                // ── HUD ──────────────────────────────────────────────────
                VStack {
                    HStack {
                        Text("GHOST: \(game.ghostScore)")
                            .font(.custom("Courier New", size: 13))
                            .foregroundColor(Color(red:0.67,green:1,blue:0.87))
                            .shadow(color: Color(red:0.33,green:1,blue:0.67), radius: 6)
                            .padding(.leading, 20).padding(.top, 52)
                        Spacer()
                        Text("SCORE: \(game.playerScore)")
                            .font(.custom("Courier New", size: 13))
                            .foregroundColor(Color(red:0,green:0.67,blue:0.16))
                            .padding(.trailing, 20).padding(.top, 52)
                    }
                    Spacer()
                    HStack {
                        Button { audio.toggleBgMusic() } label: {
                            Text(audio.bgMusicOn ? "♪" : "♫")
                                .font(.system(size: 18))
                                .foregroundColor(audio.bgMusicOn
                                    ? Color(red:0,green:0.67,blue:0.16)
                                    : Color(white: 0.2))
                                .frame(width: 34, height: 34)
                                .overlay(Circle().stroke(
                                    audio.bgMusicOn ? Color(red:0,green:0.33,blue:0) : Color(white:0.13),
                                    lineWidth: 1))
                        }
                        .opacity(0.6)
                        .padding(.leading, 20).padding(.bottom, 24)
                        Spacer()
                        Text(timeString)
                            .font(.custom("Courier New", size: 11))
                            .foregroundColor(Color(red:0,green:0.33,blue:0))
                            .padding(.trailing, 20).padding(.bottom, 24)
                    }
                }

                // ── Race result ──────────────────────────────────────────
                if game.raceOver {
                    RaceResultView(playerWon: game.playerWon) {
                        game.reset()
                        scheduleBgCycle(size: geo.size)
                    }
                }
            }
            .ignoresSafeArea()
            .onAppear {
                screenSize = geo.size
                game.ghostPos = CGPoint(
                    x: CGFloat.random(in: 50...(max(50, geo.size.width  - 50))),
                    y: CGFloat.random(in: 50...(max(50, geo.size.height - 50))))
                scheduleBgCycle(size: geo.size)
            }
            .onReceive(gameTick) { _ in
                rain.tick(width: geo.size.width, height: geo.size.height)
                guard !game.raceOver else { return }
                tickGhost(size: geo.size)
                if game.snakeActive { tickSnake(size: geo.size) }
                tickBombs(size: geo.size)
                tickEmojis()
                tickFlashes()
                tickBgOpacity()
            }
            .onReceive(emojiTick) { _ in
                guard !game.raceOver else { return }
                for _ in 0..<3 { spawnEmoji(size: geo.size) }
            }
            .onReceive(clockTick) { _ in now = Date() }
        }
    }

    // MARK: - Draw ghost pixel art

    private func drawGhost(ctx: GraphicsContext) {
        let map = game.ghostIsEvil ? GHOST_EVIL : GHOST_NICE
        let px: CGFloat = 6
        let w = CGFloat(map[0].count) * px
        let h = CGFloat(map.count) * px
        let a = game.ghostAlpha
        for (row, rowArr) in map.enumerated() {
            for (col, v) in rowArr.enumerated() {
                guard v != 0 else { continue }
                let x = game.ghostPos.x - w/2 + CGFloat(col) * px
                let y = game.ghostPos.y - h/2 + CGFloat(row) * px
                let color: Color
                if game.ghostIsEvil {
                    switch v {
                    case 1:  color = Color(red:0.43,green:0,   blue:0.63, opacity:a)
                    case 2:  color = Color(red:0.16,green:0,   blue:0.24, opacity:a)
                    case 3:  color = Color(red:1,   green:0.12,blue:0,    opacity:a)
                    default: color = Color(red:0.94,green:0.82,blue:1,    opacity:a)
                    }
                } else {
                    switch v {
                    case 1:  color = Color(red:0.63,green:1,   blue:0.82, opacity:a)
                    case 2:  color = Color(white:1,              opacity:a)
                    default: color = Color(red:0,  green:0.31,blue:0.16,  opacity:a)
                    }
                }
                ctx.fill(Path(CGRect(x:x, y:y, width:px, height:px)), with: .color(color))
            }
        }
    }

    // MARK: - Tick helpers

    private func tickGhost(size: CGSize) {
        game.ghostFloatT   += 0.045
        game.ghostPhaseT   += 0.022
        game.ghostFlickerT += 0.3
        game.ghostFlipT    += 0.18
        game.ghostIsEvil    = sin(game.ghostFlipT) > 0

        let base = 0.45 + pow(max(0, sin(game.ghostPhaseT)), 0.4) * 0.5
        game.ghostAlpha = max(0.35, base * (1 - max(0, sin(game.ghostFlickerT)) * 0.12 * (1 - base)))

        // Re-target if needed
        if game.ghostTargetId == nil || !game.emojis.contains(where: { $0.id == game.ghostTargetId }) {
            game.ghostTargetId = game.emojis.first?.id
        }
        guard let tid    = game.ghostTargetId,
              let target = game.emojis.first(where: { $0.id == tid }) else { return }

        let dx = target.pos.x - game.ghostPos.x
        let dy = target.pos.y - game.ghostPos.y
        let dist = sqrt(dx*dx + dy*dy)
        if dist > 4 {
            let spd: CGFloat = 8.5
            game.ghostPos = CGPoint(
                x: max(0, min(size.width  - 40, game.ghostPos.x + (dx/dist)*spd + sin(game.ghostFloatT*1.1)*0.8)),
                y: max(0, min(size.height - 40, game.ghostPos.y + (dy/dist)*spd + cos(game.ghostFloatT*0.7)*0.5)))
        }
        if dist < 45 {
            game.ghostScore += 1
            game.flash("BOO!", at: CGPoint(x: game.ghostPos.x, y: game.ghostPos.y - 20))
            game.checkRace()
            game.emojis.removeAll { $0.id == tid }
            game.ghostTargetId = nil
        }
    }

    private func tickSnake(size: CGSize) {
        game.snakeTimeLeft -= 1.0/30.0
        if game.snakeTimeLeft <= 0 { game.snakeActive = false; game.snakeSegs = []; return }
        guard !game.snakeSegs.isEmpty else { return }
        game.snakeWobble += 0.008 * (1000.0/30.0)

        let head = game.snakeSegs[0]
        var angle: CGFloat
        if let t = game.emojis.first {
            let dx = t.pos.x - head.x; let dy = t.pos.y - head.y
            angle = atan2(dy, dx) + sin(CGFloat(game.snakeWobble)) * 0.9
        } else {
            angle = CGFloat(game.snakeWobble)
        }
        let spd: CGFloat = 14
        let newHead = SnakeSeg(
            x: max(0, min(size.width,  head.x + cos(angle)*spd)),
            y: max(0, min(size.height, head.y + sin(angle)*spd)))
        game.snakeSegs.insert(newHead, at: 0)
        if game.snakeSegs.count > 35 { game.snakeSegs.removeLast() }

        for (ci, em) in game.emojis.enumerated().reversed() {
            var hit = false
            for s in game.snakeSegs.prefix(6) {
                let ddx = s.x - em.pos.x; let ddy = s.y - em.pos.y
                if ddx*ddx + ddy*ddy < 60*60 { hit = true; break }
            }
            if hit {
                game.playerScore += 5
                game.flash("+5", at: em.pos)
                game.checkRace()
                game.emojis.remove(at: ci)
            }
        }
    }

    private func tickBombs(size: CGSize) {
        for i in game.bombs.indices.reversed() {
            game.bombs[i].y += game.bombs[i].speed
            if game.bombs[i].y > size.height + 60 { game.bombs.remove(at: i) }
        }
    }

    private func tickEmojis() {
        let dt = 1.0/30.0
        for i in game.emojis.indices.reversed() {
            game.emojis[i].life += dt
            if game.emojis[i].life >= game.emojis[i].maxLife { game.emojis.remove(at: i) }
        }
    }

    private func tickFlashes() {
        let dt = 1.0/30.0
        for i in game.flashes.indices.reversed() {
            game.flashes[i].opacity -= dt / 0.8
            game.flashes[i].dy      -= CGFloat(dt * 40)
            if game.flashes[i].opacity <= 0 { game.flashes.remove(at: i) }
        }
    }

    private func tickBgOpacity() {
        let target = game.bgVisible ? 0.75 : 0.0
        let diff   = target - game.bgOpacity
        if abs(diff) > 0.004 { game.bgOpacity += diff * 0.05 }
    }

    // MARK: - Interactions

    private func tappedEmoji(_ e: EmojiTarget, size: CGSize) {
        guard !game.raceOver else { return }
        game.playerScore += 1
        game.flash("+1", at: e.pos)
        game.checkRace()
        game.maybeHorror()
        audio.maybePlaySpooky()
        if game.playerScore % 100 == 0 { startSnake(size: size) }
        if Double.random(in: 0...1) < 0.30 { spawnGrenade(size: size) }
        game.emojis.removeAll { $0.id == e.id }
    }

    private func tappedGrenade(_ g: GrenadeTarget) {
        guard !game.raceOver else { return }
        audio.playGrenade()
        game.playerScore += 50
        game.flash("+50!", at: g.pos)
        game.checkRace()
        game.grenades.removeAll { $0.id == g.id }
    }

    private func tappedBomb(_ b: BombTarget) {
        game.playerScore = 0
        game.flash("SCORE RESET!", at: CGPoint(x: b.x, y: b.y))
        game.bombs.removeAll { $0.id == b.id }
    }

    // MARK: - Spawners

    private func spawnEmoji(size: CGSize) {
        guard game.emojis.count < 15 else { return }
        let m: CGFloat = 60
        game.emojis.append(EmojiTarget(
            pos: CGPoint(x: m + CGFloat.random(in: 0...(max(1, size.width  - m*2))),
                         y: m + CGFloat.random(in: 0...(max(1, size.height - m*2)))),
            emoji: game.randEmoji(),
            maxLife: Double.random(in: 3...7)))
    }

    private func spawnGrenade(size: CGSize) {
        let m: CGFloat = 90
        game.grenades.append(GrenadeTarget(pos: CGPoint(
            x: m + CGFloat.random(in: 0...(max(1, size.width  - m*2))),
            y: m + CGFloat.random(in: 0...(max(1, size.height - m*2))))))
        let id = game.grenades.last!.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            game.grenades.removeAll { $0.id == id }
        }
    }

    private func startSnake(size: CGSize) {
        guard !game.snakeActive else { return }
        let sx = CGFloat.random(in: 0...size.width)
        let sy = CGFloat.random(in: 0...size.height)
        game.snakeSegs = (0..<35).map { _ in SnakeSeg(x: sx, y: sy) }
        game.snakeWobble = 0; game.snakeTimeLeft = 20; game.snakeActive = true
    }

    private func spawnBombs(size: CGSize) {
        for _ in 0..<Int.random(in: 3...6) {
            game.bombs.append(BombTarget(
                x: CGFloat.random(in: 60...(max(60, size.width - 60))),
                y: -60,
                speed: CGFloat.random(in: 1.8...4.0)))
        }
    }

    private func scheduleBgCycle(size: CGSize) {
        let delay = game.bgVisible ? Double.random(in: 2...7) : Double.random(in: 1...5)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [game] in
            game.bgVisible.toggle()
            if !game.bgVisible {
                game.showBloody = true
                spawnBombs(size: size)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    game.showBloody = false
                }
            }
            scheduleBgCycle(size: size)
        }
    }
}

// MARK: - Race Result

struct RaceResultView: View {
    let playerWon: Bool
    let onPlayAgain: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()
            VStack(spacing: 20) {
                Text(playerWon ? "YOU WIN" : "GHOST WINS")
                    .font(.custom("Courier New", size: 60).bold())
                    .foregroundColor(playerWon
                        ? Color(red:0,green:1,blue:0.25)
                        : Color(red:0.8,green:0,blue:1))
                    .shadow(color: playerWon
                        ? Color(red:0,green:1,blue:0.25)
                        : Color(red:0.8,green:0,blue:1), radius: 20)
                    .tracking(8)
                    .minimumScaleFactor(0.35).lineLimit(1)
                    .multilineTextAlignment(.center)

                Text(playerWon
                    ? "You reached 1000 first.\nThe ghost retreats."
                    : "The ghost devoured 1000 souls before you.\nYou lose.")
                    .font(.custom("Courier New", size: 15))
                    .foregroundColor(Color(white: 0.67))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Button("PLAY AGAIN") { onPlayAgain() }
                    .font(.custom("Courier New", size: 18))
                    .foregroundColor(playerWon
                        ? Color(red:0,green:1,blue:0.25)
                        : Color(red:0.8,green:0,blue:1))
                    .padding(.horizontal, 40).padding(.vertical, 12)
                    .overlay(Rectangle().stroke(
                        playerWon ? Color(red:0,green:1,blue:0.25) : Color(red:0.8,green:0,blue:1),
                        lineWidth: 2))
                    .shadow(color: playerWon
                        ? Color(red:0,green:1,blue:0.25)
                        : Color(red:0.8,green:0,blue:1), radius: 12)
            }
        }
    }
}

#Preview {
    ContentView()
}
