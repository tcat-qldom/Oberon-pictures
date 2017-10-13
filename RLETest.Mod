MODULE RLETest; (*TK 10.10.2017*)
  IMPORT SYSTEM, Files, Bitmaps, Pictures, Texts, Oberon;
  VAR W: Texts.Writer;

  (* sets test byte run 0  0  0  0  1  0  0  2  3  4  0  1 *)
  PROCEDURE SetRun(): Pictures.Picture;
    VAR p: Pictures.Picture; bt: BYTE; w, h, dpt, a: INTEGER;
  BEGIN 
    w := 12*8; h := 1; dpt := 1;
    p := Pictures.New(w, h, dpt);
    IF p # NIL THEN
      a := p.base;
      bt := 0; SYSTEM.PUT(a, bt); INC(a); SYSTEM.PUT(a, bt); INC(a); SYSTEM.PUT(a, bt); INC(a); SYSTEM.PUT(a, bt); INC(a);
      bt := 1; SYSTEM.PUT(a, bt); INC(a);
      bt := 0; SYSTEM.PUT(a, bt); INC(a); SYSTEM.PUT(a, bt); INC(a);
      bt := 2; SYSTEM.PUT(a, bt); INC(a);
      bt := 3; SYSTEM.PUT(a, bt); INC(a);
      bt := 4; SYSTEM.PUT(a, bt); INC(a);
      bt := 0; SYSTEM.PUT(a, bt); INC(a);
      bt := 1; SYSTEM.PUT(a, bt);
    END
  RETURN p END SetRun;

  PROCEDURE Run*;
	VAR p: Pictures.Picture; F: Files.File; R: Files.Rider; a, len: INTEGER; bt: BYTE;
  BEGIN
    p := SetRun();
    IF p # NIL THEN

      FOR a := p.base TO p.base+12 DO
        SYSTEM.GET(a, bt); Texts.WriteInt(W, bt, 4)
      END; Texts.WriteLn(W);
            
      F := Files.New("Test.Pict"); Files.Set(R, F, 0);
      Pictures.Store(p, R, len);
      Files.Register(F); Files.Set(R, F, 14);

      FOR a := 1 TO len-14 DO
        Files.ReadByte(R, bt); Texts.WriteInt(W, bt, 4)
      END; Texts.WriteLn(W);

    END;
    Texts.Append(Oberon.Log, W.buf)
  END Run;

  PROCEDURE Pict*;
	VAR p: Pictures.Picture; F: Files.File; R: Files.Rider; len: INTEGER;
  BEGIN
    p := Pictures.Open("Grapes.Pict");
    IF p# NIL THEN
      F := Files.New("Test.Pict"); Files.Set(R, F, 0);
      Pictures.Store(p, R, len);
      Files.Register(F)
    END
  END Pict;

BEGIN Texts.OpenWriter(W)
END RLETest.
