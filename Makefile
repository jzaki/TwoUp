SRC = $(wildcard *.sol)

.PHONY: test outdir clean

all: outdir $(SRC:.sol=.bin)

%.bin: %.sol
	solc --overwrite --abi --bin --optimize = -o out/ $<

test:
	dapp --use solc:0.4.23 test

outdir:
	mkdir -p out

clean:
	rm -f out/*