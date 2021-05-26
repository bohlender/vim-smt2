vim9script
const debug = false

# ------------------------------------------------------------------------------
# Ref: http://smtlib.cs.uiowa.edu/papers/smt-lib-reference-v2.6-r2021-05-12.pdf
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Token
# ------------------------------------------------------------------------------
const token_lparen = 0
const token_rparen = 1
const token_numeral = 2
const token_decimal = 3
const token_bv = 4
const token_string = 5
const token_symbol = 6
const token_keyword = 7
const token_comment = 8

def Token(kind: number, pos: number, lexeme: string): dict<any>
    return {kind: kind, pos: pos, lexeme: lexeme}
enddef

def TokenKind2Str(kind: number): string
    if kind == token_lparen
        return "LParen"
    elseif kind == token_rparen
        return "RParen"
    elseif kind == token_numeral
        return "Numeral"
    elseif kind == token_decimal
        return "Decimal"
    elseif kind == token_bv
        return "Bv"
    elseif kind == token_string
        return "String"
    elseif kind == token_symbol
        return "Symbol"
    elseif kind == token_keyword
        return "Keyword"
    elseif kind == token_comment
        return "Comment"
    else
        echoerr "Unexpected token kind: " .. kind # TODO: throw?
        return ''
    endif
enddef

def PrettyPrint(tokens: list<dict<any>>)
    def Rank(lhs: dict<any>, rhs: dict<any>): number
        return lhs.pos - rhs.pos
    enddef

    echo printf("%4s %8s %s", 'pos', 'kind', 'lexeme')
    for token in copy(tokens)->sort(Rank)
        echo printf("%4d %8s %s", token.pos, token.kind->TokenKind2Str(), token.lexeme)
    endfor
    echo "\n"
enddef

# ------------------------------------------------------------------------------
# Scanner
# ------------------------------------------------------------------------------
# TODO: Return token stream? Is a bit faster but complicates backtracking
# TODO: Add linenr to scanner
# TODO: Enforce restriction to ASCII? We should if we use the lookup table below
def Scanner(source: string): dict<any>
    return {
        chars: source->split('\zs'),
        pos: 0,
        at_eof: source->empty(),
        cur_char: source[0],
        cur_char_nr: source[0]->char2nr(),
        chars_len: strchars(source)}
enddef

def Scan(source: string): list<dict<any>>
    if source->empty()
        return []
    endif

    var scanner = Scanner(source)
    var tokens = []
    while !scanner.at_eof
        const c = scanner.cur_char
        const nr = scanner.cur_char_nr

        if nr->IsWhitespace()
            scanner->Next()
        elseif c == '('
            tokens->add(Token(token_lparen, scanner.pos, '('))
            scanner->Next()
        elseif c == ')'
            tokens->add(Token(token_rparen, scanner.pos, ')'))
            scanner->Next()
        elseif nr->IsStartOfSimpleSymbol()
            tokens->add(scanner->ReadSimpleSymbol())
        elseif c == '|'
            tokens->add(scanner->ReadQuotedSymbol())
        elseif c == ':'
            tokens->add(scanner->ReadKeyword())
        elseif nr->IsDigit()
            tokens->add(scanner->ReadNumber())
        elseif c == '#'
            tokens->add(scanner->ReadBv())
        elseif c == '"'
            tokens->add(scanner->ReadString())
        elseif c == ';'
            tokens->add(scanner->ReadComment())
        else
            scanner->Enforce(false, printf("unexpected character '%s'", c))
        endif
    endwhile
    return tokens
enddef

def Next(scanner: dict<any>)
    if debug | scanner->Enforce(!scanner.at_eof, "Already at EOF") | endif

    scanner.pos += 1
    scanner.at_eof = scanner.pos == scanner.chars_len
    scanner.cur_char = scanner.at_eof ? '' : scanner.chars[scanner.pos]
    scanner.cur_char_nr = scanner.cur_char->char2nr()
enddef

def Enforce(scanner: dict<any>, expr: bool, msg: string)
    if !expr
        throw printf("Scanner error: %s (pos: %d)", msg, scanner.pos)
    endif
enddef

# ------------------------------------------------------------------------------
# <white_space_char> ::= 9 (tab), 10 (lf), 13 (cr), 32 (space)
# ------------------------------------------------------------------------------
def IsWhitespace(char_nr: number): bool
    return char_nr == 32 || char_nr == 9 || char_nr == 10 || char_nr == 13
enddef

# ------------------------------------------------------------------------------
# A comment is any character sequence not contained within a string literal or a
# quoted symbol that begins with ; and ends with the first subsequent
# line-breaking character, i.e. 10 (lf) or 13 (cr)
# ------------------------------------------------------------------------------
def ReadComment(scanner: dict<any>): dict<any>
    if debug | scanner->Enforce(scanner.cur_char == ';', "Not the start of a comment") | endif

    const start_pos = scanner.pos
    scanner->Next()
    while !scanner.at_eof && scanner.cur_char_nr != 10 && scanner.cur_char_nr != 13
        scanner->Next()
    endwhile
    return Token(token_comment, start_pos, scanner.chars[start_pos : scanner.pos - 1]->join(''))
enddef

# ------------------------------------------------------------------------------
# <numeral> ::= 0
#             | a non-empty sequence of digits not starting with 0
#
# <decimal> ::= <numeral>.0*<numeral>
# ------------------------------------------------------------------------------
def IsDigit(char_nr: number): bool
    # '0'->char2nr() == 48 && '9'->char2nr() == 57
    return 48 <= char_nr && char_nr <= 57
enddef

def ReadNumber(scanner: dict<any>): dict<any>
    if debug | scanner->Enforce(scanner.cur_char_nr->IsDigit(), "Not the start of a number") | endif

    const starts_with_zero = scanner.cur_char == '0'
    const start_pos = scanner.pos
    scanner->Next()
    # TODO: Be strict about numbers not starting with 0 when not debugging?
    if debug | scanner->Enforce(!starts_with_zero || scanner.cur_char != '0', "Numeral may not start with 0") | endif

    var is_decimal = false
    while !scanner.at_eof
        const nr = scanner.cur_char_nr
        if 48 <= nr && nr <= 57 # inlined IsDigit
            scanner->Next()
        elseif scanner.cur_char == '.'
            if is_decimal
                break
            else
                is_decimal = true
                scanner->Next()
            endif
        else
            break
        endif
    endwhile
    const kind = is_decimal ? token_decimal : token_numeral
    return Token(kind, start_pos, scanner.chars[start_pos : scanner.pos - 1]->join(''))
enddef

# ------------------------------------------------------------------------------
# <hexadecimal> ::= #x followed by a non-empty sequence of digits and letters
#                   from A to F, capitalized or not
#
# <binary> ::= #b followed by a non-empty sequence of 0 and 1 characters
# ------------------------------------------------------------------------------

# Build lookup table for char->match('\m\C^[0-9a-fA-F]')
def InitIsAlphaNumericCharNr(): list<bool>
    var lookup_table = []
    var char_nr = 0
    while char_nr < 255
        lookup_table[char_nr] = char_nr->nr2char()->match('\m\C^[0-9a-fA-F]') != -1
        char_nr += 1
    endwhile
    return lookup_table
enddef
const is_alphanumeric_char_nr = InitIsAlphaNumericCharNr()

def ReadBv(scanner: dict<any>): dict<any>
    if debug | scanner->Enforce(scanner.cur_char == '#', "Not the start of a bit vector literal") | endif

    const start_pos = scanner.pos
    scanner->Next()
    if scanner.cur_char == 'x'
        scanner->Next()
        scanner->Enforce(!scanner.at_eof && is_alphanumeric_char_nr[scanner.cur_char_nr],
            "hexadecimal literal may not be empty")
        while !scanner.at_eof && is_alphanumeric_char_nr[scanner.cur_char_nr]
            scanner->Next()
        endwhile
    elseif scanner.cur_char == 'b'
        scanner->Next()
        # '0'->char2nr() == 48 && '1'->char2nr() == 49
        scanner->Enforce(!scanner.at_eof && scanner.cur_char_num == 48 || scanner.cur_char_num == 49,
            "binary literal may not be empty")
        while !scanner.at_eof && scanner.cur_char_num == 48 || scanner.cur_char_num == 49
            scanner->Next()
        endwhile
    else
        scanner->Enforce(false, "invalid bit vector literal -- expected 'x' or 'b'")
    endif
    return Token(token_bv, start_pos, scanner.chars[start_pos : scanner.pos - 1]->join(''))
enddef


# ------------------------------------------------------------------------------
# <string> ::= sequence of whitespace and printable characters in double
#              quotes with escape sequence ""
# ------------------------------------------------------------------------------
# TODO: Allow only printable characters, i.e. ranges [32, 126], [128-255]?
def ReadString(scanner: dict<any>): dict<any>
    if debug | scanner->Enforce(scanner.cur_char == '"', "Not the start of a string") | endif

    const start_pos = scanner.pos
    scanner->Next()
    while true
        scanner->Enforce(!scanner.at_eof, "unexpected end of string")

        if scanner.cur_char == '"'
            scanner->Next()
            if scanner.cur_char != '"'
                return Token(token_string, start_pos, scanner.chars[start_pos : scanner.pos - 1]->join(''))
            endif
        endif
        scanner->Next()
    endwhile
    return {} # Unreachable
enddef

# ------------------------------------------------------------------------------
# <simple symbol> ::= a non-empty sequence of letters, digits and the characters
#                     + - / * = % ? ! . $ _ ~ & ^ < > @ that does not start with
#                     a digit
# ------------------------------------------------------------------------------

# Build lookup table for char->match('\m\C^[a-zA-Z0-9+-/*=%?!.$_~&^<>@]')
def InitIsSimpleSymbolCharNr(): list<bool>
    var lookup_table = []
    var char_nr = 0
    while char_nr < 255
        lookup_table[char_nr] = char_nr->nr2char()->match('\m\C^[a-zA-Z0-9+-/*=%?!.$_~&^<>@]') != -1
        char_nr += 1
    endwhile
    return lookup_table
enddef
const is_simple_symbol_char_nr = InitIsSimpleSymbolCharNr()

def IsStartOfSimpleSymbol(char_nr: number): bool
    # '0'->char2nr() == 48 && '9'->char2nr() == 57
    return is_simple_symbol_char_nr[char_nr] && !(48 <= char_nr && char_nr <= 57)
enddef

def ReadSimpleSymbol(scanner: dict<any>): dict<any>
    if debug | scanner->Enforce(scanner.cur_char_nr->IsStartOfSimpleSymbol(), "Not the start of a simple symbol") | endif

    const start_pos = scanner.pos
    scanner->Next()
    while !scanner.at_eof && is_simple_symbol_char_nr[scanner.cur_char_nr]
        scanner->Next()
    endwhile
    return Token(token_symbol, start_pos, scanner.chars[start_pos : scanner.pos - 1]->join(''))
enddef

# ------------------------------------------------------------------------------
# <symbol> ::= <simple symbol>
#            | a sequence of whitespace and printable characters that starts
#              and ends with '|' and does not otherwise include '|' or '\'
# ------------------------------------------------------------------------------
# TODO: Allow only printable characters, i.e. ranges [32, 126], [128-255]?
def ReadQuotedSymbol(scanner: dict<any>): dict<any>
    if debug | scanner->Enforce(scanner.cur_char == '|', "Not the start of a quoted symbol") | endif

    const start_pos = scanner.pos
    scanner->Next()
    while scanner.cur_char != '|'
        scanner->Enforce(!scanner.at_eof, "unexpected end of quoted symbol")
        scanner->Enforce(scanner.cur_char != '\\', "quoted symbol may not contain '\'")
        scanner->Next()
    endwhile
    scanner->Next()
    return Token(token_symbol, start_pos, scanner.chars[start_pos : scanner.pos - 1]->join(''))
enddef

# ------------------------------------------------------------------------------
# <keyword> ::= :<simple symbol>
# ------------------------------------------------------------------------------
def ReadKeyword(scanner: dict<any>): dict<any>
    if debug | scanner->Enforce(scanner.cur_char == ':', "Not the start of a keyword") | endif

    const start_pos = scanner.pos
    scanner->Next()
    while !scanner.at_eof && is_simple_symbol_char_nr[scanner.cur_char_nr]
        scanner->Next()
    endwhile
    return Token(token_keyword, start_pos, scanner.chars[start_pos : scanner.pos - 1]->join(''))
enddef

# ------------------------------------------------------------------------------
# Public functions
# ------------------------------------------------------------------------------
def smt2#scanner#ScanSource(source: string): list<dict<any>>
    const tokens = Scan(source)

    if debug | tokens->PrettyPrint() | endif
    return tokens
enddef
