
-------Pagila Örnek Veri Tabanını Kullanmaktadır-------

----Fonksiyon (Saklı Yordam) Tanımlama--------------


CREATE OR REPLACE FUNCTION fonksiyonTanimlama(mesaj text, altKarakterSayisi SMALLINT, tekrarSayisi integer)
RETURNS text AS  -- SETOF TEXT, SETOF record... diyerek çok sayıda değerin döndürülmesi de mümkündür
$$ -- Fonksiyon govdesi başlangici
DECLARE
    sonuc text; --Degisken tanimlama Blogu
BEGIN
    sonuc := '';
    IF tekrarSayisi > 0 THEN
        FOR i IN 1 .. tekrarSayisi LOOP
            sonuc := sonuc || i || '.' || SUBSTRING(mesaj FROM 1 FOR altKarakterSayisi) || E'\r\n'; 
            -- E: string içerisindeki (E)scape karakterleri için...
        END LOOP;
    END IF;
    RETURN sonuc;
END;
$$ -- Fonksiyon govdesi sonu
LANGUAGE 'plpgsql' IMMUTABLE SECURITY DEFINER ; 
--immutable: aynı girişler için aynı çıkışları üretecek
--SECURITY DEFINER: fonksiyonu oluşturanın yetkileriyle çalıştırılsın.
  

SELECT fonksiyonTanimlama('Deneme', 2::SMALLINT, 10) --fonksiyonun cagrilmasi


-----Select Sorgusu Sonucu Üzerinde Dolanım----------


CREATE OR REPLACE FUNCTION kayitDolanimi()
RETURNS TEXT AS  
$$ 
DECLARE
    musteriler  customer%ROWTYPE; --customer."CustomerID"%TYPE
    sonuc TEXT;
BEGIN
    sonuc:='';
    FOR musteriler IN SELECT * FROM customer LOOP
        sonuc:= sonuc || musteriler."customer_id" || E'\t' || musteriler."first_name"|| E'\r\n';
    END LOOP;
    RETURN sonuc;
END;
$$ 
LANGUAGE 'plpgsql';

SELECT  kayitDolanimi() --fonksiyonun cagrilmasi



---------- Tablo Döndürme----------

CREATE or replace FUNCTION personelAra(personelNo INT)
RETURNS TABLE(numara INT, adi varchar(40), soyadi VARCHAR(40)) AS $$
BEGIN
    RETURN QUERY SELECT "staff_id","first_name","last_name" FROM staff
                 WHERE "staff_id"=personelNo;
END;
$$ 
LANGUAGE plpgsql;

Select * from personelAra(1);




--------Çıkış Parametresi-------

CREATE or replace FUNCTION inch2cm(sayiInch real, OUT sayiCM REAL)
AS $$
BEGIN
    sayiCM=2.54*sayiINCH;
END;
$$ 
LANGUAGE plpgsql;


Select * from inch2cm(2);


-------Fonksiyon içerisinden fonksiyon çağırma-------

CREATE OR REPLACE FUNCTION public.odemetoplami(personelno integer)
 RETURNS text
 LANGUAGE plpgsql
AS $$
DECLARE
    
    sonuc TEXT;
    personel record;
    miktar NUMERIC;

BEGIN
    personel=personelAra(personelNo);
    FOR miktar IN SELECT SUM(amount) from payment where staff_id=personelNo LOOP 
    END LOOP;
    
    return personel."numara"||E'\t'||personel."adi"||E'\t'||miktar;
END;
$$


select odemeToplami(2)


----- Cursor Kullanımı-----

CREATE OR REPLACE FUNCTION filmAra(p_year INTEGER, filmAdi TEXT)RETURNS text AS 
$$
DECLARE
titles TEXT DEFAULT '';
rec_film   RECORD;
cur_films CURSOR(p_year INTEGER) FOR SELECT * FROM film WHERE release_year = p_year;
BEGIN
   OPEN cur_films(p_year);  -- Open the cursor
   LOOP
      FETCH cur_films INTO rec_film; -- fetch row into the film
      EXIT WHEN NOT FOUND;     -- exit when no more row to fetch
      IF rec_film.title LIKE filmAdi||'%' THEN     -- build the output
         titles := titles || ',' || rec_film.title || ':' || rec_film.release_year;
      END IF;
   END LOOP;
   CLOSE cur_films;    -- Close the cursor
   RETURN titles;
END; $$
LANGUAGE plpgsql;
----------
SELECT * from filmAra(2006,'T');



------Trigger  ------------ 

--NorthWind veritabanındaki ürünlerin birim fiyat değişimlerini izlemek için kullanılır...

CREATE TABLE "public"."UrunDegisikligiIzle" ( 
	"kayitNo" serial,
	"urunNo" SmallInt NOT NULL,
	"eskiBirimFiyat" Real NOT NULL,
	"yeniBirimFiyat" Real NOT NULL,
	"degisiklikTarihi" TIMESTAMP NOT NULL,
	CONSTRAINT "PK" PRIMARY KEY ( "kayitNo" ) );
 -------------------
CREATE OR REPLACE FUNCTION "urunDegisikligiTR1"()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW."UnitPrice" <> OLD."UnitPrice" THEN
		INSERT INTO "UrunDegisikligiIzle"("urunNo","eskiBirimFiyat","yeniBirimFiyat","degisiklikTarihi")
		VALUES(OLD."ProductID",OLD."UnitPrice",NEW."UnitPrice",CURRENT_TIMESTAMP::TIMESTAMP);
	END IF;
 
	RETURN NEW;
END;
$$ 
LANGUAGE plpgsql;

CREATE  TRIGGER urunBirimFiyatDegistiginde
BEFORE UPDATE  ON products
FOR EACH ROW
EXECUTE PROCEDURE "urunDegisikligiTR1"();