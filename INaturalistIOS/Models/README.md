# iNaturalist Data Models

Historically we used CoreData (via RestKit), but a few years ago
we migrated to Realm for persistence. We use the Mantle models
to map API responses from JSON to iOS objects, then store those
as necessary in Realm. Any objects that need to be available to
the UI regardless of whether they're ephemeral or persistent
have a view protocol. For example, observations can be persistent
(if they belong to the logged in user) or ephemeral (they are
known to the app via an explore search or a project). In either
case, the UI should be able to consistently show the details
of the observation in question.
