//
//  Modificateurs.swift
//  SportLink
//
//  Created by Mathias La Rochelle on 2025-07-21.
//

import Foundation
import SwiftUI

private struct CacherBoutonJoinKey: EnvironmentKey {
    static let defaultValue = false
}

private struct CacherBoutonEditableKey: EnvironmentKey {
    static let defaultValue = false
}

private struct DateEtendueKey: EnvironmentKey {
    static let defaultValue = false
}

private struct EstDansVueFavorisKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var cacherBoutonJoin: Bool {
        get { self[CacherBoutonJoinKey.self] }
        set { self[CacherBoutonJoinKey.self] = newValue }
    }
    
    var cacherBoutonEditable: Bool {
        get { self[CacherBoutonEditableKey.self] }
        set { self[CacherBoutonEditableKey.self] = newValue }
    }
    
    var dateEtendue: Bool {
        get { self[DateEtendueKey.self] }
        set { self[DateEtendueKey.self] = newValue }
    }
    
    var estDansVueFavoris: Bool {
        get { self[EstDansVueFavorisKey.self] }
        set { self[EstDansVueFavorisKey.self] = newValue }
    }
}

extension View {
    func cacherBoutonJoin(_ cacher: Bool = true) -> some View {
        environment(\.cacherBoutonJoin, cacher)
    }
    
    func cacherBoutonEditable(_ cacher: Bool = true) -> some View {
        environment(\.cacherBoutonEditable, cacher)
    }
    
    func dateEtendue(_ etendue: Bool = true) -> some View {
        environment(\.dateEtendue, etendue)
    }
    
    func estDansVueFavoris(_ estDedans: Bool = false) -> some View {
        environment(\.estDansVueFavoris, estDedans)
    }
}
