# vim: foldmethod=marker
### UserScript options {{{1
See http://wiki.greasespot.net/Metadata_Block for more info.

// ==UserScript==
// @name         Lioden Improvements
// @description  Adds various improvements to the game Lioden.
// @namespace    ahto
// @version      0.1
// @include      http://*.lioden.com/*
// @include      http://lioden.com/*
// @require      https://greasyfork.org/scripts/10922-ahto-library/code/Ahto%20Library.js?version=75750
// @grant        none
// ==/UserScript==
###

### Features and changes {{{1
General:
- Made the second-to-top bar a little slimmer.

Hunting:
- Automatically reloads flashes the tab when your hunt is finished.
###

# Settings {{{1
# When searching for only a certain currency.
MAX_PRICE_MAX = '9999999999'

###
# Search branches {{{1
if urlMatches new RegExp '/search_branches\\.php', 'i'
    prices      = findMatches('input[name=maxprice]',  1, 1).parent()
    pricesDecor = findMatches('input[name=maxprice2]', 1, 1).parent()

    for [parent, inputBaseName] in [[prices, 'maxprice'], [pricesDecor, 'maxprice2']]
        # Remove SB and GB text.
        # TODO: Doesn't work.
        parent.filter(-> this.nodeType == 3).remove()

        # inputBaseName is just an overly complicated way of saying that the
        # input's names are either going to start with maxprice or maxprice2.
        sb = parent.children "input[type=text][name=#{inputBaseName}]"
        gb = parent.children "input[type=text][name=#{inputBaseName}c]"

        sbLink = sb.after "<a href='javascript:void(0)'> SB</a>"
        gbLink = gb.after "<a href='javascript:void(0)'> GB</a>"

        makeHandler = (us, them) -> ->
            # TODO: Never called.
            console.log "Handler called on:", us, "them:", them
            if us.val().length
                us.val ''
            else
                us.val   MAX_PRICE_MAX
                them.val ''

        sbLink.click makeHandler sb, gb
        gbLink.click makeHandler gb, sb
###