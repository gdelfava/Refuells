//
//  FuelLogView.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import SwiftUI

struct FuelLogView: View {
    @State private var showingAddFuel = false
    @State private var fuelEntries: [FuelEntry] = [
        FuelEntry(date: Date(), liters: 45.2, cost: 89.50, station: "Shell Station", odometer: 1234),
        FuelEntry(date: Date().addingTimeInterval(-86400), liters: 42.1, cost: 83.20, station: "BP Station", odometer: 1114),
        FuelEntry(date: Date().addingTimeInterval(-172800), liters: 38.5, cost: 76.30, station: "Exxon", odometer: 994)
    ]
    
    var body: some View {
        MenuWrapperView {
            NavigationStack {
                VStack {
                    // Fuel entries list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(fuelEntries.sorted(by: { $0.date > $1.date })) { entry in
                                FuelEntryRow(entry: entry)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .navigationTitle("Refuels")
                .navigationBarTitleDisplayMode(.large)
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showingAddFuel = true
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
            }
        }
        .sheet(isPresented: $showingAddFuel) {
            AddFuelView(fuelEntries: $fuelEntries)
        }
    }
}

struct FuelEntry: Identifiable {
    let id = UUID()
    let date: Date
    let liters: Double
    let cost: Double
    let station: String
    let odometer: Int
}

struct FuelEntryRow: View {
    let entry: FuelEntry
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: price)) ?? ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.station)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(entry.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatPrice(entry.cost))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Text("\(String(format: "%.1f", entry.liters))L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Label("Odometer: \(entry.odometer)km", systemImage: "speedometer")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(formatPrice(entry.cost / entry.liters))/L")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AddFuelView: View {
    @Binding var fuelEntries: [FuelEntry]
    @Environment(\.dismiss) private var dismiss
    
    @State private var liters: String = ""
    @State private var cost: String = ""
    @State private var station: String = ""
    @State private var odometer: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Fuel Details") {
                    HStack {
                        Text("Liters")
                        Spacer()
                        TextField("0.0", text: $liters)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Cost ($)")
                        Spacer()
                        TextField("0.00", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Station")
                        Spacer()
                        TextField("Station name", text: $station)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Odometer (km)")
                        Spacer()
                        TextField("0", text: $odometer)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section {
                    Button("Add Fuel Entry") {
                        addFuelEntry()
                    }
                    .disabled(liters.isEmpty || cost.isEmpty || station.isEmpty || odometer.isEmpty)
                }
            }
            .navigationTitle("Add Fuel Entry")
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
    
    private func addFuelEntry() {
        guard let litersValue = Double(liters),
              let costValue = Double(cost),
              let odometerValue = Int(odometer) else {
            return
        }
        
        let newEntry = FuelEntry(
            date: Date(),
            liters: litersValue,
            cost: costValue,
            station: station,
            odometer: odometerValue
        )
        
        fuelEntries.append(newEntry)
        dismiss()
    }
}

#Preview {
    FuelLogView()
} 