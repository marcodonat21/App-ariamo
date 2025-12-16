import SwiftUI
import UIKit

// --- COMPONENTI UI RIUTILIZZABILI ---

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(.system(.body, design: .rounded))
        .padding()
        .background(Color.white)
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 40)
    }
}

struct SocialButton: View {
    var text: String
    var icon: String
    var color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                Text(text)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(30)
            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 2)
        }
        .padding(.horizontal, 40)
    }
}

struct SocialButtonSmall: View {
    let icon: String
    var body: some View {
        Image(systemName: icon)
            .font(.title)
            .foregroundColor(.black)
            .padding()
            .background(Color.themeInput)
            .clipShape(Circle())
    }
}

struct GenderButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(isSelected ? .white : .gray)
                .padding()
                .frame(width: 100)
                .background(isSelected ? Color.appMint : Color.themeInput)
                .cornerRadius(20)
        }
    }
}

// --- CAMERA COMPONENT ---
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// --- EXTENSION GLOBALE (DEFINITA QUI UNA SOLA VOLTA) ---
extension View {
    func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
