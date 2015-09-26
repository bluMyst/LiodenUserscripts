# vim: foldmethod=marker
### UserScript options {{{1
See http://wiki.greasespot.net/Metadata_Block for more info.

// ==UserScript==
// @name         (Sandboxed) Lioden Improvements
// @description  Adds various improvements to the game Lioden. Sandboexed portion of the script.
// @namespace    ahto
// @version      0.1
// @include      http://*.lioden.com/*
// @include      http://lioden.com/*
// @require      https://greasyfork.org/scripts/10922-ahto-library/code/Ahto%20Library.js?version=75750
// @grant        GM_addStyle
// ==/UserScript==
###

# Settings {{{1
HUNT_BLINK_TIMEOUT = 500

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

newNavbarItem '/hunting.php',          'HUNTING'
newNavbarItem '/exploring.php',        'EXPLORING'
newNavbarItem '/branch.php',           'BRANCH'
newNavbarItem '/search_branches.php',  'BRANCHES'
newNavbarItem '/territory_map.php',    'TERRITORIES'

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