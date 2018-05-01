.PHONY: test outdir clean

all: outdir dappbuild output

outdir:
	mkdir -p out

dappbuild:
	dapp --use solc:0.4.23 build

output:
	solc --overwrite --abi --bin --optimize = -o out/ src/twoUp.sol


test:
	dapp --use solc:0.4.23 test

clean:
	rm -f out/*