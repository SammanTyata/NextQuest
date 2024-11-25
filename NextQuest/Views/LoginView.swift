//
//  LoginView.swift
//  NextQuest
//
//  Created by Samman Tyata on 10/24/24.
//
import SwiftUI
import Firebase
import FirebaseAuth

struct LoginView: View {
    
    enum Field {
        case email, password
    }
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var buttonsDisabled = true
    @State private var presentSheet: Bool = false
    @State private var isLoading = false  // Added loading state
    @State private var showResetPasswordAlert = false  // Show reset password alert
    @State private var resetEmail = ""  // Email for password reset
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        VStack {
            Image("Test")
                .resizable()
                .scaledToFit()
                .padding()
            
            Group {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .email)
                    .onSubmit {
                        focusedField = .password
                    }
                    .onChange(of: email) {
                        enableButtons()
                    }
                
                SecureField("Password", text: $password)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .password)
                    .onSubmit {
                        focusedField = nil
                    }
                    .onChange(of: password) {
                        enableButtons()
                    }
            }
            .textFieldStyle(.roundedBorder)
            .overlay{
                RoundedRectangle(cornerRadius: 5)
                    .stroke(.gray.opacity(0.5), lineWidth: 2)
            }
            .padding(.horizontal)
            
            HStack {
                Button {
                    login()
                } label: {
                    Text("Login")
                }
                .padding(.trailing)
                
                Button {
                    register()
                } label: {
                    Text("Sign Up")
                }
                .padding(.leading)
            }
            .disabled(buttonsDisabled || isLoading) // Disable buttons during loading
            .buttonStyle(.borderedProminent)
            .tint(Color("NextQuestColor"))
            .font(.title2)
            .padding(.top)
            
            // Password Reset Button
            Button {
                showResetPasswordAlert.toggle()
            } label: {
                Text("Forgot Password?")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding(.top)
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding(.top)
            }
        }
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert(isPresented: $showResetPasswordAlert) {
            Alert(
                title: Text("Enter your email to reset your password."),
                message: Text("We will send you a password reset link."),
                primaryButton: .default(Text("Send")) {
                    sendPasswordReset()
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            if Auth.auth().currentUser != nil {
                print("Login Successful")
                presentSheet = true
            }
        }
        .fullScreenCover(isPresented: $presentSheet) {
            ListView()
        }
    }
    
    func enableButtons() {
        let emailIsGood = email.count > 6 && email.contains("@")
        let passwordIsGood = password.count > 6
        buttonsDisabled = !(emailIsGood && passwordIsGood)
    }
    
    func register() {
        isLoading = true // Start loading
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            isLoading = false // Stop loading
            if let error = error {
                alertMessage = "Sign Up Error: \(error.localizedDescription)"
                showingAlert = true
            } else {
                print("User Registered")
                
                // Send email verification after successful registration
                Auth.auth().currentUser?.sendEmailVerification { error in
                    if let error = error {
                        alertMessage = "Error sending verification email: \(error.localizedDescription)"
                        showingAlert = true
                    } else {
                        alertMessage = "Please check your email to verify your account."
                        showingAlert = true
                    }
                }
            }
        }
    }
    
    func login() {
        isLoading = true // Start loading
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            isLoading = false // Stop loading
            if let error = error {
                alertMessage = "Login Error: \(error.localizedDescription)"
                showingAlert = true
            } else {
                // Check if the email is verified
                if let user = Auth.auth().currentUser, user.isEmailVerified {
                    print("Login Successful")
                    presentSheet = true
                } else {
                    alertMessage = "Please verify your email address before logging in."
                    showingAlert = true
                    
                    Auth.auth().currentUser?.sendEmailVerification { error in
                        if let error = error {
                            alertMessage = "Error sending verification email: \(error.localizedDescription)"
                            showingAlert = true
                        } else {
                            alertMessage = "Please check your email to verify your account."
                            showingAlert = true
                        }
                    }
                }
            }
        }
    }
    
    // Function to send password reset email
    func sendPasswordReset() {
        isLoading = true // Start loading
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            isLoading = false // Stop loading
            if let error = error {
                alertMessage = "Error resetting password: \(error.localizedDescription)"
                showingAlert = true
            } else {
                alertMessage = "Password reset email sent. Please check your inbox."
                showingAlert = true
            }
        }
    }
}

#Preview {
    LoginView()
}

