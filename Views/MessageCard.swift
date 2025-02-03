import SwiftUI
import AVKit

struct MessageCard: View {
    let message: Message
    
    var body: some View {
        NavigationLink {
            if let url = URL(string: message.videoUrl) {
                VideoPlayerView(url: url)
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail
                AsyncImage(url: URL(string: message.thumbnailUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(16/9, contentMode: .fill)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(message.title)
                        .font(.custom("Montserrat-SemiBold", size: 18))
                        .lineLimit(2)
                    
                    HStack {
                        Text(message.speaker)
                            .font(.custom("Montserrat-Regular", size: 14))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(message.formattedDate)
                            .font(.custom("Montserrat-Regular", size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    if message.isLiveStream {
                        Text("LIVE")
                            .font(.custom("Montserrat-Bold", size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
} 