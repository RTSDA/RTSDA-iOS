import SwiftUI

struct LivestreamCard: View {
    let livestream: Message
    
    var body: some View {
        NavigationLink {
            if let url = URL(string: livestream.videoUrl) {
                VideoPlayerView(url: url)
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail
                AsyncImage(url: URL(string: livestream.thumbnailUrl ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .aspectRatio(16/9, contentMode: .fill)
                .clipped()
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(livestream.title)
                        .font(.custom("Montserrat-SemiBold", size: 18))
                        .lineLimit(2)
                    
                    HStack {
                        Text(livestream.speaker)
                            .font(.custom("Montserrat-Regular", size: 14))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(livestream.formattedDate)
                            .font(.custom("Montserrat-Regular", size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    if livestream.isLiveStream {
                        Text("LIVE")
                            .font(.custom("Montserrat-Bold", size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
    }
} 