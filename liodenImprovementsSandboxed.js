// Generated by CoffeeScript 1.9.3

/* UserScript options {{{1
See http://wiki.greasespot.net/Metadata_Block for more info.

// ==UserScript==
// @name         (Sandboxed) Lioden Improvements
// @description  Adds various improvements to the game Lioden. Sandboxed portion of the script.
// @namespace    ahto
// @version      3.1
// @include      http://*.lioden.com/*
// @include      http://lioden.com/*
// @require      https://greasyfork.org/scripts/10922-ahto-library/code/Ahto%20Library.js?version=75750
// @grant        GM_addStyle
// ==/UserScript==
 */

/* Features and changes {{{1
General:
- Made the second-to-top bar a little slimmer.
- Added significantly more quickly-accessible links, and made the site overall faster and easier to use.

Hunting:
- Automatically reloads and flashes the tab when your hunt is finished.

Den:
- Can automatically play with all lionesses.
 */
var HUMAN_TIMEOUT_MAX, HUMAN_TIMEOUT_MIN, HUNT_BLINK_TIMEOUT, LionPlayer, blinker, exploringDropdownLinks, getResults, id, linkText, lionPlayer, logout, minutesLeft, moveToToplinks, navbar, newDropdown, newNavbarItem, setHumanTimeout, toplinks, wait,
  slice = [].slice;

HUNT_BLINK_TIMEOUT = 500;

HUMAN_TIMEOUT_MIN = 200;

HUMAN_TIMEOUT_MAX = 1000;

GM_addStyle("/* Make the top bar slimmer. */\n.main { margin-top: 10px; }\n\n/*\n * Remove the Lioden logo since I can't figure out how to shrink it,\n * and it's taking up too much space on the page. It overlaps the veeery\n * top bar, with the link to the wiki and forums and stuff.\n *\n * TODO: Figure out how to just shrink it instead of flat-out removing it.\n */\n.navbar-brand > img { display: none; }");

setHumanTimeout = function(f) {
  return setTimeout_(randInt(HUMAN_TIMEOUT_MIN, HUMAN_TIMEOUT_MAX), f);
};

navbar = $('.nav.visible-lg');

toplinks = $('.toplinks');

logout = toplinks.find('a[href="/logout.php"]');

moveToToplinks = function(page, linkText) {
  var link;
  link = navbar.find("a[href='" + page + "']").parent();
  link.remove();
  link.find('a').text(linkText);
  return logout.before(link);
};

moveToToplinks('/oasis.php', 'Oasis');

moveToToplinks('/boards.php', 'Chatter');

moveToToplinks('/news.php', 'News');

moveToToplinks('/event.php', 'Event');

moveToToplinks('/faq.php', 'FAQ');

newNavbarItem = function(page, linkText) {
  return navbar.append("<li><a href='" + page + "'>" + linkText + "</a></li>");
};

newNavbarItem('/hunting.php', 'Hunting');

newNavbarItem('/exploring.php', 'Exploring');

newNavbarItem('/branch.php', 'Branch');

newNavbarItem('/search_branches.php', 'Branches');

newNavbarItem('/territory_map.php', 'Territories');

GM_addStyle("ul li ul.dropdown {\n    min-width: 125px;\n    background: #9FAEB5;\n    padding-left: 10px;\n    padding-bottom: 5px;\n\n    display: none;\n    position: absolute;\n    z-index: 999;\n    left: 0;\n}\n\nul li ul.dropdown li {\n    display: block;\n}\n\n/* Display the dropdown on hover. */\nul li:hover ul.dropdown {\n    display: block;\n}");

newDropdown = function(menuItem, dropdownLinks) {
  var dropdown, j, len, link, linkText, ref, results;
  console.log('Appending dropdown to', menuItem);
  dropdown = $("<ul class=dropdown></ul>");
  menuItem.after(dropdown);
  results = [];
  for (j = 0, len = dropdownLinks.length; j < len; j++) {
    ref = dropdownLinks[j], link = ref[0], linkText = ref[1];
    results.push(dropdown.append("<li><a href='" + link + "'>" + linkText + "</a></li>"));
  }
  return results;
};

exploringDropdownLinks = [[1, '(1) Temperate S'], [2, '(2-5) Shrubland'], [3, '(6-10) Trpcl Forest'], [4, '(11-15) Dry S'], [5, '(16-20) Rocky Hills'], [6, '(26-30) Marshl.'], [7, '(31+) Waterhole']];

exploringDropdownLinks = (function() {
  var j, len, ref, results;
  results = [];
  for (j = 0, len = exploringDropdownLinks.length; j < len; j++) {
    ref = exploringDropdownLinks[j], id = ref[0], linkText = ref[1];
    results.push(["/explorearea.php?id=" + id, linkText]);
  }
  return results;
})();

newDropdown(navbar.find('a[href="/exploring.php"]'), exploringDropdownLinks);

newDropdown(navbar.find('a[href="/hoard.php"]'), [['/hoard.php?type=Food', 'Food'], ['/hoard.php?type=Amusement', 'Amusement'], ['/hoard.php?type=Decoration', 'Decoration'], ['/hoard.php?type=Background', 'Background'], ['/hoard.php?type=Other', 'Other'], ['/hoard.php?type=Buried', 'Buried'], ['/hoard.php?type=Bundles', 'Bundles'], ['/hoard-organisation.php', 'Organisation']]);

if (urlMatches(new RegExp('/hunting\\.php', 'i'))) {
  minutesLeft = findMatches('div.center > p', 0, 1).text();
  getResults = findMatches('input[name=get_results', 0, 1);
  if (minutesLeft.length) {
    minutesLeft = (/([0-9]+) minutes/.exec(minutesLeft))[1];
    minutesLeft = safeParseInt(minutesLeft);
    console.log(minutesLeft, 'minutes remaining.');
    wait = (minutesLeft + 1) * 60 * 1000;
    console.log("Reloading in " + wait + " ms...");
    setTimeout_(wait, function() {
      return location.reload();
    });
  } else if (getResults.length) {
    blinker = setInterval((function() {
      if (document.title === 'Ready!') {
        return document.title = '!!!!!!!!!!!!!!!!';
      } else {
        return document.title = 'Ready!';
      }
    }), HUNT_BLINK_TIMEOUT);
    window.onfocus = function() {
      clearInterval(blinker);
      return document.title = 'Ready!';
    };
  }
}

if (urlMatches(new RegExp('/territory\\.php', 'i'))) {
  LionPlayer = (function() {
    LionPlayer.prototype.LION_URL_TO_ID = new RegExp('/lion\\.php.*[?&]id=([0-9]+)');

    function LionPlayer(autoPlayLink) {
      this.autoPlayLink = autoPlayLink;
      this.lionIDs = [];
      this.safeToClick = true;
      this.autoPlayLink.click((function(_this) {
        return function() {
          return _this.clickListener();
        };
      })(this));
    }

    LionPlayer.prototype.clickListener = function() {
      if (this.safeToClick) {
        this.safeToClick = false;
        this.updateLionIDs();
        return this.play();
      }
    };

    LionPlayer.prototype.getLionID = function(lionLink) {
      var url;
      url = lionLink.attr('href');
      id = this.LION_URL_TO_ID.exec(url)[1];
      return id;
    };

    LionPlayer.prototype.updateLionIDs = function() {
      var i, lionLinks;
      lionLinks = $('a[href^="/lion.php?id="]');
      return this.lionIDs = (function() {
        var j, len, results;
        results = [];
        for (j = 0, len = lionLinks.length; j < len; j++) {
          i = lionLinks[j];
          results.push(this.getLionID($(i)));
        }
        return results;
      }).call(this);
    };

    LionPlayer.prototype.play = function(arg, playedWith, length) {
      var id, ids, recurse, ref;
      ref = arg != null ? arg : this.lionIDs, id = ref[0], ids = 2 <= ref.length ? slice.call(ref, 1) : [];
      if (playedWith == null) {
        playedWith = 0;
      }
      if (length == null) {
        length = ids.length + 1;
      }
      this.autoPlayLink.text("Loading... (" + playedWith + "/" + length + ")");
      recurse = (function(_this) {
        return function() {
          playedWith++;
          if (ids.length) {
            return setHumanTimeout(function() {
              return _this.play(ids, playedWith, length);
            });
          } else {
            return _this.autoPlayLink.text("Done! (" + playedWith + "/" + length + ")");
          }
        };
      })(this);
      return $.get("/lion.php?id=" + id).done((function(_this) {
        return function(response) {
          if ($(response).find('input[value=Interact]').length) {
            return $.post("/lion.php?id=" + id, {
              action: 'play',
              interact: 'Interact'
            }).done(function(response) {
              console.log("Played with " + id + " successfully.");
              return recurse();
            });
          } else {
            console.log("Couldn't play with " + id + "; probably on cooldown.");
            return recurse();
          }
        };
      })(this));
    };

    return LionPlayer;

  })();
  $('a[href^="/lionoverview.php"]').parent().after("<th style=\"text-align:center!important;\"><a href=\"javascript:void(0)\" id=autoPlay>Play with all.</a></th>");
  lionPlayer = new LionPlayer($('#autoPlay'));
}
