import SwiftUI

struct AsyncImageView: View {
    let url: String
    let placeholder: String
    let contentMode: ContentMode
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var hasError = false
    
    init(url: String, placeholder: String = "photo", contentMode: ContentMode = .fill) {
        self.url = url
        self.placeholder = placeholder
        self.contentMode = contentMode
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if hasError {
                Image(systemName: placeholder)
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
            } else {
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let imageURL = URL(string: url) else {
            hasError = true
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("❌ Failed to load image: \(error.localizedDescription)")
                    hasError = true
                    return
                }
                
                guard let data = data, let loadedImage = UIImage(data: data) else {
                    print("❌ Failed to create image from data")
                    hasError = true
                    return
                }
                
                image = loadedImage
            }
        }.resume()
    }
}

#Preview {
    AsyncImageView(url: "https://example.com/image.jpg")
        .frame(width: 200, height: 200)
} 