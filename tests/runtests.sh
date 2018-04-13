#!/bin/bash
#
# This test needs a databse with osml10n extension enabled
#
#

if [ $# -ne 1 ]; then
  echo "usage: $0 <dbname>"
  exit 1
fi

# check if commands we need are available
for cmd in psql uconv; do
  if ! command -v $cmd >/dev/null; then
    echo -e "[\033[1;31mERROR\033[0;0m]: command >>$cmd<< not found, please install!"
    exit 1
  fi
done

DB=$1

exitval=0

# $1 result
# $2 expected
function printresult() {
  if [ "$1" = "$2" ]; then
    echo -n -e "[\033[0;32mOK\033[0;0m]     "
  else
    echo -n -e "[\033[1;31mFAILED\033[0;0m] "
    exitval=1
  fi
  echo -e "(expected >$2<, got >$1<)"
}

echo "calling select osml10n_kanji_transcript('漢字 100 abc');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_kanji_transcript('漢字 100 abc');
EOF
)
printresult "$res" "kanji 100 abc"

echo "calling select osml10n_translit('漢字 100 abc');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_translit('漢字 100 abc');
EOF
)
printresult "$res" "hàn zì 100 abc"

echo "calling select osml10n_thai_transcript('thai ถนนข้าวสาร 100');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_thai_transcript('thai ถนนข้าวสาร 100');
EOF
)
printresult "$res" "thai thnn khaotan 100"

echo "calling select osml10n_translit('Москва́');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_translit('Москва́');
EOF
)
# unicode normalize
res=$(echo $res | uconv -x Any-NFC)
printresult "$res" "Moskvá"

echo "calling select osml10n_translit('漢字 100 abc');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_translit('漢字 100 abc');
EOF
)
printresult "$res" "hàn zì 100 abc"



echo "calling select osml10n_get_country(ST_GeomFromText('POINT(9 49)', 4326));"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_country(ST_GeomFromText('POINT(9 49)', 4326));
EOF
)
printresult "$res" "de"

echo "calling select osml10n_get_country(ST_GeomFromText('POINT(100 16)', 4326));"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_country(ST_GeomFromText('POINT(100 16)', 4326));
EOF
)
printresult "$res" "th"

echo "calling select osml10n_geo_translit('東京',ST_GeomFromText('POINT(140 40)', 4326));"
res=$(psql -X -t -A $DB <<EOF
select osml10n_geo_translit('東京',ST_GeomFromText('POINT(140 40)', 4326));
EOF
)
printresult "$res" "toukyou"

echo "calling select osml10n_geo_translit('東京',ST_GeomFromText('POINT(100 30)', 4326));"
res=$(psql -X -t -A $DB <<EOF
select osml10n_geo_translit('東京',ST_GeomFromText('POINT(100 30)', 4326));
EOF
)
printresult "$res" "dōng jīng"

echo "calling select osml10n_geo_translit('ถนนข้าวสาร',ST_GeomFromText('POINT(100 16)', 4326));"
res=$(psql -X -t -A $DB <<EOF
select osml10n_geo_translit('ถนนข้าวสาร',ST_GeomFromText('POINT(100 16)', 4326));
EOF
)
printresult "$res" "thnn khaotan"

echo "select osml10n_get_placename_from_tags('"name"=>"Москва́","name:de"=>"Moskau","name:en"=>"Moscow"',true,false, ' - ');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('"name"=>"Москва́","name:de"=>"Moskau","name:en"=>"Moscow"',true,false, ' - ');
EOF
)
# unicode normalize
res=$(echo $res | uconv -x Any-NFC)
printresult "$res" "‪Москва́ - Moskau‬"

echo "select osml10n_get_placename_from_tags('"name"=>"Москва́","name:de"=>"Moskau","name:en"=>"Moscow"',false,false, '|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('"name"=>"Москва́","name:de"=>"Moskau","name:en"=>"Moscow"',false,false, '|');
EOF
)
# unicode normalize
res=$(echo $res | uconv -x Any-NFC)
printresult "$res" "‪Moskau|Москва́‬"

echo "osml10n_get_placename_from_tags('"name"=>"القاهرة","name:de"=>"Kairo","int_name"=>"Cairo","name:en"=>"Cairo"',false,false, '|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('"name"=>"القاهرة","name:de"=>"Kairo","int_name"=>"Cairo","name:en"=>"Cairo"',false,false, '|');
EOF
)
printresult "$res" "‪Kairo|القاهرة‬"

echo "select osml10n_get_placename_from_tags('name=>"Bruxelles - Brussel",name:de=>Brüssel,name:en=>Brussels,name:xx=>Brussel,name:af=>Brussel,name:fr=>Bruxelles,name:fo=>Brussel',false,false, '|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('name=>"Bruxelles - Brussel",name:de=>Brüssel,name:en=>Brussels,name:xx=>Brussel,name:af=>Brussel,name:fr=>Bruxelles,name:fo=>Brussel',false,false, '|');
EOF
)
printresult "$res" "‪Brüssel|Bruxelles‬"

echo "select osml10n_get_placename_from_tags('"name"=>"Brixen Bressanone","name:de"=>"Brixen","name:it"=>"Bressanone"',false,false, '|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('"name"=>"Brixen Bressanone","name:de"=>"Brixen","name:it"=>"Bressanone"',false,false, '|');
EOF
)
printresult "$res" "‪Brixen|Bressanone‬"

echo "select osml10n_get_placename_from_tags('"name"=>"Roma","name:de"=>"Rom"',false,false, '|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('"name"=>"Roma","name:de"=>"Rom"',false,false, '|');
EOF
)
printresult "$res" "‪Rom|Roma‬"

echo "select osml10n_get_streetname_from_tags('"name"=>"Doktor-No-Straße"',false);"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_streetname_from_tags('"name"=>"Doktor-No-Straße"',false);
EOF
)
printresult "$res" "Dr.-No-Str."

echo "select osml10n_get_streetname_from_tags('"name"=>"Dr. No Street","name:de"=>"Professor-Doktor-No-Straße"',false);"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_streetname_from_tags('"name"=>"Dr. No Street","name:de"=>"Professor-Doktor-No-Straße"',false);
EOF
)
printresult "$res" "‪Prof.-Dr.-No-Str. - Dr. No St.‬"

echo "select osml10n_get_name_without_brackets_from_tags('"name"=>"Dr. No Street","name:de"=>"Doktor-No-Straße"');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_name_without_brackets_from_tags('"name"=>"Dr. No Street","name:de"=>"Doktor-No-Straße"');
EOF
)
printresult "$res" "Doktor-No-Straße"

echo "select osml10n_get_streetname_from_tags('"name"=>"улица Воздвиженка","name:en"=>"Vozdvizhenka Street"',true,true,' ','de');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_streetname_from_tags('"name"=>"улица Воздвиженка","name:en"=>"Vozdvizhenka Street"',true,true,' ','de');
EOF
)
printresult "$res" "‪ул. Воздвиженка (Vozdvizhenka St.)‬"

echo "select osml10n_get_streetname_from_tags('"name"=>"улица Воздвиженка"',true,true,' ','de');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_streetname_from_tags('"name"=>"улица Воздвиженка"',true,true,' ','de');
EOF
)
printresult "$res" "‪ул. Воздвиженка (ul. Vozdviženka)‬"

echo "select osml10n_get_streetname_from_tags('"name"=>"вулиця Молока"',true,false,' - ','de');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_streetname_from_tags('"name"=>"вулиця Молока"',true,false,' - ','de');
EOF
)
printresult "$res" "‪вул. Молока - vul. Moloka‬"

echo "select osml10n_get_placename_from_tags('"name"=>"주촌  Juchon", "name:ko"=>"주촌","name:ko_rm"=>"Juchon"',false,false,'|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('"name"=>"주촌  Juchon", "name:ko"=>"주촌","name:ko_rm"=>"Juchon"',false,false,'|');
EOF
)
printresult "$res" "‪Juchon|주촌‬"

echo "select osml10n_get_placename_from_tags('"name"=>"주촌", "name:ko"=>"주촌","name:ko_rm"=>"Juchon"',false,false,'|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('"name"=>"주촌", "name:ko"=>"주촌","name:ko_rm"=>"Juchon"',false,false,'|');
EOF
)
printresult "$res" "‪Juchon|주촌‬"

echo "select osml10n_get_country_name('"ISO3166-1:alpha2"=>"IN","name:de"=>"Indien","name:hi"=>"भारत","name:en"=>"India"','|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_country_name('"ISO3166-1:alpha2"=>"IN","name:de"=>"Indien","name:hi"=>"भारत","name:en"=>"India"','|');
EOF
)
printresult "$res" "Indien|भारत|India"

exit $exitval
