konira.vim
----------
A simple way of running your tests cases with konira from
within VIM.

Usage
-----

This plugin provides a single command::

    Konira

All arguments are able to be tab-completed.

For running tests the plugin provides 3 arguments with an optional one. 
These arguments are::

    describe
    it
    file


As you may expect, those will focus on the tests for the current describe, it
or the whole file.

If you are in a describe and want to run all the tests for that describe, you would
call this plugin like::

    :Konira describe

Whenever a command is triggered a small message displays informing you that
the plugin is running a certain action. In the above call, you would see 
something like this::

    Running tests for describe TestMydescribe

If you would like to see the complete konira output you can add an optional "verbose"
flag to any of the commands for Konira. For the previous command, it would
look like::

    :Konira describe verbose

This would open a split scratch buffer that you can fully interact with. You
can close this buffer with ':wq' or you can hit 'q' at any moment in that buffer
to close it.

When tests are successful a green bar appears. If you have any number of fails
you get a red bar with a line-by-line list of line numbers and errors.

I strongly encourage a mapping for the above actions. For example, if you
wanted leader (the leader key is '\' by default) mappings you would 
probably do them like this::

    " Konira
    nmap <silent><Leader>f <Esc>:Konira file<CR>
    nmap <silent><Leader>c <Esc>:Konira describe<CR>
    nmap <silent><Leader>m <Esc>:Konira it<CR>


This plugin also provides a way to jump to the actual error. Since errors can
be living in a file other than your test (e.g. a syntax error in your source
that triggers an assertion errro in the current file) you can also jump to that
file. The list of jumping-to-error arguments are::

    first
    last
    next 
    previous
    end


Konira **DOES NOT JUMP AUTOMATICALLY** to errors. You have to call the action. When
you call a jump, a split buffer is opened with a file (if it is not the same as
the one you are currently editing) and places you in the same line number were
the error was reported.

If an error starts in the current file but ends on a different one, you can
call that ``end of error`` by calling ``:Konira end``.

Finally, you can also display in a split scratch buffer either the last list
of failed tests (with line numbers, errors and paths) or the last ``konira``
session (similar to what you would see in a terminal). The arguments that 
you would need to provide for such actions are::

    session
    fails

``session`` is the buffer with a similar output to the terminal (but with
syntax highlighting) and ``fails`` has the list of last fails with the
exceptions.

If you are looking for the actual error, we have stripped it from the normal
reporting but you can call it at any time with::

    :Konira error


The reason behind this is that as soon as you hit any key, the quick display
goes away. With a split buffer you are in control and you can quit that window
when you decide -  while you work on fixing errors.

The commands that open the last session and the last fails are toggable: they
will close the scratch buffer if it is open or will open it if its closed.


PDB
---
If you have ever needed to get into a `pdb` session and debug your code, you 
already know that it is a horrible experience to be jumping between Vim and
the terminal. **konira.vim** now includes a way of dropping to a pdb session.

**konira no capture**

If you are placing `import pdb; pdb.set_trace()` somewhere in your code and 
you want to drop to pdb when that code gets executed, then you need to pass
in the no-capture flag::

    :Konira describe -s

The above command shows `describe` but you can use this with all the objects
supported (`describe`, `it` and `file`).


License
-------

MIT
Copyright (c) 2011 Alfredo Deza <alfredodeza [at] gmail [dot] com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

