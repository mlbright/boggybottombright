default: compile lint

compile:
	perl -c *.pl
lint:
	perltidy -b *.pl && rm *.bak

run: encrypt compile lint
	perl decrypt.pl cipher.txt plain.txt american-english

encrypt:
	perl -p -e 'tr/a-z/k-za-j/' < plain.txt > cipher.txt
	perl -p -e 'tr/a-z/k-za-j/' < simple-plain.txt > simple-cipher.txt
	perl -p -e 'tr/a-z/k-za-j/' < qbf-plain.txt > qbf-cipher.txt
	perl -p -e 'tr/a-z/k-za-j/' < enhanced-qbf-plain.txt > enhanced-qbf-cipher.txt

clean:
	git clean -fxd
