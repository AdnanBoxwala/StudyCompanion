import Foundation
import SwiftData

// TODO: Extract library-specific logic from views into this view model.
// Currently the Library views use @Query and @Environment(\.modelContext) directly,
// which works well for simple CRUD. As the library grows (search, filtering, sorting
// preferences, batch operations), move that logic here.
