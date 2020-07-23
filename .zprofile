alias beluga='~/Clones/Beluga/bin/beluga'
alias harpoon='~/Clones/Beluga/bin/beluga +implicit -I'
alias python='python3'
alias opythn='~/Github/opythn/main'

alias skim='/Applications/Skim.app/Contents/MacOS/Skim'

alias rer='source ranger'
export PATH="$PATH:/usr/local/smlnj/bin"

eval `opam env`

# Written by Luc Devroye
sortbibnameA () {
    filename=$1
    key="%A"
    editfile=/tmp/ed$$
    rm -f $editfile
    indexfile=/tmp/sort$$
    rm -f $indexfile

    sed '/ring;/s///g' $filename |
    sed '/acute;/s///g' |
    sed '/grave;/s///g' |
    sed '/uml;/s///g' |
    sed '/\\0/s///g' |
    awk 'BEGIN {b=0 ; line=0}\
        { line = line + 1 }\
        $0 !~ /^%/ && ( ( b == 1 ) || ( b == 3 ) ) { e = line - 1 ; b = 2  }\
        /^%/ && b == 0 { a = line ; b = 1 }\
        /^%A/ && b != 3 { n = $NF ; t = substr($0,4,length($0)-3) ; b = 3 }\
        /^%D/ { d = substr($0,4,length($0)-3) }\
        b == 2 { print a " " e " " n t d ; b = 0 }\
        END { if ( b == 1  || b == 3 ) { print a " " line  " " n t d } }\
    ' |
    sort -k 3 -df |
    awk ' { print "head -" $2 " $1 | tail -" $2-$1+1 " >> $2" ; print "echo \"\" >> $2" } ' > $editfile

    # cat $editfile
    echo "" > $indexfile
    sh $editfile $filename $indexfile
    cat $indexfile

    rm -f $editfile
    rm -f $indexfile
}

# bb : roff-format biblio to tex 
#
# Luc Devroye
# 13 October 1990
#
# Edited (and extensively commented) by Marcel Goh
# 23 July 2020
#
# Troff biblio files:  that are already in semi-TEX format,
#			i.e. no multiple lines
#			no accents in \*. format where . is '`:^
#			clean up old troff accents
#			introduce \0 instead of blanks for sorting
#			formulas should be in $texformat$
# Use : bb filename > file.tex ; 
#       bb filename >> file.tex
bb () {
    if test -f ./ref.tmp
        then rm ./ref.tmp
        fi
    sortbibnameA $1 |  sed '/\\0/s// /g'  > ./ref.tmp
    echo "" >> ./ref.tmp
    # This pass:
    # + Counts the total number of authors per reference;
    # + Checks if title is slanted (0: yes, 1: no);
    # + Checks if city of publication is included (0: no, 1: yes);
    # + Checks if page range is included (0: no, 1: yes).
    # This is all printed on a %K line:
    #   %K [total authors] [tslanted] [city] [pages]
    awk 'BEGIN { tslanted = 0 ; totalauthor=0 ; city=0 ; pages=0 }\
        $1 == "%A" { totalauthor+=1 }\
        $1 == "%J" { tslanted=1 }\
        $1 == "%B" { tslanted=1 }\
        $1 == "%R" { tslanted=1 }\
        $1 == "%C" { city=1 }\
        $1 == "%P" { pages=1 }\
        /^$/ { print "%K " totalauthor " " tslanted " " city " " pages;
               totalauthor=0 ; tslanted=0 ; city=0 ; pages=0 }\
        /^$/||/^%[ATJVLPDOBREICY]/ { print $0 }\
    ' ./ref.tmp |
    # This pass assigns a number to each field; %K gets a very small value.
    awk 'BEGIN { count=0 }\
        $0 == "" { count += 1 ; p=-40 }\
        $1 == "%K" { p=-20 }\
        $1 == "%A" { p=0 }\
        $1 == "%T" { p=20 }\
        $1 == "%J" { p=40 }\
        $1 == "%B" { p=40 }\
        $1 == "%L" { p=50 }\
        $1 == "%E" { p=55 }\
        $1 == "%V" { p=60 }\
        $1 == "%R" { p=100 }\
        $1 == "%C" { p=140 }\
        $1 == "%I" { p=160 }\
        $1 == "%D" { p=180 }\
        $1 == "%P" { p=210 }\
        $1 == "%Y" { p=220 }\
        $1 == "%O" { p=230 }\
        { print count*300+p+NR " " $0 }\
    ' |
    sort -n  | # Sorts the fields
    sed '/^.*%/s//%/' |
    sed '/^[0-9\-]/s/^.*$//' |
    # This pass:
    # + Indexes the authors (0: not an author field, n: nth author in list);
    # + Moves contents of %K line to every line in that reference.
    awk 'BEGIN { ac = 0 }\
        $0 == "" { print "" }
        $1 == "%K" { authorindex = 0 ; totalauthor=$2 ; tslanted=$3 ; city=$4 ; pages=$5 }\
        $1 == "%A" { authorindex += 1 }\
        $1 != "%K" && $0 != "" { print tslanted " " totalauthor " " authorindex " " city " " pages " " $0 }\
    ' |
    # Result of previous pass is that
    # $1 = tslanted; $2 = total no. of authors; $3 = index of this author;
    # $4 = city flag; $5 pages flag; $6 = %_ marker.
    awk 'match($0,"%O") == 0 { print $0 ","}\
         match($0,"%O") != 0 { print $0 }' |  # Add a comma to every line, except %O lines.
    sed '/^..2 1.*%A/s/,$//' |      # If there are two authors, delete comma after first author.
    sed '/%V/s/%V /%V {\\bf /' |    # Make volume no. boldface
    sed '/%V/s/,$/}/' |             # Remove comma from volume no.
    sed '/%J/s/,$/}\\\//' |         # Remove comma from journal
    sed '/%D/s/%D /%D (/' |         # Date of paper gets brackets
    sed '/%D/s/,$/),/' |
    # Check if city is 0 or 1 and put opening bracket accordingly
    awk '$4 == "0" { gsub(/%I /,"%I (") }\
         $4 == "1" { gsub(/%C /,"%C (") }\
         { print $0 }' |
    # Check if pages is 0 or 1 and put period accordingly
    awk '$5 == "0" && match($0,"%D") != 0 { gsub(/,$/,".") }\
         $5 == "1" && match($0,"%P") != 0 { gsub(/,$/,".") }
         { print $0 }' |
    sed '/%C/s/,$/:/' |             # Put colon after city
    sed '/%Y/s/,$/)./' |            # Put period after book year
    sed '/%P/s/-/--/' |             # Proper dashes for page ranges
    sed '/%E/s/%E /%E edited by /' |
    sed '/%E/s/,$/,/' |
    # Check if tslanted is 0 or 1 and add {\sl .. } or `` .. '' accordingly
    # (octal code 047 is the ' character)
    awk '$1 == "0" { gsub(/%T /,"%T {\\sl ") }\
         $1 == "0" && match($0,"%T") != 0 { gsub(/,$/,"\}") }\
         $1 == "1" { gsub(/%T /,"%T ``") }\
         $1 == "1" && match($0,"%T") != 0 { gsub(/,$/,",\047\047") }\
         { print $0 }' |
    sed '/%J/s/%J /%J {\\sl /' |    # Journal is slanted if it's there.
    sed "/%J/s/,$/},/" |
    sed '/%B/s/%B /%B in: {\\sl /'  |
    sed "/%B/s/,$/},/"  |
    # Add `and' after last author
    awk '$2 == $3 && $2 != "1" { print "XXX" $0 }\
         $2 != $3 || $2 == "1" { print $0 } '  |
    sed '/XXX/s/%A /%A and /' |
    sed '/XXX/s///' |
    sed '/%[AE]/s/[A-Za-z]\. */&XXX/g' |
    sed '/XXX/s/ *XXX/\~/g'  |
    # Final cleanup
    sed '/\.\~-/s//\.-/g'  |
    sed '/^[0-9 ,]*$/s/^.*$//'  |
    sed '/^.*%../s///' |
    sed '/\\:/s//\\"/' |
    # Preambles etc.
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
    \\font\\smallheader=cmssbx10\
    \\bigskip\\vskip\\parskip\
    \\leftline{\\smallheader References}\\nobreak\\medskip\\noindent\
    \
    \\beginref ' |
    sed '/\\beginref $/d' |
    sed '/\\beginref \\endref$/d'

    if test -f ./ref.tmp; then
        rm ./ref.tmp
    fi
}

# Convert a TeX file to PDF. -r adds the references (by calling bb)
# Written by Marcel Goh
pdf() {
    refs=0
    out=0
    while test $# -gt 0; do
        case "$1" in
            -r)
                shift
                refs=1
                ;;
            -o)
                shift
                out=1
                ;;
            *)
                break
                ;;
            esac
        done
    if test $refs; then
        cat "$1".tex > pdftemp.tex
        bb "$1".ref >> pdftemp.tex
        sed -i '' 's/\\bye//g' pdftemp.tex
        echo '\\bye' >> pdftemp.tex
    else
        $1="$1"
        cat "$1".tex > pdftemp.tex
    fi
    tex pdftemp.tex && dvipdfm pdftemp.dvi
    mv ./pdftemp.pdf ./"$1".pdf
    if test $out; then
        mv pdftemp.tex "$1"out.tex
    fi
    rm pdftemp*
}
