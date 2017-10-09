# Oberon-pictures

Grapes.Pict
![Grapes.png](Grapes.png?raw=true "Grapes.Pict")

Escher.Pict
![Escher.png](Escher.png?raw=true "Escher.Pict")

# Supported interface
    PROCEDURE LoadRLE(P: Picture; VAR R: Files.Rider; rv: BOOLEAN);
    PROCEDURE StoreRLE* (P: Picture; VAR R: Files.Rider; rv: BOOLEAN);
    PROCEDURE New*(w, h, dpt: INTEGER) : Picture;
    PROCEDURE TestRLE(): Picture;
    PROCEDURE Load*(VAR R: Files.Rider; VAR len: INTEGER) : Picture;
    PROCEDURE Open*(name: ARRAY OF CHAR) : Picture;
    PROCEDURE Show*;

# Notes
Pictures module currently has only a minimal interface, to show rle
encoded pictures. There are two B&W pictures provided
'Grapes.Pict', 'Escher.Pict', these date back to days of Xerox Alto, and
Ceres workstations. To display use the commands:

    Pictures.Show Grapes.Pict 30 30 ~  Pictures.Show Test.Pict 30 30 ~
    Pictures.Show Escher.Pict 30 30 ~

It decodes rle picture into bitmap, and displays at given coordinates.
Bitmap is then encoded back to rle and stored to 'Test.Pict'. Showing
'Test.Pict' should give identical result.

TestRLE, StoreRLE provide some functionality for
unit test of the module and will be moved to separate module in future.

# EBNF for ETH Picture format
    File.Pict = ID width height depth CT {run}.
    ID = $F003$. width=height=depth = short.
    CT = {R G B}. R=G=B = byte (colour table, 2 entries for depth=1)
    run = run0 | run1. (run0 = equal byte run, run1 = non-equal byte run)
    run0 = 257-count byte.
    run1 = count {byte}.
    count = byte.
    byte = 0..255.
    short = byte byte. (0..32767)

