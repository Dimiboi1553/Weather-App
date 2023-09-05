//
//  ContentView.swift
//  Weather
//
//  Created by Dimitris on 12/7/23.
//

import SwiftUI

public var Description: String = ""
public var WCode: Int = 0
public var weatherIconURL: URL?

public var lon: Double = 0.0
public var lat: Double = 0.0


struct ForecastData: Decodable, Hashable, Equatable {
    let max_temp: Double
    let min_temp: Double
    let temp: Double
    let precip: Double
    let weather: ForecastDescription

    struct ForecastDescription: Decodable, Hashable {
        let description: String
        let icon: String
        let code: Int
    }
}

struct ForecastResponse: Decodable{
    let data: [ForecastData]
}

struct ForecastDescription: Decodable{
    let description: String
    let icon: String
    let code: Int
}


struct WeatherData: Decodable {
    let temp: Double
    let precip: Int
    let vis: Int
    let lat: Double
    let lon: Double
    let weather: WeatherDescription
    
}

struct WeatherDescription: Decodable{
    let description: String
    let code: Int
    let icon: String
}

struct WeatherResponse: Decodable {
    let data: [WeatherData]
}

struct ContentView: View {
    @State private var isLoading: Bool = false
    @State private var userLocation: String = ""
    @State private var currentTemp: Double = 0.0
    @State private var topTempColor: Color = .black
    @State private var iconCode: String = ""
    @State private var forecastData: [ForecastData] = []
    @State private var weatherCode: Int = 0
    
    func fetchWeatherData() async throws -> WeatherData {
        guard let url = URL(string: "https://api.weatherbit.io/v2.0/current?city=\(userLocation)&key=d83e49442de549edac0752e6801b4bbd") else {
            fatalError("Missing URL")
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decode = try JSONDecoder().decode(WeatherResponse.self, from: data)
        return decode.data.first!
    }
    
    func fetchWeatherForecastData() async throws -> [ForecastData] {
        guard let url = URL(string: "https://api.weatherbit.io/v2.0/forecast/daily?city=\(userLocation)&key=d83e49442de549edac0752e6801b4bbd") else {
            fatalError("Missing URL")
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decode = try JSONDecoder().decode(ForecastResponse.self, from: data)
        return decode.data
    }
    
    func FindImage(Code: Int) -> String{
        switch Code{
        case 200...233:
            return "4"
        case 300...522:
            return "3"
        case 600...622:
            return "3"
        case 800:
            return "6"
        case 801...900:
            return "1"
        default:
            return "2"
        }
    }
    
    var body: some View {
        VStack(spacing:30){
            HStack {
                TextField("Enter your Location", text: $userLocation)
                    .padding()
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                    .textContentType(.location)
                
                Button("Fetch Location Data") {
                    isLoading = true
                    Task {
                        do {
                            let weatherData = try await fetchWeatherData()
                            isLoading = false
                            currentTemp = weatherData.temp
                            weatherCode = weatherData.weather.code
                        } catch {
                            print("Error fetching weather data:", error)
                        }
                        
                        do {
                            forecastData = try await fetchWeatherForecastData()
                        } catch {
                            print("Error fetching weather forecast data:", error)
                        }
                    }
                }.foregroundColor(.blue).opacity(0.5).offset(x:-10)
            }
            
            HStack {
                if isLoading{
                    CircularProgressView()
                        .frame(width: 150, height: 150)
            
                }else{
                    Image(FindImage(Code: weatherCode))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .offset(x:20)
                }
                
            }
            
            VStack(spacing: 0) {
                Text("\(userLocation.trimmingCharacters(in: .whitespacesAndNewlines))")
                    .foregroundColor(Color.black)
                    .fontWeight(.bold)
                    .font(.title)
                Text("Current Temperature:")
                    .foregroundColor(Color.black)
                    .bold()
                
                Text("\(currentTemp,specifier: "%.1f")°C")
                    .foregroundColor(topTempColor)
                    .padding()
                
            }
            ZStack{
                RoundedRectangle(cornerRadius:10)
                    .fill(Color.white)
                    .opacity(0.25)
                    .frame(width:375, height: 400)
                    .overlay(
                        ZStack{
                            RoundedRectangle(cornerRadius:10)
                                .fill(Color.white)
                                .opacity(0.25)
                                .frame(width:375, height: 40)
                                .offset(y: -180)
                                .overlay(
                                Text("\(userLocation.trimmingCharacters(in: .whitespacesAndNewlines)) Forecasts:")
                                    .foregroundColor(Color.black)
                                    .fontWeight(.bold)
                                    .font(.title2)
                                    .scaledToFit()
                                    .offset(y: -180)

                                )

                            ScrollView {
                                HStack{
                                    VStack(spacing: 30){
                                        ForEach(forecastData, id: \.self) { forecast in
                                            VStack(spacing: 30) {
                                                ScrollView(.horizontal){
                                                    HStack{
                                                        Image(FindImage(Code:forecast.weather.code))
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 100, height: 100)
                                                        VStack{
                                                            Text("Temperature:").foregroundColor(Color.red)
                                                            Text("\(forecast.min_temp,specifier: "%.1f")°C - \(forecast.max_temp,specifier: "%.1f")")
                                                                .font(.subheadline).scaledToFit()
                                                            
                                                            
                                                        }
                                                        VStack{
                                                            Text("Precipitation:").foregroundColor(Color.blue).scaledToFit()
                                                            Text("\(forecast.precip, specifier: "%.1f")")
                                                                .font(.subheadline)
                                                        }
                                                        
                                                    }
                                                }
                                            }
                                            .padding(.all)
                                        }
                                    }
                                    Spacer()
                                }
                            }.frame(width: 350,height: 300)
                            Spacer()
                        }
                    )
            }
            .onChange(of: currentTemp) { newTemp in
                if newTemp <= 0 {
                    topTempColor = .blue
                } else if 1...15 ~= newTemp {
                    topTempColor = .pink
                } else if 16...25 ~= newTemp {
                    topTempColor = .orange
                } else {
                    topTempColor = .red
                }
            }
        }.background(
            LinearGradient(
                gradient: Gradient(colors: [Color.teal, Color.blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }

struct CircularProgressView: View {
    @State private var progress: Double = 0.0
    
    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            DispatchQueue.main.async {
                progress += 0.01

                if progress >= 1.0 {
                    timer.invalidate()
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color(.blue).opacity(0.5),
                    lineWidth: 30
                )
            Text("\(progress * 100, specifier: "%.0f")")
                .font(.largeTitle)
                .bold()
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color(red: 0.0, green: 0.0, blue: 5),
                    style: StrokeStyle(
                        lineWidth: 30,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            startTimer() // Start the timer when the view appears
        }
    }
}
