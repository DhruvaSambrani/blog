#! /bin/sh

echo "cleaning gemini build dir"
rm -rf gemini

echo "making build dirs and linking assets"
mkdir gemini
cp -r ../assets build

echo "making html toc"
find . -maxdepth 1 -name "20*" | sed "s/\.md//g;s/\.\///g" | xargs -I{} echo "- [{}](/{}.html)" | pandoc -t html5 --template=templates/random.html -o build/random.html -s
echo "making gemini toc"
find . -maxdepth 1 -name "20*" | sed "s/\.md//g;s/\.\///g" | xargs -I{} echo "=> /{}.gmi {}" | pandoc -t plain --template=templates/gemini_contents.gmi --lua-filter=filters/gemini.lua -o gemini/contents.gmi -s

echo "making html posts"
find . -maxdepth 1 -name "20*" | sed "s/\.md//g;s/\.\///g" | xargs -I{} pandoc {}.md -f markdown -t html5 --template=templates/post.html -s --highlight-style=breezedark -o build/{}.html
echo "making gemini posts"
find . -maxdepth 1 -name "20*" | sed "s/\.md//g;s/\.\///g" | xargs -I{} pandoc {}.md -f markdown -t plain --template=templates/gemini_post.gmi --lua-filter=filters/gemini.lua -o gemini/{}.gmi -s

echo "making html home"
pandoc index.md -o build/index.html -t html5 --template=templates/home.html -s
echo "making gemini home"
pandoc index.md -o gemini/index.gmi -t plain --template=templates/gemini_home.gmi --lua-filter=filters/gemini.lua -s
