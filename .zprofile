alias beluga='~/Clones/Beluga/bin/beluga'
alias harpoon='~/Clones/Beluga/bin/beluga +implicit -I'
alias python='python3'
alias opythn='~/Github/opythn/main'

alias skim='/Applications/Skim.app/Contents/MacOS/Skim'

alias rer='source ranger'
export PATH="$PATH:/usr/local/smlnj/bin"

eval `opam env`

# Functions for references

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
        /^$/||/^%[ATJVLPDOBREICYQ]/ { print $0 }\
    ' ./ref.tmp |
    # This pass assigns a number to each field; %K gets a very small value.
    awk 'BEGIN { count=0 }\
        $0 == "" { count += 1 ; p=-40 }\
        $1 == "%K" { p=-20 }\
        $1 == "%Q" { p=-10 }\
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
    awk '$1 == "%Q" { print $0 ; print "%Z " $2 ; next }\
        { print $0 }' |
    awk 'BEGIN { ac = 0 }\
        $0 == "" { print "" }
        $1 == "%K" { authorindex = 0 ; totalauthor=$2 ; tslanted=$3 ; city=$4 ; pages=$5 }\
        $1 == "%A" { authorindex += 1 }\
        $1 != "%K" && $0 != "" { print tslanted " " totalauthor " " authorindex " " city " " pages " " $0 }\
    ' |
    # Result of previous pass is that
    # $1 = tslanted; $2 = total no. of authors; $3 = index of this author;
    # $4 = city flag; $5 pages flag; $6 = %_ marker.
    awk 'match($0,"%O") == 0 && match($0,"%Q") == 0 && match($0,"%Z") == 0 { print $0 "," ; next }\
         { print $0 }' | # Add a comma to every line, except %O, %Q, and %Z lines.
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
    sed '/%Q/s/%Q /%Q \\parindent=20pt\\item{\\bref{/' |    # Q-tags get an \item{\bref{}} macro
    sed "/%Q/s/$/}}/" |
    sed '/%Z/s/%Z /%Z \\hldest{xyz}{}{bib/' |    # Z-tags get a \hldest macro
    sed "/%Z/s/$/}%/" |
    # Add `and' before last author
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
    \\def\\bref#1{[#1]}\
    \\def\\beginref{\\noindent\
    }\
    \\def\\endref{\\medskip}\
    \\vskip\\parskip\
    \
    \\beginref ' |
    sed '/\\beginref $/d' |
    sed '/\\beginref \\endref$/d'

    if test -f ./ref.tmp; then
        rm ./ref.tmp
    fi
}

# All references in $1.ref that don't appear in $1.tex are removed.
# The remaining references are sorted, numbered, and then all
# the tags are replaced with the corresponding number in $1.tex and $1.ref.
# These two files can safely be fed into bb.

numberrefs() {
    if test -f ./ref.tmp
        then rm ./ref.tmp
        fi
    cp "$1.tex" "$1.texbak"
    echo '\\def\\ref#1{[#1]}' > "$1.tex"
    echo '\\def\\hldest#1#2#3{}' > "$1.tex"
    cat "$1.texbak" >> "$1.tex"

    echo "" >> "$1.ref"

    # Number the entries and surround entries with ENTRY [n] [...] YRTNE [n]
    awk 'BEGIN { count=0 ; inpara=0 ; foundq=0 ; q=""}\
         $1 == "%Q" { foundq=1 ; q=$2 }\
         inpara == 0 && $0 != "" { inpara=1 ; count+=1 ; print "ENTRY " count ; print $0 ; next }\
         $0 == "" && inpara == 1 { inpara=0 ; print "YRTNE " count ; print $0 ; next }\
         { print $0 }' $1.ref > ./ref.tmp

    # cat ./ref.tmp
    cp ./ref.tmp "$1.ref"
    # Mark entries whose references actually appear in $1.tex with FOUNDENTRY
    curridx=0
    keyword=""
    while IFS= read -r line; do
        firstword=$(echo $line | awk '{ print $1 }')
        if [[ "$firstword" == "ENTRY" ]]; then
            curridx=$(echo $line | awk '{ print $2 }')
            fi
        if [[ "$firstword" == "%Q" ]]; then
            keyword=$(echo $line | awk '{ print $2 }')
            # echo $keyword
            if grep -q "ref{$keyword}" "$1.tex"; then
                # echo "found $keyword"
                sed -i '' "s/^ENTRY $curridx$/FOUNDENTRY $curridx/g" "$1.ref"
            fi
        fi
    done < ./ref.tmp

    # cat "$1.ref"
    cp "$1.ref" ./ref.tmp
    # Delete all lines except %lines that appear between FOUNDENTRY and YRTNE
    awk 'BEGIN { del=1 }\
         $1 == "FOUNDENTRY" { del=0 ; next }\
         $1 == "YRTNE" { del=1 }\
         $0 == "" || del == 0 { print $0 }' ./ref.tmp > "$1.ref"
    sortbibnameA "$1.ref" | sed '/\\0/s// /g' > ./ref.tmp

    curridx=0
    inpara=0
    while IFS= read -r line; do
        firstword=$(echo $line | awk '{ print $1 }')
        if [[ "$line" != "" ]] && test $inpara -eq 0; then
            inpara=1
            curridx=$((curridx+1))
        elif [[ "$line" == "" ]] && test $inpara -eq 1; then
            inpara=0
            fi
        if [[ "$firstword" == "%Q" ]]; then
            keyword=$(echo $line | awk '{ print $2 }')
            sed -i '' "s/%Q $keyword/%Q $curridx/g" "$1.ref"
            sed -i '' "s/\\ref{$keyword}/\\ref{$curridx}/g" "$1.tex"
            sed -i '' "s/\\bref{$keyword}/\\bref{$curridx}/g" "$1.tex"
            sed -i '' "s/\\hldest{xyz}{}{bib$keyword}/\\hldest{xyz}{bib{$curridx}/g" "$1.tex"
        fi
    done < ./ref.tmp
}

# Convert a TeX file to PDF. -r adds the references (by calling bb)
# Written by Marcel Goh
pdf() {
    refs=0
    num=0
    out=0
    while test $# -gt 0; do
        case "$1" in
            -n)
                shift
                num=1
                ;;
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

    if test -f "./$1out.tex"
        then rm "./$1out.tex"
        fi

    cat "$1".tex > pdftemp.tex
    if test $num -eq 1 || test $refs -eq 1; then
        cat "$1".ref > pdftemp.ref
    fi
    if test $num -eq 1; then
        numberrefs pdftemp
    elif test $refs -eq 1; then
        awk '$1 != "%Q" { print $0 }' pdftemp.ref > ./ref.tmp &&
            mv ./ref.tmp pdftemp.ref
    fi
    if test $refs -eq 1; then
        bb pdftemp.ref >> pdftemp.tex
        sed -i '' 's/\\bye//g' pdftemp.tex
        echo '\\goodbreak\
        \\bye' >> pdftemp.tex
    else
        if test -f "$1.idx"; then
            cat "$1".idx > pdftemp.idx
        fi
        if test -f "$1.scn"; then
            cat "$1".scn > pdftemp.scn
        fi
    fi

    tex pdftemp.tex -jobname "$1" && dvips -z pdftemp.dvi
    sed -i "" "s/\[1 1 1 \[/\[0 0 0 \[/g" pdftemp.ps  # gets rid of boxes
    ps2pdf pdftemp.ps
    mv pdftemp.ps "$1".ps
    mv pdftemp.pdf "$1".pdf
    if test $out -eq 1; then
        mv pdftemp.tex "$1"out.tex
    fi
    rm pdftemp*
}


## Macaulay 2 start
if [ -f ~/.profile-Macaulay2 ]
then . ~/.profile-Macaulay2
fi
## Macaulay 2 end
