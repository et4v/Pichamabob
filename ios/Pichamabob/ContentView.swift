//
//  ContentView.swift
//  Pichamabob
//
//  Main UI — pitch calling, Bluetooth connection, stats and games
//

import SwiftUI
import Foundation

enum NavigationTabs: Hashable {
    case home
    case signal
    case bluetooth
    case statistics
}

struct pitchersFormat: Codable {
    let playerId: Int
    let fName: String
    let lName: String
    let playerNumber: Int
    let teamName: String
    let season: Int
    let ageGroup: String
}

//struct pitcherDataFormat: Codable {
//    let firstName: String
//    let lastName: String
//    let totalPitches: Int
//    let totalAccurate: Int
//    
//    enum PitchTypeKeys: String, CodingKey {
//        case curveball = "Curveball"
//        case slider = "Slider"
//        case changeup = "Changeup"
//        case cutter = "Cutter"
//        case sinker = "Sinker"
//        case knuckle = "Knuckleball"
//        case fastball = "Fastball"
//    }
//    enum CurveballKeys: String, CodingKey {
//        case strikes = "strikes"
//        case balls = "balls"
//        case fouls = "fouls"
//        case inplay = "inPlay"
//        case total = "total"
//    }
//    enum SliderKeys: String, CodingKey {
//        case strikes = "strikes"
//        case balls = "balls"
//        case fouls = "fouls"
//        case inplay = "inPlay"
//        case total = "total"
//    }
//    enum ChangeUpKeys: String, CodingKey {
//        case strikes = "strikes"
//        case balls = "balls"
//        case fouls = "fouls"
//        case inplay = "inPlay"
//        case total = "total"
//    }
//    enum CutterKeys: String, CodingKey {
//        case strikes = "strikes"
//        case balls = "balls"
//        case fouls = "fouls"
//        case inplay = "inPlay"
//        case total = "total"
//    }
//    enum SinkerKeys: String, CodingKey {
//        case strikes = "strikes"
//        case balls = "balls"
//        case fouls = "fouls"
//        case inplay = "inPlay"
//        case total = "total"
//    }
//    enum KnuckleKeys: String, CodingKey {
//        case strikes = "strikes"
//        case balls = "balls"
//        case fouls = "fouls"
//        case inplay = "inPlay"
//        case total = "total"
//    }
//    enum FastballKeys: String, CodingKey {
//        case strikes = "strikes"
//        case balls = "balls"
//        case fouls = "fouls"
//        case inplay = "inPlay"
//        case total = "total"
//    }
//    
//    let strikes: Int
//    let balls: Int
//    let fouls: Int
//    let inplay: Int
//    let total: Int
//}

struct ballTypes: Codable {
    let strikes: Int
    let balls: Int
    let fouls: Int
    let inPlay: Int
    let total: Int
}

struct pitchTypesStruct: Codable {
    let Curveball: ballTypes
    let Slider: ballTypes
    let Changeup: ballTypes
    let Cutter: ballTypes
    let Sinker: ballTypes
    let Knuckleball: ballTypes
    let Fastball: ballTypes
}

struct pitcherDataFormat: Codable{
    let firstName: String
    let lastName: String
    let totalPitches: Int
    let totalAccurate: Int
    let pitchTypes: pitchTypesStruct
}

struct gamesFormat: Codable {
    let gameId: Int
    let gameDate: String
    let homeTeamId: Int
    let homeTeamSeason: Int
    let homeTeamName: String
    let homeAgeGroup: String
    let awayTeamId: Int
    let awayTeamSeason: Int
    let awayTeamName: String
    let awayAgeGroup: String
}

// Backend address — the ngrok URL printed when you run `ngrok http 5000` (see backend/README.md)
let apiBaseURL = "https://YOUR-NGROK-URL.ngrok-free.dev"

func fetchAndParseJSON<T: Decodable>(urlString: String, type: T.Type) async throws -> T {
    guard let url = URL(string: urlString) else {
        throw NSError(domain: "InvalidURL", code: 0, userInfo: nil)
    }

    // 1. Use URLSession to fetch data
    let (data, _) = try await URLSession.shared.data(from: url)

    // 2. Use JSONDecoder to decode the data into your struct
    let decoder = JSONDecoder()
    let decodedData = try decoder.decode(T.self, from: data)

    return decodedData
}

struct ContentView: View {
    @StateObject var bleManager = BLEManager()
    @State private var selectedTab: NavigationTabs = .home

    var body: some View {
        TabView(selection: $selectedTab) {
//            HomeView()
//                .tabItem {
//                    Image(systemName: "house")
//                    Text("Home")
//                }
//                .tag(NavigationTabs.home)

            SignalView()
                .environmentObject(bleManager)
                .tabItem {
                    Image(systemName: "wifi")
                    Text("Signal")
                }
                .tag(NavigationTabs.signal)

            BluetoothView()
                .environmentObject(bleManager)
                .tabItem {
                    Image(systemName: "bolt.horizontal.circle")
                    Text("Bluetooth")
                }
                .tag(NavigationTabs.bluetooth)
            
            StatisticsView()
                .environmentObject(bleManager)
                .tabItem {
                    Image(systemName: "baseball")
                    Text("Statistics")
                }
                .tag(NavigationTabs.statistics)
            
            GameView()
                .environmentObject(bleManager)
                .tabItem {
                    Image(systemName: "gamecontroller")
                    Text("Games")
                }
                .tag(NavigationTabs.statistics)
        }
        
        .environmentObject(bleManager)
    }
}

struct HomeView: View {
    var body: some View {
        Text("Welcome Home")
            .padding()
    }
}

struct StatisticsView: View {
    //Get DB data
    @State private var showingAlert = false
    @State var pitchers: [pitchersFormat] = []
    @State var pitcherData: [pitcherDataFormat] = []

    var body: some View {
    
        NavigationStack {
            List(pitchers, id: \.playerId) { pitcher in
                NavigationLink("\(pitcher.fName) \(pitcher.lName)\n Team: \(pitcher.teamName)\n", destination: IndividualStatisticsView(playerID: pitcher.playerId))
                    
                }
            
            }
        .task {
            do {
                pitchers = try await fetchAndParseJSON(urlString: "\(apiBaseURL)/pitches/pitchers", type: [pitchersFormat].self)
            } catch {
                print("Error with JSON decoding")
            }
        }
    }
}

struct IndividualStatisticsView: View {
    
    let playerID: Int
    @State var pitcherData: pitcherDataFormat?
    @State var playerLoaded = false
    
    var body: some View {
        Text("")
            .task {
                do {
                    print("\(apiBaseURL)/pitches/pitchers/\(playerID)")
                    pitcherData = try await fetchAndParseJSON(urlString: "\(apiBaseURL)/pitches/pitchers/\(playerID)", type: pitcherDataFormat.self)
                    playerLoaded = true
                } catch {
                    print("Error with JSON decoding")
                }
            }
        if playerLoaded {
            
            Text("\(pitcherData!.firstName) \(pitcherData!.lastName)'s statistics\nTotal Pitches: \(pitcherData!.totalPitches)\nTotal Accurate: \(pitcherData!.totalAccurate)\n")
            
            HStack {
                Text("Fastballs: \n-strikes: \(pitcherData!.pitchTypes.Fastball.strikes)\n-balls: \(pitcherData!.pitchTypes.Fastball.balls)\n-fouls: \(pitcherData!.pitchTypes.Fastball.fouls)\n-in-play: \(pitcherData!.pitchTypes.Fastball.inPlay)\n-total: \(pitcherData!.pitchTypes.Fastball.total)\n")
                Text("Curveballs: \n-strikes: \(pitcherData!.pitchTypes.Curveball.strikes)\n-balls: \(pitcherData!.pitchTypes.Curveball.balls)\n-fouls: \(pitcherData!.pitchTypes.Curveball.fouls)\n-in-play: \(pitcherData!.pitchTypes.Curveball.inPlay)\n-total: \(pitcherData!.pitchTypes.Curveball.total)\n")
                Text("Sliders: \n-strikes: \(pitcherData!.pitchTypes.Slider.strikes)\n-balls: \(pitcherData!.pitchTypes.Slider.balls)\n-fouls: \(pitcherData!.pitchTypes.Slider.fouls)\n-in-play: \(pitcherData!.pitchTypes.Slider.inPlay)\n-total: \(pitcherData!.pitchTypes.Slider.total)\n")
            }
        }
    }
}

//class pitch

struct SignalView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State var pitchHistory: [String] = []

    var body: some View{
        
        NavigationView{
            
            VStack{
                
                Text("History")
                
                List(pitchHistory, id: \.self) { history in
                    Text(history)
                    //NavigationLink(destination: PitcherStatsView(id: pitcher.id))
                    
                }
                
                NavigationLink("Fast",destination: PositionView(throwType: "Fast", pitchHistory: $pitchHistory))
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(12)
                NavigationLink("Curve",destination: PositionView(throwType: "Curve", pitchHistory: $pitchHistory))
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(12)
                NavigationLink("Slider",destination: PositionView(throwType: "Slider", pitchHistory: $pitchHistory))
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(12)
                
            }
            .padding()
        }
    }
}

struct PositionView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var showMessage = false
    let throwType : String
    @Binding var pitchHistory: [String]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var positions = ["TL", "TM", "TR",
                "ML", "MM", "MR",
                "BL", "BM", "BR"]
    
    var body: some View {
        NavigationView {
            LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(0..<9) { index in
                            Button("\(positions[index])") {
                                print("Tapped \(index)")
                                withAnimation { showMessage = true}
                                processMessage(throwType: throwType, position: positions[index])
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {showMessage = false}
                                }
                            }
                            .frame(height: 60)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.15))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
        
        if showMessage {
            VStack {
                Text("Message sent to players!")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                Spacer()
            }
        }

        }
        
    
    func processMessage(throwType: String, position: String) {
        print("Sending to T-Deck: \(throwType), \(position)")
        bleManager.sendSignal(code: "\(throwType) \(position)")
        pitchHistory.insert("\(throwType) \(position)", at: 0)
        
    }
}

struct BluetoothView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var isButtonPressed: Bool = false
    
    var body: some View {
        ZStack {
            // Background
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Status area
                statusView
                
                Spacer()
                
                // Connection controls
                connectionControls
                
                // Signal count
            }
            .padding()
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundColor: Color {
        switch bleManager.connectionState {
        case .ready:
            return Color.green.opacity(0.1)
        case .connected, .connecting, .scanning:
            return Color.yellow.opacity(0.1)
        case .disconnected:
            return Color.gray.opacity(0.1)
        }
    }
    
    private var statusView: some View {
        VStack(spacing: 8) {
            // Connection indicator
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                Text(bleManager.connectionState.rawValue)
                    .font(.headline)
            }
            
            // Error message
            if let error = bleManager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch bleManager.connectionState {
        case .ready:
            return .green
        case .connected, .connecting, .scanning:
            return .yellow
        case .disconnected:
            return .red
        }
    }
    
    private var signalButton: some View {
        Button(action: {
            bleManager.sendSignal()
        }) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(buttonColor.opacity(0.3), lineWidth: 8)
                    .frame(width: 220, height: 220)
                
                // Main button
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [buttonColor.opacity(0.8), buttonColor],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .shadow(color: buttonColor.opacity(0.5), radius: isButtonPressed ? 5 : 20)
                    .scaleEffect(isButtonPressed ? 0.95 : 1.0)
                
                // Label
                VStack(spacing: 4) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 50))
                    Text("SIGNAL")
                        .font(.system(size: 24, weight: .bold))
                }
                .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(bleManager.connectionState != .ready)
        .opacity(bleManager.connectionState == .ready ? 1.0 : 0.5)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isButtonPressed = true }
                .onEnded { _ in isButtonPressed = false }
        )
        .animation(.easeInOut(duration: 0.1), value: isButtonPressed)
    }
    
    private var buttonColor: Color {
        bleManager.connectionState == .ready ? .blue : .gray
    }
    
    private var connectionControls: some View {
        HStack(spacing: 20) {
            if bleManager.connectionState == .disconnected {
                Button(action: {
                    bleManager.startScanning()
                }) {
                    Label("Connect", systemImage: "link")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else if bleManager.connectionState == .ready {
                Button(action: {
                    bleManager.disconnect()
                }) {
                    Label("Disconnect", systemImage: "link.badge.plus")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.2)
            }
        }
    }
}

struct GameView: View {
    
    @State var games: [gamesFormat] = []
    
    
    var body: some View {
        NavigationStack {
            List(games, id: \.gameId) { game in
//                Text("Game Date: \(game.gameDate) \n  Home Team Name: \(game.homeTeamName)\n Home Team Season: \(game.homeTeamSeason)\n Home Team Age Group: \(game.homeAgeGroup)\n Away Team Name: \(game.awayTeamName)\n Away Team Season \(game.awayTeamSeason)\n Away Team Age Group: \(game.awayAgeGroup)")
//                    .lineLimit(nil)
                
                NavigationLink("Game Date: \(game.gameDate)\n \(game.homeTeamName) VS \(game.awayTeamName)\n", destination: IndividualGameView(gameInfo: game))
                }
                
            }
        .task {
            do {
                games = try await fetchAndParseJSON(urlString: "\(apiBaseURL)/games", type: [gamesFormat].self)
            } catch {
                print("Error with JSON decoding")
            }
        }
        .onTapGesture {
            
        }
    }
}

struct IndividualGameView: View {
    @State var gameInfo: gamesFormat
    
    var body: some View {
        Text("\(gameInfo.homeTeamName) VS \(gameInfo.awayTeamName)\nSeason: \(gameInfo.homeTeamSeason)\n\(gameInfo.homeTeamName) age group: \(gameInfo.homeAgeGroup)\n\(gameInfo.awayTeamName) age group: \(gameInfo.homeAgeGroup)")
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.15))
            .cornerRadius(12)
        
    }
}

#Preview {
    ContentView()
}

