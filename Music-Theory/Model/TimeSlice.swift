import Foundation

class TimeSlice : Hashable  { //}: ObservableObject,  {
    //@Published
    var score:Score
    var note:[Note] 
    private static var idIndex = 0
    private var id = 0
    
    init(score:Score) {
        self.score = score
        self.note = []
        self.id = TimeSlice.idIndex
        TimeSlice.idIndex += 1
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(note)
    }
    
    func addNote(n:Note) {
        //DispatchQueue.main.async {
            self.note.append(n)
        score.update()
        //}
    }
    
    static func == (lhs: TimeSlice, rhs: TimeSlice) -> Bool {
        return lhs.id == rhs.id
    }
}
