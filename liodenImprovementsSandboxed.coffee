# vim: foldmethod=marker
### UserScript options {{{1
See http://wiki.greasespot.net/Metadata_Block for more info.

// ==UserScript==
// @name         (Sandboxed) Lioden Improvements
// @description  Adds various improvements to the game Lioden. Sandboxed portion of the script.
// @namespace    ahto
// @version      9.0
// @include      http://*.lioden.com/*
// @include      http://lioden.com/*
// @require      https://greasyfork.org/scripts/10922-ahto-library/code/Ahto%20Library.js?version=75750
// @grant        GM_addStyle
// @grant        GM_setValue
// @grant        GM_getValue
// ==/UserScript==
###

### Features and changes {{{1
General:
- Made the second-to-top bar a little slimmer.
- Added significantly more quickly-accessible links, and made the site overall faster and easier to use.

Hunting:
- Automatically reloads and flashes the tab when your hunt is finished.

Den:
- Can automatically play with all lionesses.
- Table order slightly tweaked.

Lion view:
- Can see lion name and picture right next to the chase buttons.
###

# Settings {{{1
HUNT_BLINK_TIMEOUT = 500

# Certain actions are done with a random time delay to avoid looking like a bot.
HUMAN_TIMEOUT_MIN =  200
HUMAN_TIMEOUT_MAX = 1000

# CSS {{{1
GM_addStyle """
    /* Make the top bar slimmer. */
    .main { margin-top: 10px; }

    /*
     * Remove the Lioden logo since I can't figure out how to shrink it,
     * and it's taking up too much space on the page. It overlaps the veeery
     * top bar, with the link to the wiki and forums and stuff.
     *
     * TODO: Figure out how to just shrink it instead of flat-out removing it.
     */
    .navbar-brand > img { display: none; }
"""

# Functions and classes {{{1
setHumanTimeout = (f) ->
    setTimeout_(randInt(HUMAN_TIMEOUT_MIN, HUMAN_TIMEOUT_MAX), f)

# Energy {{{1
energyBar = $('div.progress:first')

energyBarText = energyBar.find('div:last')
energyBarText.css 'z-index', '2'

energyBarBar  = energyBar.find('div:first')
energyBarBar.css 'z-index', '1'

# This is the worst variable name I've ever written in my life.
energyBarChangeBar = $ """
    <div class="progress-bar progress-bar-warning" role="progressbar" aria-valuenow="60" aria-valuemin="0" aria-valuemax="100" style="width: 0%; background: #afc7c7;" />
"""

energyBar.append energyBarChangeBar

energyUpdate = ->
    try
        energyPercent = /Energy: ([0-9]+)%/.exec( energyBarText.text() )[1]
    catch e
        if e instanceof TypeError
            console.log "Unable to read energy percent from #{energyBar}"
            console.log 'Disabling energyUpdate'
            return
        else
            throw e

    energyPercent = parseInt energyPercent

    # Updates every 15 minutes.
    now              = new Date(Date.now())
    minutes          = now.getMinutes() + now.getSeconds()/60 + now.getMilliseconds()/(1000*60)
    energyUpdateTime = new Date(now)

    console.log "now: #{now}"
    console.log "minutes: #{minutes}"

    energyUpdateTime.setSeconds      0
    energyUpdateTime.setMilliseconds 0

    if 0 <= minutes < 15
        console.log "0 <= minutes < 15"
        energyUpdateTime.setMinutes 15
    else if 15 <= minutes < 30
        console.log "15 <= minutes < 30"
        energyUpdateTime.setMinutes 30
    else if 30 <= minutes < 45
        console.log "30 <= minutes < 45"
        energyUpdateTime.setMinutes 45
    else if 45 <= minutes
        console.log "45 <= minutes"
        energyUpdateTime.setMinutes  0
        energyUpdateTime.setHours (now.getHours() + 1)

    console.log "Target time for energy refresh is:", energyUpdateTime
    console.log "That means we're waiting for #{(energyUpdateTime - now)/(1000*60)} minutes."

    setTimeout_ (energyUpdateTime - now), ->
        if energyPercent+10 <= 100
            energyPercent += 10
        else if energyPercent < 100
            console.log "Setting energyPercent to 100, from #{energyPercent}"
            energyPercent = 100

        energyBarText.text "Energy: #{energyPercent}%"
        energyBarChangeBar.css "width", "#{energyPercent}%"

        if energyPercent <= 100
            energyUpdate()
        else
            console.log 'energyPercent is > 100 so stopping energy update loop.'

energyUpdate()

# Navbar {{{1
navbar   = $('.nav.visible-lg')
toplinks = $('.toplinks')
logout   = toplinks.find('a[href="/logout.php"]')

# Move stuff to toplinks. {{{2
moveToToplinks = (page, linkText) ->
    link = navbar.find("a[href='#{page}']").parent()
    link.remove()
    link.find('a').text linkText
    logout.before link

moveToToplinks '/oasis.php',  'Oasis'
moveToToplinks '/boards.php', 'Chatter'
moveToToplinks '/news.php',   'News'
moveToToplinks '/event.php',  'Event'
moveToToplinks '/faq.php',    'FAQ'

# Add new navbar items and dropdowns. {{{2
# Dropdown CSS {{{3
GM_addStyle """
    ul li ul.dropdown {
        min-width: 125px;
        background: #{$('.navbar.navbar-default').css 'background'};
        padding-left: 10px;
        padding-bottom: 5px;

        display: none;
        position: absolute;
        z-index: 999;
        left: 0;
    }

    ul li ul.dropdown li {
        display: block;
    }

    /* Display the dropdown on hover. */
    ul li:hover ul.dropdown {
        display: block;
    }
"""

newDropdown = (menuItem, dropdownLinks) -> # {{{3
    if typeof menuItem == 'string'
        menuItem = navbar.find("a[href='#{menuItem}']").parent()

    dropdown = $ "<ul class=dropdown></ul>"
    #menuItem.after dropdown
    menuItem.append dropdown

    for [link, linkText] in dropdownLinks
        dropdown.append """
            <li><a href='#{link}'>#{linkText}</a></li>
        """

newNavbarItem = (page, linkText, dropdownLinks) -> # {{{3
    # TODO: Integrate dropdowns into this function.
    navbarItem =  $ "<li><a href='#{page}'>#{linkText}</a></li>"
    navbar.append navbarItem

    if dropdownLinks?
        newDropdown navbarItem, dropdownLinks

# Actually make the dropdowns and links. {{{3
if (kingID = GM_getValue 'kingID')?
    newDropdown '/territory.php', [
        ["/lion.php?mid=#{kingID}",        'King Overview'],
        ["/lionoverview.php?id=#{kingID}", 'Lion Overview'],
        ['/nesting.php',                   'Nesting'],
    ]

newDropdown '/hoard.php', [
    ['/hoard.php?type=Food',        'Food'],
    ['/hoard.php?type=Amusement',   'Amusement'],
    ['/hoard.php?type=Decoration',  'Decoration'],
    ['/hoard.php?type=Background',  'Background'],
    ['/hoard.php?type=Other',       'Other'],
    ['/hoard.php?type=Buried',      'Buried'],
    ['/hoard.php?type=Bundles',     'Bundles'],
    ['/hoard-organisation.php',     'Organisation'],
]

newDropdown '/explore.php', [
    ['/search.php', 'Search'],
    ['/trading_center.php', 'Trading Center'],
    ['/questing.php', 'Quests'],
    ['/monkeybusiness.php', 'Monkey Shop'],
    ['/sharpen_claws.php', 'Sharpen Claws'],
    ['/games.php', 'Games'],
    ['/patrol.php', 'Patrol'],
    ['/leaders.php', 'Leaderboards'],
    ['/special.php', 'Special Lioness'],
]

newNavbarItem '/hunting.php', 'Hunting'

newNavbarItem '/exploring.php', 'Exploring', [
    ['/explorearea.php?id=1',  '(1) Temperate S'],
    ['/explorearea.php?id=2',  '(2-5) Shrubland'],
    ['/explorearea.php?id=3',  '(6-10) Trpcl Forest'],
    ['/explorearea.php?id=4',  '(11-15) Dry S'],
    ['/explorearea.php?id=5',  '(16-20) Rocky Hills'],
    ['/explorearea.php?id=6',  '(26-30) Marshl.'],
    ['/explorearea.php?id=7',  '(31+) Waterhole'],
]

newNavbarItem '/branch.php', 'Branches', [
    ['/branch.php',           'My Branch'],
    ['/search_branches.php',  'Search'],
]

newNavbarItem '/territory_map.php', 'Territories'

newNavbarItem '/scryingstone.php', 'Scrying Stone', [
    ['/wardrobe.php', 'Wardrobe'],
    ['/falcons-eye.php', "Falcon's Eye"],
]

# Hunting {{{1
if urlMatches new RegExp '/hunting\\.php', 'i'
    minutesLeft = findMatches('div.center > p', 0, 1).text()
    getResults  = findMatches 'input[name=get_results', 0, 1

    if minutesLeft.length
        minutesLeft = (/([0-9]+) minutes/.exec minutesLeft)[1]
        minutesLeft = safeParseInt minutesLeft
        console.log minutesLeft, 'minutes remaining.'

        wait = (minutesLeft + 1) * 60 * 1000
        console.log "Reloading in #{wait} ms..."
        setTimeout_ wait, -> location.reload()
    else if getResults.length
        blinker = setInterval((->
            if document.title == 'Ready!'
                document.title = '!!!!!!!!!!!!!!!!'
            else
                document.title = 'Ready!'
        ), HUNT_BLINK_TIMEOUT)

        window.onfocus = ->
            clearInterval blinker
            document.title = 'Ready!'

# Lion view {{{1
if urlMatches new RegExp '/lion\\.php', 'i'
    namePlateClone   = findMatches('h1', 1, 1).clone()
    lionImageClone   = findMatches('center > div[style="width: 95%; overflow: auto;"]', 1, 1).clone()
    chaseButtonTable = findMatches('div.col-xs-12.col-md-4', 1, 1)
    chaseButtonTable.before namePlateClone, lionImageClone, '<br>'

# Den {{{1
if urlMatches new RegExp '/territory\\.php', 'i'
    # Own den {{{2
    # Check if we're looking at another user's den. In that case there'll be
    # an 'id' parameter.
    if not (urlMatches /[?&]id=/i)
        # Detect king ID {{{3
        storedKingID     = GM_getValue 'kingID'
        console.log "storedKingID: #{storedKingID}"
        kingPortraitHref = $('#lion_image').parent().attr('href')
        console.log "kingPortraitHref: #{kingPortraitHref}"
        currentKingID    = /\/lion\.php\?mid=([0-9]+)/.exec(kingPortraitHref)[1]

        if currentKingID != storedKingID
            console.log "Stored king ID '#{storedKingID}' didn't match detected kingID '#{currentKingID}' at URL '#{document.location.href}'"
            GM_setValue 'kingID', currentKingID

        # Rearrange interface {{{3
        GM_addStyle """
            /* Make the tables a little closer together. Website default 20px. */
            .table { margin-bottom: 10px; }
        """

        tables = $ 'div.container.main center table.table'
        [aboutKing, aboutPlayer, pride, etc...] = ($ i for i in tables)
        aboutKing.after pride

        # Auto-play {{{3
        class LionPlayer
            LION_URL_TO_ID: new RegExp '/lion\\.php.*[?&]id=([0-9]+)'

            constructor: (@autoPlayLink) ->
                @lionIDs = []

                # If @autoPlayLink can be safely clicked.
                @safeToClick = true

                @autoPlayLink.click =>
                    @clickListener()

            clickListener: () ->
                if @safeToClick
                    @safeToClick = false
                    @updateLionIDs()
                    @play()

            getLionID: (lionLink) ->
                url = lionLink.attr 'href'
                id = @LION_URL_TO_ID.exec(url)[1]
                return id

            updateLionIDs: () ->
                lionLinks = $ 'a[href^="/lion.php?id="]'
                @lionIDs  = (@getLionID $ i for i in lionLinks)

            play: ([id, ids...]=@lionIDs, playedWith=0, length=ids.length+1) ->
                @autoPlayLink.text "Loading... (#{playedWith}/#{length})"

                recurse = =>
                    playedWith++
                    if ids.length
                        setHumanTimeout =>
                            @play ids, playedWith, length
                    else
                        @autoPlayLink.text "Done! (#{playedWith}/#{length})"

                $.get("/lion.php?id=#{id}").done (response) =>
                    if $(response).find('input[value=Interact]').length
                        $.post("/lion.php?id=#{id}", {action:'play', interact:'Interact'})
                        .done (response) =>
                            console.log "Played with #{id} successfully."
                            recurse()
                    else
                        console.log "Couldn't play with #{id}; probably on cooldown."
                        recurse()

            $('th a[href^="/lionoverview.php"]').parent().after """
                <th style="text-align:center!important;"><a href="javascript:void(0)" id=autoPlay>Play with all.</a></th>
            """

            lionPlayer = new LionPlayer $ '#autoPlay'

    # Make the [X]'s Den text a little more compact. {{{2
    findMatches('h1 + br', 1, 1).remove()

# Branch {{{1
if urlMatches /\/branch\.php/i
    items = $ 'div.item'

    for item in ($ i for i in items.find 'b') when /[SG]B:/.exec item.text()
        item.wrap """
            <a href="javascript:void(0)"></a>
        """

        item.parent().click (event) ->
            console.log 'Got click event:', event
            a          = $ event.currentTarget
            targetItem = a.parents 'div.item'
            console.log 'targetItem:', targetItem
            itemName   = targetItem.find('div.item-header').text()
            console.log 'itemName:', itemName

            for i in ($ i for i in items) when i.find('div.item-header').text() == itemName
                i.find('input[name="price[]"]' ).val targetItem.find('input[name="price[]"]' ).val()
                i.find('input[name="cprice[]"]').val targetItem.find('input[name="cprice[]"]').val()

# Lioness claiming {{{1
if urlMatches /\/claimlioness\.php/i
    # TODO: Make the HTML look prettier.
    # TODO: Detect special colors.
    header = $(i for i in $ 'h1' when /Claiming a Lioness/.exec $(i).text())

    layers = header.siblings('center').find '
        div > img[src^="http://static.lioden.com/images/dynamic/lioness/"]
    '

    lionessFrame = layers.eq(0).parent().parent()
    textInsertArea = $ "<div id=lionessInfo></div>"

    lionessFrame
        .find 'form[method=post] input[name=manlyroar]'
        .parent()
        .prepend textInsertArea

    LAYER_INFO = new RegExp "^http://static\\.lioden\\.com/images/dynamic/lioness//?(.*).png$", 'i'

    for layer in ($ i for i in layers)
        info = LAYER_INFO.exec(layer.attr 'src')[1]
        if info == 'lineart' then continue

        if info.indexOf('markings') >= 0
            opacity = parseFloat(layer.css 'opacity')
            opacity = Math.round(opacity * 100)
            opacity = opacity.toString() + '%'
            info += " (#{opacity})"

        textInsertArea.append """
            <div>#{info}</div>
        """

    textInsertArea.append '<br>'
