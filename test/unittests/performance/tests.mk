#
# this makefile can be use to build and run the entire suite 
#
#     make -f tests.mk SOLC=solc ETHVM=ethvm ETHVM-JIT=ethvm EVM=evm PARITY=parity-evm all
#
# or build and run only a single test on a single VM
#
#     make -f tests.mk SOLC=solc ETHVM=ethvm pop.ran
#
# or build but not run the entire suite 
#
#     make -f tests.mk SOLC=solc all
#
# or many other such possibilities

# the programs don't need to be at global scope
#
#     make -f tests.mk SOLC=solc ETHVM=../../../build/ethvm/ethvm all

# define a path to these programs on make command line to pick one or more of them to run
# the default is to do nothing
#
ifdef EVM
	EVM_ = $(call STATS,evm) $(EVM) --codefile $*.bin run; touch $*.ran
endif
ifdef PARITY
	PARITY_ = $(call STATS,parity) $(PARITY) stats --gas 10000000000 --code `cat $*.bin`; touch $*.ran
endif
ifdef SOLC
	SOLC_SOL_= $(SOLC) -o . --overwrite --asm --bin $*.sol 
	SOLC_ASM_= $(SOLC) --assemble $*.asm | grep '^[0-9a-f]\+$\' > $*.bin
endif
ifdef ETHVM
	ETHVM_ = $(call STATS,ethvm) $(ETHVM) test $*.bin; touch $*.ran
endif
ifdef ETHVM-JIT
	ETHVM_JIT_ = $(call STATS,ethvm-jit) $(ETHVM-JIT) --vm jit test $*.bin; touch $*.ran
endif
ifdef WAST
	WAST_ = $(call STATS,evm-wast) $(WAST) ./$*.wast; touch $*.ran
endif
ifdef WAVM
	WASM_ = $(call STATS,C-wasm) $(WASM) ./$*.wasm; touch $*.ran
endif

# Macs ignore or reject --format parameter
#STATS = time --format "stats: $(1) $* %U %M"
STATS = echo $(1); time -p

#
# to support new clients
#   *  add new calls here
#   *  add corresponding functions above
#   *  add corresponding .ran targets below
#
# .ran files are just empty targets that indicate a program ran
%.ran : %.bin
	$(call EVM_)
	$(call PARITY_)
	$(call ETHVM_)
	$(call ETHVM_JIT_)

%.ran : %.c
	gcc -O3 -S $*.c
	gcc -o $* $*.s
	$(call STATS,C) ./$*
	touch $*.ran

%.ran : %.wast
	$(call WAST_)

%.ran : %.wasm
	$(call WASM_)

# hold on to intermediate binaries until source changes
.PRECIOUS : %.bin

%.bin : %.asm
	$(call SOLC_ASM_)

%.bin : %.sol
	$(call SOLC_SOL_)


all : ops programs wast C wasm

# EVM assembly programs for timing individual operators
#
# for many purposes the raw times will suffice.  when more accurate estimates
# are wanted these formulas isolate the times for operators from the overhead
#   * t(nop) = user time for nop is just start up, shut down, and interpreter overhead
#   * t(pop) = user time for pop can be much less than big arithmetic OPs
#   * (t(OP) - (t(pop) + t(nop))/2)/N = estimated time per OP, less all overhead
# for all tests except exp N = 2**27, for exp N=2**17 and the last formula gets trickier
ops : \
	nop.ran \
	pop.ran \
	add64.ran \
	add128.ran \
	add256.ran \
	sub64.ran \
	sub128.ran \
	sub256.ran \
	mul64.ran \
	mul128.ran \
	mul256.ran \
	div64.ran \
	div128.ran \
	div256.ran \
	exp.ran

# Solidity programs for more realistic timing
programs : \
	loop.ran \
	fun.ran \
	rc5.ran \
	mix.ran \
	rng.ran

	
# EVM -> wast versions for comparison
wast : \
	rc5ew.ran \
	mixew.ran \
	rngew.ran

# C versions for comparison
C : \
	popincc.ran \
	poplnkc.ran \
	mul64c.ran \
	func.ran \
	rc5c.ran \
	mixc.ran \
	rngc.ran

# C -> wasm versions for comparison
wasm : \
	funcw.ran \
	rc5cw.ran \
	mixcw.ran \
	rngcw.ran

clean :
	rm *.ran *.bin *.evm *.s mul64c poplnkc popincc
	
rerun :
	rm *.ran
