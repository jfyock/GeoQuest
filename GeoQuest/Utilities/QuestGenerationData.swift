import Foundation

enum QuestGenerationData {

    // MARK: - Fake Player Usernames

    static let fakeUsernames = [
        "ShadowWalker42", "StreetPhantom", "GeoHunter99", "MapQuester",
        "UrbanExplorer_X", "QuestMaster_J", "NightRover", "TrailBlazer77",
        "CitySeeker", "WanderWolf", "PixelPilgrim", "CoordCrusader",
        "PathFinder_K", "RouteRunner33", "LandmarkLion", "AlleyAdventurer",
        "CompassKid", "GridGhost", "PinDropper", "TreasureTrex",
        "SidewalkSage", "BlockBreaker_M", "HiddenGem88", "NavNinja",
        "ScoutMaster", "QuestHawk", "WaypointWiz", "DriftKing_R",
        "RoamRanger", "ClueChaser_V", "MapMaverick", "StreetSleuth",
        "GeoGlitch", "TrailTiger22", "SpotSeeker", "LocusLegend",
        "MarkerMystic", "PinPointPro", "ZoneZapper", "QuestCrafter_D",
        "WalkAbout_77", "RouteStar", "NorthBound_K", "StepTracker",
        "Wayfarer_X", "CoordKing", "GridRunner_22", "PathProwler",
        "SignSeeker_J", "StreetOracle", "MapDrifter", "ClueHound88",
        "TreckTitan", "UrbanOwl", "LostAndFound_M", "RoadRiddler",
        "GeoNomad_V", "TrailWhisper", "SpotlightSam", "PinChaser_99",
    ]

    // MARK: - Quest Icons (SF Symbols)

    static let questIcons = [
        "mappin.circle.fill", "flag.fill", "star.fill", "heart.fill",
        "bolt.fill", "flame.fill", "leaf.fill", "tree.fill",
        "mountain.2.fill", "drop.fill", "sparkles", "diamond.fill",
        "shield.fill", "trophy.fill", "key.fill", "binoculars.fill",
        "magnifyingglass", "puzzlepiece.fill", "crown.fill", "gift.fill",
        "globe.americas.fill", "building.2.fill", "figure.walk",
    ]

    // MARK: - Quest Colors (hex strings)

    static let questColors = [
        "FF3B30", "FF9500", "FFCC00", "34C759", "5AC8FA",
        "007AFF", "5856D6", "AF52DE", "FF2D55", "00C7BE",
        "32D2FF", "FF6B35", "A3CB38", "FFC312", "ED4C67",
        "6AB04C", "22A6B3", "4A90FF", "7B5CFF", "FF8A34",
    ]

    // MARK: - Quest Title Templates
    // {place} = POI name, {street} = street name, {area} = neighborhood/area

    static let questTitleTemplates = [
        "The {street} Mystery",
        "Secrets of {place}",
        "Hidden Path to {place}",
        "{street} Shadow Hunt",
        "The Lost Code of {area}",
        "Ghost Trail: {street}",
        "Riddle of {place}",
        "The {area} Challenge",
        "Whispers Near {place}",
        "{street} Treasure Run",
        "Midnight at {place}",
        "The {area} Cipher",
        "Pathfinder: {street}",
        "Echoes of {place}",
        "Urban Legend: {area}",
        "Clue Hunter: {street}",
        "The {place} Expedition",
        "Decoder: {area} Trail",
        "Signal at {place}",
        "The {street} Enigma",
        "Phantom of {place}",
        "The {area} Puzzle",
        "{street} Recon",
        "Traces Near {place}",
    ]

    // MARK: - Quest Description Templates

    static let questDescriptionTemplates = [
        "Someone left a trail of clues near {place}. Can you follow them and crack the code?",
        "I found something strange on {street}. Follow these steps to uncover the secret.",
        "There's a hidden code waiting to be found near {place}. Think you can spot it?",
        "Explore {area} and follow the clues. The answer is hiding in plain sight.",
        "I spent an afternoon mapping this trail near {street}. Good luck cracking it!",
        "The code is out there near {place}. Keep your eyes open and trust the clues.",
        "A friend and I set this one up around {area}. Pay attention to your surroundings!",
        "This one's tricky. Navigate through {street} and find what most people walk right past.",
        "Ever notice the details around {place}? This quest will open your eyes.",
        "Walk the path near {street}. The code reveals itself to those who look carefully.",
        "Stumbled onto something interesting near {place}. Made a quest out of it!",
        "Can you decode the secrets hidden around {area}? Only the observant will succeed.",
        "I walk past {place} every day and never noticed this until last week. Your turn!",
        "There's more to {street} than meets the eye. Follow the steps and find the code.",
        "Set this up for my friends but figured everyone should try it. Start near {place}!",
        "The answer is written right there on {street} — you just have to know where to look.",
    ]

    // MARK: - First Step Templates (orient the player)

    static let firstStepTemplates = [
        "Head toward {place} on {street}. You'll want to be on the side closest to it.",
        "Start by making your way to {street}. Look for {place} — that's your starting point.",
        "Find {place} near {street}. Stand where you can see the entrance clearly.",
        "Walk to {street} and locate {place}. This is where the trail begins.",
        "Your quest begins at {place}. Get there and look around carefully.",
        "Head to {street} and find {place}. Stand in front and face it directly.",
        "Make your way to {place}. Once you can see it, you're ready for the next step.",
        "Go to {street} — you're looking for {place}. That's where everything starts.",
        "Begin at {place} on {street}. Take a good look at the surroundings before moving on.",
    ]

    // MARK: - Middle Step Templates (navigation and observation)

    static let middleStepTemplates = [
        "From here, turn {direction} and walk along {street} until you spot {place}.",
        "Look {direction} — do you see {place}? Head that way now.",
        "Continue along {street}. Keep going until {place} is on your {side}.",
        "Cross to the other side of {street}. You should be able to see {place} from here.",
        "Walk past {place} and keep going. There's something you need to notice on {street}.",
        "Stop when you reach {place}. Look at the building carefully — notice anything unusual?",
        "Head {direction} along {street}. You'll pass a few buildings before reaching {place}.",
        "From {place}, look across {street}. What do you see? Remember it.",
        "Follow {street} and keep {place} on your {side}. You're getting closer.",
        "Take a moment at {place}. Look up — there's a detail most people miss.",
        "Now face {direction}. Walk until you can read the sign at {place}.",
        "Keep {street} on your {side} and head toward {place}. Almost there.",
        "You should see {place} ahead. Walk toward it and pay attention to what's around the entrance.",
    ]

    // MARK: - Observation Steps (no specific POI needed)

    static let observationStepTemplates = [
        "Stop and look around. Notice the street sign for {street}. Remember the name.",
        "Look down {street} in both directions. Which way has more shops? Head that way.",
        "Find the nearest intersection on {street}. Read the crossing street name — you'll need it.",
        "Look for any numbers on the buildings around you on {street}. Pay attention to them.",
        "Pause here on {street}. Look at the storefronts nearby. Something stands out.",
        "Check your surroundings on {street}. What's the most colorful sign you can see?",
    ]

    // MARK: - Final Step Templates (finding the code)

    static let finalStepTemplates = [
        "You've made it to {place}. The address number on the building is your code!",
        "Now find the sign for {place}. The street number displayed there is the secret code.",
        "At {place}, look for the address. Those digits are what you need to complete the quest.",
        "Check the front of {place}. The numbers on the building are what you're looking for.",
        "You're at {place} on {street}. The address number here is the code — enter it to finish!",
        "Stand in front of {place}. The code is the building number you can see from the street.",
        "Look at {place} closely. The numbers visible from outside hold the answer.",
        "Find the address displayed at {place}. Those digits are the secret code. Well done!",
        "Almost done! The code is the address number at {place}. Look at the front of the building.",
        "You made it! Look at {place} — the address number right there is your secret code.",
    ]

    // MARK: - Name-Based Final Step Templates (when code is derived from place name)

    static let nameBasedFinalStepTemplates = [
        "Find {place} and look at the sign. The first {n} letters of the name are your code.",
        "You've reached {place}. Read the name on the sign — the first {n} letters are the code.",
        "Look at the {place} sign carefully. Take the first {n} letters. That's your secret code!",
        "At {place}, read the name displayed outside. The first {n} letters complete the quest.",
    ]

    // MARK: - Directions & Sides

    static let directions = ["left", "right"]
    static let sides = ["left", "right"]
}
