
TARGET_SCRIPT=./grid-window.sh

all: git

git: TODO README
	git commit -m'update by Makefile'

TODO: $(TARGET_SCRIPT)
	grep -E 'TODO' $(TARGET_SCRIPT) > TODO
	git add TODO

README: $(TARGET_SCRIPT)
	$(TARGET_SCRIPT) > README
	git add README

clean:
	rm README TODO
