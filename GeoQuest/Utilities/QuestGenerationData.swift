import Foundation

enum QuestGenerationData {

    // MARK: - Fake Player Usernames

    static let fakeUsernames = [
        // Casual everyday explorers
        "MorningWalker", "LocalLooper", "JustPassingThru", "WeekendRoamer",
        "PocketMap_J", "BrunchHunter", "AfternoonStroller", "CityDaydream",
        "QuietNomad", "PavementPainter", "CornerCurious", "DailyDetour",
        "NoonExplorer", "BlockByBlock", "SlowWanderer", "NeighborhoodNerd",
        "UrbanSketchr", "SidewalkDiary", "MapAndMuffin", "FreshAirFinder",

        // Adventure-coded names
        "ShadowWalker42", "StreetPhantom", "GeoHunter99", "NightRover",
        "TrailBlazer77", "WanderWolf", "UrbanExplorer_X", "AlleyAdventurer",
        "GridGhost", "NavNinja", "RoamRanger", "ClueChaser_V",
        "GeoGlitch", "TrailTiger22", "LocusLegend", "QuestHawk",
        "DriftKing_R", "MapMaverick", "StreetSleuth", "CoordCrusader",

        // Hobbyist / theme names
        "CoffeeCrawler", "BrickByBrick_K", "TileTracker", "FacadeFreak",
        "SignSpotter_M", "WindowWatcher", "GraffitiGuide", "HistoryHiker",
        "ArchNerd_P", "PlaquePursuit", "OldTownOtto", "PaveStoneQuest",
        "NeonSeeker", "CrosswalkKid", "LampostLore", "GargoyleGazer",

        // Number-coded handles
        "Wanderer_404", "QuestLog_07", "GeoRun_22", "Marker_X9",
        "TrailCode_33", "ClueMap_11", "StepSeeker_88", "RouteRunner33",
        "HiddenGem88", "WalkAbout_77", "GridRunner_22", "ClueHound88",
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
        "camera.fill", "map.fill", "compass.drawing", "eye.fill",
        "lightbulb.fill", "clock.fill", "sun.max.fill", "moon.fill",
    ]

    // MARK: - Quest Colors (hex strings)

    static let questColors = [
        "FF3B30", "FF9500", "FFCC00", "34C759", "5AC8FA",
        "007AFF", "5856D6", "AF52DE", "FF2D55", "00C7BE",
        "32D2FF", "FF6B35", "A3CB38", "FFC312", "ED4C67",
        "6AB04C", "22A6B3", "4A90FF", "7B5CFF", "FF8A34",
        "C0392B", "8E44AD", "2980B9", "27AE60", "D35400",
    ]

    // MARK: - Quest Title Templates
    // {place} = POI name, {street} = street name, {area} = neighborhood/area

    static let questTitleTemplates = [
        // Mystery / cipher
        "The {street} Mystery",
        "The {area} Cipher",
        "The {place} Enigma",
        "Secrets of {place}",
        "Riddle of {place}",
        "Echoes Near {place}",
        "What's Hidden on {street}?",
        "Decode {area}",
        "The {area} Code",
        "Phantom of {place}",

        // Adventure / exploration
        "Hidden Path to {place}",
        "{street} Shadow Hunt",
        "Ghost Trail: {street}",
        "{street} Treasure Run",
        "Pathfinder: {street}",
        "The {place} Expedition",
        "Signal at {place}",
        "Traces Near {place}",
        "{street} Recon",
        "Whispers Near {place}",
        "Urban Legend: {area}",

        // Casual / personal
        "My Favorite Spot in {area}",
        "You Have to See {place}",
        "Quick One Near {place}",
        "A Walk I Made in {area}",
        "Worth the Trip: {place}",
        "Lunch Break in {area}",
        "My {street} Route",
        "Look Closer at {place}",
        "Coffee & Clues: {area}",
        "Saturday Stroll: {street}",

        // Challenge-framed
        "Can You Find It? — {area}",
        "Most People Miss This on {street}",
        "The {area} Challenge",
        "Eyes Open: {street}",
        "Clue Hunter: {street}",
        "Decoder: {area} Trail",
        "Spot It Near {place}",
        "Only the Observant: {area}",
        "Missed by Thousands: {place}",
        "Follow the Signs in {area}",
    ]

    // MARK: - Quest Description Templates

    static let questDescriptionTemplates = [
        // Personal / casual voice
        "I walk past {place} almost every day and finally decided to make a quest out of it. Pay attention!",
        "Stumbled onto something interesting near {place} last week — made a quick quest. Have fun.",
        "Set this up with a friend on {street}. We were surprised how few people notice this.",
        "I make this walk at least once a week. There's a detail near {place} most folks miss.",
        "Made this one after noticing something odd near {place}. See if you spot it too.",
        "My go-to afternoon route around {area}. The code hides in plain sight.",
        "Built this after a rainy Saturday walk around {street}. The clue is right there if you look.",
        "A friend dared me to make a quest near {place}. Now it's your problem.",
        "I noticed this on my lunch break near {place}. Figured it was quest-worthy.",
        "Did this walk with my dog on {street} and had an idea. Hope you enjoy it!",

        // Mysterious / atmospheric
        "Someone left a trail of clues near {place}. Can you follow them and crack the code?",
        "There's a hidden code waiting near {place}. Think you can spot it?",
        "I found something strange on {street}. Follow these steps to uncover the secret.",
        "The code is out there near {place}. Keep your eyes open and trust the clues.",
        "Walk the path near {street}. The code reveals itself to those who look carefully.",
        "Can you decode the secrets hidden around {area}? Only the observant will succeed.",
        "There's more to {street} than meets the eye. Follow the steps and find the code.",

        // Challenge-framed
        "Think you know {area}? This quest will test that. The answer is hiding in plain sight.",
        "Navigate through {street} and find what most people walk right past.",
        "Ever notice the details around {place}? This quest will open your eyes.",
        "The answer is written right there on {street} — you just have to know where to look.",
        "A friend tried this for 10 minutes before giving up. You'll do better, right?",
        "Looks simple. Isn't. The code near {place} is trickier than it sounds.",

        // Flavor / local knowledge
        "Explore {area} and follow the clues. The answer is hiding in plain sight.",
        "A friend and I set this one up around {area}. Pay attention to your surroundings!",
        "Start near {place} and keep your eyes up — you'll need to notice more than usual.",
        "There's a lot going on around {street} if you slow down and look.",
        "This stretch of {street} has more to offer than most people realize. Go see.",
    ]

    // MARK: - First Step Templates (orient the player)

    static let firstStepTemplates = [
        // Straightforward directions
        "Head toward {place} on {street}. You'll want to be on the side closest to it.",
        "Start by making your way to {street}. Look for {place} — that's your starting point.",
        "Walk to {street} and locate {place}. This is where the trail begins.",
        "Head to {street} and find {place}. Stand in front and face it directly.",
        "Go to {street} — you're looking for {place}. That's where everything starts.",
        "Your quest begins at {place}. Get there and look around carefully.",

        // Personal/conversational
        "Make your way to {place}. Once you can see it clearly, you're in the right spot.",
        "Find {place} near {street}. Stand where you can see the entrance clearly.",
        "Begin at {place} on {street}. Take a good look at the surroundings before moving on.",
        "First stop: {place}. You'll know you're in the right place when you see it.",
        "Go to {place}. Take a moment when you arrive — there's more to see than you expect.",
        "Head out to {place} and get your bearings. The rest follows from there.",

        // Observational prompt
        "Your starting point is {place} on {street}. Once you're there, look around — notice anything?",
        "Make your way to {street} and find {place}. Before you move on, look at it carefully.",
        "Start at {place}. Don't rush — there's something here worth noticing first.",
    ]

    // MARK: - Middle Step Templates (navigation and observation)

    static let middleStepTemplates = [
        // Navigation
        "From here, turn {direction} and walk along {street} until you spot {place}.",
        "Look {direction} — do you see {place}? Head that way now.",
        "Continue along {street}. Keep going until {place} is on your {side}.",
        "Cross to the other side of {street}. You should be able to see {place} from here.",
        "Head {direction} along {street}. You'll pass a few buildings before reaching {place}.",
        "Now face {direction}. Walk until you can read the sign at {place}.",
        "Keep {street} on your {side} and head toward {place}. Almost there.",

        // Observation prompts
        "Walk past {place} and keep going. There's something you need to notice on {street}.",
        "Stop when you reach {place}. Look at the building carefully — notice anything unusual?",
        "From {place}, look across {street}. What do you see? Remember it.",
        "Take a moment at {place}. Look up — there's a detail most people miss.",
        "You should see {place} ahead. Walk toward it and pay attention to what's around the entrance.",
        "Follow {street} and keep {place} on your {side}. You're getting closer.",

        // Personal/casual tone
        "This part of {street} is easy to rush through. Don't. Look at {place} when you pass it.",
        "Head to {place} but don't go inside — the clue is on the outside.",
        "You'll see {place} as you continue on {street}. Slow down when you get there.",
        "Walk toward {place} and keep your eyes at street level. Things are visible if you look.",
        "This next bit is on {street}. Find {place} and note what's right outside it.",
        "Follow {street} until {place} comes into view. There's something worth reading there.",
    ]

    // MARK: - Observation Steps (no specific POI needed)

    static let observationStepTemplates = [
        "Stop and look around. Notice the street sign for {street}. Remember the name.",
        "Look down {street} in both directions. Which way has more shops? Head that way.",
        "Find the nearest intersection on {street}. Read the crossing street name — you'll need it.",
        "Look for any numbers on the buildings around you on {street}. Pay attention to them.",
        "Pause here on {street}. Look at the storefronts nearby. Something stands out.",
        "Check your surroundings on {street}. What's the most colorful sign you can see?",
        "Take a look at the buildings on {street}. Notice anything placed at eye level?",
        "There's a detail on {street} that most people walk past. Slow down and look.",
        "Before you move on, count the number of businesses you can see from where you're standing.",
        "Look both ways on {street}. Is there a bench, plaque, or marker nearby?",
    ]

    // MARK: - Final Step Templates (finding the code)

    static let finalStepTemplates = [
        // Address number
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
        "You're here. The answer is the street address of {place}. Should be visible from the sidewalk.",
        "Good work getting here. The code is the building number at {place}. Enter it and you're done!",
    ]

    // MARK: - Name-Based Final Step Templates (when code is derived from place name)

    static let nameBasedFinalStepTemplates = [
        "Find {place} and look at the sign. The first {n} letters of the name are your code.",
        "You've reached {place}. Read the name on the sign — the first {n} letters are the code.",
        "Look at the {place} sign carefully. Take the first {n} letters. That's your secret code!",
        "At {place}, read the name displayed outside. The first {n} letters complete the quest.",
        "Almost there! Find {place} and read the sign. Your code is the first {n} letters.",
        "The code is spelled out right there — look at {place} and use the first {n} letters.",
    ]

    // MARK: - Directions & Sides

    static let directions = ["left", "right", "north", "south", "east", "west"]
    static let sides = ["left", "right"]
}
