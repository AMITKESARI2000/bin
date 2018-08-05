#!/usr/local/bin/python2.7
import sys


class Cmd_arithmetic:

    def __init__(self, code):
        self.code = code
        self.counter = -1

    def generate(self):
        self.counter += 1
        return self.code.replace('%d', str(self.counter))


class Cmd_push:
    def __init__(self, code):
        self.code = code
        self.segment = 'constant'
        self.index = 0

    def generate(self):
        code = self.code
        if self.segment == 'constant':
            code = '    @' + str(self.index) + '\n' + self.code
        return code


cmd_add = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=M     // D is value at top of the stack
    @SP
    A=M-1   // Point to next highest on stack
    M=D+M   // Add D to that guy
"""
)

cmd_sub = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=M     // D is value at top of the stack
    @SP
    A=M-1   // Point to next highest on stack
    M=D-M   // Sub that guy from D
"""
)

cmd_neg = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=-M    // D is value at top of the stack
    M=D
    @SP
    M=M+1
"""
)

cmd_eq = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=M     // D is value at top of the stack
    @SP
    A=M-1   // Point to next highest on stack
    D=D-M   // Sub that guy from D
    @EQ_DONE_%d
    D;JNE   // D is set to false (0) & will be pushed to the stack
(EQ_NOT_EQ_%d)
    @0
    D=A-1   // D is set to true (-1)
    @EQ_DONE_%d
    0;JMP
(EQ_DONE_%d)
    @SP
    M=M-1
    A=M
    M=D
    @SP
    M=M+1
    A=M
"""
)

cmd_lt = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=M     // D is value at top of the stack
    @SP
    A=M-1   // Point to next highest on stack
    D=D-M   // Sub that guy from D
    @LT_DONE_%d
    D;JGE   // D is set to false (0) & will be pushed to the stack
(LT_NOT_LT_%d)
    @0
    D=A-1   // D is set to true (-1)
    @LT_DONE_%d
    0;JMP
(LT_DONE_%d)
    @SP
    M=M-1
    A=M
    M=D
    @SP
    M=M+1
    A=M
"""
)

cmd_gt = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=M     // D is value at top of the stack
    @SP
    A=M-1   // Point to next highest on stack
    D=D-M   // Sub that guy from D
    @GT_DONE_%d
    D;JLE   // D is set to false (0) & will be pushed to the stack
(GT_NOT_GT_%d)
    @0
    D=A-1   // D is set to true (-1)
    @GT_DONE_%d
    0;JMP
(GT_DONE_%d)
    @SP
    M=M-1
    A=M
    M=D
    @SP
    M=M+1
    A=M
"""
)

cmd_and = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=M     // D is value at top of the stack
    @SP
    A=M-1   // Point to next highest on stack
    M=D&M   // Add D to that guy
"""
)

cmd_or = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=M     // D is value at top of the stack
    @SP
    A=M-1   // Point to next highest on stack
    M=D|M   // Add D to that guy
"""
)

cmd_not = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=!M    // D is value at top of the stack
    M=D
    @SP
    M=M+1
"""
)

cmd_push = Cmd_push(
    """    D=A
    @SP
    A=M
    M=D
    @SP
    M=M+1
"""
)

def parse(line):
    # strip comments
    no_comments = line.split('#', 1)[0]
    no_comments = no_comments.split('//', 1)[0]
    tokens = no_comments.split()
    return (tokens)


def writecode(tokens):
    if not tokens:
        return
    asm_file.write('//')
    for token in tokens:
        asm_file.write(' ' + str(token))
    asm_file.write('\n')
    if tokens[0] == 'add':
        asm_file.write(cmd_add.generate())
    if tokens[0] == 'sub':
        asm_file.write(cmd_sub.generate())
    if tokens[0] == 'neg':
        asm_file.write(cmd_neg.generate())
    if tokens[0] == 'eq':
        asm_file.write(cmd_eq.generate())
    if tokens[0] == 'lt':
        asm_file.write(cmd_lt.generate())
    if tokens[0] == 'gt':
        asm_file.write(cmd_gt.generate())
    if tokens[0] == 'and':
        asm_file.write(cmd_and.generate())
    if tokens[0] == 'or':
        asm_file.write(cmd_or.generate())
    if tokens[0] == 'not':
        asm_file.write(cmd_not.generate())
    if tokens[0] == 'push':
        cmd_push.segment = tokens[1]
        cmd_push.index = tokens[2]
        asm_file.write(cmd_push.generate())

def banner():
    asm_file.write(
"""
//
// Brian Cunnie's output for Nand to Tetris
//
""")

cmd_name = sys.argv[0].split('/')[-1]

if len(sys.argv) != 2:
    sys.exit(cmd_name + " error: pass me one arg, the name of the file to compile")

intermediate_filename = sys.argv[1]

try:
    intermediate_code = open(intermediate_filename, "r")
except:
    sys.exit(cmd_name + " error. I couldn't open " + intermediate_filename + " for reading!")

asm_filename = intermediate_filename.replace('.vm', '.asm')

if intermediate_filename == asm_filename:
    asm_filename += ".asm"

try:
    asm_file = open(asm_filename, "w")
except:
    sys.exit(cmd_name + " error. I couldn't open " + asm_filename + " for writing!")

banner()
for line in intermediate_code:
    x = parse(line)
    writecode(x)
