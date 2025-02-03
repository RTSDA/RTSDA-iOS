import SwiftUI

struct Belief: Identifiable {
    let id: Int
    let title: String
    let summary: String
    let verses: [String]
}

struct BeliefsView: View {
    let beliefs = [
        Belief(id: 1, title: "The Holy Scriptures", 
              summary: "The Holy Scriptures, Old and New Testaments, are the written Word of God, given by divine inspiration. The inspired authors spoke and wrote as they were moved by the Holy Spirit.",
              verses: ["2 Timothy 3:16-17", "2 Peter 1:20-21", "Psalm 119:105"]),
        
        Belief(id: 2, title: "The Trinity",
              summary: "There is one God: Father, Son, and Holy Spirit, a unity of three coeternal Persons.",
              verses: ["Deuteronomy 6:4", "Matthew 28:19", "2 Corinthians 13:14"]),
        
        Belief(id: 3, title: "The Father",
              summary: "God the eternal Father is the Creator, Source, Sustainer, and Sovereign of all creation.",
              verses: ["Genesis 1:1", "Revelation 4:11", "1 Corinthians 15:28"]),
        
        Belief(id: 4, title: "The Son",
              summary: "God the eternal Son became incarnate in Jesus Christ. Through Him all things were created, the character of God is revealed, the salvation of humanity is accomplished, and the world is judged.",
              verses: ["John 1:1-3", "John 1:14", "Colossians 1:15-19"]),
        
        Belief(id: 5, title: "The Holy Spirit",
              summary: "God the eternal Spirit was active with the Father and the Son in Creation, incarnation, and redemption.",
              verses: ["Genesis 1:1-2", "John 14:16-18", "John 16:7-13"]),
        
        Belief(id: 6, title: "Creation",
              summary: "God has revealed in Scripture the authentic and historical account of His creative activity. He created the universe, and in a recent six-day creation the Lord made 'the heavens and the earth, the sea, and all that is in them' and rested on the seventh day.",
              verses: ["Genesis 1-2", "Exodus 20:8-11", "Psalm 19:1-6"]),
        
        Belief(id: 7, title: "The Nature of Humanity",
              summary: "Man and woman were made in the image of God with individuality, the power and freedom to think and to do.",
              verses: ["Genesis 1:26-28", "Psalm 8:4-8", "Acts 17:24-28"]),
        
        Belief(id: 8, title: "The Great Controversy",
              summary: "All humanity is now involved in a great controversy between Christ and Satan regarding the character of God, His law, and His sovereignty over the universe.",
              verses: ["Revelation 12:4-9", "Isaiah 14:12-14", "Ezekiel 28:12-18"]),
        
        Belief(id: 9, title: "The Life, Death, and Resurrection of Christ",
              summary: "In Christ's life of perfect obedience to God's will, His suffering, death, and resurrection, God provided the only means of atonement for human sin.",
              verses: ["John 3:16", "Isaiah 53", "1 Peter 2:21-22"]),
        
        Belief(id: 10, title: "The Experience of Salvation",
              summary: "In infinite love and mercy God made Christ, who knew no sin, to be sin for us, so that in Him we might be made the righteousness of God.",
              verses: ["2 Corinthians 5:17-21", "John 3:16", "Galatians 1:4"]),
        
        Belief(id: 11, title: "Growing in Christ",
              summary: "By His death on the cross Jesus triumphed over the forces of evil. He who subjugated the demonic spirits during His earthly ministry has broken their power and made certain their ultimate doom.",
              verses: ["Philippians 2:5-8", "2 Corinthians 3:18", "1 Peter 1:23"]),
        
        Belief(id: 12, title: "The Church",
              summary: "The church is the community of believers who confess Jesus Christ as Lord and Savior. In continuity with the people of God in Old Testament times, we are called out from the world.",
              verses: ["Genesis 12:3", "Acts 7:38", "Ephesians 4:11-15"]),
        
        Belief(id: 13, title: "The Remnant and Its Mission",
              summary: "The universal church is composed of all who truly believe in Christ, but in the last days, a time of widespread apostasy, a remnant has been called out to keep the commandments of God and the faith of Jesus.",
              verses: ["Revelation 12:17", "Revelation 14:6-12", "2 Corinthians 5:10"]),
        
        Belief(id: 14, title: "Unity in the Body of Christ",
              summary: "The church is one body with many members, called from every nation, kindred, tongue, and people. In Christ we are a new creation.",
              verses: ["Psalm 133:1", "1 Corinthians 12:12-14", "Ephesians 4:4-6"]),
        
        Belief(id: 15, title: "Baptism",
              summary: "By baptism we confess our faith in the death and resurrection of Jesus Christ, and testify of our death to sin and of our purpose to walk in newness of life.",
              verses: ["Romans 6:1-6", "Colossians 2:12-13", "Acts 16:30-33"]),
        
        Belief(id: 16, title: "The Lord's Supper",
              summary: "The Lord's Supper is a participation in the emblems of the body and blood of Jesus as an expression of faith in Him, our Lord and Savior.",
              verses: ["1 Corinthians 10:16-17", "1 Corinthians 11:23-30", "Matthew 26:17-30"]),
        
        Belief(id: 17, title: "Spiritual Gifts and Ministries",
              summary: "God bestows upon all members of His church spiritual gifts which each member is to employ in loving ministry for the common good of the church and humanity.",
              verses: ["Romans 12:4-8", "1 Corinthians 12:9-11", "Ephesians 4:8"]),
        
        Belief(id: 18, title: "The Gift of Prophecy",
              summary: "The Scriptures testify that one of the gifts of the Holy Spirit is prophecy. This gift is an identifying mark of the remnant church and we believe it was manifested in the ministry of Ellen G. White.",
              verses: ["Joel 2:28-29", "Acts 2:14-21", "Revelation 12:17"]),
        
        Belief(id: 19, title: "The Law of God",
              summary: "The great principles of God's law are embodied in the Ten Commandments and exemplified in the life of Christ. They express God's love, will, and purposes.",
              verses: ["Exodus 20:1-17", "Psalm 40:7-8", "Matthew 22:36-40"]),
        
        Belief(id: 20, title: "The Sabbath",
              summary: "The gracious Creator, after the six days of Creation, rested on the seventh day and instituted the Sabbath for all people as a memorial of Creation.",
              verses: ["Genesis 2:1-3", "Exodus 20:8-11", "Mark 2:27-28"]),
        
        Belief(id: 21, title: "Stewardship",
              summary: "We are God's stewards, entrusted by Him with time and opportunities, abilities and possessions, and the blessings of the earth and its resources.",
              verses: ["Genesis 1:26-28", "1 Chronicles 29:14", "Malachi 3:8-12"]),
        
        Belief(id: 22, title: "Christian Behavior",
              summary: "We are called to be a godly people who think, feel, and act in harmony with biblical principles in all aspects of personal and social life.",
              verses: ["Romans 12:1-2", "1 Corinthians 10:31", "Philippians 4:8"]),
        
        Belief(id: 23, title: "Marriage and the Family",
              summary: "Marriage was divinely established in Eden and affirmed by Jesus to be a lifelong union between a man and a woman in loving companionship.",
              verses: ["Genesis 2:18-25", "Matthew 19:3-9", "Ephesians 5:21-33"]),
        
        Belief(id: 24, title: "Christ's Ministry in the Heavenly Sanctuary",
              summary: "There is a sanctuary in heaven, the true tabernacle that the Lord set up and not humans. In it Christ ministers on our behalf, making available to believers the benefits of His atoning sacrifice.",
              verses: ["Hebrews 8:1-5", "Hebrews 4:14-16", "Daniel 8:14"]),
        
        Belief(id: 25, title: "The Second Coming of Christ",
              summary: "The second coming of Christ is the blessed hope of the church, the grand climax of the gospel. The Savior's coming will be literal, personal, visible, and worldwide.",
              verses: ["Titus 2:13", "John 14:1-3", "Acts 1:9-11"]),
        
        Belief(id: 26, title: "Death and Resurrection",
              summary: "The wages of sin is death. But God, who alone is immortal, will grant eternal life to His redeemed. Until that day death is an unconscious state for all people.",
              verses: ["Romans 6:23", "1 Timothy 6:15-16", "Ecclesiastes 9:5-6"]),
        
        Belief(id: 27, title: "The Millennium and the End of Sin",
              summary: "The millennium is the thousand-year reign of Christ with His saints in heaven between the first and second resurrections. During this time the wicked dead will be judged.",
              verses: ["Revelation 20:1-6", "Jeremiah 4:23-26", "Revelation 21:1-5"]),
        
        Belief(id: 28, title: "The New Earth",
              summary: "On the new earth, in which righteousness dwells, God will provide an eternal home for the redeemed and a perfect environment for everlasting life, love, joy, and learning in His presence.",
              verses: ["2 Peter 3:13", "Isaiah 35", "Revelation 21:1-7"])
        
        // End of beliefs
    ]
    
    @State private var selectedBelief: Belief?
    
    private func formatVerseForURL(_ verse: String) -> String {
        // Convert "Romans 4:11" to "rom.4.11"
        let bookMap = [
            "Genesis": "gen", "Exodus": "exo", "Leviticus": "lev", "Numbers": "num",
            "Deuteronomy": "deu", "Joshua": "jos", "Judges": "jdg", "Ruth": "rut",
            "1 Samuel": "1sa", "2 Samuel": "2sa", "1 Kings": "1ki", "2 Kings": "2ki",
            "1 Chronicles": "1ch", "2 Chronicles": "2ch", "Ezra": "ezr", "Nehemiah": "neh",
            "Esther": "est", "Job": "job", "Psalm": "psa", "Psalms": "psa", "Proverbs": "pro",
            "Ecclesiastes": "ecc", "Song of Solomon": "sng", "Isaiah": "isa", "Jeremiah": "jer",
            "Lamentations": "lam", "Ezekiel": "ezk", "Daniel": "dan", "Hosea": "hos",
            "Joel": "jol", "Amos": "amo", "Obadiah": "oba", "Jonah": "jon",
            "Micah": "mic", "Nahum": "nam", "Habakkuk": "hab", "Zephaniah": "zep",
            "Haggai": "hag", "Zechariah": "zec", "Malachi": "mal", "Matthew": "mat",
            "Mark": "mrk", "Luke": "luk", "John": "jhn", "Acts": "act",
            "Romans": "rom", "1 Corinthians": "1co", "2 Corinthians": "2co", "Galatians": "gal",
            "Ephesians": "eph", "Philippians": "php", "Colossians": "col", "1 Thessalonians": "1th",
            "2 Thessalonians": "2th", "1 Timothy": "1ti", "2 Timothy": "2ti", "Titus": "tit",
            "Philemon": "phm", "Hebrews": "heb", "James": "jas", "1 Peter": "1pe",
            "2 Peter": "2pe", "1 John": "1jn", "2 John": "2jn", "3 John": "3jn",
            "Jude": "jud", "Revelation": "rev"
        ]
        
        let components = verse.components(separatedBy: " ")
        guard components.count >= 2 else { return verse.lowercased() }
        
        // Handle book name (including numbered books like "1 Corinthians")
        var bookName = ""
        var remainingComponents: [String] = components
        
        if let firstComponent = components.first, let _ = Int(firstComponent) {
            if components.count >= 2 {
                bookName = components[0] + " " + components[1]
                remainingComponents = Array(components.dropFirst(2))
            }
        } else {
            bookName = components[0]
            remainingComponents = Array(components.dropFirst())
        }
        
        guard let bookCode = bookMap[bookName] else { return verse.lowercased() }
        
        // Format chapter and verse
        let reference = remainingComponents.joined(separator: "")
            .replacingOccurrences(of: ":", with: ".")
            .replacingOccurrences(of: "-", with: "-")
        
        return "\(bookCode).\(reference)"
    }
    
    var body: some View {
        List {
            Text("The Seventh-day Adventist Church's 28 Fundamental Beliefs are a concise expression of our core beliefs. These beliefs reveal God's character and His plan for our lives.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
                .listRowSeparator(.hidden)
            
            ForEach(beliefs) { belief in
                Button(action: {
                    selectedBelief = belief
                }) {
                    HStack {
                        Text("\(belief.id).")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        
                        Text(belief.title)
                            .font(.headline)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Our Beliefs")
        .sheet(item: $selectedBelief) { belief in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(belief.summary)
                            .font(.body)
                            .padding(.horizontal)
                        
                        if !belief.verses.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Key Verses")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(belief.verses, id: \.self) { verse in
                                    Button(action: {
                                        let formattedVerse = formatVerseForURL(verse)
                                        if let url = URL(string: "https://www.bible.com/bible/1/\(formattedVerse)") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        Text(verse)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "book.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemBackground))
                                }
                            }
                            .padding(.vertical)
                            .background(Color(.secondarySystemBackground))
                        }
                    }
                    .padding(.vertical)
                }
                .navigationTitle(belief.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            selectedBelief = nil
                        }
                    }
                }
            }
        }
    }
}
