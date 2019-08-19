all : rtl

rtl :
	@mkdir -p bin;iverilog -o./bin/$@ src/symbols.v src/AXILite.v src/Modulators.v src/Top.v tb/tb.v

.PHONY : clean

clean :
	@rm -rf bin

