# Oberon-pictures

Grapes.Pict
![Grapes.png](Grapes.png?raw=true "Grapes.Pict")

Escher.Pict
![Escher.png](Escher.png?raw=true "Escher.Pict")

# Supported interface
    PROCEDURE New*(w, h, dpt: INTEGER) : Picture;
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

TestRLE, StoreRLE procedures provide some functionality for
unit test of the module and will be moved to separate module in future.

# ETH Picture format definition
    LSB = <00> | <01> | ... | <FE> | <FF>.
    MSB = <00> | <01> | ... | <FE> | <FF>.
    
    PictFile = ID Width Height ColorTable { Run } .
    ID = <03> <F0>.
    Width = LSB MSB.
    Height = LSB MSB.
    ColorTable = Depth { R G B }
    Depth = LSB MSB
    R = LSB.
    G = LSB.
    B = LSB.
    Run = Compressed | Uncompressed.
    Compressed = Negative LSB.
    Uncompressed = Positive { LSB }.
    Negative = <80> | <81> | ... | <FF>.
    Positive = <00> | <01> | ... | <7F>.

- Width, Height and Depth are integer values (MSB * 256 + LSB). 
- ColorTable has 2^Depth RGB entries.
- Negative: Copy (256-Negative) times the LSB of RLE to the screen.
- Positive: Transfer (Positive+1) bytes in the file 1:1 to the screen.
