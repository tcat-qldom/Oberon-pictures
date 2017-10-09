MODULE Pictures; (*TK 8.10.2017*)
  IMPORT SYSTEM, Files, Display, Bitmaps, Texts, Oberon;

  TYPE
    (* Depth=1 only *)
    ColorTable = POINTER TO RECORD
      i: ARRAY 2 OF RECORD red, green, blue: BYTE END
    END;

    Picture* = POINTER TO PictureDesc;
    PictureDesc* = RECORD (Bitmaps.BitmapDesc)
      ct: ColorTable
    END;

  VAR W: Texts.Writer;

  PROCEDURE ReadShort(VAR R: Files.Rider; VAR i: INTEGER);
	VAR bt0, bt1: BYTE;
  BEGIN
    Files.ReadByte(R, bt0); Files.ReadByte(R, bt1); i := bt0 + bt1*100H
  END ReadShort;

  PROCEDURE WriteShort(VAR R: Files.Rider; i: INTEGER);
	VAR bt0, bt1: BYTE;
  BEGIN bt0 := i MOD 100H; bt1 := i DIV 100H;
    Files.WriteByte(R, bt0); Files.WriteByte(R, bt1);
  END WriteShort;

  PROCEDURE LoadCT(VAR ct: ColorTable; VAR R: Files.Rider; depth: INTEGER);
    VAR i: INTEGER;
  BEGIN
    i := 0;
    WHILE i < LSL(1, depth) DO
      Files.ReadByte(R, ct.i[i].red);
      Files.ReadByte(R, ct.i[i].green);
      Files.ReadByte(R, ct.i[i].blue);
      INC(i)
   END
  END LoadCT;

  PROCEDURE StoreCT(ct: ColorTable; VAR R: Files.Rider; depth: INTEGER);
    VAR i: INTEGER;
  BEGIN
    i := 0;
    WHILE i < LSL(1, depth) DO
      Files.WriteByte(R, ct.i[i].red);
      Files.WriteByte(R, ct.i[i].green);
      Files.WriteByte(R, ct.i[i].blue);
      INC(i)
   END
  END StoreCT;

  (* load run length RLE1 encoded picture *)
  PROCEDURE LoadRLE(P: Picture; VAR R: Files.Rider; rv: BOOLEAN);
	VAR bt: BYTE; x, y, k, a, w, h, bw: INTEGER;
  BEGIN 
    w := P.width; h := P.height;
    bw := (w+31) DIV 32 * 4;   (* number of bytes on bitmap line, word aligned *)
    a := P.base + P.size - bw;

    y := h; REPEAT
      x := 0; REPEAT
        Files.ReadByte(R, bt); k := bt;
        IF k < 128 THEN          (* end of RLE run *)
          REPEAT                     (* copy `k' bytes until next run *)
            Files.ReadByte(R, bt);
            (*a := P.base + y*bw + (x DIV 32)*4;*)
            Bitmaps.PutPix(a, x, bt, P.depth);
            DEC(k)
          UNTIL k < 0
        ELSIF k >= 128 THEN  (* start of RLE run *)
          k := 257 - k;
          Files.ReadByte(R, bt);
          REPEAT                     (* duplicate byte `257-k' times *)
            (*a := P.base + y*bw + (x DIV 32)*4;*)
            Bitmaps.PutPix(a, x, bt, P.depth);
            DEC(k)
          UNTIL k < 1
        END;
      UNTIL x = w; DEC(y); a := P.base + y*bw - bw
    UNTIL y = 0;

  END LoadRLE;

  (* store run length RLE1 encoded picture *)
  PROCEDURE StoreRLE* (P: Picture; VAR R: Files.Rider; rv: BOOLEAN);
  VAR j, a, b, h, w, d: INTEGER; bt :BYTE; bw, bw0, pos, adr: INTEGER; 
         buf: ARRAY 129 OF BYTE; help: BOOLEAN;
         f: Files.File; r: Files.Rider;
  BEGIN
    f := Files.New("Test.Pict");
    Files.Set(r, f, 0);
	
    w := P.width; h := P.height; d := P.depth;
    bw := (w+31) DIV 32 * 4;   (* number of bytes on bitmap line, word aligned *)
    bw0 := (w+7) DIV 8;           (* number of bytes on bitmap line *)
    adr := P.base + P.size - bw;

    WriteShort(r, 0F003H);
    WriteShort(r, w); WriteShort(r, h); WriteShort(r, d); StoreCT(P.ct, r, d);
	
    REPEAT
      j := 1; buf[0] := 0; (* run len, 0,1,.. | -1,-2,.. *)
      a := 0; b := a + 1;  (* b-a bytes in run *)
      Bitmaps.GetPix(adr, buf[j], d);
      WHILE b < bw0 DO
        Bitmaps.GetPix(adr, bt, d); help := (buf[j] = bt);
        IF ((b - a) < 127) & ((buf[0] = 0) OR help & (j = 1) OR ~help & (j > 1)) THEN (* same run *)
          IF bt # buf[j] THEN INC(buf[0]); INC(j); buf[j] := bt ELSE DEC(buf[0]) END
        ELSE (* new run *)
          IF (help) & (b - a # 127) THEN DEC(buf[0]); Files.WriteBytes(r, buf, j); buf[0] := -1
          ELSE Files.WriteBytes(r, buf, j + 1); buf[0] := 0 END;
          j := 1; buf[j] := bt; a := b
        END;
        INC(b)
      END;
      Files.WriteBytes(r, buf, j + 1);
      adr := adr - bw0 - bw; (* adr := P.base + h*bw - bw; *)
      DEC(h)
    UNTIL h = 0;

    Files.Register(f)
  END StoreRLE;

  PROCEDURE New*(w, h, dpt: INTEGER) : Picture;
    VAR p: Picture; b: Bitmaps.Bitmap;
  BEGIN
    NEW(p); IF p # NIL THEN
      NEW(p.ct); IF p.ct # NIL THEN 
        b := Bitmaps.New(p, w, h, dpt);
        IF (b = NIL) THEN p := NIL END
      END
   END  
  RETURN p END New;

  (* sets test byte run 0  0  0  0  1  0  0  2  3  4  0  1 *)
  PROCEDURE TestRLE(): Picture;
    VAR p: Picture; bt: BYTE; w, h, dpt, a: INTEGER;
  BEGIN 
    w := 12*8; h := 1; dpt := 1;
    p := New(w, h, dpt);
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
  RETURN p END TestRLE;
 
  PROCEDURE Load*(VAR R: Files.Rider; VAR len: INTEGER) : Picture;
    VAR p: Picture; w, h, dpt: INTEGER;
  BEGIN
    ReadShort(R, w); ReadShort(R, h);  ReadShort(R, dpt);
    p := New(w, h, dpt);
    IF p # NIL THEN 
      LoadCT(p.ct, R, p.depth);
      LoadRLE(p, R, p.depth = 1)
    END;
    len := Files.Pos(R)-2;
  RETURN p END Load;

  PROCEDURE Open*(name: ARRAY OF CHAR) : Picture;
    VAR p: Picture; F: Files.File; R: Files.Rider; len, id: INTEGER; 
  BEGIN
    F := Files.Old(name);
    IF F # NIL THEN
      Files.Set(R, F, 0); ReadShort(R, id);
      IF id = 0F003H THEN 
        Texts.WriteString(W, "Pictures.Load "); Texts.WriteString(W, name);
        Texts.Append(Oberon.Log, W.buf); 
        p := Load(R, len); Texts.WriteString(W, " done.")
      ELSE Texts.WriteString(W, "This file is not a picture ") END
    END;
    IF p # NIL THEN Texts.WriteInt(W, len, 6); Texts.WriteInt(W, p.size, 6) END;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  RETURN p END Open;

  PROCEDURE Show*;
	VAR p: Picture; x, y: INTEGER; S: Texts.Scanner; R: Files.Rider;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN Texts.Scan(S);
      IF S.class = Texts.Int THEN x := S.i; Texts.Scan(S);
        IF S.class = Texts.Int THEN y := S.i END
      END
    END;
    p := Open(S.s); (* p := TestRLE(); *)
    IF p # NIL THEN Bitmaps.DisplayBlock(p, 0, 0, p.width, p.height, x, y, Display.replace);
     StoreRLE(p, R, FALSE)
    END
  END Show;

BEGIN Texts.OpenWriter(W)
END Pictures.

Pictures.Show Grapes.Pict 30 30 ~  Pictures.Show Test.Pict 30 30 ~
Pictures.Show Escher.Pict 30 30 ~
