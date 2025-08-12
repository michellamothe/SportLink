//
//  CreerActivitesVue.swift
//  SportLink
//
//  Created by Michel Lamothe on 2025-06-21.
//

import SwiftUI
import CoreLocation
import Combine

enum ActiveOverlay {
    case none, sport, date, temps, participants, invites
}

struct TripleDates: Equatable {
    let selection: Date
    let debut: Date
    let fin: Date
}

struct CreerActiviteVue: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appVM: AppVM
    @StateObject var vm: CreerActiviteVM
    
    @State private var sportSelectionTemporaire: Sport? = .soccer
    @State private var nbParticipantsSelectionTemporaire: Int? = 0
    @State private var permettreInvitationsSelectionTemporaire: Bool = true
    @State private var overlayActif: ActiveOverlay = .none
    @State private var sportChoisis: Set<String> = [Sport.soccer.nomPourAffichage.capitalized]
    @State private var montrerAlerteChevauchement = false
    
    private let titreLimite = 30
    private let descriptionLimite = 420
    private let minGap: TimeInterval = 15 * 60 // 15 minutes

    
    init(serviceEmplacements: DonneesEmplacementService) {
        self._vm = StateObject(wrappedValue: CreerActiviteVM(serviceActivites: ServiceActivites(), serviceEmplacements: serviceEmplacements))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                contenuPrincipal
            }
            .onChange(of: vm.tempsDebut) { _, nv in
                if vm.tempsFin < nv {
                    vm.tempsFin = Calendar.current.date(byAdding: .hour, value: 1, to: nv)!
                }
            }
            .toolbar { contenuToolbar }
            .safeAreaInset(edge: .bottom, alignment: .center) { barAction }
        }
        .overlay(vueOverlay)
        .onChange(of: vm.sportSelectionne) { _, nvValeur in
            if let infraChoisie = vm.infraChoisie,
               !infraChoisie.sport.contains(nvValeur) {
                vm.infraChoisie = nil
            }
        }
    }
    
    private var contenuPrincipal: some View {
        VStack(spacing: 20) {
            BoiteTitre(
                titre: $vm.titre,
                overlayActif: $overlayActif,
                titreLimite: titreLimite
            )
            
            boutonsOption
            
            sectionCarte
            
            sectionParticipantsEtInvitations
            
            BoiteDescription(
                description: $vm.description,
                overlayActif: $overlayActif,
                descriptionLimite: descriptionLimite
            )
            
            boutonInviterTeammates
            
        }
        .padding(.horizontal)
        .padding(.top, 40)
        .navigationTitle("create an activity".localizedFirstCapitalized)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var boutonsOption: some View {
        VStack(spacing: 20) {
            BoutonOptionOverlay(
                icon: vm.sportSelectionne.icone,
                text: vm.sportSelectionne.nomPourAffichage.capitalized,
                action: { overlayActif = .sport }
            )
            
            BoutonOptionOverlay(
                icon: "calendar",
                text: vm.dateEnString,
                action: { overlayActif = .date }
            )
            
            BoutonOptionOverlay(
                icon: "clock",
                text: "\(vm.debutDuTempsEnString) to \(vm.finDuTempsEnString)",
                action: { overlayActif = .temps }
            )
        }
    }
    
    private var sectionCarte: some View {
        VStack(spacing: 8) {
            BoutonAvecApercuCarte(
                vm: vm,
                sportChoisis: $sportChoisis,
                infraChoisie: $vm.infraChoisie
            )
            .padding(.horizontal)
            
            Text((vm.infraChoisie != nil) ? "A marker has been selected" : "Click on the map to select a marker")
                .font(.caption)
                .foregroundStyle(Color(red: 0.3, green: 0.3, blue: 0.3))
        }
    }

    private var sectionParticipantsEtInvitations: some View {
        VStack(spacing: 20) {
            BoutonOptionOverlay(
                icon: "person.2",
                text: vm.texteParticipants,
                action: { overlayActif = .participants }
            )
            
            BoutonOptionOverlay(
                icon: vm.permettreInvitations ? "figure.child.and.lock.open.fill" : "figure.child.and.lock.fill",
                text: vm.texteInvitations,
                action: { overlayActif = .invites }
            )
        }
    }

    private var boutonInviterTeammates: some View {
        Button {
            // action d'invitation
        } label: {
            Label("Invite teammates", systemImage: "person.2.badge.plus")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(Color("CouleurParDefaut"))
        .controlSize(.large)
        .padding(.horizontal)
        .padding(.bottom, 10)
    }

    @ToolbarContentBuilder
    private var contenuToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Close") { dismiss() }
                .foregroundStyle(.black)
        }
        
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
            }
        }
    }

    private var barAction: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                boutonCreer
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .ignoresSafeArea(edges: .bottom)
        }
    }
    
    private var boutonCreer: some View {
        Button {
            Task {
                if await vm.existeActivitesDejaCreer() {
                    montrerAlerteChevauchement = true
                } else {
                    await vm.creerActivite()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                        appVM.ongletSelectionne = .activites
                        appVM.trigger = .organise
                        appVM.sousOngletSelectionne = .organise
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("create".localizedCapitalized)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color("CouleurParDefaut"))
        .controlSize(.large)
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .opacity(estDesactiver ? 0.6 : 1)
        .disabled(estDesactiver)
        .alert("Overlapping detected", isPresented: $montrerAlerteChevauchement) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("An activity is already planned at this infrastructure for the selected time.")
        }
    }

    private var estDesactiver: Bool {
        vm.titre.isEmpty || vm.nbParticipants == 0 || vm.infraChoisie == nil || montrerAlerteChevauchement
    }
    
    struct BoiteTitre: View {
        @Binding var titre: String
        @Binding var overlayActif: ActiveOverlay
        let titreLimite: Int
        
        var body: some View {
            VStack {
                TextField("Title of the activity", text: $titre)
                    .padding(.leading, 16)
                    .frame(minHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.gray.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    .onReceive(Just(titre)) { _ in limiterTexte(titreLimite) }
                    .disabled(overlayActif != .none)
            }
            .padding(.horizontal)
        }
        
        func limiterTexte(_ upper: Int) {
            if titre.count > upper {
                titre = String(titre.prefix(upper))
            }
        }
    }
    
    struct BoiteDescription: View {
        @Binding var description: String
        @Binding var overlayActif: ActiveOverlay
        let descriptionLimite: Int

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("Description")
                    .font(.headline)
                
                Text("Maximum of \(descriptionLimite) characters")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 4)
                
                TextEditor(text: $description)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .onReceive(Just(description)) { _ in limiterTexte(descriptionLimite) }
                    .disabled(overlayActif != .none)
            }
            .padding(.horizontal)
        }
        
        func limiterTexte(_ upper: Int) {
            if description.count > upper {
                description = String(description.prefix(upper))
            }
        }
    }

    @ViewBuilder
    private var vueOverlay: some View {
        switch overlayActif {
        case .sport: pickerPourSport
        case .date: pickerPourDate
        case .temps: pickerPourHeure
        case .participants: pickerPourParticipants
        case .invites: pickerPourInvites
        default: EmptyView()
        }
    }

    private var pickerPourSport: some View {
        FenetreModaleFlottante(estPresente: Binding(
            get: { overlayActif == .sport },
            set: { if !$0 { overlayActif = .none } }
        )) {
            VStack(spacing: 16) {
                VStack(spacing: 0) {
                    Text("Select a sport")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(Sport.allCases, id: \.self) { sport in
                                Button {
                                    sportSelectionTemporaire = sport
                                } label: {
                                    HStack {
                                        Image(systemName: sport.icone)
                                        Text(sport.nomPourAffichage.capitalized)
                                        Spacer()
                                    }
                                    .foregroundColor(sportSelectionTemporaire == sport ? Color("CouleurParDefaut") : .black)
                                    .padding(.horizontal)
                                    .padding(.vertical, 14)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(.top, 30)
                .padding(.bottom, 10)
                .padding(.horizontal, 20)
                
                VStack(spacing: 0) {
                    Divider()

                      HStack(spacing: 0) {
                        Button(action: {
                            sportSelectionTemporaire = vm.sportSelectionne
                            overlayActif = .none
                        }) {
                          Text("Close")
                            .frame(maxWidth: .infinity, maxHeight: 60)
                        }
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)

                        Divider()
                          .frame(width: 1, height: 60)

                        Button(action: {
                          if let sportConfirme = sportSelectionTemporaire {
                              vm.sportSelectionne = sportConfirme
                              sportChoisis = [sportConfirme.nomPourAffichage.capitalized]
                          }
                          overlayActif = .none
                        }) {
                          Text("OK")
                            .frame(maxWidth: .infinity, maxHeight: 60)
                        }
                        .foregroundColor(Color("CouleurParDefaut"))
                    }
                }
            }
            .frame(width: 300)
        }
    }

    private var pickerPourDate: some View {
        FenetreModaleFlottante(estPresente: Binding(
            get: { overlayActif == .date },
            set: { if !$0 { overlayActif = .none } }
        )) {
            VStack(spacing: 8) {
                VStack(spacing: 8) {
                    Text("Select a date")
                        .font(.title3)
                        .fontWeight(.semibold)

                    DatePicker(
                        "",
                        selection: Binding(
                            get: { vm.dateSelectionneeSelectionTemporaire ?? vm.dateSelectionnee },
                            set: { vm.dateSelectionneeSelectionTemporaire = $0 }
                        ),
                        in: vm.dateMin...vm.dateMax,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .accentColor(Color("CouleurParDefaut"))
                }
                .padding([.top, .leading, .trailing], 30)
                .padding(.bottom, 10)

                // --- Barre Close / OK
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 0) {
                        Button("Close") {
                            vm.dateSelectionneeSelectionTemporaire = vm.dateSelectionnee
                            overlayActif = .none
                        }
                        .frame(maxWidth: .infinity, maxHeight: 60)
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)

                        Divider()
                            .frame(width: 1, height: 60)

                        Button("OK") {
                            var sd = vm.tempsDebutSelectionTemporaire!
                            var ef = vm.tempsFinSelectionTemporaire!
                            if ef < sd.addingTimeInterval(minGap) {
                                ef = sd.addingTimeInterval(minGap)
                            }
                            vm.tempsDebut = sd
                            vm.tempsFin = ef
                            overlayActif = .none
                        }
                        .frame(maxWidth: .infinity, maxHeight: 60)
                        .foregroundColor(Color("CouleurParDefaut"))
                        .fontWeight(.semibold)
                    }
                }
            }
            .frame(width: 300)
        }
    }

    private var pickerPourHeure: some View {
        FenetreModaleFlottante(estPresente: Binding(
            get: { overlayActif == .temps },
            set: { if !$0 { overlayActif = .none } }
        )) {
            VStack(spacing: 0) {
                // Calcul des bornes 06:00 et 22:00 du même jour
                let calendrier = Calendar.current
                let debutDeJournee = calendrier.startOfDay(for: vm.dateSelectionnee)
                let tempsMin = calendrier.date(byAdding: .hour, value: 6,  to: debutDeJournee)!
                let tempsMax = calendrier.date(byAdding: .hour, value: 22, to: debutDeJournee)!

                // Initialisation des temporaires à l’apparition
                Color.clear.onAppear {
                    vm.tempsDebutSelectionTemporaire = vm.tempsDebut
                    vm.tempsFinSelectionTemporaire = vm.tempsFin
                }

                let startBinding = Binding<Date>(
                    get: { vm.tempsDebutSelectionTemporaire! },
                    set: { new in
                        vm.tempsDebutSelectionTemporaire = new
                        // fin ≥ début + 15min
                        if let curEnd = vm.tempsFinSelectionTemporaire,
                           curEnd < new.addingTimeInterval(minGap) {
                            vm.tempsFinSelectionTemporaire = new.addingTimeInterval(minGap)
                        }
                    }
                )

                let endBinding = Binding<Date>(
                    get: { vm.tempsFinSelectionTemporaire! },
                    set: { vm.tempsFinSelectionTemporaire = $0 }
                )

                // Roulettes avec restriction
                VStack(spacing: 20) {
                    VStack {
                        Text("Start time")
                            .font(.title3).fontWeight(.semibold)
                        DatePicker(
                            "",
                            selection: startBinding,
                            in: tempsMin...tempsMax,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                    }
                    VStack {
                        Text("End time")
                            .font(.title3).fontWeight(.semibold)
                        DatePicker(
                            "",
                            selection: endBinding,
                            in: max(startBinding.wrappedValue.addingTimeInterval(minGap), tempsMin)...tempsMax,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                    }
                }
                .padding([.top, .leading, .trailing], 30)
                .padding(.bottom, 10)

                // Barre Close / OK
                Divider()
                HStack(spacing: 0) {
                    Button("Close") {
                        // on annule les temporaires
                        vm.tempsDebutSelectionTemporaire = vm.tempsDebut
                        vm.tempsFinSelectionTemporaire = vm.tempsFin
                        overlayActif = .none
                    }
                    .frame(maxWidth: .infinity, maxHeight: 60)
                    .foregroundColor(.primary)
                    .fontWeight(.semibold)

                    Divider().frame(width: 1, height: 60)

                    Button("OK") {
                        // on commit en veillant à ne jamais sortir des bornes
                        let sd = vm.tempsDebutSelectionTemporaire!
                        var ef = vm.tempsFinSelectionTemporaire!

                        // si ef < sd, recaler ef = sd
                        if ef < sd { ef = sd }

                        vm.tempsDebut = sd
                        vm.tempsFin = ef
                        overlayActif = .none
                    }
                    .frame(maxWidth: .infinity, maxHeight: 60)
                    .foregroundColor(Color("CouleurParDefaut"))
                    .fontWeight(.semibold)
                }
            }
            .frame(width: 300)
        }
    }


    private var pickerPourParticipants: some View {
        FenetreModaleFlottante(estPresente: Binding(
            get: { overlayActif == .participants },
            set: { if !$0 { overlayActif = .none } }
        )) {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Text("Select number")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.bottom, 6)
                    
                    Text("This number does not include you.")
                        .font(.caption)
                        .foregroundStyle(.gray)

                    Picker(
                        "",
                        selection: Binding(
                            get: { nbParticipantsSelectionTemporaire ?? vm.nbParticipants },
                            set: { nbParticipantsSelectionTemporaire = $0 }
                        )
                    ) {
                        ForEach(0..<16, id: \.self) {
                            Text("\($0)")
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                    .clipped()
                }
                .padding([.top, .leading, .trailing], 30)
                .padding(.bottom, 10)

                // --- Barre Close / OK
                Divider()
                HStack(spacing: 0) {
                    Button("Close") {
                        nbParticipantsSelectionTemporaire = vm.nbParticipants
                        overlayActif = .none
                    }
                    .frame(maxWidth: .infinity, maxHeight: 60)
                    .foregroundColor(.primary)
                    .fontWeight(.semibold)

                    Divider()
                        .frame(width: 1, height: 60)

                    Button("OK") {
                        vm.nbParticipants = nbParticipantsSelectionTemporaire!
                        overlayActif = .none
                    }
                    .frame(maxWidth: .infinity, maxHeight: 60)
                    .foregroundColor(Color("CouleurParDefaut"))
                    .fontWeight(.semibold)
                }
            }
            .frame(width: 300)
        }
    }

    private var pickerPourInvites: some View {
        FenetreModaleFlottante(estPresente: Binding(
          get: { overlayActif == .invites },
          set: { if !$0 { overlayActif = .none } }
      )) {
          VStack(spacing: 0) {
              VStack(spacing: 0) {
                  Text("Guests invitations")
                      .font(.title3)
                      .fontWeight(.semibold)

                  VStack(spacing: 10) {
                      Button {
                          permettreInvitationsSelectionTemporaire = true
                      } label: {
                          Label("Open to guests invitations", systemImage: "figure.child.and.lock.open.fill")
                              .frame(maxWidth: .infinity, alignment: .leading)
                              .padding()
                              .background(Color(.systemGray6))
                                .foregroundColor(permettreInvitationsSelectionTemporaire ? Color("CouleurParDefaut") : .black)
                                .cornerRadius(8)
                      }
                      .buttonStyle(.plain)

                      Button {
                          permettreInvitationsSelectionTemporaire = false
                      } label: {
                          Label("Close to guests invitations", systemImage: "figure.child.and.lock.fill")
                              .frame(maxWidth: .infinity, alignment: .leading)
                              .padding()
                              .background(Color(.systemGray6))
                              .foregroundColor(!permettreInvitationsSelectionTemporaire ? Color("CouleurParDefaut") : .black)
                              .cornerRadius(8)
                      }
                      .buttonStyle(.plain)
                  }
                  .padding(.top, 20)
              }
              .padding([.top, .leading, .trailing], 20)
              .padding(.bottom, 25)

              // --- Barre Close / OK
              Divider()
              HStack(spacing: 0) {
                  Button("Close") {
                      if permettreInvitationsSelectionTemporaire && !vm.permettreInvitations {
                          permettreInvitationsSelectionTemporaire = false
                      } else if !permettreInvitationsSelectionTemporaire && vm.permettreInvitations {
                          permettreInvitationsSelectionTemporaire = true
                      }
                      overlayActif = .none
                  }
                  .frame(maxWidth: .infinity, maxHeight: 60)
                  .foregroundColor(.primary)
                  .fontWeight(.semibold)

                  Divider().frame(width: 1, height: 60)

                  Button("OK") {
                      vm.permettreInvitations = permettreInvitationsSelectionTemporaire
                      overlayActif = .none
                  }
                  .frame(maxWidth: .infinity, maxHeight: 60)
                  .foregroundColor(Color("CouleurParDefaut"))
                  .fontWeight(.semibold)
              }
          }
          .frame(width: 300)
        }
    }
}

struct BoutonOptionOverlay: View {
    let icon: String, text: String, action: () -> Void
    var body: some View {
        Button(action: action) {
            BoiteAvecChevron(showChevron: true) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.red)
                Text(text).foregroundColor(.black)
            }
        }.buttonStyle(.plain)
    }
}

#Preview {
    CreerActiviteVue(serviceEmplacements: DonneesEmplacementService())
        .environmentObject(DonneesEmplacementService())
        .environmentObject(AppVM())
}

