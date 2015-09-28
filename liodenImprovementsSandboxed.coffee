# vim: foldmethod=marker
### UserScript options {{{1
See http://wiki.greasespot.net/Metadata_Block for more info.

// ==UserScript==
// @name         (Sandboxed) Lioden Improvements
// @description  Adds various improvements to the game Lioden. Sandboxed portion of the script.
// @namespace    ahto
// @version      3.0
// @include      http://*.lioden.com/*
// @include      http://lioden.com/*
// @require      https://greasyfork.org/scripts/10922-ahto-library/code/Ahto%20Library.js?version=75750
// @grant        GM_addStyle
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

# Create new navbar items. {{{2
newNavbarItem = (page, linkText) ->
    navbar.append "<li><a href='#{page}'>#{linkText}</a></li>"

newNavbarItem '/hunting.php',          'Hunting'
newNavbarItem '/exploring.php',        'Exploring'
newNavbarItem '/branch.php',           'Branch'
newNavbarItem '/search_branches.php',  'Branches'
newNavbarItem '/territory_map.php',    'Territories'

# Navbar dropdowns. {{{3
# TODO: Background color that adapts to CSS (night vs day and user CSS).
GM_addStyle """
    ul li ul.dropdown {
        min-width: 125px;
        background: #9FAEB5;
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

newDropdown = (menuItem, dropdownLinks) ->
    console.log 'Appending dropdown to', menuItem
    dropdown = $ "<ul class=dropdown></ul>"
    menuItem.after dropdown

    for [link, linkText] in dropdownLinks
        dropdown.append """
            <li><a href='#{link}'>#{linkText}</a></li>
        """

# Exploring dropdown. {{{4
exploringDropdownLinks = [
    [1, '(1) Temperate S'],
    [2, '(2-5) Shrubland'],
    [3, '(6-10) Trpcl Forest'],
    [4, '(11-15) Dry S'],
    [5, '(16-20) Rocky Hills'],
    [6, '(26-30) Marshl.'],
    [7, '(31+) Waterhole'],
]

exploringDropdownLinks = for [id, linkText] in exploringDropdownLinks
    ["/explorearea.php?id=#{id}", linkText]

newDropdown navbar.find('a[href="/exploring.php"]'), exploringDropdownLinks

# Hoard dropdown. {{{4
newDropdown navbar.find('a[href="/hoard.php"]'), [
    ['/hoard.php?type=Food',        'Food'],
    ['/hoard.php?type=Amusement',   'Amusement'],
    ['/hoard.php?type=Decoration',  'Decoration'],
    ['/hoard.php?type=Background',  'Background'],
    ['/hoard.php?type=Other',       'Other'],
    ['/hoard.php?type=Buried',      'Buried'],
    ['/hoard.php?type=Bundles',     'Bundles'],
    ['/hoad-organisation.php',      'Organisation'],
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

# Den {{{1
if urlMatches new RegExp '/territory\\.php', 'i'
    # Auto-play {{{2
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

    $('a[href^="/lionoverview.php"]').parent().after """
        <th style="text-align:center!important;"><a href="javascript:void(0)" id=autoPlay>Play with all.</a></th>
    """

    lionPlayer = new LionPlayer $ '#autoPlay'
