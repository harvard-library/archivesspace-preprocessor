$(function () {
  /* Helper function for filter strings */
  /* Constructs regex for tokenized positive/negative token search */
  var construct_regex = function(search_string) {
    var pos = [], neg = [],
        re = null,
        re_quote = /[-\/\\^$*+?.()|\[\]{}]/g,
        char_len = search_string.length,
        case_sen = 'i',
        tokens = search_string.split(/\s+/),
        len = tokens.length;

    // Case insensitive unless uppercase chars in string
    while (char_len--) {
      if (search_string[char_len] !== search_string[char_len].toLowerCase()) {
        case_sen = "";
        break;
      }
    }

    while (len--) {
      if (tokens[len].match(/^\^/)) {
        if (tokens[len] === '^') { continue; }
        neg.push(tokens[len].slice(1));
      }
      else {
        pos.push(tokens[len]);
      }
    }

    pos = pos.map(function (tok) { return '(?=.*' + tok.replace(re_quote, '\\$&') +')'}).join('');
    neg = (neg.length > 0) ? '(^((?!' + neg.map(function (tok) { return tok.replace(re_quote, '\\$&')}).join('|') + ').)*$)$' : ''

    /* Val might not contain a working regex, because users input one char at  *
     * a time, or might just write bad regex. Ideally, perhaps, we'd strip any *
     * broken parts off the end of what we have, but for now we're just gonna  *
     * treat that case as "no regex"                                           */
    try { re = RegExp('^' + pos + neg, case_sen) } catch (e) { re = null };

    return re;
  };

  var filter = function (e) {
    /* Matches strings with all positive tokens present
       and no negative tokens present */
    var val       = e.target.value,
        re        = construct_regex(val),
        $table    = $('#' + $(e.target).data('table-id')),
        /* Perf note: els is DELIBERATELY not jq, loop over it *
           MUST be as fast as possible for UX reasons          */
        els       = $table.find('> tbody > tr').get(),
        current,   // Current element ptr
        len       = els.length,
        filter_on = $table.data('filter-on') || 'a',
        sub_els, sub_els_len, sstring;

    if (!val || !re) {
      while (len--) {
        els[len].className = '';
      }
    }
    else {
      while (len--) {
        current = els[len];
        sub_els = current.querySelectorAll(filter_on);
        sub_els_len = sub_els.length;
        sstring = "";
        while (sub_els_len--) {
          sstring += sub_els[sub_els_len].textContent + "\v";
        }
        if (!sstring.match(re)) {
          current.classList.add("hidden");
        }
        else { current.classList.remove('hidden') }
      }
    }
    $table.removeClass('busy');
  };

  $('table.table-filtered').each(function (i, table) {
    var timeout = null,
        $input;

    $(table).before('<div>Filter: <input type="text" data-table-id="'+ table.id + '" /></div>');
    $input = $(table).prev().children('input');

    $input.on('input propertychange', function (e) {
      if (timeout) {clearTimeout(timeout)};
      if (table.className.indexOf(' busy') === -1) {
        table.className += ' busy';
      }
      timeout = setTimeout(filter, 300, e);
    });
  });
});
