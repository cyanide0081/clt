## command-line trimmer

simple trailing-whitespace trimmer for saving files
(made for plugging into helix).

preserves line-endings as long as they're either LF (Unix) or CRLF (Windows).

usage (read lines from stdin and trim on the fly):  
```
clt
```
  
or (trim file and overwrite):
```
clt [filename]
```
