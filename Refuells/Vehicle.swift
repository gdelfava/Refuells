import Foundation
import FirebaseFirestore

struct Vehicle: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let make: String
    let model: String
    let year: Int
    let fuelType: String
    let tankCapacity: Double
    let imageURL: String?
    let createdAt: Date
    let updatedAt: Date
    
    init(name: String, make: String, model: String, year: Int, fuelType: String, tankCapacity: Double, imageURL: String? = nil) {
        self.name = name
        self.make = make
        self.model = model
        self.year = year
        self.fuelType = fuelType
        self.tankCapacity = tankCapacity
        self.imageURL = imageURL
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    init(id: String?, name: String, make: String, model: String, year: Int, fuelType: String, tankCapacity: Double, imageURL: String?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.name = name
        self.make = make
        self.model = model
        self.year = year
        self.fuelType = fuelType
        self.tankCapacity = tankCapacity
        self.imageURL = imageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func updated(name: String, make: String, model: String, year: Int, fuelType: String, tankCapacity: Double, imageURL: String?) -> Vehicle {
        return Vehicle(
            id: self.id,
            name: name,
            make: make,
            model: model,
            year: year,
            fuelType: fuelType,
            tankCapacity: tankCapacity,
            imageURL: imageURL,
            createdAt: self.createdAt,
            updatedAt: Date()
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case make
        case model
        case year
        case fuelType
        case tankCapacity
        case imageURL
        case createdAt
        case updatedAt
    }
} 