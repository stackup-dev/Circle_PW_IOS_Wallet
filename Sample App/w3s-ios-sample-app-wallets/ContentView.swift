// Copyright (c) 2023, Circle Technologies, LLC. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI
import CircleProgrammableWalletSDK

struct Wallet: Codable{
   let id: String
    let state: String
    let walletSetId: String
    let  custodyType: String
    let userId: String
    let address: String
    let blockchain: String
    let accountType: String
    let updateDate: String
    let createDate: String
}

struct ChallengeId: Decodable{
    let challengeId: String
}

enum AppState {
    case idle
    case loggingIn
    case regsitering
    case sendingTokens
    case retrieveBalance
}

enum Screens {
    case Login
    case Home
    case SendToken
    case Transactions
    case Transction
}

enum TokenOptions: CaseIterable, Identifiable, CustomStringConvertible{
    case FujiAvax
    case USDC

    var id: Self { self }
    
    var description: String{
        switch self {
        case .FujiAvax:
            return "Fuji AVAX"
        case .USDC:
            return "USDC"
        }
    }
    
    var tokenId:String{
        switch self {
        case .FujiAvax:
            return FujiAvaxTokenAddress
        case .USDC:
            return UsdcTokenAddress
        }
    }
}

let FujiAvaxTokenAddress = "87a5c41c-fcb4-5973-8c66-72e2ed851ab8"
let UsdcTokenAddress = "ff47a560-9795-5b7c-adfc-8f47dad9e06a"

struct Transaction: Identifiable, Decodable{
    let id: String
    let amounts: [String]

    let sourceAddress: String
    let state: String
    let updateDate: String
    let transactionType: String

    let createDate: String
    let destinationAddress : String
    let networkFee : String
    let tokenId: String
    let blockchain: String
}

let defaultTransaction : Transaction = Transaction(
    id: "Default"
    , amounts: ["Default"]
    , sourceAddress: "Default"
    , state: "Default"
    , updateDate: "Default"
    , transactionType: "Default"
    , createDate: "Default"
    , destinationAddress : "Default"
    , networkFee : "Default"
    , tokenId: "Default"
    , blockchain: "Default"
)

struct ContentView: View {
    
    let adapter = WalletSdkAdapter()
    
    let endPoint = "https://enduser-sdk.circle.com/v1/w3s"
    
    @State private var selectedOption: TokenOptions = .USDC
    //Step 1 - REPLACE PLACEHOLDER WITH YOUR APP ID
    @State var appId = "" // put your App ID here programmatically
    @State var apiKey = ""
    @State var userId = "" // Enter userID
    @State var userToken = ""
    @State var encryptionKey = ""
    @State var challengeId = ""
    @State var currentScreen : Screens = .Login
    @State var showToast = false
    @State var toastMessage: String?
    @State var toastConfig: Toast.Config = .init()
    @State var wallet: Wallet? = nil
    @State var appState : AppState = .idle
    @State var usdcBalance: String =  "0"
    @State var avaxBalance: String =  "0"
    @State var sendAmount: String  = "0"
    @State var destinationAddress: String = ""
    @State var transactionHistory: [Transaction] = [ ]
    @State var selectedTransaction: Transaction = defaultTransaction
    
    var body: some View {
        VStack {
        Image("circle-logo")
        List {
                switch  currentScreen{
                    case .Login:
                        sectionInputField("User ID", binding: $userId)
                        sectionInputField("API Key", binding: $apiKey)
                        loginButton
                        registerButton
                        Spacer()
                    case .Home:
                        HStack {
                            Image("avalanche-avax-logo").resizable().frame(width: 50,height: 50)
                            Text("Avalanche FUJI").font(.title)
                        }.listRowSeparator(.hidden)
                        HStack{
                            Text("My Wallet Address").font(.title2).bold()
                            Image("copy_icon").onTapGesture {
                                UIPasteboard.general.string = wallet?.address ?? "No Address"
                                showToast(.success, message: "Address Copied")
                            }
                        }.listRowSeparator(.hidden)
                        Text("Token Balance").font(.title2).bold().listRowSeparator(.hidden)
                        HStack {
                            Image("avalanche-avax-logo").resizable().frame(width: 40,height: 40)
                            Text("AVAX-Fuji: \(avaxBalance) AVAX").font(.title3)
                        }.listRowSeparator(.hidden)
                        HStack {
                            Image("usd-coin-usdc-logo").resizable().frame(width: 40,height: 40)
                            Text("USDC: \(usdcBalance) USDC").font(.title3)
                        }.listRowSeparator(.hidden)
                        Spacer().listRowSeparator(.hidden)
                        HStack{
                            sendButton
                            transactionHistoryButton
                        }.padding(EdgeInsets(top: 100, leading: 0, bottom: 0,trailing:0))
                        
                        logoutButton
                    case .SendToken:
                        Text( "Send Tokens" ).font(.title2)
                        HStack {
                            Image("avalanche-avax-logo").resizable().frame(width: 40,height: 40)
                            Text("AVAX-Fuji: \(avaxBalance) AVAX").font(.title3)
                        }.listRowSeparator(.hidden)
                        HStack {
                            Image("usd-coin-usdc-logo").resizable().frame(width: 40,height: 40)
                            Text("USDC: \(usdcBalance) USDC").font(.title3)
                        }.listRowSeparator(.hidden)
                        Picker("Select which token to send", selection: $selectedOption) {
                                        ForEach(TokenOptions.allCases) { option in
                                            Text(String(describing: option))
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                        sectionInputField("Destination Address", binding: $destinationAddress )
                        sectionInputField("Amount", binding: $sendAmount )
                        sendTokensButton
                        HStack{
                            homeButton
                            logoutButton
                        }.listRowSeparator(.hidden)

                    case .Transactions:
                        Text( "Transactions" ).font(.title2)
                        List(transactionHistory){
                            transaction in
                            VStack(alignment: .leading) {
                                HStack{
                                    VStack(alignment: .leading){
                                        Text(transaction.transactionType).font(.body)
                                        let token = transaction.tokenId == FujiAvaxTokenAddress ? "Avalanche-Fuji" : "USDC"
                                        Text(token).font(.body)
                                        let textColor = transaction.state == "COMPLETE" ? Color.green : Color.red
                                        Text(transaction.state).font(.body).foregroundColor(textColor)
                                    }.padding(EdgeInsets(top: 0, leading: 0, bottom: 0,trailing:100))
                                    
                                    Text(transaction.amounts[0]).font(.body).alignmentGuide(.leading) { _ in 0 }
                                }
                            }.onTapGesture {
                                selectedTransaction = transaction
                                currentScreen = .Transction
                            }
                        }.frame(height: 400)
                        Spacer().listRowSeparator(.hidden)
                        HStack{
                            homeButton
                            logoutButton
                        }.listRowSeparator(.hidden)
                            
                    case .Transction:
                        Text( "View Transaction" ).font(.title2)
                        ZStack{
                            VStack (alignment: .leading){
                                Text("Source Address:").bold().font(.body)
                                Text(selectedTransaction.sourceAddress).font(.body)
                                VStack (alignment: .leading){
                                    Text("Destination Address:").bold().font(.body)
                                    Text(selectedTransaction.destinationAddress).font(.body)
                                }
                                
                                HStack{
                                    Text("State: ").bold().font(.body)
                                    Text(selectedTransaction.state).font(.body)
                                }
                                HStack {
                                    Text("Amount: ").bold().font(.body)
                                    Text(selectedTransaction.amounts[0]).font(.body)
                                }
                                HStack {
                                    Text("Transaction Type: ").bold().font(.body)
                                    Text(selectedTransaction.transactionType).font(.body)
                                }
                                HStack{
                                    let token = selectedTransaction.tokenId == FujiAvaxTokenAddress ? "Avalanche-Fuji" : "USDC"
                                    Text("Token: ").bold().font(.body)
                                    Text(token).font(.body)
                                }
                                HStack{
                                    Text("Blockchain: ").bold().font(.body)
                                    Text(selectedTransaction.blockchain).font(.body)
                                }
                                HStack{
                                    Text("Created at: ").bold().font(.body)
                                    Text(selectedTransaction.createDate).font(.body)
                                }
                                HStack{
                                    Text("Update at: ").bold().font(.body)
                                    Text(selectedTransaction.updateDate).font(.body)
                                } 
                            }.padding()
                                .background(Color.white)
                            RoundedRectangle(cornerRadius: 10) // You can adjust the corner radius as needed
                                .stroke(Color.black, lineWidth: 2) // Border color and width
                                .padding(5) // Adjust the padding to control the border distance
                        }
                        Spacer().listRowSeparator(.hidden)
                        transactionBackButton       
                }
            }.gesture(DragGesture().onChanged({_ in
                Task{
                    if (currentScreen == .Home && appState == .idle){
                        appState = .retrieveBalance
                        showToast(.general, message: "Updating Wallet Balances")
                        await getWalletBalances()
                        showToast(.success, message: "Balance Updated")
                        appState = .idle
                    }
                }    
            }))
            versionText
        }
        .scrollContentBackground(.hidden)
        .onAppear {
            self.adapter.initSDK(endPoint: endPoint, appId: appId)
            if let storedAppId = self.adapter.storedAppId, !storedAppId.isEmpty {
                self.appId = storedAppId
            }
        }
        .onChange(of: appId) { newValue in
            self.adapter.updateEndPoint(endPoint, appId: newValue)
            self.adapter.storedAppId = newValue
        }.onChange(of: currentScreen, perform: { newValue in
            if(newValue != .Login ){
                Task{
                    await getWalletsList()
                    await getWalletBalances()
                    appState = .idle
                }
            }
            
        })
        .toast(message: toastMessage ?? "",
               isShowing: $showToast,
               config: toastConfig)
    }

    var versionText: some View {
        Text("CircleProgrammableWalletSDK - \(WalletSdk.shared.sdkVersion() ?? "")").font(.footnote)
    }

    var sectionEndPoint: some View {
        Section {
            Text(endPoint)
        } header: {
            Text("End Point :")
        }
    }

    func sectionInputField(_ title: String, binding: Binding<String>) -> Section<Text, some View, EmptyView> {
        Section {
            TextField(title, text: binding)
                .textFieldStyle(.roundedBorder)
        } header: {
            Text(title + " :")
        }
    }

    var loginButton: some View {
        Button {
            guard !userId.isEmpty else { showToast(.general, message: "User ID is Empty"); return }
            Task{await userLogin()}

        } label: {
            let message = appState == .loggingIn ? "Logging In": "Login"
            Text(message)
                .frame(maxWidth: .infinity)
        }.disabled(appState != .idle)
        .buttonStyle(.borderedProminent)
        .listRowSeparator(.hidden)
    }
    var registerButton: some View {
        Button {
            guard !userId.isEmpty else { showToast(.general, message: "User ID is Empty"); return }
            Task{
                await  userRegistration()
            }

        } label: {
            let message = appState == .regsitering ? "Registering User": "Register"
            Text(message)
                .frame(maxWidth: .infinity)
        }.disabled(appState != .idle)
        .buttonStyle(.borderedProminent)
        .listRowSeparator(.hidden)
    }
    var logoutButton: some View {
        Button {
            currentScreen = .Login
             userToken = ""
            encryptionKey = ""
            challengeId = ""
            avaxBalance = "0"
            usdcBalance = "0"
            wallet = nil
            userId = ""
            
        } label: {
            Text("Log out")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .listRowSeparator(.hidden)
    }
    
    var homeButton: some View {
        Button {
            currentScreen = .Home
           
            
        } label: {
            Text("Home")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .listRowSeparator(.hidden)
    }
    
    var transactionBackButton: some View {
        Button {
            currentScreen = .Transactions
            selectedTransaction = defaultTransaction
            
        } label: {
            Text("Back")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .listRowSeparator(.hidden)
    }
    
    var sendButton: some View {
        Button {            
            currentScreen = .SendToken
            
        } label: {
            Text("Send")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .listRowSeparator(.hidden)
    }
    
    var transactionHistoryButton: some View {
        Button {
            Task {
                await getTransactionHistory( )
            }
            currentScreen = .Transactions
        } label: {
            Text("Transactions")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .listRowSeparator(.hidden)
    }
    
    var sendTokensButton: some View {
        Button {
            let isAllowed = containsOnlyNumbersAndDecimalPoint(sendAmount)
            guard isAllowed else { showToast(.general, message: "Invalid Format"); return }
            guard !sendAmount.isEmpty else { showToast(.general, message: "send amount is Empty"); return }
            let sendAmountFloat = Float(sendAmount) ?? 0
            let usdcBalanceFloat = Float(usdcBalance) ?? 0
            let avaxBalanceFloat = Float(avaxBalance) ?? 0
            if ( selectedOption == .USDC ) {
                guard sendAmountFloat<usdcBalanceFloat else { showToast(.failure, message: "Insufficient Balance"); return }
            }
            if ( selectedOption == .FujiAvax ) {
                let allowedTransferBalance = avaxBalanceFloat * 0.9
                guard sendAmountFloat < allowedTransferBalance else { showToast(.failure, message: "Insufficient Balance"); return }
            }
            appState = .sendingTokens
            Task {
                await createChallengeToSendTokens( )
                executeChallenge(userToken: userToken, encryptionKey: encryptionKey, challengeId: challengeId)
            }
        } label: {
            Text("Send Tokens")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .listRowSeparator(.hidden)
    }
    
    
}

extension ContentView {

    enum ToastType {
        case general
        case success
        case failure
    }

    func showToast(_ type: ToastType, message: String) {
        toastMessage = message
        showToast = true

        switch type {
        case .general:
            toastConfig = Toast.Config()
        case .success:
            toastConfig = Toast.Config(backgroundColor: .green, duration: 2.0)
        case .failure:
            toastConfig = Toast.Config(backgroundColor: .pink, duration: 10.0)
        }
    }

    func executeChallenge(userToken: String, encryptionKey: String, challengeId: String) {
        let _ = WalletSdk.Configuration.init(endPoint: endPoint, appId: appId)
        WalletSdk.shared.execute(userToken: userToken,encryptionKey: encryptionKey,challengeIds: [challengeId]) { response in
            switch response.result {
                case .success(let result):
                    let challengeStatus = result.status.rawValue
                    let challeangeType = result.resultType.rawValue
                    showToast(.success, message: "\(challeangeType) - \(challengeStatus)")
                    self.challengeId = ""
                    let addOnTime =  3.0 // Add 3 seconds delay
                    let delayTime = DispatchTime.now() + addOnTime
                    DispatchQueue.main.asyncAfter(deadline: delayTime) {
                        currentScreen = .Home
                        if ( currentScreen == .SendToken ){
                            sendAmount = "0"
                            destinationAddress = ""
                        }
                    }

                    
                    

                case .failure(let error):
                    showToast(.failure, message: "Error: " + error.displayString)
                    errorHandler(apiError: error, onErrorController: response.onErrorController)
                    appState = .idle
                }
        }
    }

    func errorHandler(apiError: ApiError, onErrorController: UINavigationController?) {
        switch apiError.errorCode {
        case .userHasSetPin:
            onErrorController?.dismiss(animated: true)
        default:
            break
        }
    }

    var TestButtons: some View {
        Section {
            Button("New PIN", action: newPIN)
            Button("Change PIN", action: changePIN)
            Button("Restore PIN", action: restorePIN)
            Button("Enter PIN", action: enterPIN)

        } header: {
            Text("UI Customization Entry")
                .font(.title3)
                .fontWeight(.semibold)
        }
    }
    
    

    func newPIN() {
        WalletSdk.shared.execute(userToken: "", encryptionKey: "", challengeIds: ["ui_new_pin"])
    }

    func enterPIN() {
        WalletSdk.shared.execute(userToken: "", encryptionKey: "", challengeIds: ["ui_enter_pin"])
    }

    func changePIN() {
        WalletSdk.shared.execute(userToken: "", encryptionKey: "", challengeIds: ["ui_change_pin"])
    }

    func restorePIN() {
        WalletSdk.shared.execute(userToken: "", encryptionKey: "", challengeIds: ["ui_restore_pin"])
    }
    

    
    func userLogin () async {
        appState =  .loggingIn
        await getSessionToken()
        guard !userToken.isEmpty else { showToast(.failure, message: "User Token is Empty. Please register for an account"); return appState = .idle }
        guard !encryptionKey.isEmpty else { showToast(.failure, message: "Encryption Key is Empty"); return }
        currentScreen = .Home
        appState = .idle
    }
    
    func userRegistration () async {
        appState = .regsitering
        await createUser()
        await getSessionToken()
        await getChallengIdandCreateWallet()
        guard !userToken.isEmpty else { showToast(.general, message: "User Token is Empty"); return }
        guard !encryptionKey.isEmpty else { showToast(.general, message: "Encryption Key is Empty"); return }
        guard !challengeId.isEmpty else { showToast(.general, message: "Challenge ID is Empty"); return }
        executeChallenge(userToken: userToken, encryptionKey: encryptionKey, challengeId: challengeId)
    }
    
    func createUser()async  {
        //Step 2 - PASTE CODE HERE FOR "CREATE USER" API
    }
    
    func getSessionToken() async {
        //Step 3 - PASTE CODE HERE FOR "CREATE SESSION TOKEN" API
    }
    
    func getChallengIdandCreateWallet() async {
        //Step 4 - PASTE CODE HERE FOR "CREATE WALLET" API
    }
    
    func getWalletsList() async {
        let apiUrl = URL(string: "https://api.circle.com/v1/w3s/wallets?blockchain=AVAX-FUJI&pageSize=10")!
        struct ResponseData: Codable {
            let data: Data
             struct Data:Codable {
                 let wallets:[Wallet]
             }
        }
        do {
            var request = URLRequest(url: apiUrl)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue(userToken, forHTTPHeaderField: "X-User-Token")
            
            let (data,_)=try await URLSession.shared.data(for: request)
            let walletData = try JSONDecoder().decode(ResponseData.self, from: data)
            if(walletData.data.wallets.isEmpty){
                currentScreen = .Login
            }else{
                wallet = walletData.data.wallets[0]
            }
        } catch {
            // Handle JSON serialization error.
            print("JSON Serialization Error: \(error.localizedDescription)")
        }
    }
    
    func getWalletBalances() async {
        let apiUrl = URL(string: "https://api.circle.com/v1/w3s/wallets/\(wallet?.id ?? "")/balances")!
        struct Balance: Codable {
            let amount: String
            let updateDate: String
            let token: Token
            struct Token: Codable {
                let id: String
                let blockchain: String
                let name : String
                let symbol: String
                let decimals: Int
                let isNative: Bool
                let updateDate: String
                let createDate: String
            }
        }
        struct ResponseData: Codable {
            let data: Data
             struct Data:Codable {
                 let tokenBalances:[Balance]
             }
        }
        do {
            var request = URLRequest(url: apiUrl)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            let (data,_)=try await URLSession.shared.data(for: request)
            let tokenBalances = try JSONDecoder().decode(ResponseData.self, from: data)
            for tokenBalanceData in tokenBalances.data.tokenBalances {
                if(tokenBalanceData.token.name == "Avalanche-Fuji"){
                    avaxBalance = tokenBalanceData.amount
                }
                if(tokenBalanceData.token.name == "USD Coin"){
                    usdcBalance = tokenBalanceData.amount
                }  
            }
        } catch {
            // Handle JSON serialization error.
            print("JSON Serialization Error: \(error.localizedDescription)")
        }
    }
    
    func containsOnlyNumbersAndDecimalPoint(_ text: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[0-9.]*$")
        return regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) != nil
    }
    
    func createChallengeToSendTokens() async {
        //Step 5 - PASTE CODE HERE "SEND TOKEN" API
    }
    
    func getTransactionHistory() async {
       //Step 6 - PASTE CODE HERE "FETCH TRANSACTIONS" API
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
