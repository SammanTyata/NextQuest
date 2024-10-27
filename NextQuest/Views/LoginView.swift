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
    //@State private var path = NavigationPath()
    @State private var presentSheet: Bool = false
    
    @FocusState private var focusedField: Field?
    
    
    
    var body: some View {
        //NavigationStack (path: $path) {
        VStack{
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
                    .focused($focusedField, equals: .email) // this field is bound to the .email case
                    .onSubmit {
                        focusedField = .password
                    }
                    .onChange(of: email) {
                        enableButtons()
                    }
                
                SecureField("Password", text: $password)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .password) // this field is bound to the .email case
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
            
            HStack{
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
            .disabled(buttonsDisabled)
            .buttonStyle(.borderedProminent)
            .tint(Color("NextQuestColor"))
            .font(.title2)
            .padding(.top)
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationDestination(for: String.self) { view in
//                if view == "ListView"{
//                    ListView()
//                }
//            }
        }
        
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("OK", role: .cancel){}
        }
        
        .onAppear{
            // if logged in when app runs, navigate to the new screen and skip login screen
            if Auth.auth().currentUser != nil{
                print("Login Successful")
                //TODO Load List View
                //Done
                
                //path.append("ListView")
                presentSheet = true
            }
        }.fullScreenCover(isPresented: $presentSheet) {
            ListView()
        }
    }
    
    func enableButtons(){
        let emailIsGood = email.count > 6 && email.contains("@")
        let passwordIsGood = password.count > 6
        buttonsDisabled = !(emailIsGood && passwordIsGood)
    }
    
    func register(){
        
        Auth.auth().createUser(withEmail: email, password: password) { result,
            error in
            if let error = error{ //login error occured
                print("Sign Up Error: \(error.localizedDescription)")
                alertMessage = "Sign Up Error: \(error.localizedDescription)"
                showingAlert = true
            }
            
            else{
                print("User Registered")
                //TODO Load List View
                // Done
                
                //path.append("ListView")
                presentSheet = true
            }
        }
    }
    
    func login(){
        Auth.auth().signIn(withEmail: email, password: password) { result,
            error in
            if let error = error{ //login error occured
                print("Login Error: \(error.localizedDescription)")
                alertMessage = "Login Error: \(error.localizedDescription)"
                showingAlert = true
            }
            
            else{
                print("Login Successful")
                //TODO Load List View
                //Done
                
                //path.append("ListView")
                presentSheet = true
            }
        }
    }
    
    
}

#Preview {
    LoginView()
}
