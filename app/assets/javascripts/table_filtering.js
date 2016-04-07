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
    var val      = e.target.value,
        re       = construct_regex(val),
        $table    = $('#' + $(e.target).data('table-id')),
        els      = $table.find('> tbody > tr').get(),
        len      = els.length;

    if (!val || !re) {
      while (len--) {
        els[len].className = '';
      }
    }
    else {
      while (len--) {
        if (els[len].querySelector('a') &&
            !els[len].querySelector('a').textContent.match(re)) {
          els[len].className = "hidden";
        }
        else { els[len].className = '' }
      }
    }
    $table.removeClass('busy');
  };

  $('table.table-filtered').each(function (i, table) {
    var timeout = null,
        input;

    $(table).before('<div>Filter: <input type="text" data-table-id="'+ table.id + '" /></div>');
    input = $(table).prev().children('input').get(0);

    input.addEventListener('keyup', function (e) {
      clearTimeout(timeout);
      table.className += ' busy';
      setTimeout(filter, 200, e);
    });
  });
});
