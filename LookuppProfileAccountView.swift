import SwiftUI
import FirebaseAuth
import Firebase
import UIKit

struct LookuppProfileAccountView: View, AppConfigProtocol {
    @EnvironmentObject var db: LookuppQuickContentDBModel
    @FocusState private var focusedField: Field?
    @State var showAlert: Bool = false
    @State private var name = ""
    @State var remoteMessage = ""
    @State private var currentPoints = ""
    @State private var totalPoints = ""
    @State private var remoteMessageButton = LookuppQuickContentDBModel.shared.localUserDB1.remoteNotificationSound ?? true
    @State private var emmitterID = ""
    @State private var beaconTimeLimit = 180
    @State private var awardID = ""
    @State private var isRevalidateFordelete = false
    @State private var isUpdate = false
    @Binding var isNavigationActive: Bool
    @Binding var showToast: Bool
    @State var toggleOn: Bool = true
    @State private var email = ""
    @State private var researchCode = ""
    @State private var region = ""
    @State var alert = false
    @State var error = ""
    @State var title = ""
    @State var focused: Bool = false
    private let oldPasswordToConfirmAgainst = ""
    @State private var oldPassword = ""
    @State private var password = ""
    
    @State private var newPassword = ""
    @State private var confirmedPassword = ""
    @State private var role = "NA"
    var updateButton: Bool = false
    @State var backText = ""
    @State private var hasInitialized = false
    
    @State var isFinished = false
    
    var body: some View {
        NavigationView {
            Form {
                // General Information
                Section(header: Text("General Information").font(.title3).textCase(nil)) {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Enter Your Name", text: $name)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.primary)
                            .focused($focusedField, equals: .name)
                    }.font(.csubheadline)
                        .onChange(of: name) { newValue in
                            guard hasInitialized else { return }
                            guard !newValue.isEmpty else { return }
                            name = newValue
                            updateProfileFromLocalDB1()
                        }
                    
                    HStack {
                        Text("Role")
                        Spacer()
                        TextField("", text: $role)
                            .disabled(true)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }.font(.csubheadline)
                    
                    HStack {
                        Text("Research Code")
                        Spacer()
                        TextField("", text: $researchCode)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.primary)
                            .focused($focusedField, equals: .researchCode)
                    }.font(.csubheadline)
                        .onChange(of: researchCode) { newValue in
                            guard hasInitialized else { return }
                            var acceptableResearchCodes = ["NA", "UNCW_1", "UNCW_2", "UNCW_3", "JTH", "IBECHS", "ASH"]
                            guard acceptableResearchCodes.contains(researchCode) else { return }
                            researchCode = newValue
                            updateProfileFromLocalDB1()
                        }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        TextField("", text: $email)
                            .disabled(true)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }.font(.csubheadline)
                    
                    Picker("Region", selection: $region) {
                        ForEach(["New Hanover County, NC", "Prince William County, VA", "Santa Clara County, CA", "Warsaw, Poland", "NA"], id: \.self) {
                            Text($0).foregroundColor(.primary)
                        }
                    }
                    .pickerStyle(.menu)
                    .accentColor(.primary)
                    .font(.csubheadline)
                    .foregroundColor(.primary)
                    .onChange(of: region) { newValue in
                        guard hasInitialized else { return }
                        guard !newValue.isEmpty else { return }
                        region = newValue
                        updateProfileFromLocalDB1()
                    }
                }
                
                // Points Information
                if TimeService.timeservice.getPointDisplayStatus(context: "accountPointStats") {
                    Section(header: Text("Points Information").font(.title3).textCase(nil)) {
                        HStack {
                            Text("Current Points")
                            Spacer()
                            TextField("", text: $currentPoints)
                                .disabled(true)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.secondary)
                        }.font(.csubheadline)
                        
                        HStack {
                            Text("Lifetime Points")
                            Spacer()
                            TextField("", text: $totalPoints)
                                .disabled(true)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.secondary)
                        }.font(.csubheadline)
                        
                        Stepper(value: $beaconTimeLimit, in: 10...180, step: 10) {
                            Text("Zone Time Limit: \(beaconTimeLimit) min")
                        }
                        .font(.csubheadline)
                        .onChange(of: beaconTimeLimit) { newValue in
                            guard hasInitialized else { return }
                            updateProfileFromLocalDB1()
                        }
                    }
                }
                
                // Notification Settings
                Section(header: Text("Notification Settings").font(.title3).textCase(nil)) {
                    Toggle(isOn: $remoteMessageButton) {
                        Text("Sound")
                    }
                    .font(.csubheadline)
                    .onChange(of: remoteMessageButton) {
                        guard hasInitialized else { return }
                        LookuppQuickContentDBModel.shared.localUserDB1.remoteNotificationSound = $0
                        updateProfileFromLocalDB1()
                    }
                    
                    HStack {
                        Text("Emitter ID")
                        Spacer()
                        TextField("", text: $emmitterID)
                            .disabled(true)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }.font(.csubheadline)
                    
                    HStack {
                        Text("Message")
                        Spacer()
                        NavigationLink(destination: LookuppRemoteMessageDetailsView(remoteMessage: $remoteMessage, remoteMessageButton: $remoteMessageButton)) {}
                    }.font(.csubheadline)
                }
                
                // Reset Password
                Section(header: Text("Password").font(.title3).textCase(nil)) {
                    SecureField("Enter old password", text: $oldPassword)
                        .font(.csubheadline)
                        .focused($focusedField, equals: .oldPassword)
                    
                    SecureField("New Password", text: $newPassword)
                        .font(.csubheadline)
                        .focused($focusedField, equals: .newPassword)
                    
                    SecureField("Confirm New Password", text: $confirmedPassword)
                        .font(.csubheadline)
                        .focused($focusedField, equals: .confirmedPassword)
                    
                    Button("Reset Password") {
                        guard !oldPassword.isEmpty else {
                            TimeService.timeservice.setAppAlert(title: "Input Error", message: "Old password cannot be empty!", type: 0)
                            showToast.toggle()
                            return
                        }
                        
                        guard !newPassword.isEmpty else {
                            TimeService.timeservice.setAppAlert(title: "Input Error", message: "New password cannot be empty!", type: 0)
                            showToast.toggle()
                            return
                        }
                        
                        guard newPassword == confirmedPassword else {
                            TimeService.timeservice.setAppAlert(title: "Input Error", message: "Passwords do not match!", type: 0)
                            showToast.toggle()
                            return
                        }
                        
                        let localerror = changePassword()
                        if !localerror.isEmpty {
                            TimeService.timeservice.setAppAlert(title: "Password Update Error", message: localerror, type: 0)
                        } else {
                            TimeService.timeservice.setAppAlert(title: "Success", message: "Your password has been updated!", type: 1)
                        }
                        showToast.toggle()
                    }
                    .font(.csubheadline)
                }
                
                // Delete Profile
                Section {
                    Button(action: {
                        isRevalidateFordelete = true
                    }) {
                        Text("Delete Profile")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationBarTitle("Account", displayMode: .inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text("Old password incorrect"), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                guard !hasInitialized else { return }
                
                Task {
                    TimeService.timeservice.loadUserStatsFromDB()
                    LookuppQuickContentDBModel.shared.getUserProfileDetails()
                    await TimeService.timeservice.waitUntilUserStatsLoadedAsync()
                    
                    let user = LookuppQuickContentDBModel.shared.localUserDB1
                    name = user.name
                    email = user.email
                    role = user.role!
                    emmitterID = user.emmitterCode!
                    awardID = user.awardID!
                    beaconTimeLimit = user.beaconTimeLimit!
                    researchCode = user.researchCode!
                    region = user.region
                    currentPoints = "\(user.currentPoints)"
                    totalPoints = "\(user.totalPoints)"
                    remoteMessageButton = user.remoteNotificationSound ?? true
                    hasInitialized = true
                }
            }
            .onDisappear {
                isNavigationActive.toggle()
            }
            .background(Color(appConfig.mainThemeBackgroundColor))
            .popover(isPresented: $isRevalidateFordelete) {
                ZStack {
                    Color.white.opacity(0.7).edgesIgnoringSafeArea(.all)
                    VStack(spacing: 20) {
                        Text("Your entire score will be erased. If you still wish to delete your account, please reauthenticate.")
                            .font(.csubheadline)
                        
                        if Auth.auth().currentUser?.providerData.first?.providerID == "password" {
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            HStack {
                                Button("Cancel") {
                                    isRevalidateFordelete.toggle()
                                }
                                Spacer()
                                Button("Delete") {
                                    userPasswordReAuthenticateAndDelete(password: password)
                                }
                            }
                        } else if Auth.auth().currentUser?.providerData.first?.providerID == "microsoft.com" {
                            HStack {
                                Button("Cancel") {
                                    isRevalidateFordelete.toggle()
                                }
                                Spacer()
                                Button("Delete") {
                                    userMicrosoftReAuthenticateAndDelete()
                                }
                            }
                        }
                    }
                    .frame(width: 300)
                    .padding()
                    .background(Color.red.opacity(0.7))
                    .cornerRadius(20)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
    
    /// Call this ONLY from the on‑change handlers that have `guard hasInitialized`.
    private func updateProfileFromLocalDB1() {
        let user = LookuppQuickContentDBModel.shared.localUserDB1
        
        guard hasInitialized,
              !user.emmitterCode!.isEmpty,
              !user.awardID!.isEmpty,
              !user.name.isEmpty else {
            print("⏳  Profile not ready – skipping update to avoid overwrite")
            return
        }
        
        LookuppQuickContentDBModel.shared.updateUserProfile(
            role: role,
            name: name,
            region: region,
            totalPoints: user.totalPoints,
            currentPoints: user.currentPoints,
            transactionID: user.emmitterCode ?? "NA",
            awardID: user.awardID ?? "NA",
            beaconTimeLimit: beaconTimeLimit,
            remoteNotificationSound: remoteMessageButton,
            researchCode: researchCode,
            remoteNotificationMessage: remoteMessage,
            termsAccepted: user.termsAccepted ?? false
        )
        
        TimeService.timeservice.setResearchCode(resCode: researchCode)
    }
    
    private func changePassword() -> String {
        var returnValue = "One or more password incorrectly entered or do not match"
        if !newPassword.isEmpty && newPassword == confirmedPassword && !oldPassword.isEmpty {
            LookuppQuickContentDBModel.shared.userPasswordReAuthenticateAndUpdate(oldPassword: self.oldPassword, newPassword: self.newPassword)
        }
        Thread.sleep(forTimeInterval: 1)
        return LookuppQuickContentDBModel.shared.localDBError
    }
    
    private func showAgreementAlert(title: String, error: String) {
        self.alert.toggle()
        self.title = title
        self.error = error
    }
    
    private func viewSignOut() {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        if let windowScenedelegate = scene?.delegate as? SceneDelegate {
            let window = UIWindow(windowScene: scene!)
            TimeService.timeservice.setwalkthoughStatus(walkthrough: false)
            TimeService.timeservice.setReloginStatus(relogin: false)
            windowScenedelegate.beaconemmitter = BeaconEmmiter()
            windowScenedelegate.homeview = homeviewobject()
            windowScenedelegate.notification = NotificationService()
            windowScenedelegate.db = LookuppQuickContentDBModel()
            window.rootViewController = HostingController(rootView: LookuppWalkthoughView().environmentObject(windowScenedelegate.beacon).environmentObject(windowScenedelegate.notification).environmentObject(windowScenedelegate.db).environmentObject(windowScenedelegate.beaconemmitter).environmentObject(windowScenedelegate.homeview))
            windowScenedelegate.window = window
            window.overrideUserInterfaceStyle = .light
            window.makeKeyAndVisible()
        }
    }
    
    func userPasswordReAuthenticateAndDelete(password: String) {
        var localDBError = ""
        let user = Auth.auth().currentUser
        let credential = EmailAuthProvider.credential(withEmail: LookuppQuickContentDBModel.shared.localUserDB1.email, password: password)
        user?.reauthenticate(with: credential, completion: { (authResult, error) in
            if error != nil {
                print("Re-authentication failed ", error!)
                localDBError = error!.localizedDescription
                TimeService.timeservice.setAppAlert(title: "Account Deletion Failed", message: localDBError, type: 0)
                showToast.toggle()
                isRevalidateFordelete.toggle()
                return
            } else {
                print(" Reautheticated successfully")
                LookuppQuickContentDBModel.shared.userDelete()
                if Auth.auth().currentUser == nil {
                    self.viewSignOut()
                }
                isRevalidateFordelete.toggle()
            }
            return
        })
    }
    
    func userMicrosoftReAuthenticateAndDelete() {
        guard let user = Auth.auth().currentUser else {
            print("❌ No current user found – cannot proceed with Microsoft reauth")
            TimeService.timeservice.setAppAlert(
                title: "Authentication Error",
                message: "No current user found",
                type: 0
            )
            showToast.toggle()
            isRevalidateFordelete.toggle()
            return
        }

        print("🔄 Starting Microsoft re-authentication for user: \(user.uid)")

        // Create the Microsoft OAuth provider
        let provider = OAuthProvider(providerID: "microsoft.com")
        
        // Set the scopes we need
        provider.scopes = ["User.Read", "offline_access"]
        
        // Set custom parameters if needed
        provider.customParameters = [
            "prompt": "select_account"
        ]

        print("📱 Presenting Microsoft sign-in...")
        
        // Present the sign-in flow
        provider.signIn(withPresenting: getRootViewController()) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Microsoft sign-in failed: \(error.localizedDescription)")
                    TimeService.timeservice.setAppAlert(
                        title: "Re-authentication Failed",
                        message: error.localizedDescription,
                        type: 0
                    )
                    showToast.toggle()
                    isRevalidateFordelete.toggle()
                    return
                }

                guard let result = result else {
                    print("❌ No result from Microsoft sign-in")
                    TimeService.timeservice.setAppAlert(
                        title: "Re-authentication Failed",
                        message: "No authentication result received",
                        type: 0
                    )
                    showToast.toggle()
                    isRevalidateFordelete.toggle()
                    return
                }

                print("✅ Microsoft sign-in successful, user: \(result.user.uid)")

                // Now re-authenticate with the credential
                let credential = result.credential
                user.reauthenticate(with: credential) { _, reauthError in
                    DispatchQueue.main.async {
                        if let reauthError = reauthError {
                            print("❌ Re-authentication failed: \(reauthError.localizedDescription)")
                            TimeService.timeservice.setAppAlert(
                                title: "Account Deletion Failed",
                                message: reauthError.localizedDescription,
                                type: 0
                            )
                            showToast.toggle()
                            isRevalidateFordelete.toggle()
                            return
                        }

                        print("🎉 Re-authentication succeeded")

                        // Now delete the user
                        LookuppQuickContentDBModel.shared.userDelete()
                        print("🗑️ Called userDelete() on DB model")

                        if Auth.auth().currentUser == nil {
                            print("✅ Firebase user deleted → signing out")
                            self.viewSignOut()
                        }
                        isRevalidateFordelete.toggle()
                    }
                }
            }
        }
    }

    // Helper function to get the root view controller
    private func getRootViewController() -> UIViewController {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            fatalError("Could not find root view controller")
        }
        
        // Find the topmost presented view controller
        var topController = rootViewController
        while let presentedController = topController.presentedViewController {
            topController = presentedController
        }
        
        return topController
    }

    private func handleDelete() {
        isRevalidateFordelete = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let providerID = Auth.auth().currentUser?.providerData.first?.providerID

            if providerID == "password" {
                userPasswordReAuthenticateAndDelete(password: password)
            } else if providerID == "microsoft.com" {
                userMicrosoftReAuthenticateAndDelete()
            } else {
                print("⚠️ Unknown provider: \(providerID ?? "nil")")
            }
        }
    }
}

struct ProfileRow: View {
    var label: String
    @Binding var value: String
    var editable: Bool = true
    @FocusState.Binding var focusedField: Field?
    var field: Field? = nil
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: $value)
                .disabled(!editable)
                .multilineTextAlignment(.trailing)
                .foregroundColor(editable ? .primary : .secondary)
                .focused($focusedField, equals: field)
        }
        .font(.csubheadline)
        .padding(.horizontal)
    }
}

struct SectionView<Content: View>: View {
    var title: String
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3)
                .textCase(nil)
                .padding(.horizontal)
            
            content()
        }
    }
}

struct RegionPicker: View {
    @Binding var region: String
    let options = ["New Hanover County, NC", "Prince William County, VA", "Santa Clara County, CA", "Warsaw, Poland", "NA"]
    
    var body: some View {
        Picker("Region", selection: $region) {
            ForEach(options, id: \.self) { option in
                Text(option).foregroundColor(.primary)
            }
        }
        .pickerStyle(.menu)
        .padding(.horizontal)
        .onChange(of: region) { newValue in
            LookuppQuickContentDBModel.shared.localUserDB1.region = newValue
        }
    }
}