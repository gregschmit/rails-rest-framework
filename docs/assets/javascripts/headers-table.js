/*
 * This JS components renders headers into a floating table on the right.
 */
$(function() {
  let table = '<ul>';
  let hlevel = 2;
  let hprevlevel = 2;
  $('h2, h3, h4').each(function(index, header) {
    let h = $(header);
    hlevel = parseInt(h.prop('tagName')[1]);
    console.log(`index: ${index} -- header: ${header}`);
    if (hlevel > hprevlevel) {
      table += '<ul>';
    } else if (hlevel < hprevlevel) {
      Array(hprevlevel - hlevel).fill(0).forEach(function() {
        table += '</ul>';
      });
    }
    table += `<li><a href="${h.find('a').attr('href')}">${header.childNodes[0].nodeValue.trim()}</a></li>`;
    hprevlevel = hlevel;
  });
  if (hlevel > hprevlevel) {
    table += '</ul>';
  }
  table += '</ul>';
  if (table != '<ul></ul>') { $('#headersTable').html(table); }
});
