import SwiftUI
import UIKit

// --- REUSABLE UI COMPONENTS --- // Translated Comment

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
        .font(.system(.body, design: .rounded)) // ROUNDED FONT // Translated Comment
        .padding()
        .background(Color.white) // WHITE BACKGROUND // Translated Comment
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2) // Light shadow for separation // Translated Comment
        .padding(.horizontal, 40)
    }
}

// Large Social Button (Used in AuthLandingScreen for Login/Sign up with third parties) // Translated Comment
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

// NEW: Small Social Button (Used in AuthLandingScreen for social HStack) // Translated Comment
struct SocialButtonSmall: View {
    let icon: String
    var body: some View {
        Image(systemName: icon)
            .font(.title)
            .foregroundColor(.black)
            .padding()
            .background(Color.inputGray)
            .clipShape(Circle())
    }
}

// Button for Gender selection // Translated Comment
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
                .background(isSelected ? Color.appMint : Color.inputGray) // appMint from AppConstants
                .cornerRadius(20)
        }
    }
}

// --- PREVIEWS ---

struct ReusableComponents_Previews: PreviewProvider {
    @State static var testText = "Example" // Translated
    
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Test CustomTextField:")
            CustomTextField(placeholder: "Email", text: $testText)
            CustomTextField(placeholder: "Password", text: $testText, isSecure: true)
            
            Text("Test SocialButton:")
            SocialButton(text: "Connect with Google", icon: "g.circle.fill", color: .red)
            
            Text("Test GenderButton:")
            HStack {
                GenderButton(title: "Man", isSelected: true) {}
                GenderButton(title: "Woman", isSelected: false) {}
            }
            
            Text("Test SocialButtonSmall:")
            SocialButtonSmall(icon: "applelogo")
            
        }
        .padding(.top, 50)
        .background(Color.white)
    }
}

// --- CAMERA COMPONENT --- // Translated Comment
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera // Opens the camera // Translated Comment
        picker.allowsEditing = true // Allows cropping (square) // Translated Comment
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
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
