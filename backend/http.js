function http(r) {
  var s = "";
  s += "<!DOCTYPE html>\n";
  s += "<html>\n";
  s += "<head>\n";
  s += "<title>Backend</title>\n";
  s += "</head>\n";
  s += "<body>\n";
  s += process.env.HOSTNAME;
  s += "\n";
  s += "</body>\n";
  s += "</html>\n";
  r.return(200, s);
}
