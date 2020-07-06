alias beluga='~/Clones/Beluga/bin/beluga'
alias harpoon='~/Clones/Beluga/bin/beluga +implicit -I'
alias python='python3'
alias opythn='~/Github/opythn/main'

alias skim='/Applications/Skim.app/Contents/MacOS/Skim'

alias rer='source ranger'
export PATH="$PATH:/usr/local/smlnj/bin"

# bb : roff-format biblio to tex 
#
# Luc Devroye
# 13 October 1990
#
# Adapted by Marcel Goh
# 6 July 2020
# Troff biblio files:  that are already in semi-TEX format,
#			i.e. no multiple lines
#			no accents in \*. format where . is '`:^
#			clean up old troff accents
#			introduce \0 instead of blanks for sorting
#			formulas should be in $texformat$
# Use : bb filename > file.tex ; 
#       bb filename >> file.tex
bb () {
    # MACHINE="muff"
    # SORTBIB="rsh $MACHINE /usr/bin/sortbib"
    # rcp $1 luc@$MACHINE:/home/cgm/profs/luc/$1bb 
        # uncomment
    # rcp $1 luc@lisa:/u0/prof/luc/$1bb
    if test -f ./ref.tmp
        then rm ./ref.tmp
        fi
    # sortbibnameA $1 |  sed '/\\0/s// /g'  > /tmp/ref.$$
    cat $1 |  sed '/\\0/s// /g'  > ./ref.tmp
    # $SORTBIB -sA+D $1bb  |  sed '/\\0/s// /g'  > /tmp/ref.$$ 
        # uncomment
    # sed '/\\0/s// /g' R > /tmp/ref.$$          
        # remove later
    #clean /tmp/ref.$$ 
    echo "" >> ./ref.tmp
    awk 'BEGIN { count=0 ; author=0 ; tslanted = 0 ; totalauthor=0 }\
    $0 == "" { count += 1 ; p=0 ;  author=0   }\
    $1 == "%A" { p=0 ; author += 1 ; totalauthor=author }\
    $1 == "%T" { p=20  ; author=0}\
    $1 == "%J" { p=40  ; author=0 ; tslanted = 1 }\
    $1 == "%L" { p=50 ; author=0}\
    $1 == "%E" { p=55 ; author=0 }\
    $1 == "%V" { p=60  ; author=0}\
    $1 == "%B" { p=40 ; author=0 ; tslanted = 1 }\
    $1 == "%R" { p=100 ; author=0  ; tslanted = 1}\
    $1 == "%C" { p=140 ; author=0 }\
    $1 == "%I" { p=160 ; author=0 }\
    $1 == "%D" { p=180 ; author=0 }\
    $1 == "%O" { p=200  ; author=0}\
    $1 == "%P" { p=210 ; author=0}\
    $1 == "%Y" { p=220 ; author=0}\
    /^$/ { print count*250+p+NR " " 0 " %K " totalauthor " " tslanted ; totalauthor = 0 ; tslanted = 0 }\
    /^$/||/^%[ATJVLPDOBREICY]/ { print count*250+p+NR+1 " " author " " $0 }\
    ' ./ref.tmp |
    sort -n |
    sed '/^.*%/s//%/' |
    awk 'substr( $0 , 1 , 1 ) != "%" { print "" } substr($0, 1, 1) == "%" { print $0 }' |
    awk 'BEGIN { count=0 ; author=0 ; tslanted = 0 ; totalauthor=0 }\
    $0 == "" { count += 1 ; p=-40 ;  author=0   }\
    $1 == "%K" { p=-20 }\
    $1 == "%A" { p=0 ; author += 1 ; totalauthor=author }\
    $1 == "%T" { p=20  ; author=0}\
    $1 == "%J" { p=40  ; author=0 ; tslanted = 1 }\
    $1 == "%L" { p=50 ; author=0}\
    $1 == "%E" { p=55 ; author=0 }\
    $1 == "%V" { p=60  ; author=0}\
    $1 == "%B" { p=40 ; author=0 ; tslanted = 1 }\
    $1 == "%R" { p=100 ; author=0  ; tslanted = 1}\
    $1 == "%C" { p=140 ; author=0 }\
    $1 == "%I" { p=160 ; author=0 }\
    $1 == "%D" { p=180 ; author=0 }\
    $1 == "%O" { p=200  ; author=0}\
    $1 == "%P" { p=210 ; author=0}\
    $1 == "%Y" { p=220 ; author=0}\
    { print count*300+p+NR " " author " " $0 }\
    ' |
    sort -n  |
    sed '/^.*%/s//%/' |
    sed '/^[0-9\-]/s/^.*$//' |
    awk 'BEGIN { ac = 0 }\
    $1 == "%K" { ac = 0 ; slant = $3 ; author = $2 }\
    $1 == "%A" { ac += 1 }\
    $1 != "%K" { print slant " " author " " ac " " $0 }\
    ' |
    awk '$4 == "%P" || $4 == "%O" { print $0 "." }\
    $4 != "%P" && $4 != "%O" { print $0 ","} ' |
    sed '/^..2 1.*%A/s/,$//' |
    # sed '/%V/s/%V /%V vol.\~/' |
    sed '/%V/s/%V /%V {\\bf /' |    # Make volume no. boldface
    sed '/%V/s/,$/}/' |             # Remove comma from volume no.
    sed '/%J/s/,$/}\\\//' |         # Remove comma from journal
    #sed '/%P/s/%P /%P p.\~/'  |
    #sed '/%P.*-/s/%P p/%P pp/' |
    sed '/%D/s/%D /%D (/' |
    sed '/%D/s/,$/),/' |
    sed '/%C/s/%C /%C (/' |
    sed '/%C/s/,$/:/' |
    sed '/%Y/s/,$/.)/' |
    sed '/%P/s/-/--/' |
    sed '/%E/s/%E /%E edited by /' |
    sed '/%E/s/,$/,/' |
    sed '/^0.*%T/s/%T /%T {\\sl /' |
    sed "/^0.*%T/s/,$/}/" |
    sed '/^1.*%T/s/%T /%T ``/' |
    sed "/^1.*%T/s/,$/,''/" |
    sed '/%J/s/%J /%J {\\sl /' |
    sed "/%J/s/,$/},/" |
    sed '/%B/s/%B /%B in: {\\sl /'  |
    sed "/%B/s/,$/},/"  |
    awk ' $2 == $3 && $2 != "1" { print "XXX" $0 } $2 != $3 || $2 == "1" { print $0 } '  |
    sed '/XXX/s/%A /%A and /' |
    sed '/XXX/s///' |
    sed '/%[AE]/s/[A-Za-z]\. */&XXX/g' |
    sed '/XXX/s/ *XXX/\~/g'  |
    sed '/\.\~-/s//\.-/g'  |
    sed '/^[0-9 ,]*$/s/^.*$//'  |
    sed '/^.*%../s///' |
    sed '/\\:/s//\\"/' |
    sed '/^$/c\
    \\endref\
    \
    \\beginref ' |
    sed '1i\
    \\parskip=0pt\
    \\hyphenpenalty=-1000 \\pretolerance=-1 \\tolerance=1000\
    \\doublehyphendemerits=-100000 \\finalhyphendemerits=-100000\
    \\frenchspacing\
    \\def\\beginref{\
      \\par\\begingroup\\nobreak\\smallskip\\parindent=0pt\\kern1pt\\nobreak\
      \\everypar\{\\strut\}\
    }\
    \\def\\endref{\\kern1pt\\endgroup\\smallbreak\\noindent}\
    \
    \\beginref ' |
    sed '/\\beginref $/d'

    if test -f ./ref.tmp; then
        rm ./ref.tmp
    fi
}

pdf() {
    if test "$#" -ne 1 && test "$#" -ne 2; then
        echo "$0: Wrong number of arguments."
        exit 3
    fi
    filename=""
    if test "$1" = "-r"; then
        filename="$2"
        cat "$filename".tex > pdftemp.tex
        bb "$filename".ref >> pdftemp.tex
        sed -i '' 's/\\bye//g' pdftemp.tex
        echo '\\bye' >> pdftemp.tex
    else
        cat "$1".tex > pdftemp.tex
    fi
    tex pdftemp.tex && dvipdfm pdftemp.dvi
    mv pdftemp.pdf "$filename".pdf
    rm pdftemp*
}
