//
//  TripsView.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import SwiftUI

struct TripsView: View {
    var body: some View {
        TripsViewContent()
    }
}

struct TripsViewContent: View {
    @State private var showingAddTrip = false
    @State private var trips: [Trip] = [
        Trip(
            title: "Downtown Shopping",
            startLocation: "Home",
            endLocation: "Downtown Mall",
            distance: 25.5,
            duration: 35,
            fuelUsed: 2.1,
            date: Date(),
            type: .personal
        ),
        Trip(
            title: "Airport Pickup",
            startLocation: "Home",
            endLocation: "International Airport",
            distance: 45.2,
            duration: 55,
            fuelUsed: 3.8,
            date: Date().addingTimeInterval(-86400),
            type: .business
        ),
        Trip(
            title: "Weekend Road Trip",
            startLocation: "Home",
            endLocation: "Mountain Resort",
            distance: 120.0,
            duration: 140,
            fuelUsed: 9.5,
            date: Date().addingTimeInterval(-172800),
            type: .leisure
        )
    ]
    
    var body: some View {
        NavigationStack {
                VStack {
                    // Trips list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(trips.sorted(by: { $0.date > $1.date })) { trip in
                                TripRow(trip: trip)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .navigationTitle("Trips")
                .navigationBarTitleDisplayMode(.large)
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showingAddTrip = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                )
                .withMenuButton()
                .onAppear {
                    print("TripsView appeared")
                }
        }
        .sheet(isPresented: $showingAddTrip) {
            AddTripView(trips: $trips)
        }
    }
}

struct Trip: Identifiable {
    let id = UUID()
    let title: String
    let startLocation: String
    let endLocation: String
    let distance: Double
    let duration: Int // in minutes
    let fuelUsed: Double
    let date: Date
    let type: TripType
}

enum TripType: String, CaseIterable {
    case personal = "Personal"
    case business = "Business"
    case leisure = "Leisure"
    case commute = "Commute"
    
    var icon: String {
        switch self {
        case .personal: return "person.fill"
        case .business: return "briefcase.fill"
        case .leisure: return "car.fill"
        case .commute: return "house.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .personal: return .blue
        case .business: return .green
        case .leisure: return .orange
        case .commute: return .purple
        }
    }
}

struct TripRow: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: trip.type.icon)
                            .font(.caption)
                            .foregroundColor(trip.type.color)
                        Text(trip.type.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(String(format: "%.1f", trip.distance))km")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text("\(trip.duration)min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("From: \(trip.startLocation)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("To: \(trip.endLocation)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(String(format: "%.1f", trip.fuelUsed))L")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text(trip.date, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AddTripView: View {
    @Binding var trips: [Trip]
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var startLocation: String = ""
    @State private var endLocation: String = ""
    @State private var distance: String = ""
    @State private var duration: String = ""
    @State private var fuelUsed: String = ""
    @State private var selectedType: TripType = .personal
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    HStack {
                        Text("Title")
                        Spacer()
                        TextField("Trip title", text: $title)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Type")
                        Spacer()
                        Picker("Type", selection: $selectedType) {
                            ForEach(TripType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("Start Location")
                        Spacer()
                        TextField("Start", text: $startLocation)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("End Location")
                        Spacer()
                        TextField("End", text: $endLocation)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Trip Metrics") {
                    HStack {
                        Text("Distance (km)")
                        Spacer()
                        TextField("0.0", text: $distance)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Duration (min)")
                        Spacer()
                        TextField("0", text: $duration)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Fuel Used (L)")
                        Spacer()
                        TextField("0.0", text: $fuelUsed)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section {
                    Button("Add Trip") {
                        addTrip()
                    }
                    .disabled(title.isEmpty || startLocation.isEmpty || endLocation.isEmpty || distance.isEmpty || duration.isEmpty || fuelUsed.isEmpty)
                }
            }
            .navigationTitle("Add Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addTrip() {
        guard let distanceValue = Double(distance),
              let durationValue = Int(duration),
              let fuelUsedValue = Double(fuelUsed) else {
            return
        }
        
        let newTrip = Trip(
            title: title,
            startLocation: startLocation,
            endLocation: endLocation,
            distance: distanceValue,
            duration: durationValue,
            fuelUsed: fuelUsedValue,
            date: Date(),
            type: selectedType
        )
        
        trips.append(newTrip)
        dismiss()
    }
}

#Preview {
    TripsView()
} 