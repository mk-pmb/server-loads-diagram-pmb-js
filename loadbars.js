/*jslint indent: 2, maxlen: 80, continue: false, unparam: false, browser: true */
/* -*- tab-width: 2 -*- */
(function () {
  'use strict';

  function byId(id) { return document.getElementById('loadbars-' + id); }

  (function fixCssPath() {
    var css = byId('css'), url = (byId('js') || false).src;
    if (!css) { return; }
    if (!url) { return; }
    css.href = String(url).replace(/\.js$/, '.css');
  }());

  function range(n, s, f) {
    s = (s || 1);
    f = (f || Number);
    var rg = [], i;
    for (i = 0; i < n; i += s) { rg[rg.length] = f(i); }
    return rg;
  }

  function arr2html(arr) {
    if (typeof arr !== 'object') { return String(arr); }
    var open = arr[0], close = '';
    if (open.slice(-1) !== '>') {
      close = '</' + open.split(/\s/)[0] + '>';
      open += '>';
    }
    return ('<' + open + arr.slice(1).map(arr2html).join('') + close);
  }

  function tmpl(code, data) {
    return code.replace(/\{(\w+)\}/g, function (m, k) {
      k = data[k];
      return String(k === undefined ? m : k);
    });
  }
  tmpl.hourOuter = 'abbr class="hour" data-h="{h}" ' +
    'title="{hh}:00&ndash;{hh}:59, {ddd} {date}"';
  tmpl.hour = function (h) {
    var data = { h: h, hh: String(100 + h).substr(1, 2) };
    return [tmpl(tmpl.hourOuter, data), ['var', data.hh]];
  };
  tmpl.day = arr2html(['div class="row day {imgHas}-img-data"{allDataAttr}',
    ['div class="subrow hours"',
      ['div class="date date-mmm"', ['abbr title="{mmm} {yyyy}"', '{mmm}'] ],
      ].concat(range(24, 1, tmpl.hour)),
    ['div class="subrow diag"',
      ['div class="img-bg"', ['img src="{imgSrc}">'] ],
      ['div class="date date-dd"', ['abbr title="{date}"', '{dd}'] ] ],
    ]);

  function readProps(destObj, propDescrs, values) {
    if (!values) { return; }
    var slot = 0;
    propDescrs.replace(/((?!\w)\S|)\w+/g, function (f, t) {
      if (t) { f = f.slice(1); }
      var v = values[slot];
      slot += 1;
      if (t === '#') { v = parseInt(v, 10); }
      if (t !== '!') {
        destObj.allDataAttr = (destObj.allDataAttr || ''
          ) + ' data-' + f + '="' + String(v) + '"';
      }
      destObj[f] = v;
    });
    return destObj;
  }


  function tla(list, slot) { return list.substr(slot * 3, 3); }
  // three-letter abbreviations
  tla.weekdayNames = 'MonTueWedThuFriSatSun';
  tla.monthNames = 'JanFebMarAprMayJunJulAugSepOctNovDec';


  (function () {
    function render(dayta) {
      dayta = readProps({},
        'date #weekdayIdx imgFmt !imgData',
        dayta.split(/:/));
      readProps(dayta, 'yyyy mm dd', dayta.date.split(/\-/));
      readProps(dayta, '#y #m #d', dayta.date.split(/\-/));
      readProps(dayta, 'mmm ddd', [
        tla(tla.monthNames, dayta.m - 1),
        tla(tla.weekdayNames, dayta.weekdayIdx),
      ]);
      dayta.imgHas = (dayta.imgData ? 'has' : 'no');
      dayta.imgSrc = 'data:image/' + (dayta.imgData ? (dayta.imgFmt +
        ';base64,' + dayta.imgData) : 'none,');
      return tmpl(tmpl.day, dayta);
    }

    var days = byId('days');
    days.innerHTML = days.innerHTML.replace(/\S+/g, render);
  }());































}());
