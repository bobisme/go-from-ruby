# Tell teh go tool link command not to create symbolic tables.
FLAGS := -ldflags -s

# If this is a Mac
ifeq ($(shell uname), Darwin)
	# Then use the .dylib extension.
	EXT := dylib
else
	# Otherwise we'll assume this is a Linux box and use .so.
	EXT := so
endif
# Nobody cares about Windows and the .dll

libsum.$(EXT): sum/sum.go
	go build $(FLAGS) -buildmode=c-shared -o $@ ./sum

all: libsum.$(EXT)

run: all
	bundle exec sum.rb
