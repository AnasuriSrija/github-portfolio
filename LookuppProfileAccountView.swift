import SwiftUI
import FirebaseAuth
import Firebase
import UIKit

enum Field {
    case name, researchCode, oldPassword, newPassword, confirmedPassword
}

struct LookuppProfileAccountView: View, AppConfigProtocol {
    @EnvironmentObject var db : LookuppQuickContentDBModel
    @FocusState private var focusedField: Field?
    @State var showAlert: Bool = false
    @State private var name = ""
    @State  var remoteMessage = ""
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
    @State var focused : Bool = false
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
                            guard hasInitialized else { return }   // ⛔ don't fire while loading
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
                            var acceptableResearchCodes = ["NA", "UNCW_1", "UNCW_2", "UNCW_3", "JTH", "IBECHS", "ASH"]// ⛔ don't fire while loading
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
                        guard hasInitialized else { return }   // ⛔ don't fire while loading
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
                        guard hasInitialized else { return }   // ⛔ don't fire while loading
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
                        }    else {
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
                    LookuppQuickContentDBModel.shared.getUserProfileDetails()   // ✅ add this
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
                    totalPoints =  "\(user.totalPoints)"
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
                        }  else if Auth.auth().currentUser?.providerData.first?.providerID == "microsoft.com" {
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
        
        // 1️⃣ – the profile object that already holds the *authoritative* server values
        let user = LookuppQuickContentDBModel.shared.localUserDB1
        
        // 2️⃣ – never push if critical fields are still blank
        guard hasInitialized,
              !user.emmitterCode!.isEmpty,
              !user.awardID!.isEmpty,
              !user.name.isEmpty else {
            print("⏳  Profile not ready – skipping update to avoid overwrite")
            return
        }
        
        LookuppQuickContentDBModel.shared.updateUserProfile(
            /* editable fields – come from @State */
            role:              role,
            name:              name,
            region:            region,
            
            /* points – use up‑to‑date ints from the model, not the text boxes */
            totalPoints:       user.totalPoints,
            currentPoints:     user.currentPoints,
            
            /* read‑only server fields – always take them from the model */
            transactionID:     user.emmitterCode ?? "NA",
            awardID:           user.awardID     ?? "NA",
            beaconTimeLimit:   beaconTimeLimit,
            
            /* the two fields that *can* change in the UI */
            remoteNotificationSound: remoteMessageButton,
            researchCode:      researchCode,
            
            /* message text comes from the editor */
            remoteNotificationMessage: remoteMessage,
            termsAccepted:   user.termsAccepted ?? false
        )
        
        TimeService.timeservice.setResearchCode(resCode: researchCode)
    }
    
    private func changePassword() -> String {
        
        var returnValue = "One or more password incorrectly entered or do not match"
        if !newPassword.isEmpty && newPassword == confirmedPassword && !oldPassword.isEmpty {
            LookuppQuickContentDBModel.shared.userPasswordReAuthenticateAndUpdate(oldPassword: self.oldPassword, newPassword: self.newPassword)}
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
            window.rootViewController = HostingController(rootView: LookuppWalkthoughView().environmentObject(windowScenedelegate.beacon).environmentObject(windowScenedelegate.notification).environmentObject(windowScenedelegate.db) .environmentObject(windowScenedelegate.beaconemmitter).environmentObject(windowScenedelegate.homeview))
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
                // Handle re-authentication error
                print("Re-authentication failed ", error! )
                localDBError = error!.localizedDescription
                TimeService.timeservice.setAppAlert(title: "Account Deletion Failed", message: localDBError, type: 0)
                showToast.toggle()
                isRevalidateFordelete.toggle()
                return
            } else {
                
                print (" Reautheticated successfully")
                
                LookuppQuickContentDBModel.shared.userDelete()
                
                if Auth.auth().currentUser == nil {
                    self.viewSignOut()}
                isRevalidateFordelete.toggle()}
            return
        }
        )
    }

    // FIXED: Microsoft re-authentication with proper UI context and error handling
    func userMicrosoftReAuthenticateAndDelete() {
        guard let user = Auth.auth().currentUser else {
            print("❌ No current user found – cannot proceed with Microsoft reauth")
            DispatchQueue.main.async {
                TimeService.timeservice.setAppAlert(
                    title: "Authentication Error",
                    message: "No authenticated user found",
                    type: 0
                )
                self.showToast.toggle()
                self.isRevalidateFordelete.toggle()
            }
            return
        }

        print("🔄 Starting Microsoft re-authentication for user: \(user.uid)")

        // Ensure we're on the main thread for UI-related operations
        DispatchQueue.main.async {
            let provider = OAuthProvider(providerID: "microsoft.com")
            provider.scopes = ["User.Read"]
            
            // Get the current UI window for presentation context
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                print("❌ Could not find window for OAuth presentation")
                TimeService.timeservice.setAppAlert(
                    title: "Authentication Error",
                    message: "Could not present authentication window",
                    type: 0
                )
                self.showToast.toggle()
                self.isRevalidateFordelete.toggle()
                return
            }
            
            print("🔄 Attempting to get Microsoft credential...")
            
            // Use the window's root view controller as presentation context
            provider.getCredentialWith(window.rootViewController) { [weak self] credential, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Failed to get Microsoft credential: \(error.localizedDescription)")
                        TimeService.timeservice.setAppAlert(
                            title: "Re-authentication Failed",
                            message: error.localizedDescription,
                            type: 0
                        )
                        self.showToast.toggle()
                        self.isRevalidateFordelete.toggle()
                        return
                    }

                    guard let credential = credential else {
                        print("❌ No credential returned from Microsoft provider")
                        TimeService.timeservice.setAppAlert(
                            title: "Re-authentication Failed",
                            message: "No credential received from Microsoft",
                            type: 0
                        )
                        self.showToast.toggle()
                        self.isRevalidateFordelete.toggle()
                        return
                    }

                    print("✅ Got Microsoft credential, attempting re-authenticate...")

                    user.reauthenticate(with: credential) { _, reauthError in
                        DispatchQueue.main.async {
                            if let reauthError = reauthError {
                                print("❌ Re-authentication failed: \(reauthError.localizedDescription)")
                                TimeService.timeservice.setAppAlert(
                                    title: "Account Deletion Failed",
                                    message: reauthError.localizedDescription,
                                    type: 0
                                )
                                self.showToast.toggle()
                                self.isRevalidateFordelete.toggle()
                                return
                            }

                            print("🎉 Re-authentication succeeded")
                            
                            // Proceed with account deletion
                            LookuppQuickContentDBModel.shared.userDelete()
                            print("🗑️ Called userDelete() on DB model")

                            // Check if user was actually deleted
                            if Auth.auth().currentUser == nil {
                                print("✅ Firebase user deleted → signing out")
                                self.viewSignOut()
                            } else {
                                print("⚠️ User still exists after deletion attempt")
                                TimeService.timeservice.setAppAlert(
                                    title: "Deletion Warning",
                                    message: "Account deletion may not have completed fully",
                                    type: 0
                                )
                                self.showToast.toggle()
                            }
                            self.isRevalidateFordelete.toggle()
                        }
                    }
                }
            }
        }
    }

    private func handleDelete() {
        // 1️⃣ Dismiss popover
        isRevalidateFordelete = false

        // 2️⃣ Run logic after popover closes
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
    @ViewBuilder var content: () -> Content  // ✅ ADD THIS LINE
    
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

// MARK: - Extension for missing Font
extension Font {
    static let csubheadline = Font.subheadline
}

// MARK: - Protocol and missing types (you'll need to implement these based on your app)
protocol AppConfigProtocol {
    var appConfig: AppConfig { get }
}

extension AppConfigProtocol {
    var appConfig: AppConfig {
        return AppConfig()
    }
}

struct AppConfig {
    let mainThemeBackgroundColor = UIColor.systemBackground
}

// MARK: - Placeholder types (replace with your actual implementations)
class LookuppQuickContentDBModel: ObservableObject {
    static let shared = LookuppQuickContentDBModel()
    var localUserDB1 = UserProfile()
    var localDBError = ""
    
    func updateUserProfile(role: String, name: String, region: String, totalPoints: Int, currentPoints: Int, transactionID: String, awardID: String, beaconTimeLimit: Int, remoteNotificationSound: Bool, researchCode: String, remoteNotificationMessage: String, termsAccepted: Bool) {
        // Implement your profile update logic
    }
    
    func getUserProfileDetails() {
        // Implement your profile loading logic
    }
    
    func userPasswordReAuthenticateAndUpdate(oldPassword: String, newPassword: String) {
        // Implement password update logic
    }
    
    func userDelete() {
        // Implement user deletion logic
    }
}

class UserProfile {
    var name = ""
    var email = ""
    var role: String? = "NA"
    var emmitterCode: String? = ""
    var awardID: String? = ""
    var beaconTimeLimit: Int? = 180
    var researchCode: String? = "NA"
    var region = ""
    var currentPoints = 0
    var totalPoints = 0
    var remoteNotificationSound: Bool? = true
    var termsAccepted: Bool? = false
}

class TimeService {
    static let timeservice = TimeService()
    
    func getPointDisplayStatus(context: String) -> Bool {
        return true
    }
    
    func loadUserStatsFromDB() {
        // Implement stats loading
    }
    
    func waitUntilUserStatsLoadedAsync() async {
        // Implement async waiting
    }
    
    func setAppAlert(title: String, message: String, type: Int) {
        // Implement alert setting
    }
    
    func setwalkthoughStatus(walkthrough: Bool) {
        // Implement walkthrough status
    }
    
    func setReloginStatus(relogin: Bool) {
        // Implement relogin status
    }
    
    func setResearchCode(resCode: String) {
        // Implement research code setting
    }
}

// MARK: - Additional placeholder classes
class SceneDelegate: UIWindowSceneDelegate {
    var window: UIWindow?
    var beacon = BeaconService()
    var notification = NotificationService()
    var db = LookuppQuickContentDBModel()
    var beaconemmitter = BeaconEmmiter()
    var homeview = homeviewobject()
}

class BeaconService: ObservableObject {}
class NotificationService: ObservableObject {}
class BeaconEmmiter: ObservableObject {}
class homeviewobject: ObservableObject {}

struct LookuppRemoteMessageDetailsView: View {
    @Binding var remoteMessage: String
    @Binding var remoteMessageButton: Bool
    
    var body: some View {
        Text("Remote Message Details")
    }
}

struct LookuppWalkthoughView: View {
    var body: some View {
        Text("Walkthrough View")
    }
}

class HostingController<Content: View>: UIHostingController<Content> {}