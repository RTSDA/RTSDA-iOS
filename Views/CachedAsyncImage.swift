import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let scale: CGFloat
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.scale = scale
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let url = url {
                AsyncImage(
                    url: url,
                    scale: scale,
                    transaction: Transaction(animation: .easeInOut)
                ) { phase in
                    switch phase {
                    case .empty:
                        placeholder()
                    case .success(let image):
                        content(image)
                            .task {
                                await storeImageInCache(image: image, url: url)
                            }
                    case .failure(_):
                        placeholder()
                    @unknown default:
                        placeholder()
                    }
                }
                .task {
                    await loadImageFromCache(url: url)
                }
            } else {
                placeholder()
            }
        }
    }
    
    private func loadImageFromCache(url: URL) async {
        guard let cachedImage = await ImageCache.shared.image(for: url) else { return }
        _ = content(Image(uiImage: cachedImage))
    }
    
    private func storeImageInCache(image: Image, url: URL) async {
        // Convert SwiftUI Image to UIImage and cache it
        let renderer = ImageRenderer(content: content(image))
        if let uiImage = renderer.uiImage {
            await ImageCache.shared.setImage(uiImage, for: url)
        }
    }
} 