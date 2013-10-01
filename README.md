# Tangerine-pouch

1. Use js/init.rb to generate the js files from coffee
2. Edit file.watchr as needed and run it.
3. If a coffee file does not generate via uglify.rb (see file.watchr), run it manually:

        www/js]$ coffee --bare --compile boot.coffee 2>&1

4. Run npm start to launch the mini server and view at <http://localhost:8000/index-dev.html>