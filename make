#! /bin/sh

case "$1" in
    gemini) GEMINI="1"
    ;;
    ghpages) PAGES="1"
    ;;
    *) GEMINI="1" && PAGES="1"
    ;;
esac

pageroot="/newblog"

echo "======="

if [[ $PAGES == "1" ]]; then
    echo "making build dirs and linking assets"
    cp -r assets build
    cp assets/images/favicon.ico build
    echo "Making html toc"
    zk list -s created- -qf oneline -x index.md -f json | jq "\"- \"+.[].link" -r | pandoc -t html5 --template=templates/contents.html -V "pageroot=$pageroot" -s -o build/contents.html --wrap=preserve
    echo "Making html posts"
    find . -maxdepth 1 -name "20*" | sed "s/\.md//g;s/\.\///g" | xargs -I{} pandoc {}.md -f markdown -t html5 --template=templates/post.html -V "pageroot=$pageroot" -s --highlight-style=breezedark -o build/{}.html --wrap=preserve
    echo "Making html home"
    pandoc index.md -o build/index.html -t html5 --template=templates/home.html -s -V "pageroot=$pageroot" --wrap=preserve
    echo "Making html tag-list"
    ./maketag_html | pandoc -o build/tags.html -t html5 --template=templates/tags.html --wrap=preserve
    echo "Compressing html"
    ./minify -r -a build -o .
    echo "======="
    echo "Making rss"
    ./rss_feed > build/feed.xml
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

