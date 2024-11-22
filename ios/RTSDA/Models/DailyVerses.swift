import Foundation

struct DailyVerse {
    let id: String
    let theme: String
}

struct DailyVerses {
    static let verses: [DailyVerse] = [
        // Encouragement
        DailyVerse(id: "PHP.4.13", theme: "Strength"),
        DailyVerse(id: "ISA.41.10", theme: "Courage"),
        DailyVerse(id: "PSA.23.4", theme: "Comfort"),
        
        // Love
        DailyVerse(id: "JHN.3.16", theme: "God's Love"),
        DailyVerse(id: "1JN.4.19", theme: "Love"),
        DailyVerse(id: "ROM.5.8", theme: "God's Love"),
        
        // Faith
        DailyVerse(id: "HEB.11.1", theme: "Faith"),
        DailyVerse(id: "2CR.5.7", theme: "Faith"),
        DailyVerse(id: "MRK.11.24", theme: "Faith"),
        
        // Peace
        DailyVerse(id: "PHP.4.6-7", theme: "Peace"),
        DailyVerse(id: "JHN.14.27", theme: "Peace"),
        DailyVerse(id: "ISA.26.3", theme: "Peace"),
        
        // Hope
        DailyVerse(id: "ROM.15.13", theme: "Hope"),
        DailyVerse(id: "JER.29.11", theme: "Hope"),
        DailyVerse(id: "PSA.33.22", theme: "Hope"),
        
        // Wisdom
        DailyVerse(id: "JAM.1.5", theme: "Wisdom"),
        DailyVerse(id: "PRO.3.5-6", theme: "Guidance"),
        DailyVerse(id: "PSA.119.105", theme: "Guidance"),
        
        // Grace
        DailyVerse(id: "EPH.2.8-9", theme: "Grace"),
        DailyVerse(id: "2CR.12.9", theme: "Grace"),
        DailyVerse(id: "ROM.6.23", theme: "Grace"),
        
        // Joy
        DailyVerse(id: "PSA.16.11", theme: "Joy"),
        DailyVerse(id: "ROM.15.13", theme: "Joy"),
        DailyVerse(id: "PSA.30.5", theme: "Joy"),
        
        // Trust
        DailyVerse(id: "PRO.3.5-6", theme: "Trust"),
        DailyVerse(id: "PSA.56.3", theme: "Trust"),
        DailyVerse(id: "ISA.26.4", theme: "Trust"),
        
        // Salvation
        DailyVerse(id: "ACT.4.12", theme: "Salvation"),
        DailyVerse(id: "ROM.10.9", theme: "Salvation"),
        DailyVerse(id: "EPH.2.8-9", theme: "Salvation")
    ]
    
    static func getVerseForDate(_ date: Date = Date()) -> DailyVerse {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        
        // Use the day of the year to select a verse
        // We use modulo to wrap around if we have fewer verses than days
        let index = (dayOfYear - 1) % verses.count
        return verses[index]
    }
    
    static func getVerseForNextDays(_ count: Int, startingFrom date: Date = Date()) -> [DailyVerse] {
        var result: [DailyVerse] = []
        let calendar = Calendar.current
        
        for dayOffset in 0..<count {
            if let nextDate = calendar.date(byAdding: .day, value: dayOffset, to: date) {
                result.append(getVerseForDate(nextDate))
            }
        }
        
        return result
    }
}
