# Wizard Fight

## by Christian Koch

So I'm learning dRuby and Rinda. This is a silly little game built on top of
that.


## TODO

- don't hardcode interpreter path, use getopt or whatever alternative to
  "ruby -s", as useful as it is.

- colors

- game logging

- tie up 2 processes => 1 process w/ 2 threads

- curses

- seriously, what of rubygame? it might just be worth it to use plain boring
  ruby/sdl.

- what is the best way to safely update a player tuple? it's just take and
  write, right? just make sure that the client is looking for the specific
  player tuple. it won't find it until it's there. ok i suppose that makes
  sense.


# NOTE

- it seems to me that there is no linda tuplespace implementation as robust
  as the one that ships with Ruby.
