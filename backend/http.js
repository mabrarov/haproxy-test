// noinspection ES6ConvertVarToLetConst

function http(r) {
  var s = "";
  s += "<!DOCTYPE html>\n";
  s += "<html lang=\"en-US\">\n";
  // noinspection HtmlRequiredTitleElement
  s += "<head>\n";
  s += "<title>Backend</title>\n";
  s += "</head>\n";
  s += "<body>\n";
  // noinspection JSUnresolvedReference
  s += process.env.HOSTNAME;
  s += "\n";
  s += "</body>\n";
  s += "</html>\n";
  r.return(200, s);
}

// noinspection JSUnusedGlobalSymbols
export default {http};
