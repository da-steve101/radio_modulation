import numpy as np

class SymbolsGenerator() :

    def __init__(self, out_file, bs_length) :
        self.out_file = out_file
        self.active_modulations = []
        self.symbols_str = {}
        self.num_symbols = {}
        self.bs_length = bs_length
        self.bitstream = self.make_bitstream(bs_length)

    def write_to_file(self) :
        with open(self.out_file,"w") as fp :

            fp.write("`ifndef _SYMBOLS_V_\n")
            fp.write("`define _SYMBOLS_V_\n\n")

            for mod in self.active_modulations :
                fp.write("// %s symbols\n" % (mod))
                fp.write("%s\n" % (self.symbols_str[mod]))

            fp.write("`endif // _SYMBOLS_V_\n")

    def make_bitstream(self,length) :
        bits = []
        for _ in range(length) :
            bits.append(np.random.randint(0,2))

        return bits

    def bs_iterator(self,bs,length,stride,func) :
        s = ""
        i_str = "{"
        q_str = "{"
        for i in range(0,length-stride,stride) :
            args = bs[i:(i+stride)]
            i, q = func(*args)
            i_str += str("%d," % (i))
            q_str += str("%d," % (q))
        args = bs[(length-stride):length]
        i, q = func(*args)
        i_str += str("%d}\n" % (i))
        q_str += str("%d}\n" % (q))
        s += i_str
        s += q_str
        return s

    def mem_gen(self,name) :

        # io
        s = str("module %s_mem(\n\tinput wire clk,\n\tinput wire rst,\n\t" % (name))
        s += str("input wire [15:0] rd_addr,\n\toutput reg [7:0] i,\n\toutput reg [7:0] q\n);\n")
        s += str("\n\tlocalparam NUM_WORDS = (1 << 16);\n")
        s += str("\n\treg [7:0] mem_i [0:NUM_WORDS-1];\n")
        s += str("\treg [7:0] mem_q [0:NUM_WORDS-1];\n")

        # rd_addr modulus to only send valid symbols
        s += str("\n\tlocalparam NUM_SYMBOLS = %d;\n" % (self.num_symbols[name]))
        s += str("\twire [15:0] rd_addr_mod = (rd_addr % NUM_SYMBOLS);\n")

        # sequential read logic
        s += str("\n\talways @ (posedge clk) begin\n")
        s += str("\t\tif (rst) begin\n")
        s += str("\t\t\ti <= 0;\n")
        s += str("\t\t\tq <= 0;\n")
        s += str("\t\tend else begin\n")
        s += str("\t\t\ti <= mem_i[rd_addr_mod];\n")
        s += str("\t\t\tq <= mem_q[rd_addr_mod];\n")
        s += str("\t\tend\n");
        s += str("\tend\n");

        return s

    def qpsk(self) :
        self.active_modulations.append('qpsk')
        num_symbols = self.bs_length // 2
        self.num_symbols['qpsk'] = num_symbols
        s = self.mem_gen("qpsk")

        def symbol_map(b0,b1) :

            smap = {
                '00' : [1,1],
                '01' : [-1,1],
                '10' : [1,-1],
                '11' : [-1,-1]
            }
            return smap[str("%s%s" % (b0,b1))]

        # initialize memory
        s += str("\n\tinitial begin\n")
        for i in range(num_symbols) :
            ival, qval = symbol_map(self.bitstream[(i*2)], self.bitstream[(i*2+1)])
            s += str("\t\tmem_i[%d] = $signed(%d); mem_q[%d] = $signed(%d);\n" % (i,ival,i,qval))
        s += str("\tend\n")

        s += str("\nendmodule\n")

        self.symbols_str['qpsk'] = s

    def M8psk(self) :
        self.active_modulations.append('8psk')
        num_symbols = self.bs_length // 3
        self.num_symbols['M8psk'] = num_symbols
        s = self.mem_gen("M8psk")

        def symbol_map(b0,b1,b2) :

            smap = {
                '000' : [1,0],
                '001' : [1,1],
                '010' : [1,-1],
                '011' : [0,1],
                '100' : [-1,-1],
                '101' : [-1,0],
                '110' : [0,-1],
                '111' : [-1,1]
            }
            return smap[str("%s%s%s" % (b0,b1,b2))]

        # initialize memory
        s += str("\n\tinitial begin\n")
        for i in range(num_symbols) :
            ival, qval = symbol_map(self.bitstream[(i*3)], self.bitstream[(i*3+1)], self.bitstream[(i*3+2)])
            s += str("\t\tmem_i[%d] = $signed(%d); mem_q[%d] = $signed(%d);\n" % (i,ival,i,qval))
        s += str("\tend\n")

        s += str("\nendmodule\n")

        self.symbols_str['8psk'] = s

    def bpsk(self) :
        self.active_modulations.append('bpsk')
        num_symbols = self.bs_length
        self.num_symbols['bpsk'] = num_symbols
        s = self.mem_gen("bpsk")

        def symbol_map(b0) :

            smap = {
                '0' : [-1,0],
                '1' : [1,0]
            }
            return smap[str("%s" % (b0))]

        # initialize memory
        s += str("\n\tinitial begin\n")
        for i in range(num_symbols) :
            ival, qval = symbol_map(self.bitstream[i])
            s += str("\t\tmem_i[%d] = $signed(%d); mem_q[%d] = $signed(%d);\n" % (i,ival,i,qval))
        s += str("\tend\n")

        s += str("endmodule\n")

        self.symbols_str['bpsk'] = s

if __name__ == "__main__" :

    sg = SymbolsGenerator("symbols.v",288)
    sg.qpsk()
    sg.bpsk()
    sg.M8psk()
    sg.write_to_file()
    print(''.join(str(n) for n in sg.bitstream))
