//
//  ChoixDisponibilitesVue.swift
//  SportLink
//
//  Created by Michel Lamothe on 2025-07-24.
//

import SwiftUI

let joursDeLaSemaine = [
    "Monday", "Tuesday", "Wednesday",
    "Thursday", "Friday", "Saturday", "Sunday"
]

enum JourDeLaSemaine: String, CaseIterable, Identifiable {
    case lundi = "Monday",
         mardi = "Tuesday",
         mercredi = "Wednesday",
         jeudi = "Thursday",
         vendredi = "Friday",
         samedi = "Saturday",
         dimanche = "Sunday"
    
    var id: String { rawValue }
    var nomLocalise: String { rawValue.localizedCapitalized }
}

struct CreneauHoraire: Identifiable, Equatable {
    let id = UUID()
    var debut: Date
    var fin: Date
    
    func formate() -> String {
        "\(debut.formatted(date: .omitted, time: .shortened)) - \(fin.formatted(date: .omitted, time: .shortened))"
    }
}

struct ChoixDisponibilitesVue: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: InscriptionVM
    @Binding var etape: [EtapeSupplementaireInscription]
    
    @State private var disponibilites: [JourDeLaSemaine: [CreneauHoraire]] = Dictionary(uniqueKeysWithValues: JourDeLaSemaine.allCases.map { ($0, []) })
    @State private var creneauEditable: (jour: JourDeLaSemaine, creneau: CreneauHoraire)? = nil
    @State private var overlayActif = false
    @State private var jourEnEdition: JourDeLaSemaine? = nil
    @State private var indexEnEdition: Int? = nil
    @State private var debutTemp = Date()
    @State private var finTemp = Date()
    
    private let minSlotGap: TimeInterval = 60

    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                enTete
                listeJournees
            }
        }
        .frame(maxHeight: .infinity)
        .overlay(overlay)
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            boutonContinuer
        }
    }
    
    @ViewBuilder
    private var enTete: some View {
        VStack {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .tint(.primary)
                }
                .frame(height: 30)
                .padding()
                Spacer()
            }
            HStack {
                Text("select your weekly availability".localizedCapitalized)
                    .font(.title.weight(.bold))
                    .padding(.horizontal)
                Spacer()
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    private var listeJournees: some View {
        LazyVStack(spacing: 20) {
            ForEach(JourDeLaSemaine.allCases) { jour in
                DisponibilitesJourRangee(
                    jour: jour,
                    creneaux: disponibilites[jour]!,
                    toggle: { toggle(jour) },
                    ajouterCreneau: { ajouterCreneau(to: jour) },
                    editerCreneau: { index in
                        let slot = disponibilites[jour]![index]
                        debutTemp = slot.debut
                        finTemp = max(slot.debut.addingTimeInterval(minSlotGap), slot.fin)
                        jourEnEdition = jour
                        indexEnEdition = index
                        withAnimation(.none) { overlayActif = true }
                    },
                    supprimerCreneau: { index in
                        supprimerCreneau(jour, index: index)
                    },
                    nbDeSlots: disponibilites[jour]!.count
                )
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var boutonContinuer: some View {
        Button {
            // MARK: Modifier plus tard pour que la VM fasse la logique
            let filled = disponibilites
                .filter { !$0.value.isEmpty }

            guard !filled.isEmpty else {
                // aucun créneau -> on ne fait rien (ou afficher une alerte)
                return
            }

            // 2) Construire le dictionnaire à donner à la VM
            let backendDict = Dictionary(
                uniqueKeysWithValues:
                    filled.map { day, slots in
                        (day.rawValue,slots.map { ($0.debut, $0.fin) })
                    }
            )

            vm.disponibilites = backendDict
            etape.append(.photoProfil)
        } label: {
            Text("Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(disponibilites.values.flatMap { $0 }.isEmpty ? Color.gray : Color.red)
                .foregroundColor(.white)
                .cornerRadius(25)
                .padding()
        }
    }
    
    private func toggle(_ jour: JourDeLaSemaine) {
        if disponibilites[jour]!.isEmpty {
            disponibilites[jour]! = [creneauParDefaut()]
        } else {
            disponibilites[jour]! = []
        }
    }

    private func ajouterCreneau(to jour: JourDeLaSemaine) {
        disponibilites[jour, default: []].append(creneauParDefaut())
    }

    private func creneauParDefaut() -> CreneauHoraire {
        let maintenant = Date()
        let uneHeurePlusTard = Calendar.current.date(byAdding: .hour, value: 1, to: maintenant)!
        return CreneauHoraire(debut: maintenant, fin: uneHeurePlusTard)
    }

    private var overlay: some View {
        Group {
            if overlayActif, let jour = jourEnEdition, let index = indexEnEdition {
                FenetreModaleFlottante(estPresente: Binding(
                    get: { overlayActif },
                    set: { if !$0 { withAnimation(.none) { overlayActif = false } } }
                )) {
                    // Fenêtre style "pickerPourHeure" (OK / Close)
                    VStack(spacing: 0) {
                        // Fenêtre: bornes horaires (ex: 06:00–22:00 du jour courant)
                        let cal = Calendar.current
                        let base = cal.startOfDay(for: Date())
                        let minT = cal.date(bySettingHour: 6, minute: 0, second: 0, of: base)!
                        let maxT = cal.date(bySettingHour: 22, minute: 0, second: 0, of: base)!

                        let startBinding = Binding<Date>(
                            get: { debutTemp },
                            set: { newVal in
                                debutTemp = newVal
                                if finTemp < newVal.addingTimeInterval(minSlotGap) {
                                    finTemp = newVal.addingTimeInterval(minSlotGap)
                                }
                            }
                        )

                        let endBinding = Binding<Date>(
                            get: { finTemp },
                            set: { finTemp = $0 }
                        )

                        VStack(spacing: 20) {
                            VStack {
                                Text("Start time").font(.title3).fontWeight(.semibold)
                                DatePicker(
                                    "",
                                    selection: startBinding,
                                    in: minT...maxT,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                            }
                            VStack {
                                Text("End time").font(.title3).fontWeight(.semibold)
                                DatePicker(
                                    "",
                                    selection: endBinding,
                                    in: max(startBinding.wrappedValue.addingTimeInterval(minSlotGap), minT)...maxT,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                            }
                        }
                        .padding([.top, .leading, .trailing], 30)
                        .padding(.bottom, 10)

                        Divider()
                        HStack(spacing: 0) {
                            Button("Close") {
                                // on annule (rien n’a été committé)
                                withAnimation(.none) { overlayActif = false }
                            }
                            .frame(maxWidth: .infinity, maxHeight: 60)
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)

                            Divider().frame(width: 1, height: 60)

                            Button("OK") {
                                let sd = debutTemp
                                var ef = finTemp
                                if ef < sd.addingTimeInterval(minSlotGap) {
                                    ef = sd.addingTimeInterval(minSlotGap)
                                }
                                var slot = disponibilites[jour]![index]
                                slot.debut = sd
                                slot.fin = ef
                                disponibilites[jour]![index] = slot
                                withAnimation(.none) { overlayActif = false }
                            }
                            .frame(maxWidth: .infinity, maxHeight: 60)
                            .foregroundColor(Color("CouleurParDefaut"))
                            .fontWeight(.semibold)
                        }
                    }
                    .frame(width: 300)
                    .transition(.identity) // empêche le fade par défaut
                }
            }
        }
    }
    
    private func supprimerCreneau(_ jour: JourDeLaSemaine, index: Int) {
        guard var slots = disponibilites[jour], slots.indices.contains(index) else { return }
        // Fermer l'éditeur si on supprime le créneau en cours d'édition
        if let ce = creneauEditable, ce.jour == jour, slots[index].id == ce.creneau.id {
            creneauEditable = nil
        }
        slots.remove(at: index)
        disponibilites[jour] = slots
    }
}

struct DisponibilitesJourRangee: View {
    let jour: JourDeLaSemaine
    let creneaux: [CreneauHoraire]
    let toggle: () -> Void
    let ajouterCreneau: () -> Void
    let editerCreneau: (_ index: Int) -> Void
    let supprimerCreneau: (_ index: Int) -> Void
    let nbDeSlots: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: toggle) {
                HStack {
                    Text(jour.nomLocalise).foregroundColor(.primary)
                    Spacer()
                    Image(systemName: creneaux.isEmpty ? "square" : "checkmark.square.fill")
                        .foregroundColor(.red)
                }
            }

            if !creneaux.isEmpty {
                ForEach(Array(creneaux.enumerated()), id: \.element.id) { index, slot in
                    HStack {
                        Image(systemName: "clock").foregroundColor(.red)
                        Text(slot.formate()).foregroundColor(.primary)
                        Spacer()
                        Button {
                            supprimerCreneau(index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .accessibilityLabel(Text("Supprimer ce créneau"))
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())                // agrandit la zone de tap
                    .onTapGesture { editerCreneau(index) }    // tap = éditer
                }

                if nbDeSlots < 2 {
                    Button(action: ajouterCreneau) {
                        HStack {
                            Image(systemName: "plus.circle.fill").foregroundColor(.red)
                            Text("Add time slot").foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            Divider()
        }
    }
}

struct CreneauHoraireEditeur: View {
    let jour: JourDeLaSemaine
    @Binding var creneau: CreneauHoraire
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Set time for \(jour.nomLocalise)").font(.headline)
            DatePicker("Start", selection: $creneau.debut, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
            DatePicker("End", selection: $creneau.fin, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
            Divider()
            HStack {
                Button("Cancel") { onSave() }
                    .frame(maxWidth: .infinity)
                Divider()
                Button("OK") { onSave() }
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    ChoixDisponibilitesVue(vm: InscriptionVM(), etape: .constant([.choixDisponibilites]))
}

