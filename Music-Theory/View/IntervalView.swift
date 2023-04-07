import SwiftUI
import CoreData

//https://www.musictheory.net/calculators/interval
//https://www.musicca.com/interval-song-chart

struct IntervalView: View {
    @State var score:Score
    @ObservedObject var staff:Staff
    @State var songs = Songs()
    @State var intName:String?
    @State var scale:Scale
    @State var diatonic = true
    @State var descending = true
    @State var ascending = true
    @State var fixedRoot = false
    @State var lastNote1 = 0
    @State var lastNote2 = 0
    @State var queuedSpan = 0
    @State var intervalNotes: (Note, Note)
    @State var note1ScaleOffset = 0
    @State var answerCounter = 0
    @State var musicPlayer = MusicPlayer()
    @State private var showPopover = false
    @State private var songName = ""
    @State private var tempNoteIndex = 0
    @State private var animationAmount = 1.0
    @State var scaleAnim = 1.0
    
    init() {
        let key = Key.currentKey
        let score = Score()
        score.key = key
        let staff = Staff(score: score, type: .treble, staffNum: 0)
        score.tempo = Score.midTempo
        score.setStaff(num: 0, staff: staff)

        self.staff = staff
        self.scale = Scale(score: score)
        self.score = score
        self.intervalNotes = (Note(num: 0), Note(num: 0))
    }
    
    func setKey(key:Key) {
        score.setKey(key: key)
        scale = Scale(score: score)
    }
    
    func makeInterval() -> [Note] {
        var notes:[Note] = []
        while true {
            note1ScaleOffset = 0
            if !fixedRoot {
                let idx = Int.random(in: 0..<scale.diatonicOffsets().count)
                note1ScaleOffset = scale.diatonicOffsets()[idx]
            }
            let note1 = Note(num: scale.notes[0].num + note1ScaleOffset)
            
            var note2Distance = Int.random(in: -12..<12)
            //note2Distance = -2
            if note2Distance == 0 {
                continue
            }
            if ascending && !descending {
                if note2Distance < 0 {
                    continue
                }
            }
            if descending && !ascending {
                if note2Distance > 0 {
                    continue
                }
            }
            if diatonic {
                let offsets = scale.diatonicOffsets()
                var check = (note2Distance < 0) ? 12 + note2Distance : note2Distance
                check = (check + note1ScaleOffset) % 12
                if !offsets.contains(check) {
                    continue
                }
            }
            let note2 = Note(num: note1.num + note2Distance)

            if note1.num < Note.MIDDLE_C || note2.num < Note.MIDDLE_C {
                note2.num += 12
                note1.num += 12
            }
            
            if note1.num == lastNote1 && note2.num == lastNote2 {
                continue
            }
            
            let interval = note2.num - note1.num

            let (songName, _) = songs.song(base: Note(num: 0), interval: interval)
            if songName == nil {
                continue
            }
//            let ok = [7, -5, 9, 5, -4]  //TODO
//            if tempNoteIndex >= ok.count {
//                tempNoteIndex = 0
//            }
//            if interval != ok[tempNoteIndex] {
//                continue
//            }
            tempNoteIndex += 1
            lastNote1 = note1.num
            lastNote2 = note2.num
            notes.append(note1)
            notes.append(note2)
            return notes
        }
    }
    
    func notesToScore(notes : [Note]) {
        for note in notes {
            let ts = score.addTimeSlice()
            ts.addNote(n: note)
        }
    }
    
    func makeNoteSteps(interval: (Note, Note)) -> [Note] {
        var steps : [Note] = []
        let inc = interval.0.num < interval.1.num ? 1 : -1
        var num = interval.0.num
        while (num != interval.1.num) {
            let note = Note(num: num)
            if self.scale.noteInScale(note: note) {
                steps.append(note)
            }
            num += inc
        }

        steps.append(interval.1)
        return steps
    }

    func newInterval() {
        intName = nil
        answerCounter = 0
        score.clear()
        let notes = makeInterval()
        self.intervalNotes = (notes[0], notes[1])
        notesToScore(notes: notes)

        DispatchQueue.global(qos: .userInitiated).async {
            intName = ""
            let span = notes[1].num - notes[0].num
            queuedSpan = span
            while answerCounter < 8 {
                Thread.sleep(forTimeInterval: 0.5)
                answerCounter += 1
                //sleep(UInt32(1))
            }
            let intervals = Intervals()
            if span == queuedSpan {
                intName = "\(intervals.getName(span: abs(span)) ?? "none")"
            }
        }
        //score.setTempo(temp: Int(tempo))
        score.playScore()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScoreView(score: score).padding().onAppear {
                    setKey(key: Key.currentKey)
                }
                
                if intName == "" {
                    Button(action: {
                        answerCounter = 8
                        animationAmount = 1
                    }) {
                        Label(
                            title: { Text("") },
                            icon: {
                                Image("questionMark")
                                    .padding(16)
                                    .background(Color.blue.opacity(0.4))
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(.blue)
                                            .scaleEffect(animationAmount)
                                            .opacity(2 - animationAmount)
                                            .opacity(1)
                                            .animation(
                                                .easeInOut(duration: 1)
                                                .repeatForever(autoreverses: false),
                                                value: animationAmount
                                            )
                                    )
                                    .onAppear {
                                        animationAmount += 1
                                    }
                                    .onDisappear() {
                                        animationAmount = 1
                                    }
                            }
                        )
                        .frame(width: 20, height: 20)
                    }
                    .padding()
                }
                else {
                    if let intName = intName {
                        UIHiliteText(text: intName)//.font(.title) //.foregroundColor(.black).bold()
                    }
                }
                
                Button(action: {
                    newInterval()
                }) {
                    UIHiliteText(text: "Next Interval")//.foregroundColor(.purple) //.font(.title)
                }
                .padding()

                HStack {
                    Spacer()
                    Button("Play Again") {
                        //score.setTempo(temp: Int(tempo))
                        answerCounter = 0
                        score.playScore()
                    }
                    Spacer()
                    Button("Example") {
                        showPopover = true
                        let songs = Songs()
                        let base = self.intervalNotes.0
                        let interval = self.intervalNotes.1.num - self.intervalNotes.0.num
                        let (songName, notes) = songs.song(base: base, interval: interval) // 2
                        self.songName = songName ?? ""
                        musicPlayer.play(notes: notes)
                    }
                    .alert(isPresented: $showPopover) {
                        Alert(title: Text("Example"), message: Text(songName).font(.title), dismissButton: .default(Text("OK")))
                    }
                    Spacer()
                    Button("Play Steps") {
                        answerCounter = 0
                        score.clear()
                        let notes = makeNoteSteps(interval: self.intervalNotes)
                        notesToScore(notes: notes)
                        score.playScore(onDone: {answerCounter = 0})
                    }
                    Spacer()
                }
                .padding()
                
                VStack {
                    HStack {
                        Button(action: {
                            ascending = !ascending
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: ascending ? "checkmark.square": "square")
                                Text("Ascending")
                            }
                        }
                        Button(action: {
                            descending = !descending
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: descending ? "checkmark.square": "square")
                                Text("Descending")
                            }
                        }
                    }
                    .padding(8)
                    Button(action: {
                        diatonic = !diatonic
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: diatonic ? "checkmark.square": "square")
                            Text("Diatonic")
                        }
                    }
                    
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SetKeyView()) {
                        //Image(systemName: "arrow.right.circle")
                        UIHiliteText(text: "Change Key")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    UIHiliteText(text: "Tempo")
                }
            }
        }
   }

}
