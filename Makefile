VERSION=0.4

all:
	haxe -cp lib -cp demos -main Test -neko test.n

haxelib: clean
	-rm lib.zip
	zip -r lib lib -x \*svn*

package: clean
	cd .. && tar --exclude=".git" --exclude="*.zip" --exclude="*.n" --exclude="*.js" --exclude=".svn" --exclude=".*.swp" -zcvf memcached-$(VERSION).tgz memcached
	mv ../memcached-$(VERSION).tgz .

clean:
	-rm *.n
	-rm *.tgz

