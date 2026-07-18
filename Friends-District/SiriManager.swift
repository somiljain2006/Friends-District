//
//  SiriManager.swift
//  Friends-District
//
//  Created by somil jain on 18/07/26.
//

internal import Combine
import Foundation

class SiriManager: ObservableObject {
    static let shared = SiriManager()
    
    // Broadcasts the incoming text query from Siri
    @Published var incomingSiriQuery: String? = nil
    
    private init() {}
}
