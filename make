#! /bin/sh

case "$1" in
    gemini) GEMINI="1" && ASSETS="1"
    ;;
    html) PAGES="1" && ASSETS="1"
    ;;
    onlyassets) ASSETS="1"
    ;;
    *) GEMINI="1" && PAGES="1" && ASSETS="1"
    ;;
esac

pageroot=$2
echo "pageroot= $pageroot"

echo "======="

if [[ $ASSETS == "1" ]]; then
    echo "making build dirs and linking assets"
    cp -r assets build
    cp assets/images/favicon.ico build
fi

if [[ $PAGES == "1" ]]; then
    echo "Making html toc"
    zk list -x index.md --format '{{metadata.updated}}\t{{format-date created "%Y-%m-%d"}}\t{{title}}\t{{path}}' 2>/dev/null |
        awk -F'\t' '{ u=$1; c=$2; if(u=="") u=c; else u=substr(u,1,10); print u "\t" c "\t" $3 "\t" $4 }' |
        sort -r |
        awk -F'\t' 'BEGIN { print "| Title | Modified | Created |"; print "|---|---|---|" } { printf "| [%s](%s) | %s | %s |\n", $3, $4, $1, $2 }' |
        sed "s|](|]($pageroot/|g;s|\.md)|.html)|g" |
        pandoc -t html5 --template=templates/contents.html -V "pageroot=$pageroot" -s -o build/contents.html --wrap=preserve
    echo "Making html posts"
    find . -maxdepth 1 -name "20*" | sed "s/\.md//g;s/\.\///g" | xargs -I{} pandoc {}.md -f markdown -t html5 --template=templates/post.html -V "pageroot=$pageroot" -s -o build/{}.html --wrap=preserve --mathjax
    echo "Making html home"
    RECENT=$(zk list -x index.md --format '{{metadata.updated}}\t{{format-date created "%Y-%m-%d"}}\t{{title}}\t{{path}}' 2>/dev/null | awk -F'\t' '{ u=$1; c=$2; if(u=="") u=c; else u=substr(u,1,10); print u "\t" $3 "\t" $4 }' | sort -r | head -n 3 | awk -F'\t' '{ printf "- [%s](%s) (last edited: %s) \\n", $2, $3, $1 }')
    awk -v r="$RECENT" '{gsub("{{recent}}", r); print}' index.md |
        sed "s|](|]($pageroot/|g;s|\.md)|.html)|g" |
        pandoc -t html5 --template=templates/home.html -V "pageroot=$pageroot" -s -o build/index.html --wrap=preserve
    echo "Making html tag-list"
    ./maketag_html $pageroot | pandoc -t html5 --template=templates/tags.html -V "pageroot=$pageroot" -s -o build/tags.html --wrap=preserve 2> /dev/null
    echo "======="
    echo "Making rss"
    ./rss_feed > build/feed.xml
    echo "======="
    echo "Compressing html"
    ./minify -r -a build -o .
    echo "======="
fi
if [[ $GEMINI == "1" ]]; then
    echo "cleaning gemini build dir"
    rm -rf gemini
    mkdir gemini
    echo "Making gemini toc"
    zk list -s created- -qf oneline -x index.md -f json | jq ".[].link" -r | pandoc -t plain --template=templates/gemini_contents.gmi --lua-filter=filters/gemini.lua -o gemini/contents.gmi -s --wrap=preserve
    echo "Making gemini posts"
    find . -maxdepth 1 -name "20*" | sed "s/\.md//g;s/\.\///g" | xargs -I{} pandoc -i {}.md -f markdown -t plain --template=templates/gemini_post.gmi --lua-filter=filters/gemini.lua -o gemini/{}.gmi -s --wrap=preserve
    echo "Making gemini home"
    pandoc index.md -o gemini/index.gmi -t plain --template=templates/gemini_home.gmi --lua-filter=filters/gemini.lua -s --wrap=preserve
    echo "Making gemini tag-list"
    ./maketag_gemini | pandoc -t plain --template=templates/gemini_tags.gmi --lua-filter=filters/gemini.lua -o gemini/tags.gmi -s --wrap=preserve
    echo "======="
fi

