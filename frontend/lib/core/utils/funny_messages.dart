import 'dart:math';

/// Funny industry-themed messages (Dad Jokes style) for user actions
class FunnyMessages {
  FunnyMessages._();

  static final _random = Random();

  static String _pickRandom(List<String> messages) {
    return messages[_random.nextInt(messages.length)];
  }

  // ==================== SUCCESS MESSAGES ====================

  static String get toolAdded => _pickRandom(_toolAddedMessages);
  static const _toolAddedMessages = [
    "Nailed it! Your tool is now in the box.",
    "Tool secured! That's one less thing rattling around.",
    "Another one for the collection! Your toolbox approves.",
    "Tool added successfully. Your garage cred just went up!",
    "Boom! Tool's in. You're building quite the arsenal.",
  ];

  static String get toolboxCreated => _pickRandom(_toolboxCreatedMessages);
  static const _toolboxCreatedMessages = [
    "You've built yourself a fine toolbox! Bob the Builder would be proud.",
    "New toolbox unlocked! Time to fill 'er up.",
    "Toolbox created! It's not the size that matters... okay, maybe it does.",
    "Your new toolbox is ready. It's already judging your organization skills.",
    "Toolbox assembled! No instructions needed, apparently.",
  ];

  static String get sharingApproved => _pickRandom(_sharingApprovedMessages);
  static const _sharingApprovedMessages = [
    "Tool's out! Remember, measure twice, lend once.",
    "Sharing approved! Your tool is on a field trip.",
    "Lending confirmed. May your tool return unscratched.",
    "Tool shared! You're a true tool philanthropist.",
    "Approved! Your tool promises to behave.",
  ];

  static String get profileUpdated => _pickRandom(_profileUpdatedMessages);
  static const _profileUpdatedMessages = [
    "Looking sharp! Sharper than a freshly honed chisel.",
    "Profile updated! You clean up nice.",
    "Saved! Your profile is now the talk of the workshop.",
    "Updated! Looking good enough for the tool catalog.",
    "Profile polished. Shiny as a new socket wrench!",
  ];

  static String get toolReturned => _pickRandom(_toolReturnedMessages);
  static const _toolReturnedMessages = [
    "Welcome back, tool! We missed you.",
    "Tool returned! Did it have fun on its adventure?",
    "Back in the toolbox where it belongs!",
    "Return confirmed. Tool appears undamaged... we'll verify.",
    "Your tool is home safe and sound!",
  ];

  static String get buddyAdded => _pickRandom(_buddyAddedMessages);
  static const _buddyAddedMessages = [
    "New buddy acquired! Your tool circle grows.",
    "You've got a new workshop friend!",
    "Buddy added! Someone to borrow tools from... I mean, share with.",
    "Connection made! Tool networking at its finest.",
    "New buddy on board! The more the merrier.",
  ];

  // ==================== ERROR MESSAGES ====================

  static String get networkError => _pickRandom(_networkErrorMessages);
  static const _networkErrorMessages = [
    "Looks like our wires got crossed. Check your connection!",
    "Connection dropped faster than a dropped wrench. Try again!",
    "The internet took a coffee break. Please reconnect.",
    "Signal lost! Even our digital tools need good connections.",
    "Network hiccup! Give it another shot.",
  ];

  static String get saveFailed => _pickRandom(_saveFailedMessages);
  static const _saveFailedMessages = [
    "Houston, we have a problem. That didn't stick like wood glue.",
    "Oops! That didn't save. Unlike duct tape, this didn't hold.",
    "Save failed. Even WD-40 can't fix this one.",
    "Something went wrong. Time to get out the troubleshooting manual.",
    "Error! But unlike a stripped screw, we can retry this.",
  ];

  static String get invalidInput => _pickRandom(_invalidInputMessages);
  static const _invalidInputMessages = [
    "That doesn't quite fit. Like a square peg in a round hole.",
    "Invalid input. Measure twice, type once!",
    "That's not right. Check your measurements... I mean, input.",
    "Error! That's like using a hammer when you need a screwdriver.",
    "Something's off. Let's recalibrate.",
  ];

  static String get genericError => _pickRandom(_genericErrorMessages);
  static const _genericErrorMessages = [
    "Something broke! Time to get out the duct tape.",
    "Error encountered. This is why we keep spare parts.",
    "Oops! That wasn't supposed to happen.",
    "Well, that didn't work. Back to the drawing board!",
    "Houston, we have a problem. Let's troubleshoot.",
  ];

  // ==================== LOADING MESSAGES ====================

  static String get loading => _pickRandom(_loadingMessages);
  static const _loadingMessages = [
    "Tightening the bolts...",
    "Measuring twice...",
    "Leveling things out...",
    "Sanding the rough edges...",
    "Calibrating precision...",
    "Organizing the toolbox...",
    "Polishing the chrome...",
    "Checking the blueprints...",
    "Warming up the workshop...",
    "Getting our ducks in a row...",
  ];

  // ==================== EMPTY STATE MESSAGES ====================

  static String get noTools => _pickRandom(_noToolsMessages);
  static const _noToolsMessages = [
    "Your toolbox is emptier than a hardware store on Black Friday. Add some tools!",
    "No tools yet? Every craftsman starts somewhere. Add your first one!",
    "This toolbox is feeling lonely. Time to add some tools!",
    "Empty toolbox detected. The hardware store is calling your name!",
    "Crickets in here... Add some tools to get started!",
  ];

  static String get noToolboxes => _pickRandom(_noToolboxesMessages);
  static const _noToolboxesMessages = [
    "No toolboxes yet! Time to build your first one. No hard hat required.",
    "Empty workshop! Create a toolbox to start organizing.",
    "No toolboxes here. Every master craftsman needs to start somewhere!",
    "Your garage is empty. Let's change that with a new toolbox!",
    "Time to get organized! Create your first toolbox.",
  ];

  static String get noRequests => _pickRandom(_noRequestsMessages);
  static const _noRequestsMessages = [
    "No lending requests yet. Your tools are taking a well-deserved break.",
    "All quiet on the western front. No borrow requests today!",
    "No requests! Your tools are enjoying their staycation.",
    "Nothing to see here. Your tools are staying cozy.",
    "Request inbox: empty. Your tools are relieved.",
  ];

  static String get noSearchResults => _pickRandom(_noSearchResultsMessages);
  static const _noSearchResultsMessages = [
    "Couldn't find anyone. They must be on a coffee break.",
    "No results! Like looking for a 10mm socket - impossible!",
    "Nothing found. Maybe try different search terms?",
    "Empty results. They're hiding better than missing socks.",
    "No matches! Time to cast a wider net.",
  ];

  static String get noBuddies => _pickRandom(_noBuddiesMessages);
  static const _noBuddiesMessages = [
    "No buddies yet! Time to expand your tool network.",
    "Your buddy list is empty. Get out there and connect!",
    "Flying solo for now. Add some tool-loving friends!",
    "No connections yet. Even lone wolves need a pack sometimes!",
    "Buddy list: empty. Let's change that!",
  ];

  static String get noHistory => _pickRandom(_noHistoryMessages);
  static const _noHistoryMessages = [
    "No lending history yet. Your tools haven't been on any adventures!",
    "History is empty. Start sharing to build your legacy!",
    "Clean slate! No lending activity to show yet.",
    "Nothing in the history books. Time to make some memories!",
    "No history recorded. Your tools are homebodies... for now.",
  ];

  // ==================== CONFIRMATION MESSAGES ====================

  static String get deleteTool => _pickRandom(_deleteToolMessages);
  static const _deleteToolMessages = [
    "Are you sure? This tool won't come back like a boomerang.",
    "Delete this tool? It's not like misplacing your keys - it's permanent!",
    "Sure about this? Once it's gone, it's gone. Like that 10mm socket.",
    "Ready to say goodbye? This tool will miss you.",
    "Confirm deletion? Think carefully - tools have feelings too!",
  ];

  static String get deleteToolbox => _pickRandom(_deleteToolboxMessages);
  static const _deleteToolboxMessages = [
    "Delete this toolbox? All tools inside will go with it!",
    "Sure? This will permanently remove the toolbox and everything in it.",
    "This will clear out the entire toolbox. Are you certain?",
    "Ready to demolish? This toolbox and all its contents will be gone.",
    "Delete everything? Once confirmed, there's no going back!",
  ];

  static String get returnTool => _pickRandom(_returnToolMessages);
  static const _returnToolMessages = [
    "Ready to return? Hope it wasn't used to fix the unfixable.",
    "Returning this tool? May it arrive in the same condition it left!",
    "Confirm return? The owner will be notified.",
    "Return time! Did the tool behave itself?",
    "Sending it back? Safe travels, little tool!",
  ];

  static String get signOut => _pickRandom(_signOutMessages);
  static const _signOutMessages = [
    "Clocking out? Your tools will be here when you get back!",
    "Leaving so soon? Don't forget to put your tools away first!",
    "Signing out? The workshop will miss you.",
    "Taking a break? See you next time, tool master!",
    "Heading out? Your toolbox will keep everything safe.",
  ];

  static String get cancelRequest => _pickRandom(_cancelRequestMessages);
  static const _cancelRequestMessages = [
    "Cancel this request? The tool might be disappointed.",
    "Sure you want to cancel? No hard feelings either way!",
    "Backing out? That's okay, there are plenty of tools in the box.",
    "Cancel request? Let us know if you change your mind!",
    "Withdrawing the request? We'll pretend this never happened.",
  ];

  // ==================== WELCOME/ONBOARDING MESSAGES ====================

  static String get welcomeBack => _pickRandom(_welcomeBackMessages);
  static const _welcomeBackMessages = [
    "Welcome back, tool master!",
    "The workshop missed you! Welcome back.",
    "You're back! Your tools are exactly where you left them.",
    "Welcome home! Ready to get organized?",
    "Good to see you! Let's get to work.",
  ];

  static String get welcomeNew => _pickRandom(_welcomeNewMessages);
  static const _welcomeNewMessages = [
    "Welcome to the crew! Hard hats optional, tools mandatory.",
    "You're in! Time to build your tool empire.",
    "Welcome aboard! Let's organize those tools.",
    "New member alert! Your workshop journey begins now.",
    "You made it! Ready to become a tool organization master?",
  ];

  static String get firstToolbox => _pickRandom(_firstToolboxMessages);
  static const _firstToolboxMessages = [
    "Your first toolbox! Every craftsman starts somewhere.",
    "First toolbox created! This is where legends begin.",
    "Toolbox #1 is ready! Now let's fill it with goodies.",
    "Your journey begins! First toolbox: unlocked.",
    "Welcome to the club! Your first toolbox is ready.",
  ];

  // ==================== MISC/CELEBRATION MESSAGES ====================

  static String get greatChoice => _pickRandom(_greatChoiceMessages);
  static const _greatChoiceMessages = [
    "Great choice! You have excellent taste in tools.",
    "Nice pick! That's a fine addition.",
    "Smart move! Your tool collection thanks you.",
    "Excellent decision! The workshop approves.",
    "Good call! That's a keeper.",
  ];

  static String get actionComplete => _pickRandom(_actionCompleteMessages);
  static const _actionCompleteMessages = [
    "Done! Like a pro.",
    "Mission accomplished!",
    "That's a wrap!",
    "Finished! Time for a coffee break.",
    "All done! What's next on the project list?",
  ];
}

/// Message categories for specific contexts
class FunnyMessageCategory {
  static const success = 'success';
  static const error = 'error';
  static const loading = 'loading';
  static const empty = 'empty';
  static const confirmation = 'confirmation';
  static const welcome = 'welcome';
}
