import Foundation
import SwiftUI

@MainActor
public final class SessionsListViewModel: ObservableObject {
    
    @Published public var searchQuery: String = ""
    @Published public var sessionToRename: ChatSession?
    @Published public var newTitleInput: String = ""
    @Published public var showRenameDialog: Bool = false
    @Published public var showDeleteConfirmation: Bool = false
    @Published public var sessionToDelete: ChatSession?
    
    public let storageRepo = ChatStorageRepository.shared
    
    public var filteredSessions: [ChatSession] {
        storageRepo.searchSessions(query: searchQuery)
    }
    
    public func promptRename(session: ChatSession) {
        self.sessionToRename = session
        self.newTitleInput = session.title
        self.showRenameDialog = true
    }
    
    public func confirmRename() {
        guard let s = sessionToRename, !newTitleInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        var updated = s
        updated.title = newTitleInput.trimmingCharacters(in: .whitespaces)
        storageRepo.updateSession(updated)
        sessionToRename = nil
        showRenameDialog = false
    }
    
    public func promptDelete(session: ChatSession) {
        self.sessionToDelete = session
        self.showDeleteConfirmation = true
    }
    
    public func confirmDelete() {
        if let s = sessionToDelete {
            storageRepo.deleteSession(id: s.id)
            sessionToDelete = nil
        }
        showDeleteConfirmation = false
    }
    
    public func togglePin(session: ChatSession) {
        storageRepo.togglePin(for: session.id)
        #if canImport(UIKit)
        HapticsManager.shared.impact(.light)
        #endif
    }
    
    public func duplicate(session: ChatSession) {
        storageRepo.duplicateSession(id: session.id)
        #if canImport(UIKit)
        HapticsManager.shared.impact(.light)
        #endif
    }
}
