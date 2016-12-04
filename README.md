
<!--#echo json="package.json" key="name" underline="=" -->
server-loads-diagram-pmb
========================
<!--/#echo -->

<!--#echo json="package.json" key="description" -->
Render my server load logfiles as color gradient bar charts.
<!--/#echo -->
([Screenshots](https://github.com/mk-pmb/server-loads-diagram-pmb-js/tree/screenshots))


Usage
-----

```bash
$ cd doc/example-01/

$ ./generate-logfiles.sh
create ex01-day-5.txt: done.
symlink 2010-08-31.txt: done.

$ ./generate-diagrams.sh
render month 2010-07 (shell command: **snip**) …
probably result file(s): 2010-07-99.diag.html
render month 2010-08 (shell command: **snip**) …
probably result file(s): 2010-08-99.diag.html

$ firefox ./2010-07-99.diag.html
```
  * [ScreenGrab!](screengrab) -> Copy -> Complete Page/Frame.
  * Paste into your favorite image editor.
  * Crop at the huge border area.
  * Your diagram should now look like [this image][img-ex01-07].


Hints
-----

  * You can [remix date ranges][img-ex01-07] from any number of months by
    remixing their data lines in the generated HTML files.
    (You may want to rename them.)




<!--#toc stop="scan" -->


  [screengrab]: http://www.s3blog.org/screengrab.html
  [img-ex01-07]: https://github.com/mk-pmb/server-loads-diagram-pmb-js/raw/screenshots/example-01.2010-07.png
  [img-ex01-mix]: https://github.com/mk-pmb/server-loads-diagram-pmb-js/raw/screenshots/example-01.remixed.png


License
-------
<!--#echo json="package.json" key=".license" -->
ISC
<!--/#echo -->
