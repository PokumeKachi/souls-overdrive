local __DARKLUA_BUNDLE_MODULES = {cache = {}}

do
    do
        local function __modImpl()
            local IS_ROBLOX = (game ~= nil)
            local stdio
            local process

            if not IS_ROBLOX then
                stdio = require('@lune/stdio')
                process = require('@lune/process')
            end

            local SpecialSymbols = {
                CLI = {
                    Line = '\u{2500}',
                    Down = '\u{2502}',
                    DownDash = '\u{2506}',
                    Cross = '\u{252c}',
                    RightUp = '\u{256d}',
                    LeftDown = '\u{256f}',
                    RightDown = '\u{2570}',
                },
                ROBLOX = {
                    Line = '-',
                    Down = '|',
                    DownDash = ' ',
                    Cross = '-',
                    RightUp = '\u{256d}',
                    LeftDown = '\u{256f}',
                    RightDown = '\u{2570}',
                },
            }
            local Colors = {
                black = 'rgb(0, 0, 0)',
                blue = 'rgb(0, 0, 255)',
                cyan = 'rgb(0, 255, 255)',
                green = 'rgb(0, 255, 0)',
                purple = 'rgb(163, 44, 196)',
                red = 'rgb(255, 0, 0)',
                white = 'rgb(255, 255, 255)',
                yellow = 'rgb(255, 255, 0)',
            }
            local Compact = false
            local Error = {
                OnEmit = nil,
                LexerUnexpectedToken = 1001,
                ParserUnexpectedEndOfFile = 2001,
                ParserUnexpectedToken = 2002,
                ParserUnknownOption = 2003,
                ParserUnexpectedSymbol = 2004,
                ParserExpectedExtraToken = 2005,
                AnalyzeReferenceInvalidType = 3001,
                AnalyzeInvalidOptionalType = 3002,
                AnalyzeNestedMap = 3003,
                AnalyzeDuplicateField = 3004,
                AnalyzeReservedIdentifier = 3005,
                AnalyzeNestedScope = 3006,
                AnalyzeUnknownReference = 3007,
                AnalyzeInvalidRangeType = 3008,
                AnalyzeInvalidRange = 3009,
                AnalyzeDuplicateDeclaration = 3010,
                AnalyzeDuplicateTypeGeneric = 3011,
                AnalyzeInvalidGenerics = 3012,
                AnalyzeInvalidExport = 3013,
                AnalyzeUnknownImport = 3014,
                AnalyzeErrorWhileImporting = 3015,
                AnalyzeOptionAfterStart = 3016,
            }

            Error.__index = Error

            local Symbols = IS_ROBLOX and SpecialSymbols.ROBLOX or SpecialSymbols.CLI

            local function Color(Text, Color)
                if IS_ROBLOX then
                    return `<font color="{Colors[Color]}">{Text}</font>`
                end

                return `{stdio.color(Color)}{Text}{stdio.color('reset')}`
            end
            local function Style(Text, Style)
                if IS_ROBLOX then
                    return Text
                end

                return `{stdio.style(Style)}{Text}{stdio.style('reset')}`
            end

            function Error.SetCompact(Value)
                Compact = Value
            end
            function Error.GetNameFromCode(From)
                for Name, Code in Error do
                    if Code == From then
                        return Name
                    end
                end

                error(`Unknown error code: {From}`)
            end
            function Error.new(Code, Source, Message, File)
                local Lines = string.split(Source, '\n')
                local Content = `{Color(`[E{string.format('%04i', Code)}] Error`, 'red')}: {Message}`

                Content ..= `\n    {Symbols.RightUp}{Symbols.Line}[{File or 'input.blink'}:1:{#Lines}]`
                Content ..= `\n    {Symbols.Down}`

                return setmetatable({
                    Labels = {},
                    Source = Lines,
                    Message = Content,
                    Code = Code,
                    File = File or 'input.blink',
                    RawMessage = Message,
                }, Error)
            end
            function Error.Slice(self, Span)
                local Slices = {}
                local Cursor = 1

                for Line, Text in self.Source do
                    local Start = Cursor
                    local Length = #Text

                    Cursor += (Length + 1)

                    if Span.Start > Cursor then
                        continue
                    end

                    local Spaces = (Span.Start - Start)
                    local Underlines = math.clamp(Span.End - Span.Start, 1, Length)

                    table.insert(Slices, {
                        Line = Line,
                        Text = Text,
                        Spaces = Spaces,
                        Underlines = Underlines,
                    })

                    if Span.End <= Cursor then
                        break
                    end
                end

                return Slices
            end
            function Error.Label(self, Span, Text, TextColor)
                local Slices = self:Slice(Span)

                table.insert(self.Labels, {
                    Span = Span,
                    Text = Text,
                })

                for Index, Slice in Slices do
                    self.Message ..= `\n{Style(string.format('%03i', Slice.Line), 'dim')} {Symbols.Down} {Slice.Text}`

                    if Index == #Slices then
                        local Length = (Slice.Underlines // 2)
                        local Indent = `    {Symbols.DownDash} {string.rep(' ', Slice.Spaces)}`
                        local Underlines = Color(string.rep(Symbols.Line, Length), TextColor)
                        local ExtraIndent = string.rep(' ', Length)

                        self.Message ..= `\n{Indent}{Underlines}{Color(Symbols.Cross, TextColor)}{Underlines}`
                        self.Message ..= `\n{Indent}{ExtraIndent}{Color(Symbols.Down, TextColor)}`
                        self.Message ..= `\n{Indent}{ExtraIndent}{Color(`{Symbols.RightDown}{Symbols.Line}{Symbols.Line}`, TextColor)} {Color(Text, TextColor)}`
                    end
                end

                return self
            end
            function Error.Primary(self, Span, Text)
                self.PrimarySpan = Span

                return self:Label(Span, Text, 'red')
            end
            function Error.Secondary(self, Span, Text)
                return self:Label(Span, Text, 'blue')
            end
            function Error.Emit(self)
                self.Message ..= `\n    {Symbols.Down}`
                self.Message ..= `\n{string.rep(Symbols.Line, 4)}{Symbols.LeftDown}\n`

                if IS_ROBLOX or true == nil then
                    local OnEmit = Error.OnEmit

                    if OnEmit then
                        OnEmit(self)
                    end

                    error(self.Message, 2)
                elseif stdio and process then
                    if Compact then
                        local LineStart = 0
                        local LineFinish = 0

                        if self.PrimarySpan then
                            local Slices = self:Slice(self.PrimarySpan)

                            LineStart = Slices[1].Line
                            LineFinish = Slices[#Slices].Line
                        end

                        stdio.ewrite(string.format('[E%04i] [L%03i:L%03i] [%s] Error: %s', self.Code, LineStart, LineFinish, self.File, self.RawMessage))
                    else
                        stdio.ewrite(self.Message)
                    end
                    if _G.WATCH_THREAD then
                        error(self.RawMessage)
                    else
                        process.exit(1)
                    end
                end

                error('never')
            end

            return Error
        end

        function __DARKLUA_BUNDLE_MODULES.a()
            local v = __DARKLUA_BUNDLE_MODULES.cache.a

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.a = v
            end

            return v.c
        end
    end
    do
        local function __modImpl()
            local NumberRange = {
                new = function(Min, Max)
                    return {
                        Min = Min,
                        Max = Max or Min,
                    }
                end,
            }
            local Indexes = {
                Pascal = 1,
                Camel = 2,
                Snake = 3,
            }
            local Cases = {
                On = {
                    'On',
                    'on',
                    'on',
                },
                Invoke = {
                    'Invoke',
                    'invoke',
                    'invoke',
                },
                Fire = {
                    'Fire',
                    'fire',
                    'fire',
                },
                FireAll = {
                    'FireAll',
                    'fireAll',
                    'fire_all',
                },
                FireList = {
                    'FireList',
                    'fireList',
                    'fire_list',
                },
                FireExcept = {
                    'FireExcept',
                    'fireExcept',
                    'fire_except',
                },
                StepReplication = {
                    'StepReplication',
                    'stepReplication',
                    'step_replication',
                },
                Next = {
                    'Next',
                    'next',
                    'next',
                },
                Iter = {
                    'Iter',
                    'iter',
                    'iter',
                },
                Read = {
                    'Read',
                    'read',
                    'read',
                },
                Write = {
                    'Write',
                    'write',
                    'write',
                },
            }
            local Primitives = {
                u8 = {
                    Bounds = NumberRange.new(0, 255),
                    Integer = true,
                    Component = true,
                    AllowsRange = true,
                    AllowsOptional = true,
                    AllowedComponents = 0,
                },
                u16 = {
                    Bounds = NumberRange.new(0, 65535),
                    Integer = true,
                    Component = true,
                    AllowsRange = true,
                    AllowsOptional = true,
                    AllowedComponents = 0,
                },
                u32 = {
                    Bounds = NumberRange.new(0, 4294967295),
                    Integer = true,
                    Component = true,
                    AllowsRange = true,
                    AllowsOptional = true,
                    AllowedComponents = 0,
                },
                i8 = {
                    Bounds = NumberRange.new(-128, 127),
                    Integer = true,
                    Component = true,
                    AllowsRange = true,
                    AllowsOptional = true,
                    AllowedComponents = 0,
                },
                i16 = {
                    Bounds = NumberRange.new(-32768, 32767),
                    Integer = true,
                    Component = true,
                    AllowsRange = true,
                    AllowsOptional = true,
                    AllowedComponents = 0,
                },
                i32 = {
                    Bounds = NumberRange.new(-2147483648, 2147483647),
                    Integer = true,
                    Component = true,
                    AllowsRange = true,
                    AllowsOptional = true,
                    AllowedComponents = 0,
                },
                f16 = {
                    Bounds = NumberRange.new(-65504, 65504),
                    Component = true,
                    AllowsRange = true,
                    AllowsOptional = true,
                    AllowedComponents = 0,
                },
                f32 = {
                    Bounds = NumberRange.new(-16777216, 16777216),
                    Component = true,
                    AllowsRange = true,
                    AllowsOptional = true,
                    AllowedComponents = 0,
                },
                f64 = {
                    Bounds = NumberRange.new(-9007199254740992, 9007199254740992),
                    Component = true,
                    AllowsRange = true,
                    AllowsOptional = true,
                    AllowedComponents = 0,
                },
                boolean = {
                    Component = false,
                    AllowsRange = false,
                    AllowsOptional = true,
                    AllowedComponents = 0,
                },
                string = {
                    Bounds = NumberRange.new(0, 4294967295),
                    Integer = true,
                    Component = false,
                    AllowsRange = true,
                    AllowsOptional = true,
                    AllowedComponents = 0,
                },
                vector = {
                    Component = false,
                    AllowsRange = true,
                    AllowsOptional = true,
                    AllowedComponents = 1,
                },
                buffer = {
                    Bounds = NumberRange.new(0, 4294967295),
                    Integer = true,
                    Component = false,
                    AllowsRange = true,
                    AllowsOptional = true,
                    AllowedComponents = 0,
                },
                Color3 = {
                    Component = false,
                    AllowsRange = false,
                    AllowsOptional = true,
                    AllowedComponents = 0,
                },
                CFrame = {
                    Component = false,
                    AllowsRange = false,
                    AllowsOptional = true,
                    AllowedComponents = 2,
                },
                Instance = {
                    Component = false,
                    AllowsRange = false,
                    AllowsOptional = true,
                    AllowedComponents = 0,
                },
                BrickColor = {
                    Component = false,
                    AllowsRange = false,
                    AllowsOptional = true,
                    AllowedComponents = 0,
                },
                unknown = {
                    Component = false,
                    AllowsRange = false,
                    AllowsOptional = false,
                    AllowedComponents = 0,
                },
                DateTime = {
                    Component = false,
                    AllowsRange = false,
                    AllowsOptional = true,
                    AllowedComponents = 0,
                },
                DateTimeMillis = {
                    Component = false,
                    AllowsRange = false,
                    AllowsOptional = true,
                    AllowedComponents = 0,
                },
            }

            return {
                Keywords = {
                    map = true,
                    set = true,
                    type = true,
                    enum = true,
                    struct = true,
                    event = true,
                    ['function'] = true,
                    scope = true,
                    option = true,
                    export = true,
                },
                Primtives = Primitives,
                GetCasing = function(Case)
                    local Index = Indexes[Case]

                    if not Index then
                        error(`Unknown casing "{Case}", expectd one of "Pascal" or "Camel" or "Snake"`)
                    end

                    local Casing = {}

                    for Key, Options in Cases do
                        Casing[Key] = Options[Index]
                    end

                    return Casing
                end,
            }
        end

        function __DARKLUA_BUNDLE_MODULES.b()
            local v = __DARKLUA_BUNDLE_MODULES.cache.b

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.b = v
            end

            return v.c
        end
    end
    do
        local function __modImpl()
            local Error = __DARKLUA_BUNDLE_MODULES.a()
            local Settings = __DARKLUA_BUNDLE_MODULES.b()
            local DOTS = '%.%.'
            local NUMBER = '%-?%d*%.?%d+'
            local Keywords = Settings.Keywords
            local Primitives = Settings.Primtives
            local Booleans = {
                ['true'] = true,
                ['false'] = true,
            }
            local TOKENS = {
                {
                    '^%s+',
                    'Whitespace',
                },
                {
                    '^=',
                    'Assign',
                },
                {
                    '^:',
                    'FieldAssign',
                },
                {
                    '^{',
                    'OpenBraces',
                },
                {
                    '^}',
                    'CloseBraces',
                },
                {
                    '^<',
                    'OpenChevrons',
                },
                {
                    '^>',
                    'CloseChevrons',
                },
                {
                    '^,',
                    'Comma',
                },
                {
                    '^%.%.',
                    'Merge',
                },
                {
                    '^%-%-%[(=*)%[.-%]%1%]',
                    'Comment',
                },
                {
                    '^%-%-%[%[.-.*',
                    'Comment',
                },
                {
                    '^%-%-.-\n',
                    'Comment',
                },
                {
                    '^%-%-.-.*',
                    'Comment',
                },
                {
                    '^?',
                    'Optional',
                },
                {
                    `^%(%a+%)`,
                    'Class',
                },
                {
                    `^%[]`,
                    'Array',
                },
                {
                    `^%({NUMBER}%)`,
                    'Range',
                },
                {
                    `^%({NUMBER}{DOTS}%)`,
                    'Range',
                },
                {
                    `^%({DOTS}{NUMBER}%)`,
                    'Range',
                },
                {
                    `^%({NUMBER}{DOTS}{NUMBER}%)`,
                    'Range',
                },
                {
                    `^%[{NUMBER}%]`,
                    'Array',
                },
                {
                    `^%[{NUMBER}{DOTS}%]`,
                    'Array',
                },
                {
                    `^%[{DOTS}{NUMBER}%]`,
                    'Array',
                },
                {
                    `^%[{NUMBER}{DOTS}{NUMBER}%]`,
                    'Array',
                },
                {
                    '^%(',
                    'OpenParentheses',
                },
                {
                    '^%)',
                    'CloseParentheses',
                },
                {
                    '^%[',
                    'OpenBrackets',
                },
                {
                    '^%]',
                    'CloseBrackets',
                },
                {
                    '^""',
                    function(Toke)
                        return 'String', ''
                    end,
                },
                {
                    '^([\'"]).-[^\\](\\*)%2%1',
                    function(Token)
                        return 'String', string.sub(Token, 2, #Token - 1)
                    end,
                },
                {
                    '^([\'"]).-.*',
                    function(Token)
                        return 'String', string.sub(Token, 2)
                    end,
                },
                {
                    '^[%w_]+%.[%w_%.]+',
                    'Identifier',
                },
                {
                    '^[%a_][%w_]*',
                    function(Token)
                        if Token == 'import' then
                            return 'Import', Token
                        elseif Token == 'as' then
                            return 'As', Token
                        elseif Keywords[Token] then
                            return 'Keyword', Token
                        elseif Primitives[Token] then
                            return 'Primitive', Token
                        elseif Booleans[Token] then
                            return 'Boolean', (Token == 'true')
                        end

                        return 'Identifier', Token
                    end,
                },
            }
            local SKIPPED_TOKENS = {
                Comment = true,
                Whitespace = true,
            }
            local Lexer = {}

            Lexer.__index = Lexer

            function Lexer.new(Mode)
                return setmetatable({
                    Size = 0,
                    Mode = Mode or 'Parsing',
                    Source = '',
                    Cursor = 1,
                }, Lexer)
            end
            function Lexer.Initialize(self, Source)
                self.Size = #Source
                self.Source = Source
                self.Cursor = 1
            end
            function Lexer.GetNextToken(self, DontAdvanceCursor, StartAt)
                if self.Cursor > self.Size then
                    return {
                        Type = 'EndOfFile',
                        Value = '',
                        Start = #self.Source,
                        End = #self.Source,
                    }
                end

                local Source = self.Source
                local Position = StartAt or self.Cursor
                local IsHighlighting = (self.Mode == 'Highlighting')

                local function Match(Pattern)
                    local Start, End = string.find(Source, Pattern, Position)

                    if not Start or not End then
                        return nil, Position, Position
                    end

                    local Text = string.sub(Source, Start, End)

                    return Text, Position, math.min(Position + #Text, self.Size)
                end

                for Index, Token in TOKENS do
                    local Pattern = Token[1]
                    local Type = Token[2]
                    local Text, Start, End = Match(Pattern)

                    if not Text then
                        continue
                    end
                    if not DontAdvanceCursor or (SKIPPED_TOKENS[Type] and not IsHighlighting) then
                        Position += #Text

                        self.Cursor = Position
                    end
                    if SKIPPED_TOKENS[Type] and not IsHighlighting then
                        return self:GetNextToken(DontAdvanceCursor)
                    end
                    if type(Type) == 'function' then
                        local TrueType, TrueText = Type(Text)

                        Type = TrueType
                        Text = IsHighlighting and Text or TrueText
                    end

                    return {
                        Type = Type,
                        Value = Text,
                        Start = Start,
                        End = End,
                    }
                end

                if not IsHighlighting then
                    Error.new(Error.LexerUnexpectedToken, self.Source, 'Unexpected token'):Primary({
                        Start = self.Cursor,
                        End = self.Cursor,
                    }, `Unexpected token`):Emit()
                end

                local Symbol = string.sub(self.Source, Position, Position)

                if DontAdvanceCursor ~= true then
                    self.Cursor += 1
                end

                return {
                    Type = 'Unknown',
                    Value = Symbol,
                    Start = Position,
                    End = Position,
                }
            end

            return Lexer
        end

        function __DARKLUA_BUNDLE_MODULES.c()
            local v = __DARKLUA_BUNDLE_MODULES.cache.c

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.c = v
            end

            return v.c
        end
    end
    do
        local function __modImpl()
            local Utility = {}

            function Utility.PathType(Path)
                if string.sub(Path, 1, 1) == '/' then
                    return 'absolute'
                end
                if string.sub(Path, 2, 2) == ':' then
                    return 'absolute'
                end

                return 'relative'
            end
            function Utility.Components(Path)
                local Filename
                local Directory, FilenameExt, Extension = string.match(Path, '(.-)([^\\/]-%.?([^%.\\/]*))$')

                if FilenameExt then
                    if FilenameExt == Extension then
                        Extension = nil
                        Filename = FilenameExt
                    elseif Extension then
                        Filename = string.sub(FilenameExt, 1, #FilenameExt - (#Extension + 1))
                    end
                end

                return Directory, Filename, Extension
            end
            function Utility.Filename(Path)
                local _, Filename = Utility.Components(Path)

                return Filename
            end
            function Utility.Directory(Path)
                local Directory = Utility.Components(Path)

                return Directory
            end
            function Utility.Extension(Path)
                local _, _, Extension = Utility.Components(Path)

                return Extension
            end
            function Utility.NameWithExtension(Path)
                local _, Name, Extension = Utility.Components(Path)

                if Name and Extension then
                    return `{Name}.{Extension}`
                end

                return
            end

            return Utility
        end

        function __DARKLUA_BUNDLE_MODULES.d()
            local v = __DARKLUA_BUNDLE_MODULES.cache.d

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.d = v
            end

            return v.c
        end
    end
    do
        local function __modImpl()
            return {
                Merge = function(...)
                    local Tables = {...}
                    local Allocate = 0

                    for _, Table in Tables do
                        Allocate += #Table
                    end

                    local Index = 1
                    local Merged = table.create(Allocate)

                    for _, Table in Tables do
                        table.move(Table, 1, #Table, Index, Merged)

                        Index += #Table
                    end

                    return Merged
                end,
                DeepClone = function(Table)
                    local Cache = {}

                    local function Clone(Original)
                        local Cached = Cache[Original]

                        if Cached ~= nil then
                            return Cached
                        end

                        local Copy = Original

                        if type(Original) == 'table' then
                            Copy = {}
                            Cache[Original] = Copy

                            for Key, Value in Original do
                                Copy[Clone(Key)] = Clone(Value)
                            end
                        end

                        return Copy
                    end

                    return Clone(Table)
                end,
            }
        end

        function __DARKLUA_BUNDLE_MODULES.e()
            local v = __DARKLUA_BUNDLE_MODULES.cache.e

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.e = v
            end

            return v.c
        end
    end
    do
        local function __modImpl()
            local PathParser = __DARKLUA_BUNDLE_MODULES.d()
            local fs = require('@lune/fs')
            local EXTENSIONS = {
                '',
                '.txt',
                '.blink',
            }

            return function(Path)
                local Directory, Filename = PathParser.Components(Path)

                Directory = Directory or './'

                assert(Filename, `Unable to parse filename from {Path}, path may be malformed!`)

                for _, Extension in EXTENSIONS do
                    local Temporary = `{Directory}{Filename}{Extension}`

                    if fs.isFile(Temporary) then
                        return Temporary
                    end
                end

                return Path
            end
        end

        function __DARKLUA_BUNDLE_MODULES.f()
            local v = __DARKLUA_BUNDLE_MODULES.cache.f

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.f = v
            end

            return v.c
        end
    end
    do
        local function __modImpl()
            local Error = __DARKLUA_BUNDLE_MODULES.a()
            local Lexer = __DARKLUA_BUNDLE_MODULES.c()
            local PathParser = __DARKLUA_BUNDLE_MODULES.d()
            local Table = __DARKLUA_BUNDLE_MODULES.e()
            local Settings = __DARKLUA_BUNDLE_MODULES.b()
            local NumberRange = {
                new = function(Min, Max)
                    return {
                        Min = Min,
                        Max = Max or Min,
                    }
                end,
            }
            local OPTIONS = {
                Casing = 'Identifier',
                UseColon = 'Boolean',
                UsePolling = 'Boolean',
                Typescript = 'Boolean',
                TypesOutput = 'String',
                ClientOutput = 'String',
                ServerOutput = 'String',
                FutureLibrary = 'String',
                PromiseLibrary = 'String',
                SyncValidation = 'Boolean',
                WriteValidations = 'Boolean',
                ManualReplication = 'Boolean',
                RemoteScope = 'String',
            }
            local EVENT = {
                {
                    Key = 'From',
                    Type = 'Identifier',
                    Values = {
                        'Client',
                        'Server',
                    },
                },
                {
                    Key = 'Type',
                    Type = 'Identifier',
                    Values = {
                        'Reliable',
                        'Unreliable',
                    },
                },
                {
                    Key = 'Call',
                    Type = 'Identifier',
                    Values = {
                        'SingleSync',
                        'SingleAsync',
                        'ManySync',
                        'ManyAsync',
                        'Polling',
                    },
                },
                {
                    Key = 'Poll',
                    Type = 'Boolean',
                    Values = {true, false},
                    Optional = true,
                },
                {
                    Key = 'Data',
                    Type = 'Identifier',
                    Values = {},
                    Optional = true,
                },
            }
            local FUNCTION = {
                {
                    Key = 'Yield',
                    Type = 'Identifier',
                    Values = {
                        'Future',
                        'Promise',
                        'Coroutine',
                    },
                },
                {
                    Key = 'Data',
                    Type = 'Identifier',
                    Values = {},
                    Optional = true,
                },
                {
                    Key = 'Return',
                    Type = 'Identifier',
                    Values = {},
                    Optional = true,
                },
            }
            local BUCKETS = {
                Type = 'Types',
                Event = 'Scopes',
                Function = 'Scopes',
                Scope = 'Scopes',
            }
            local KEYWORDS = {
                map = {
                    Type = 'Map',
                    Class = 'Type',
                    Generics = true,
                    Exportable = true,
                },
                set = {
                    Type = 'Set',
                    Class = 'Type',
                    Generics = true,
                    Exportable = true,
                },
                enum = {
                    Type = 'Enum',
                    Class = 'Type',
                    Generics = true,
                    Exportable = true,
                },
                type = {
                    Type = 'Primitive',
                    Class = 'Type',
                    Generics = false,
                    Exportable = true,
                },
                struct = {
                    Type = 'Struct',
                    Class = 'Type',
                    Generics = true,
                    Exportable = true,
                },
                event = {
                    Type = 'Event',
                    Class = 'Event',
                    Generics = false,
                    Exportable = false,
                },
                ['function'] = {
                    Type = 'Function',
                    Class = 'Function',
                    Generics = false,
                    Exportable = false,
                },
                scope = {
                    Type = 'Scope',
                    Class = 'Scope',
                    Generics = false,
                    Exportable = false,
                },
            }
            local GENERICS_TYPES = {
                Map = true,
                Struct = true,
                TagEnum = true,
            }
            local RESERVED = {StepReplication = true}
            local PRIMITIVES = Settings.Primtives
            local ARRAY_BOUNDS = NumberRange.new(0, ((PRIMITIVES.u16.Bounds)).Max)
            local UINT_BOUNDS = (PRIMITIVES.u32.Bounds)
            local DOUBLE_BOUNDS = (PRIMITIVES.f64.Bounds)
            local TotalOptions = 0

            for _ in OPTIONS do
                TotalOptions += 1
            end

            local Parser = {}

            Parser.__index = Parser

            function Parser.new(Directory, File)
                return setmetatable({
                    Source = '',
                    File = File,
                    Directory = Directory or './',
                    Lexer = Lexer.new('Parsing'),
                    Symbols = {},
                    Scope = nil,
                }, Parser)
            end

            local function IsInteger(Number)
                return (Number // 1) == Number
            end
            local function GetFileSource(Path, Directory)
                local IsROBLOX = (task ~= nil)

                if IsROBLOX then
                    local Parent = game:GetService('ServerStorage')['BLINK_CONFIGURATION_FILES']
                    local Indices = string.split(Path, '.')

                    for _, Index in Indices do
                        if not Parent then
                            break
                        end

                        Parent = Parent:FindFirstChild(Index)
                    end

                    return (Parent ~= nil and Parent:IsA('StringValue')) and Parent.Value or nil, ''
                end

                local fs = require('@lune/fs')
                local GetDefinitionFilePath = __DARKLUA_BUNDLE_MODULES.f()

                if PathParser.PathType(Path) == 'relative' then
                    Path = `{Directory}{Path}`
                end

                Path = GetDefinitionFilePath(Path)

                if not fs.isFile(Path) then
                    return
                end

                local FileDirectory = PathParser.Directory(Path) or './'

                return fs.readFile(Path), FileDirectory
            end
            local function IsDeclarationTypeSimiliar(A, B)
                if A == B then
                    return true
                end
                if A == 'Enum' or B == 'Enum' then
                    return (A == 'TagEnum' and B == 'Enum') or (A == 'Enum' and B == 'TagEnum')
                end

                return false
            end

            function Parser.Peek(self)
                local Token = self.LookAhead

                if not Token then
                    error(Error.new(Error.ParserUnexpectedEndOfFile, self.Source, 'Unexpected end of file', self.File):Primary({
                        Start = #self.Source,
                        End = #self.Source,
                    }, 'File ends here'):Emit())
                end

                return Token
            end
            function Parser.Consume(self, Type)
                local Token = self.LookAhead

                if not Token then
                    Error.new(Error.ParserUnexpectedEndOfFile, self.Source, 'Unexpected end of file', self.File):Primary({
                        Start = #self.Source,
                        End = #self.Source,
                    }, 'File ends here'):Emit()
                    error('Unexpected end of file')
                end
                if Token.Type ~= Type then
                    Error.new(Error.ParserUnexpectedToken, self.Source, `Unexpected token`, self.File):Primary(Token, `Expected "{Type}", found "{Token.Type}"`):Emit()
                end

                self.LookAhead = self.Lexer:GetNextToken()

                return Token
            end
            function Parser.TryConsume(self, Type)
                local Token = self.LookAhead

                if not Token then
                    return
                end
                if Token.Type ~= Type then
                    return
                end

                self.LookAhead = self.Lexer:GetNextToken()

                return Token
            end
            function Parser.ConsumeAny(self, ...)
                local Types = {...}

                for _, Type in Types do
                    local Token = self:TryConsume(Type)

                    if Token then
                        return Token
                    end
                end

                local Token = self:Peek()

                error(Error.new(Error.ParserUnexpectedToken, self.Source, `Unexpected token`, self.File):Primary(Token, `Expected one of "{table.concat(Types, `", "`)}", found "{Token.Type}"`):Emit())
            end
            function Parser.ConsumeAll(self, ...)
                local Tokens = {}

                for _, Type in {...}do
                    table.insert(Tokens, self:Consume(Type))
                end

                return table.unpack(Tokens)
            end
            function Parser.ConsumeText(
                self,
                ConsumePrimitives,
                ConsumeStrings
            )
                local Token

                if ConsumeStrings and self:Peek().Type == 'String' then
                    Token = self:Consume('String')
                else
                    if ConsumePrimitives then
                        Token = self:ConsumeAny('As', 'Import', 'Boolean', 'Keyword', 'Identifier', 'Primitive')
                    else
                        Token = self:ConsumeAny('As', 'Import', 'Boolean', 'Keyword', 'Identifier')
                    end
                end

                return {
                    End = Token.End,
                    Start = Token.Start,
                    Type = 'Identifier',
                    Value = Token.Value,
                }
            end
            function Parser.Reference(self, Bucket, Identifier)
                local Path = string.split(Identifier, '.')
                local Scope = self.Scope
                local Offset = 1
                local Length = #Path
                local Result

                while Scope do
                    local Index = Path[Offset]

                    if not Index then
                        break
                    end

                    local Symbols = Scope.Symbols
                    local Symbol = if Offset == Length then Symbols[Bucket][Index]else Symbols.Scopes[Index]

                    if Symbol == nil then
                        Scope = Scope.Parent

                        continue
                    end
                    if Symbol and Offset < Length then
                        Offset += 1

                        Scope = Symbol

                        continue
                    end

                    Result = Symbol

                    break
                end

                return Result
            end
            function Parser.SetReference(self, Bucket, Identifier, Declaration)
                local Name = Identifier.Value

                if RESERVED[Name] then
                    Error.new(Error.AnalyzeReservedIdentifier, self.Source, `Reserved identifier`, self.File):Primary(Identifier, `"{Name}" is reserved and cannot be used as an identifier.`):Emit()
                end

                self.Symbols[Name] = true
                self.Scope.Symbols[Bucket][Name] = {
                    To = Declaration,
                    Name = Identifier,
                }
            end
            function Parser.GetGenerics(self)
                if self.Generics then
                    return self.Generics
                end

                local OpenChevrons = self:TryConsume('OpenChevrons')

                if not OpenChevrons then
                    return
                end

                local Generics = {
                    Keys = {},
                    List = {},
                    Span = {
                        Start = OpenChevrons.Start,
                        End = OpenChevrons.End + 1,
                    },
                }

                while true do
                    if self:TryConsume('CloseChevrons') then
                        break
                    end

                    local Token = self:ConsumeText()

                    Generics.Span.End = Token.End
                    Generics.Keys[Token.Value] = {}

                    table.insert(Generics.List, Token.Value)

                    if self:Peek().Type ~= 'CloseChevrons' then
                        self:Consume('Comma')
                    end
                end

                self.Generics = Generics

                return Generics
            end
            function Parser.NumberRange(self, Token, Bounds, Integer)
                local Value = Token.Value

                Value = string.sub(Value, 2, #Value - 1)

                local function ParseRange()
                    local Single = tonumber(string.match(Value, `^(%-?%d*%.?%d+)$`))

                    if Single then
                        return NumberRange.new(Single)
                    end

                    local LowerBounds = tonumber(string.match(Value, `^(%-?%d*%.?%d+)%.%.$`))

                    if LowerBounds then
                        return NumberRange.new(LowerBounds, Bounds.Max)
                    end

                    local UpperBounds = tonumber(string.match(Value, `^%.%.(%-?%d*%.?%d+)$`))

                    if UpperBounds then
                        return NumberRange.new(Bounds.Min, UpperBounds)
                    end

                    local Lower, Upper = string.match(Value, `^(%-?%d*%.?%d+)%.%.(%-?%d*%.?%d+)$`)
                    local Minimum, Maximum = tonumber(Lower), tonumber(Upper)

                    if Minimum and Maximum then
                        return NumberRange.new(Minimum, Maximum)
                    end

                    Error.new(Error.AnalyzeInvalidRange, self.Source, 'Malformed range', self.File):Primary(Token, 'Unable to parse range'):Emit()
                    error('never')
                end

                local Range = ParseRange()

                if Integer and (IsInteger(Range.Min) == false or IsInteger(Range.Max) == false) then
                    Error.new(Error.AnalyzeInvalidRange, self.Source, 'Expected an integer', self.File):Primary(Token, 'Expected an integer'):Emit()
                    error('never')
                end
                if Range.Min < Bounds.Min or Range.Max > Bounds.Max then
                    Error.new(Error.AnalyzeInvalidRange, self.Source, 'Range outside bounds', self.File):Primary(Token, `Expected a range within ({Bounds.Min}..{Bounds.Max})`):Emit()
                    error('never')
                end

                return Range
            end
            function Parser.Range(self, Primitive)
                local Token = self:TryConsume('Range')

                if Token == nil then
                    return
                end

                local NumberRange = self:NumberRange(Token, Primitive.Bounds or DOUBLE_BOUNDS, Primitive.Integer)

                return {
                    Range = NumberRange,
                    Token = Token,
                }
            end
            function Parser.Array(self)
                local Token = self:TryConsume('Array')

                if not Token then
                    return
                end

                local Value = Token.Value

                if Value == '[]' then
                    return {
                        Range = ARRAY_BOUNDS,
                        Token = Token,
                    }
                end

                local NumberRange = self:NumberRange(Token, ARRAY_BOUNDS, true)

                return {
                    Range = NumberRange,
                    Token = Token,
                }
            end
            function Parser.Components(self, Primitive)
                local OpenChevrons = self:TryConsume('OpenChevrons')

                if not OpenChevrons then
                    return
                end
                if Primitive.AllowedComponents == 0 then
                    error(Error.new(Error.AnalyzeInvalidRange, self.Source, `Type doesn't accept components`, self.File):Primary(OpenChevrons, `Remove component here`):Emit())
                end

                local Components = {}
                local Primitives = {}

                for Index = 1, Primitive.AllowedComponents do
                    table.insert(Primitives, self:Consume('Primitive'))

                    if self:TryConsume('CloseChevrons') then
                        break
                    end

                    self:Consume('Comma')
                end

                for Index, Token in Primitives do
                    local Component = Token.Value
                    local ComponentPrimitive = PRIMITIVES[Component]

                    if not ComponentPrimitive then
                        error(Error.new(Error.AnalyzeInvalidRange, self.Source, `Unknown primitive used as component`, self.File):Primary(Token, `"{Component}" is invalid`):Emit())
                    end
                    if not ComponentPrimitive.Component then
                        error(Error.new(Error.AnalyzeInvalidRange, self.Source, `Invalid primitive used as component`, self.File):Primary(Token, `"{Component}" cannot be used as a component`):Emit())
                    end

                    table.insert(Components, Component)
                end

                return Components
            end
            function Parser.Optional(self)
                return self:TryConsume('Optional')
            end
            function Parser.ReplaceGenerics(self, Of, Previous)
                local Clone = (Table.DeepClone(Of))
                local Generics = (Clone.Value.Generics)
                local Replacements = {}

                Clone.Value.Generics = nil

                self:Consume('OpenChevrons')

                for Index = 1, #Generics.List do
                    local Key = Generics.List[Index]
                    local List = Generics.Keys[Key]
                    local Token = self:Peek()
                    local Declaration = self:Type(Token)

                    Replacements[Key] = Declaration

                    for _, Generic in List do
                        local Replacement = Table.DeepClone(Declaration)

                        Generic.Type = Replacement.Type
                        Generic.Value = Replacement.Value
                        Generic.Tokens = Replacement.Tokens
                    end

                    if Index < #Generics.List then
                        self:Consume('Comma')
                    end
                end

                self:Consume('CloseChevrons')

                local function Traverse(Type)
                    if Type.Type == 'Array' or Type.Type == 'Optional' then
                        Traverse(Type.Value.Of)
                    elseif Type.Type == 'TagEnum' or Type.Type == 'Struct' or Type.Type == 'Map' then
                        for _, Type in (Type.Value.Values)do
                            Traverse(Type)
                        end
                    elseif Type.Type == 'Generic' then
                        local Key = Type.Value.Generic
                        local Declaration = Replacements[Key]

                        if Declaration == nil then
                            return
                        end

                        local Replacement = Table.DeepClone(Declaration)

                        Type.Type = Replacement.Type
                        Type.Value = Replacement.Value
                        Type.Tokens = Replacement.Tokens
                    end
                end

                Traverse(Clone)

                return Clone
            end
            function Parser.Parse(self, Source, Scope)
                self.Scope = Scope or {
                    Name = {
                        Value = '',
                        Start = 0,
                        End = 0,
                    },
                    Symbols = {
                        Types = {},
                        Scopes = {},
                    },
                }
                self.Source = Source

                table.clear(self.Symbols)
                self.Lexer:Initialize(Source)

                self.LookAhead = self.Lexer:GetNextToken()

                local Options = self:Options()
                local Declarations = self:Declarations()

                Options.SyncValidation = if Options.SyncValidation ~= nil then Options.SyncValidation else true

                return {
                    Type = 'Body',
                    Name = Scope and Scope.Name.Value or 'Body',
                    Value = {
                        Symbols = table.clone(self.Symbols),
                        Options = Options,
                        Declarations = Declarations,
                    },
                    Tokens = {},
                }
            end
            function Parser.Import(self)
                self:Consume('Import')

                local Path = self:Consume('String')
                local ImportPath = Path.Value
                local ImportSource, ImportDirectory = GetFileSource(ImportPath, self.Directory)

                if not ImportSource then
                    error(Error.new(Error.AnalyzeUnknownImport, self.Source, `Unknown require`, self.File):Primary(Path, `Unknown require: "{ImportPath}"`):Emit())
                end

                local Name
                local Token = Path

                if self:TryConsume('As') then
                    Token = self:ConsumeText()
                    Name = Token.Value
                elseif task ~= nil then
                    local Indices = string.split(ImportPath, '.')

                    Name = Indices[#Indices]
                else
                    if PathParser.PathType(ImportPath) == 'absolute' and string.sub(ImportPath, 1, 2) ~= './' then
                        ImportPath = `./{ImportPath}`
                    end

                    local Filename = PathParser.Filename(ImportPath)

                    assert(Filename, 'Unable to parse file path for filename!')

                    Name = Filename
                    Token.Value = Filename
                end

                local Existing = self:Reference('Scopes', Name)

                if Existing then
                    Error.new(Error.AnalyzeDuplicateDeclaration, self.Source, `Duplicate declaration: "{Name}"`, self.File):Secondary(Existing.Name, 'Previously declared here'):Primary(Token, 'Duplicate declared here'):Emit()
                end

                local Parent = self.Scope
                local Scope = {
                    Name = Token,
                    Symbols = {
                        Types = {},
                        Scopes = {},
                    },
                }
                local AST
                local ImportParser = Parser.new(ImportDirectory, ImportPath)
                local Success, ErrorText = pcall(function()
                    AST = ImportParser:Parse(ImportSource, Scope)
                end)

                if not Success then
                    error(ErrorText)
                end

                Scope.Parent = Parent
                self.Symbols[Name] = true
                Parent.Symbols.Scopes[Name] = Scope

                return {
                    Type = 'Scope',
                    Name = Name,
                    Value = {
                        Scope = Scope,
                        Values = AST.Value.Declarations,
                    },
                    Tokens = {},
                }
            end
            function Parser.Options(self)
                local Options = {}

                for Index = 1, TotalOptions do
                    local Keyword = self:Peek()

                    if Keyword.Value ~= 'option' then
                        break
                    end

                    self:Consume('Keyword')

                    local Key = self:ConsumeAll('Identifier', 'Assign')
                    local Name = Key.Value
                    local Type = OPTIONS[Name]

                    if not Type then
                        local Examples = ''

                        for Option in OPTIONS do
                            Examples ..= `{Examples ~= '' and ' or ' or ''}"{Option}"`
                        end

                        Error.new(Error.ParserUnknownOption, self.Source, `Unknown option "{Name}"`, self.File):Primary(Key, `Expected one of {Examples}`):Emit()
                    end

                    local Value = self:Consume(Type)

                    Options[Name] = Value.Value
                end

                return Options
            end
            function Parser.Declarations(self)
                local Declarations = {}

                while true do
                    if self:TryConsume('EndOfFile') then
                        break
                    end
                    if self.Scope and self:TryConsume('CloseBraces') then
                        break
                    end

                    local LookAhead = self:Peek()

                    if LookAhead.Type == 'Import' then
                        table.insert(Declarations, self:Import())

                        continue
                    end

                    local Export

                    if LookAhead.Type == 'Keyword' and LookAhead.Value == 'export' then
                        Export = self:Consume('Keyword')
                    end

                    local Keyword = self:Consume('Keyword')
                    local Name = self:ConsumeText()
                    local Declaration

                    if Keyword.Value == 'option' then
                        Error.new(Error.AnalyzeOptionAfterStart, self.Source, 'Option set after start of file', self.File):Primary(Keyword, 'Move to the start of the file'):Emit()
                    end

                    local KeywordSettings = KEYWORDS[Keyword.Value]
                    local Type = KeywordSettings.Class
                    local Bucket = BUCKETS[Type]
                    local Existing = self:Reference(Bucket, Name.Value)

                    if Existing then
                        Error.new(Error.AnalyzeDuplicateDeclaration, self.Source, `Duplicate declaration`, self.File):Secondary(Existing.Name, 'Previously declared here'):Primary(Name, 'Duplicate declared here'):Emit()
                    end

                    local Generics

                    if KeywordSettings.Generics then
                        Generics = self:GetGenerics()
                    end
                    if Type == 'Type' then
                        local Node = self:Type(Name, Keyword)
                        local Value = Node.Value

                        Value.Scope = self.Scope
                        Declaration = Node
                    elseif Type == 'Event' then
                        Declaration = self:Event(Name)
                    elseif Type == 'Function' then
                        Declaration = self:Function(Name)
                    elseif Type == 'Scope' then
                        Declaration = self:Namespace(Name)
                    end

                    table.insert(Declarations, Declaration)

                    if Export then
                        if not KeywordSettings.Exportable then
                            Error.new(Error.AnalyzeInvalidExport, self.Source, `Declaration of type "{Keyword.Value}" is not exportable`, self.File):Primary(Export, `Remove export here`):Emit()
                        elseif Generics then
                            Error.new(Error.AnalyzeInvalidExport, self.Source, `Generic types can't be exported`, self.File):Primary(Export, `Remove export here`):Emit()
                        end

                        Declaration.Value.Export = true
                    end
                    if Generics then
                        if Declaration.Type == 'Enum' then
                            Error.new(Error.AnalyzeInvalidGenerics, self.Source, `Unit enums don't support generics`, self.File):Primary(Generics.Span, 'Remove generics'):Emit()
                        end

                        self.Generics = nil
                        Declaration.Value.Generics = Generics
                    end
                    if Type ~= 'Scope' then
                        self:SetReference(Bucket, Name, Declaration)
                    end
                end

                return Declarations
            end
            function Parser.GetOptionFromToken(self, Token, Structure)
                local Value = Token.Value

                for Index, Option in Structure do
                    local Key = Option.Key

                    if Key == Value or string.lower(Key) == Value then
                        return Option
                    end
                end

                local OptionsString = ''

                for Index, Option in Structure do
                    OptionsString ..= `{Index ~= 1 and ' or ' or ''}"{Option.Key}"`
                end

                error(Error.new(Error.ParserUnknownOption, self.Source, `Unknown option "{Value}"`, self.File):Primary(Token, `Expected one of {OptionsString}`):Emit())
            end
            function Parser.Structure(self, Name, Structure)
                local Fields = {}
                local Open, Close = self:Consume('OpenBraces'), nil

                while true do
                    Close = self:TryConsume('CloseBraces')

                    if Close then
                        break
                    end

                    local Value
                    local Field = self:ConsumeText()
                    local Option = self:GetOptionFromToken(Field, Structure)

                    self:Consume('FieldAssign')

                    if Fields[Option.Key] then
                        Error.new(Error.AnalyzeDuplicateField, self.Source, `Field "{Option.Key}" was already specified`, self.File):Primary(Field, `Already specified earlier in the structure`):Emit()
                    end
                    if Option.Key ~= 'Data' and Option.Key ~= 'Return' then
                        local Token = self:Consume(Option.Type)

                        Value = Token.Value

                        if not table.find(Option.Values, Value) then
                            Error.new(Error.ParserUnknownOption, self.Source, `Unknown option "{Value}"`, self.File):Primary(Token, `Expected one of "{table.concat(Option.Values, `" or "`)}"`):Emit()
                        end
                    else
                        Value = self:Type(Name, nil, true)
                    end

                    Fields[Option.Key] = Value
                    Close = self:TryConsume('CloseBraces')

                    if Close then
                        break
                    end

                    self:Consume('Comma')
                end

                for _, Option in Structure do
                    if Option.Optional then
                        continue
                    end
                    if Fields[Option.Key] ~= nil then
                        continue
                    end

                    local Span = {
                        End = math.max((Close).End - 2, Open.Start),
                        Start = Open.Start,
                    }

                    Error.new(Error.ParserExpectedExtraToken, self.Source, `Field "{Option.Key}" is missing`, self.File):Primary(Span, `Add missing field "{Option.Key}"`):Emit()
                end

                return Fields
            end
            function Parser.Event(self, Name)
                local Structure = self:Structure(Name, EVENT)
                local Call = Structure.Call

                if Structure.Poll then
                    Call = 'Polling'
                end

                return {
                    Type = 'Event',
                    Name = Name.Value,
                    Value = {
                        From = Structure.From,
                        Type = Structure.Type,
                        Call = Call,
                        Data = Structure.Data,
                    },
                    Tokens = {},
                }
            end
            function Parser.Function(self, Name)
                local Structure = self:Structure(Name, FUNCTION)

                return {
                    Type = 'Function',
                    Name = Name.Value,
                    Value = {
                        Yield = Structure.Yield,
                        Data = Structure.Data,
                        Return = Structure.Return,
                    },
                    Tokens = {},
                }
            end
            function Parser.Namespace(self, Name)
                self:Consume('OpenBraces')

                local Parent = self.Scope
                local Scope = {
                    Name = Name,
                    Parent = Parent,
                    Symbols = {
                        Types = {},
                        Scopes = {},
                    },
                }

                self.Scope = Scope
                self.Symbols[Name.Value] = true
                Parent.Symbols.Scopes[Name.Value] = Scope

                local Declarations = self:Declarations()

                self.Scope = Parent

                return {
                    Type = 'Scope',
                    Name = Name.Value,
                    Value = {
                        Scope = Scope,
                        Values = Declarations,
                    },
                    Tokens = {},
                }
            end
            function Parser.Type(self, Name, Keyword, IsDataField)
                local Declaration

                if Keyword then
                    local Value = Keyword.Value

                    if Value ~= 'struct' then
                        self:Consume('Assign')

                        local Type = KEYWORDS[Value].Type
                        local Token = self:Peek()

                        if Token.Type == 'Identifier' then
                            Declaration = self:Declaration(Name)

                            if not IsDeclarationTypeSimiliar(Declaration.Type, Type) then
                                Error.new(Error.AnalyzeReferenceInvalidType, self.Source, `Cannot cast "{Declaration.Type}" to "{Type}"`, self.File):Primary(Token, `Expected a reference to "{Type}", got "{Declaration.Type}" instead`):Emit()
                            end
                        end
                    end
                    if not Declaration then
                        if Value == 'map' then
                            Declaration = self:Map(Name)
                        elseif Value == 'set' then
                            Declaration = self:Set(Name)
                        elseif Value == 'enum' then
                            Declaration = self:Enum(Name)
                        elseif Value == 'type' then
                            Declaration = self:Primitive(Name)
                        elseif Value == 'struct' then
                            Declaration = self:Struct(Name)
                        end
                    end
                end
                if not Keyword then
                    local Peek = self:Peek()
                    local Type = (Peek.Type)

                    if Type == 'Keyword' then
                        local Value = Peek.Value

                        self:Consume('Keyword')

                        if Value == 'map' then
                            Declaration = self:Map(Name)
                        elseif Value == 'set' then
                            Declaration = self:Set(Name)
                        elseif Value == 'enum' then
                            Declaration = self:Enum(Name)
                        elseif Value == 'struct' then
                            Declaration = self:Struct(Name)
                        end
                    elseif Type == 'Primitive' then
                        Declaration = self:Primitive(Name)
                    elseif Type == 'Identifier' then
                        Declaration = self:Declaration(Name)
                    elseif Type == 'OpenParentheses' and IsDataField then
                        Declaration = self:Tuple(Name)
                    end
                    if not Declaration then
                        Error.new(Error.ParserUnexpectedToken, self.Source, `Unexpected token`, self.File):Primary(Peek, `Expected one of "Identifier" or "Primitive" or "Keyword", got "{Type}" instead`):Emit()
                    end
                end

                local Primitive

                if Declaration.Type == 'Primitive' then
                    Primitive = (Declaration).Value.Primitive
                end

                local Value = (Declaration.Value)
                local Tokens = (Declaration.Tokens)

                if Primitive then
                    local Components = self:Components(Primitive)

                    if Components then
                        Value.Components = Components
                    end

                    local Range = self:Range(Primitive)

                    if Range then
                        Value.Range = Range.Range
                        Tokens.Range = Range.Token
                    end
                end

                local function WrapInOptional()
                    local Optional = self:Optional()

                    if Optional then
                        Declaration = {
                            Type = 'Optional',
                            Name = Name.Value,
                            Value = {Of = Declaration},
                            Tokens = {},
                        }
                    end
                end

                WrapInOptional()

                while true do
                    local Array = self:Array()

                    if Array then
                        Declaration = {
                            Type = 'Array',
                            Name = Name.Value,
                            Value = {
                                Of = Declaration,
                                Range = Array.Range,
                            },
                            Tokens = {
                                Range = Array.Token,
                            },
                        }
                    end

                    WrapInOptional()

                    if Array == nil then
                        break
                    end
                end

                return Declaration
            end
            function Parser.Set(self, Name)
                self:Consume('OpenBraces')

                local Values = {}

                while true do
                    if self:TryConsume('CloseBraces') then
                        break
                    end

                    local Token = self:ConsumeText(true, true)

                    table.insert(Values, Token.Value)

                    if self:TryConsume('CloseBraces') then
                        break
                    end

                    self:Consume('Comma')
                end

                return {
                    Type = 'Set',
                    Name = Name.Value,
                    Value = {Values = Values},
                    Tokens = {},
                }
            end
            function Parser.Map(self, Name)
                self:ConsumeAll('OpenBraces', 'OpenBrackets')

                local function ParseElement()
                    local Token = self:Peek()
                    local Declaration = self:Type(Name)

                    if Declaration.Type == 'Optional' then
                        Error.new(Error.AnalyzeInvalidOptionalType, self.Source, 'Invalid optional type', self.File):Primary(Token, `Maps cannot have optionals as keys or values`):Emit()
                    end

                    return Declaration
                end

                local Key = ParseElement()

                self:Consume('CloseBrackets')
                self:Consume('FieldAssign')

                local Value = ParseElement()

                self:Consume('CloseBraces')

                return {
                    Type = 'Map',
                    Name = Name.Value,
                    Value = {
                        Values = {Key, Value},
                    },
                    Tokens = {},
                }
            end
            function Parser.Enum(self, Name)
                local Values = {}
                local Tag = self:TryConsume('String')

                if Tag then
                    return self:TagEnum(Tag, Name)
                end

                self:Consume('OpenBraces')

                while true do
                    if self:TryConsume('CloseBraces') then
                        break
                    end

                    local Token = self:ConsumeText(true, true)

                    table.insert(Values, Token.Value)

                    if self:TryConsume('CloseBraces') then
                        break
                    end

                    self:Consume('Comma')
                end

                return {
                    Type = 'Enum',
                    Name = Name.Value,
                    Value = {Values = Values},
                    Tokens = {},
                }
            end
            function Parser.TagEnum(self, Tag, Name)
                local Values = {}

                self:Consume('OpenBraces')

                while true do
                    if self:TryConsume('CloseBraces') then
                        break
                    end

                    local Token

                    if self:Peek().Type == 'OpenBrackets' then
                        self:Consume('OpenBrackets')

                        Token = self:Consume('String')

                        self:Consume('CloseBrackets')
                    else
                        Token = self:ConsumeText(true)
                    end

                    local Struct = self:Struct(Token)
                    local Fields = Struct.Value.Values

                    for _, Field in Fields do
                        if Field.Name == Tag.Value then
                            Error.new(Error.AnalyzeReservedIdentifier, self.Source, `Enum tag used as field in variant`, self.File):Secondary(Token, `Used in variant`):Primary(Tag, `Enum tag`):Emit()
                        end
                    end

                    table.insert(Values, Struct)

                    if self:TryConsume('CloseBraces') then
                        break
                    end

                    self:Consume('Comma')
                end

                return {
                    Type = 'TagEnum',
                    Name = Name.Value,
                    Value = {
                        Tag = Tag.Value,
                        Values = Values,
                    },
                    Tokens = {},
                }
            end
            function Parser.Tuple(self, Name)
                local Values = {}

                self:Consume('OpenParentheses')

                while true do
                    if self:TryConsume('CloseParentheses') then
                        break
                    end

                    local Value = self:Type(Name)

                    table.insert(Values, Value)

                    if self:TryConsume('CloseParentheses') then
                        break
                    end

                    self:Consume('Comma')
                end

                return {
                    Type = 'Tuple',
                    Name = Name.Value,
                    Value = {Values = Values},
                    Tokens = {},
                }
            end
            function Parser.Struct(self, Name)
                local Fields = {}
                local Values = {}

                self:Consume('OpenBraces')

                while true do
                    if self:TryConsume('CloseBraces') then
                        break
                    end
                    if self:TryConsume('Merge') then
                        local Text = self:Peek()
                        local Declaration = self:Declaration(Name)

                        if Declaration.Type ~= 'Struct' then
                            error(Error.new(Error.AnalyzeReferenceInvalidType, self.Source, `Expected a struct to merge, got "{Declaration.Type}" instead`, self.File):Primary(Text, `Expected a "Struct", got "{Declaration.Type}" instead`):Emit())
                        end

                        local Struct = Declaration
                        local StructValues = Struct.Value.Values

                        for _, Field in StructValues do
                            local FieldIdentifier = Field.Name

                            if Fields[FieldIdentifier] then
                                error(Error.new(Error.AnalyzeDuplicateField, self.Source, `Merged struct contains a duplicate field`, self.File):Primary(Text, `Field "{FieldIdentifier}" already exists in struct`):Emit())
                            end

                            table.insert(Values, Field)

                            Fields[FieldIdentifier] = true
                        end
                    else
                        local Text

                        if self:Peek().Type == 'OpenBrackets' then
                            self:Consume('OpenBrackets')

                            Text = self:Consume('String')

                            self:Consume('CloseBrackets')
                        else
                            Text = self:ConsumeText(true)
                        end
                        if Fields[Text.Value] then
                            error(Error.new(Error.AnalyzeDuplicateField, self.Source, `Duplicate field "{Text.Value}"`, self.File):Primary(Text, `Duplicate field`):Emit())
                        end

                        self:Consume('FieldAssign')

                        Fields[Text.Value] = true

                        table.insert(Values, self:Type(Text))
                    end
                    if self:TryConsume('CloseBraces') then
                        break
                    end

                    self:Consume('Comma')
                end

                return {
                    Type = 'Struct',
                    Name = Name.Value,
                    Value = {Values = Values},
                    Tokens = {},
                }
            end
            function Parser.Primitive(self, Name)
                local Token = self:Consume('Primitive')
                local Class
                local Value = Token.Value
                local Primitive = PRIMITIVES[Value]

                if Value == 'Instance' then
                    local ClassToken = self:TryConsume('Class')

                    Class = if ClassToken then string.sub(ClassToken.Value, 2, #ClassToken.Value - 1)else'Instance'
                end

                return {
                    Type = 'Primitive',
                    Name = Name.Value,
                    Value = {
                        Class = Class,
                        Primitive = Primitive,
                    },
                    Tokens = {Primitive = Token},
                }
            end
            function Parser.Declaration(self, Name)
                local Token = self:ConsumeText()
                local Generics = self.Generics
                local List = (Generics and Generics.Keys[Token.Value])

                if List then
                    local Generic = {
                        Type = 'Generic',
                        Name = Name.Value,
                        Value = {
                            Generic = Token.Value,
                        },
                        Tokens = {},
                    }

                    table.insert(List, Generic)

                    return Generic
                end

                local Reference = (self:Reference('Types', Token.Value))

                if not Reference then
                    error(Error.new(Error.AnalyzeUnknownReference, self.Source, `Unknown reference`, self.File):Primary(Token, 'Unknown reference'):Emit())
                end

                local To = Reference.To

                To = table.clone(To)
                To.Name = Name.Value

                if GENERICS_TYPES[To.Type] and To.Value.Generics then
                    To = self:ReplaceGenerics(To)
                end

                return To
            end

            return Parser
        end

        function __DARKLUA_BUNDLE_MODULES.g()
            local v = __DARKLUA_BUNDLE_MODULES.cache.g

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.g = v
            end

            return v.c
        end
    end
    do
        local function __modImpl()
            local Builder = {}

            function Builder.new()
                local Strings = table.create(512)

                local function PushLines(Lines, Returns, Tabs)
                    local Size = #Lines
                    local Last = Lines[Size]
                    local Tabs = Tabs or 0
                    local Returns = Returns or 0

                    if Tabs == 0 and Returns == 0 then
                        table.move(Lines, 1, Size, #Strings + 1, Strings)

                        return
                    end

                    local Indentation = string.rep('\t', Tabs)

                    if Last == '' then
                        Size -= 1

                        Lines[Size] = nil
                    end

                    for Index, Line in Lines do
                        table.insert(Strings, `{Indentation}{Line}{Index == Size and string.rep('\n', Returns) or ''}`)
                    end
                end

                return {
                    Push = function(Text, Returns, Tabs)
                        table.insert(Strings, `{string.rep('\t', Tabs or 0)}{Text}\n{string.rep('\n', Returns or 0)}`)
                    end,
                    PushFront = function(Text, Returns, Tabs)
                        table.insert(Strings, 1, `{string.rep('\n', Returns or 1)}{Text}{string.rep('\t', Tabs or 0)}\n`)
                    end,
                    PushLines = PushLines,
                    PushMultiline = function(Text, Returns, Tabs)
                        PushLines(string.split(Text, '\n'), Returns, Tabs)
                    end,
                    Print = function()
                        print(table.concat(Strings))
                    end,
                    DumpNoClear = function()
                        return table.concat(Strings)
                    end,
                    Dump = function()
                        local Text = table.concat(Strings)

                        table.clear(Strings)

                        return Text
                    end,
                    DumpLines = function()
                        return Strings
                    end,
                }
            end

            return Builder
        end

        function __DARKLUA_BUNDLE_MODULES.h()
            local v = __DARKLUA_BUNDLE_MODULES.cache.h

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.h = v
            end

            return v.c
        end
    end
    do
        local function __modImpl()
            local DEFAULT_UNIQUE = 'BLOCK_START'
            local ARRAY_UNIQUE = 'ARRAY_START'
            local Operators = {
                Not = '~=',
                Equals = '==',
                Greater = '>',
                Less = '<',
                GreaterOrEquals = '>=',
                LessOrEquals = '<=',
            }
            local Block = {}

            Block.__index = Block

            function Block.new(Parent, Unique)
                local Indent = (Parent and Parent.Indent + 1 or 1)

                return setmetatable({
                    Unique = Unique or DEFAULT_UNIQUE,
                    Parent = Parent,
                    Indent = Indent,
                    Cursor = 1,
                    Unsafe = false,
                    Content = table.create(64),
                    Operation = {
                        Method = 'None',
                        Bytes = 0,
                        Counts = 0,
                    },
                    Variables = {},
                    OperationOffset = 0,
                }, Block)
            end
            function Block.DisableOperationOptimisations(self)
                self.Unsafe = true

                return self
            end
            function Block._operation(self, Method, Bytes)
                local Operation = self.Operation

                if Operation.Method ~= 'None' and Operation.Method ~= Method then
                    error(`Block can't both Allocate and Read`)
                end
                if self.Unsafe then
                    local Counts = Operation.Counts
                    local Variable = `OFFSET_{Counts}`

                    Operation.Counts += 1

                    self:Line(`local {Variable} = {Method}({Bytes})`)

                    return Variable
                end

                local Offset = Operation.Bytes

                Operation.Bytes += Bytes

                Operation.Method = Method

                if self.Unique ~= DEFAULT_UNIQUE then
                    self:Comment(`{Method} {Bytes}`)

                    local OperationOffset = `OPERATION_OFFSET_{self.OperationOffset}`

                    self.OperationOffset += 1

                    self:Line(`local {OperationOffset} = {self.Unique}`)
                    self:Line(`{self.Unique} += {Bytes}`)

                    return OperationOffset
                end

                return `{self.Unique} + {Offset}`
            end
            function Block.Read(self, Bytes)
                return self:_operation('Read', Bytes)
            end
            function Block.Allocate(self, Bytes)
                return self:_operation('Allocate', Bytes)
            end
            function Block._lineFront(self, Text, Indent)
                table.insert(self.Content, self.Cursor, `{string.rep('\t', Indent or self.Indent)}{Text}\n`)

                return self
            end
            function Block._appendOperations(self)
                local Operation = self.Operation
                local Variable = Operation.Variable

                if Operation.Method == 'None' then
                    return self
                end

                local Append = `local {self.Unique} = {Operation.Method}({Operation.Bytes}{Variable and ` * {Variable}` or ''})`

                self:_lineFront(Append, self.Unique ~= DEFAULT_UNIQUE and self.Indent - 1 or self.Indent)
                self:_lineFront(`-- {Operation.Method} BLOCK: {Operation.Bytes} bytes`)

                return self
            end
            function Block.Declare(self, Variable, Initialize)
                local Block = self
                local Declared = false
                local IsFieldAccess = (string.find(Variable, '[%.%[]', 1) ~= nil)

                if IsFieldAccess then
                    return Variable
                end

                while Block do
                    if Block.Variables[Variable] then
                        Declared = true

                        break
                    end

                    Block = Block.Parent
                end

                if Declared then
                    return Variable
                end

                self.Variables[Variable] = true

                if Initialize then
                    self:Line(`local {Variable}`)
                end

                return `local {Variable}`
            end
            function Block.EmptyDeclare(self, Variable)
                self.Variables[Variable] = true
            end
            function Block.Advance(self, Offset)
                self.Cursor += Offset

                return self
            end
            function Block.Line(self, Text, Indent)
                table.insert(self.Content, `{string.rep('\t', Indent or self.Indent)}{Text}\n`)

                return self
            end
            function Block.Character(self, Character)
                table.insert(self.Content, Character)

                return self
            end
            function Block.Comment(self, Content)
                self:Line(`-- {Content}`)

                return self
            end
            function Block.Lines(self, Lines, Indent)
                local Indent = Indent or 0

                if Indent == 0 then
                    table.move(Lines, 1, #Lines, #self.Content + 1, self.Content)

                    return self
                end

                local Indentation = string.rep('\t', Indent)

                for Index, Line in Lines do
                    table.insert(self.Content, `{Indentation}{Line}`)
                end

                return self
            end
            function Block.Multiline(self, Content, Indent)
                local Lines = string.split(Content, '\n')

                for Index, Line in Lines do
                    table.insert(self.Content, `{string.rep('\t', Indent or 0)}{Line}\n`)
                end

                return self
            end
            function Block.Loop(self, Counter, Length)
                local Loop = Block.new(self, `{ARRAY_UNIQUE}_{self.Indent}`)

                Loop:Line(`for {Counter}, {Length} do`, Loop.Indent - 1)

                Loop.Operation.Variable = Length

                return Loop
            end
            function Block.While(self, Condition)
                self:Line(`while ({Condition}) do`)

                return Block.new(self)
            end
            function Block.Iterator(self, Key, Value, Iterator)
                self:Line(`for {Key}, {Value} in {Iterator} do`)

                return Block.new(self)
            end
            function Block.Compare(self, Left, Right, Operator)
                self:Line(`if {Left} {Operators[Operator]} {Right} then`)

                return Block.new(self)
            end
            function Block.Branch(self, Branch, Left, Right, Operator)
                local Parent = self.Parent

                assert(Parent, 'Cannot branch the top level block.')
                self:_appendOperations()
                Parent:Lines(self.Content)

                if Branch == 'Conditional' then
                    Parent:Line(`elseif {Left} {Operators[Operator]} {Right} then`)
                else
                    Parent:Line(`else`)
                end

                return Block.new(Parent)
            end
            function Block.Return(self, Return)
                self:Line(`return {Return}`)

                return self
            end
            function Block.End(self)
                self:_appendOperations()

                local Parent = self.Parent

                if Parent then
                    Parent:Lines(self.Content)
                    Parent:Line('end')

                    return Parent
                end

                self:Line('end', 0)

                return self
            end
            function Block.Wrap(self, Front, Back)
                local First = self.Content[1]

                self.Content[1] = `{Front}{First}`

                local Last = self.Content[#self.Content]

                self.Content[#self.Content] = `{string.gsub(Last, '\n', '')}{Back}\n`

                return self
            end
            function Block.Unwrap(self)
                return table.concat(self.Content)
            end

            local Function = {}

            Function.__index = Function

            setmetatable(Function, Block)

            function Function.new(
                Name,
                Arguments,
                Return,
                IsInlined,
                Localised
            )
                local Block = Block.new(nil)

                setmetatable(Block, Function)

                local Suffix = Return and `: {Return}` or ''

                Block:Advance(1)

                if IsInlined then
                    Block:Line(`{Name} = function({Arguments}){Suffix}`, 0)
                elseif Localised then
                    Block:Line(`local function {Name}({Arguments}){Suffix}`, 0)
                else
                    Block:Line(`function {Name}({Arguments}){Suffix}`, 0)
                end

                return Block
            end

            local Connection = {}

            Connection.__index = Connection

            setmetatable(Connection, Block)

            function Connection.new(Signal, Arguments)
                local Block = Block.new()

                setmetatable(Block, Connection)
                Block:Advance(1)
                Block:Line(`{Signal}:Connect(function({Arguments})`, 0)

                return Block
            end
            function Connection.End(self, Return)
                self:Line('end)', 0)

                return self
            end

            return {
                Block = Block.new,
                Function = Function.new,
                Connection = Connection.new,
            }
        end

        function __DARKLUA_BUNDLE_MODULES.i()
            local v = __DARKLUA_BUNDLE_MODULES.cache.i

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.i = v
            end

            return v.c
        end
    end
    do
        local function __modImpl()
            local Blocks = __DARKLUA_BUNDLE_MODULES.i()
            local Parser = __DARKLUA_BUNDLE_MODULES.g()
            local SEND_BUFFER = 'SendBuffer'
            local RECIEVE_BUFFER = 'RecieveBuffer'
            local SEND_POSITION = 'SendOffset'
            local BYTE = 1
            local SHORT = 2
            local INTEGER = 4
            local HALF_FLOAT = 2
            local FLOAT = 4
            local DOUBLE = 8
            local Types = {}
            local Asserts = {
                number = function(Variable, Min, Max)
                    return {
                        Lower = `if {Variable} < {Min} then error(\`Expected "{Variable}" to be larger than {Min}, got \{{Variable}} instead.\`) end`,
                        Upper = `if {Variable} > {Max} then error(\`Expected "{Variable}" to be smaller than {Max}, got \{{Variable}} instead.\`) end`,
                        Exact = `if {Variable} ~= {Max} then error(\`Expected "{Variable}" to be equal to {Max}, got \{{Variable}} instead.\`) end`,
                    }
                end,
                string = function(Variable, Min, Max)
                    return {
                        Lower = `if #{Variable} < {Min} then error(\`Expected length of "{Variable}" to be larger than {Min}, got \{#{Variable}} instead.\`) end`,
                        Upper = `if #{Variable} > {Max} then error(\`Expected length of "{Variable}" to be smaller than {Max}, got \{#{Variable}} instead.\`) end`,
                        Exact = `if #{Variable} ~= {Max} then error(\`Expected length of "{Variable}" to equal to {Max}, got \{#{Variable}} instead.\`) end`,
                    }
                end,
                vector = function(Variable, Min, Max)
                    return {
                        Lower = `if {Variable}.Magnitude < {Min} then error(\`Expected magnitude of "{Variable}" to be larger than {Min}, got \{{Variable}.Magnitude} instead.\`) end`,
                        Upper = `if {Variable}.Magnitude > {Max} then error(\`Expected magnitude of "{Variable}" to be smaller than {Max}, got \{{Variable}.Magnitude} instead.\`) end`,
                        Exact = `if {Variable}.Magnitude ~= {Max} then error(\`Expected magnitude of "{Variable}" to equal to {Max}, got \{{Variable}.Magnitude} instead.\`) end`,
                    }
                end,
                buffer = function(Variable, Min, Max)
                    return {
                        Lower = `if buffer.len({Variable}) < {Min} then error(\`Expected size of "{Variable}" to be larger than {Min}, got \{buffer.len({Variable})} instead.\`) end`,
                        Upper = `if buffer.len({Variable}) > {Max} then error(\`Expected size of "{Variable}" to be smaller than {Max}, got \{buffer.len({Variable})} instead.\`) end`,
                        Exact = `if buffer.len({Variable}) ~= {Max} then error(\`Expected size of "{Variable}" to equal to {Max}, got \{buffer.len({Variable})} instead.\`) end`,
                    }
                end,
                Instance = function(Variable, Class)
                    return {
                        Lower = `error("Something has gone wrong")`,
                        Upper = `error("Something has gone wrong")`,
                        Exact = `if typeof({Variable}) ~= "Instance" then error(\`Expected an Instance, got \{typeof({Variable})} instead.\`) end\nif not {Variable}:IsA("{Class}") then error(\`Expected an Instance of type "{Class}", got "\{{Variable}.ClassName}" instead.\`) end`,
                    }
                end,
            }
            local Structures = {Array = nil}
            local Primitives = {}
            local NumberTypeBounds = {
                {
                    Bits = 8,
                    Maximum = 255,
                    Type = 'u8',
                },
                {
                    Bits = 16,
                    Maximum = 65535,
                    Type = 'u16',
                },
                {
                    Bits = 32,
                    Maximum = 4294967295,
                    Type = 'u32',
                },
            }

            local function GetTypeToUse(UpperSize)
                for _, NumberType in NumberTypeBounds do
                    if NumberType.Maximum >= UpperSize then
                        return Types[NumberType.Type]
                    end
                end

                error('Value is too large to be written to a buffer.')
            end
            local function GetTypeToUseByBits(UpperBits)
                for _, NumberType in NumberTypeBounds do
                    if NumberType.Bits >= UpperBits then
                        return Types[NumberType.Type]
                    end
                end

                error('Value is too large to be written to a buffer.')
            end
            local function GeneratePrimitivePrefab(
                Type,
                Prefab,
                AssertGenerator
            )
                return function(
                    Declaration,
                    Variable,
                    Read,
                    Write,
                    WriteValidations
                )
                    local Value = Declaration.Value
                    local Tokens = Declaration.Tokens
                    local Variable = Variable or 'Value'
                    local Range = Value.Range
                    local Class = Value.Class
                    local Components = Value.Components
                    local Primitive = Tokens.Primitive.Value
                    local IsVariableSize = (Range and Range.Max ~= Range.Min)

                    local function GenerateValidation(Block, Variable)
                        if Block == Write and WriteValidations ~= true then
                            return
                        end
                        if Block == Write and Type ~= 'any' then
                            Block:Compare(`typeof({Variable})`, `"{Type}"`, 'Not'):Line(`error(\`Expected {Variable} to be of type {Type}, got \{type({Variable})} instead.\`)`):End()
                        end
                        if not AssertGenerator then
                            return
                        end
                        if Range then
                            local Assert = AssertGenerator(Variable, Range.Min, Range.Max)

                            if not IsVariableSize and Assert.Exact then
                                Block:Line(Assert.Exact)
                            else
                                Block:Line(Assert.Lower)
                                Block:Line(Assert.Upper)
                            end
                        elseif Primitive == 'Instance' and Class then
                            local Assert = AssertGenerator(Variable, Class)

                            if Block == Write then
                                Block:Compare(Variable, 'nil', 'Not'):Multiline(Assert.Exact, Block.Indent + 1):End()
                            else
                                Block:Multiline(Assert.Exact, Block.Indent)
                            end
                        end
                    end

                    GenerateValidation(Write, Variable)
                    Prefab.Read(Variable, Read, Range, Components)
                    Prefab.Write(Variable, Write, Range, Components)
                    GenerateValidation(Read, Variable)
                end
            end
            local function GenerateNumberGenerator(Type, Size)
                local Prefab = {
                    Read = function(Variable, Block)
                        Block:Line(`{Block:Declare(Variable)} = buffer.read{Type}({RECIEVE_BUFFER}, {Block:Read(Size)})`)
                    end,
                    Write = function(Value, Block)
                        Block:Line(`buffer.write{Type}({SEND_BUFFER}, {Block:Allocate(Size)}, {Value})`)
                    end,
                }
                local Primitive = {
                    Type = 'number',
                    Generate = GeneratePrimitivePrefab('number', Prefab, Asserts.number),
                }

                return Prefab, Primitive
            end

            Types.u8, Primitives.u8 = GenerateNumberGenerator('u8', BYTE)
            Types.u16, Primitives.u16 = GenerateNumberGenerator('u16', SHORT)
            Types.u32, Primitives.u32 = GenerateNumberGenerator('u32', INTEGER)
            Types.i8, Primitives.i8 = GenerateNumberGenerator('i8', BYTE)
            Types.i16, Primitives.i16 = GenerateNumberGenerator('i16', SHORT)
            Types.i32, Primitives.i32 = GenerateNumberGenerator('i32', INTEGER)
            Types.f32, Primitives.f32 = GenerateNumberGenerator('f32', FLOAT)
            Types.f64, Primitives.f64 = GenerateNumberGenerator('f64', DOUBLE)
            Types.f16 = {
                Read = function(Variable, Block)
                    Types.u16.Read('Encoded', Block)
                    Block:Declare(Variable, true)
                    Block:Line(`local MantissaExponent = Encoded % 0x8000`)
                    Block:Compare('MantissaExponent', '0b0_11111_0000000000 ', 'Equals'):Compare('Encoded // 0x8000', '1', 'Equals'):Line(`{Variable} = -math.huge`):Branch('Default'):Line(`{Variable} = math.huge`):End():Branch('Conditional', 'MantissaExponent', '0b1_11111_0000000000  ', 'Equals'):Line(`{Variable} = 0 / 0`):Branch('Conditional', 'MantissaExponent', '0b0_00000_0000000000  ', 'Equals'):Line(`{Variable} = 0`):Branch('Default'):Lines({
                        'local Mantissa = MantissaExponent % 0x400\n',
                        'local Exponent = MantissaExponent // 0x400\n',
                        'local Fraction;\n',
                        'if Exponent == 0 then\n',
                        '\tFraction = Mantissa / 0x400\n',
                        'else\n',
                        '\tFraction = Mantissa / 0x800 + 0.5\n',
                        'end\n',
                        'local Result = math.ldexp(Fraction, Exponent - 14)\n',
                    }, Block.Indent + 1):Line(`{Variable} = if Encoded // 0x8000 == 1 then -Result else Result`):End()
                end,
                Write = function(Value, Block)
                    local Allocation = Block:Allocate(HALF_FLOAT)

                    Block:Compare(Value, '65504', 'Greater'):Line(`buffer.writeu16({SEND_BUFFER}, {Allocation}, 0b0_11111_0000000000)`):Branch('Conditional', Value, '-65504', 'Less'):Line(`buffer.writeu16({SEND_BUFFER}, {Allocation}, 0b1_11111_0000000000)`):Branch('Conditional', Value, Value, 'Not'):Line(`buffer.writeu16({SEND_BUFFER}, {Allocation}, 0b1_11111_0000000001)`):Branch('Conditional', Value, '0', 'Equals'):Line(`buffer.writeu16({SEND_BUFFER}, {Allocation}, 0)`):Branch('Default'):Line(`local float = {Value}`):Lines({
                        'local Abosulte = math.abs(float)\n',
                        
[[local Interval = math.ldexp(1, math.floor(math.log(Abosulte, 2)) - 10)
]],
                        'local RoundedValue = (Abosulte // Interval) * Interval\n',
                        'local Fraction, Exponent = math.frexp(RoundedValue)\n',
                        'Exponent += 14\n',
                        'local Mantissa = math.round(if Exponent <= 0\n',
                        '\tthen Fraction * 0x400 / math.ldexp(1, math.abs(Exponent))\n',
                        '\telse Fraction * 0x800) % 0x400\n',
                        'local Result = Mantissa\n',
                        '\t+ math.max(Exponent, 0) * 0x400\n',
                        '\t+ if float < 0 then 0x8000 else 0\n',
                    }, Block.Indent + 1):Line(`buffer.writeu16({SEND_BUFFER}, {Allocation}, Result)`):End()
                end,
            }
            Primitives.f16 = {
                Type = 'number',
                Generate = GeneratePrimitivePrefab('number', Types.f16, Asserts.number),
            }

            do
                Types.boolean = {
                    Read = function(Variable, Block)
                        Block:Line(`{Block:Declare(Variable)} = (buffer.readu8({RECIEVE_BUFFER}, {Block:Read(BYTE)}) == 1)`)
                    end,
                    Write = function(Value, Block)
                        Block:Line(`buffer.writeu8({SEND_BUFFER}, {Block:Allocate(BYTE)}, {Value} and 1 or 0)`)
                    end,
                }
                Primitives.boolean = {
                    Type = 'boolean',
                    Generate = GeneratePrimitivePrefab('boolean', Types.boolean),
                }
            end
            do
                Types.string = {
                    Read = function(Variable, Block, Range)
                        if Range and Range.Min == Range.Max then
                            Block:Line(`{Block:Declare(Variable)} = buffer.readstring({RECIEVE_BUFFER}, {Block:Read(Range.Min)}, {Range.Min})`)

                            return
                        end

                        local Upper = Range and Range.Max or (65535)
                        local LengthType = GetTypeToUse(Upper)

                        LengthType.Read('Length', Block)
                        Block:Line(`{Block:Declare(Variable)} = buffer.readstring({RECIEVE_BUFFER}, Read(Length), Length)`)
                    end,
                    Write = function(Value, Block, Range)
                        if Range and Range.Min == Range.Max then
                            Block:Line(`buffer.writestring({SEND_BUFFER}, {Block:Allocate(Range.Min)}, {Value}, {Range.Min})`)

                            return
                        end

                        local Upper = Range and Range.Max or (65535)
                        local LengthType = GetTypeToUse(Upper)

                        Block:Line(`local Length = #{Value}`)
                        LengthType.Write('Length', Block)
                        Block:Line(`Allocate(Length)`)
                        Block:Line(`buffer.writestring({SEND_BUFFER}, {SEND_POSITION}, {Value}, Length)`)
                    end,
                }
                Primitives.string = {
                    Type = 'string',
                    Generate = GeneratePrimitivePrefab('string', Types.string, Asserts.string),
                }
            end
            do
                Types.vector = {
                    Read = function(Variable, Block, _, Components)
                        local Prefab = Types.f32

                        if Components then
                            Prefab = Types[Components[#Components] ] or Prefab
                        end

                        Prefab.Read('X', Block)
                        Prefab.Read('Y', Block)
                        Prefab.Read('Z', Block)
                        Block:Line(`{Block:Declare(Variable)} = Vector3.new(X, Y, Z)`)
                    end,
                    Write = function(Value, Block, _, Components)
                        local Prefab = Types.f32

                        if Components then
                            Prefab = Types[Components[#Components] ] or Prefab
                        end

                        Block:Line(`local Vector = {Value}`)
                        Prefab.Write('Vector.X', Block)
                        Prefab.Write('Vector.Y', Block)
                        Prefab.Write('Vector.Z', Block)
                    end,
                }
                Primitives.vector = {
                    Type = 'Vector3',
                    Generate = GeneratePrimitivePrefab('Vector3', Types.vector, Asserts.vector),
                }
            end
            do
                Types.buffer = {
                    Read = function(Variable, Block, Range)
                        if Range and Range.Min == Range.Max then
                            local Length = Range.Max

                            Block:Line(`{Block:Declare(Variable)} = buffer.create({Length})`)
                            Block:Line(`buffer.copy({Variable}, 0, {RECIEVE_BUFFER}, {Block:Read(Length)}, {Length})`)

                            return
                        end

                        local Upper = Range and Range.Max or (65535)
                        local LengthType = GetTypeToUse(Upper)

                        LengthType.Read('Length', Block)
                        Block:Line(`{Block:Declare(Variable)} = buffer.create(Length)`)
                        Block:Line(`buffer.copy({Variable}, 0, {RECIEVE_BUFFER}, Read(Length), Length)`)
                    end,
                    Write = function(Value, Block, Range)
                        if Range and Range.Min == Range.Max then
                            Block:Line(`buffer.copy({SEND_BUFFER}, {Block:Allocate(Range.Max)}, {Value}, 0, {Range.Max})`)

                            return
                        end

                        local Upper = Range and Range.Max or (65535)
                        local LengthType = GetTypeToUse(Upper)

                        Block:Line(`local Length = buffer.len({Value})`)
                        LengthType.Write('Length', Block)
                        Block:Line(`Allocate(Length)`)
                        Block:Line(`buffer.copy({SEND_BUFFER}, {SEND_POSITION}, {Value}, 0, Length)`)
                    end,
                }
                Primitives.buffer = {
                    Type = 'buffer',
                    Generate = GeneratePrimitivePrefab('buffer', Types.buffer, Asserts.buffer),
                }
            end
            do
                Types.CFrame = {
                    Read = function(Variable, Block, _, Components)
                        local Prefab = Types.f32

                        if Components then
                            Prefab = Types[Components[1] ]
                        end

                        Types.vector.Read('Position', Block, nil, Components)
                        Prefab.Read('rX', Block)
                        Prefab.Read('rY', Block)
                        Prefab.Read('rZ', Block)
                        Block:Line(`{Block:Declare(Variable)} = CFrame.new(Position) * CFrame.fromOrientation(rX, rY, rZ)`)
                    end,
                    Write = function(Value, Block, _, Components)
                        local Prefab = Types.f32

                        if Components then
                            Prefab = Types[Components[1] ]
                        end

                        Types.vector.Write(`{Value}.Position`, Block, nil, Components)
                        Block:Line(`local rX, rY, rZ = {Value}:ToOrientation()`)
                        Prefab.Write('rX', Block)
                        Prefab.Write('rY', Block)
                        Prefab.Write('rZ', Block)
                    end,
                }
                Primitives.CFrame = {
                    Type = 'CFrame',
                    Generate = GeneratePrimitivePrefab('CFrame', Types.CFrame),
                }
            end
            do
                Types.Color3 = {
                    Read = function(Variable, Block)
                        local R = Block:Read(BYTE)
                        local G = Block:Read(BYTE)
                        local B = Block:Read(BYTE)

                        Block:Line(`{Block:Declare(Variable)} = Color3.fromRGB(buffer.readu8({RECIEVE_BUFFER}, {R}), buffer.readu8({RECIEVE_BUFFER}, {G}), buffer.readu8({RECIEVE_BUFFER}, {B}))`)
                    end,
                    Write = function(Value, Block)
                        Block:Line(`local Color = {Value}`)
                        Types.u8.Write('Color.R * 255', Block)
                        Types.u8.Write('Color.G * 255', Block)
                        Types.u8.Write('Color.B * 255', Block)
                    end,
                }
                Primitives.Color3 = {
                    Type = 'Color3',
                    Generate = GeneratePrimitivePrefab('Color3', Types.Color3),
                }
            end
            do
                Types.DateTime = {
                    Read = function(Variable, Block)
                        local UnixTimestamp = Block:Read(BYTE)

                        Block:Line(`{Block:Declare(Variable)} = DateTime.fromUnixTimestamp(buffer.readf64({RECIEVE_BUFFER}, {UnixTimestamp}))`)
                    end,
                    Write = function(Value, Block)
                        Block:Line(`local DateTime = {Value}`)
                        Types.f64.Write(`DateTime.UnixTimestamp`, Block)
                    end,
                }
                Primitives.DateTime = {
                    Type = 'DateTime',
                    Generate = GeneratePrimitivePrefab('DateTime', Types.DateTime),
                }
            end
            do
                Types.DateTimeMillis = {
                    Read = function(Variable, Block)
                        local UnixTimestampMillis = Block:Read(BYTE)

                        Block:Line(`{Block:Declare(Variable)} = DateTime.fromUnixTimestampMillis(buffer.readf64({RECIEVE_BUFFER}, {UnixTimestampMillis}))`)
                    end,
                    Write = function(Value, Block)
                        Block:Line(`local DateTimeMillis = {Value}`)
                        Types.f64.Write(`DateTimeMillis.UnixTimestampMillis`, Block)
                    end,
                }
                Primitives.DateTimeMillis = {
                    Type = 'DateTime',
                    Generate = GeneratePrimitivePrefab('DateTime', Types.DateTimeMillis),
                }
            end
            do
                Types.BrickColor = {
                    Read = function(Variable, Block)
                        local Number = Block:Read(SHORT)

                        Block:Line(`{Block:Declare(Variable)} = BrickColor.new(buffer.readu16({RECIEVE_BUFFER}, {Number}))`)
                    end,
                    Write = function(Value, Block)
                        Block:Line(`local BrickColor = {Value}`)
                        Types.u16.Write('BrickColor.Number', Block)
                    end,
                }
                Primitives.BrickColor = {
                    Type = 'BrickColor',
                    Generate = GeneratePrimitivePrefab('BrickColor', Types.BrickColor),
                }
            end
            do
                Types.Instance = {
                    Read = function(Variable, Block)
                        Block:Line(`{Block:Declare(Variable)} = RecieveInstances[RecieveInstanceCursor]`)
                    end,
                    Write = function(Value, Block)
                        Block:Line(`table.insert(SendInstances, {Value} or Null)`)
                    end,
                }
                Primitives.Instance = {
                    Type = function(Declaration)
                        return Declaration.Value.Class
                    end,
                    Generate = GeneratePrimitivePrefab('any', Types.Instance, Asserts.Instance),
                }
            end
            do
                Types.unknown = {
                    Read = function(Variable, Block)
                        Block:Line('RecieveInstanceCursor += 1')
                        Block:Line(`{Block:Declare(Variable)} = RecieveInstances[RecieveInstanceCursor]`)
                    end,
                    Write = function(Value, Block)
                        Block:Line(`table.insert(SendInstances, if {Value} == nil then Null else {Value})`)
                    end,
                }
                Primitives.unknown = {
                    Type = 'any',
                    Generate = GeneratePrimitivePrefab('any', Types.unknown),
                }
            end

            return {
                Types = Types,
                Asserts = Asserts,
                Primitives = Primitives,
                Structures = Structures,
                GetTypeToUse = GetTypeToUse,
                GetTypeToUseByBits = GetTypeToUseByBits,
            }
        end

        function __DARKLUA_BUNDLE_MODULES.j()
            local v = __DARKLUA_BUNDLE_MODULES.cache.j

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.j = v
            end

            return v.c
        end
    end
    do
        local function __modImpl()
            local Parser = __DARKLUA_BUNDLE_MODULES.g()

            local function GetScopePrefix(ReferenceScope, Dots, CurrentScope)
                local Prefix = ''
                local WorkingScope = ReferenceScope or CurrentScope

                while WorkingScope and WorkingScope.Name.Value ~= '' do
                    Prefix = `{WorkingScope.Name.Value}{Dots and '.' or '_'}` .. Prefix
                    WorkingScope = WorkingScope.Parent
                end

                return Prefix
            end
            local function GetScopeIndent(CurrentScope)
                return math.max(#string.split(GetScopePrefix(nil, true, CurrentScope), '.'), 1)
            end
            local function GetTypesPath(Name, Write, CurrentScope)
                return `{GetScopePrefix(nil, false, CurrentScope)}{Write and 'Write' or 'Read'}{Name}`
            end
            local function GetExportName(Name, CurrentScope)
                return `{GetScopePrefix(nil, false, CurrentScope)}{Name}`
            end
            local function GenerateEnumLiterals(Variants)
                local Literals = {}

                for Index, EnumItem in Variants do
                    table.insert(Literals, `"{EnumItem}"`)
                end

                return `{table.concat(Literals, ' | ')}`
            end

            return {
                GetPath = GetTypesPath,
                GetExportName = GetExportName,
                GetScopePrefix = GetScopePrefix,
                GetScopeIndent = GetScopeIndent,
                GenerateEnumLiterals = GenerateEnumLiterals,
            }
        end

        function __DARKLUA_BUNDLE_MODULES.k()
            local v = __DARKLUA_BUNDLE_MODULES.cache.k

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.k = v
            end

            return v.c
        end
    end
    do
        local function __modImpl()
            local Parser = __DARKLUA_BUNDLE_MODULES.g()
            local Settings = __DARKLUA_BUNDLE_MODULES.b()
            local Blocks = __DARKLUA_BUNDLE_MODULES.i()
            local Prefabs = __DARKLUA_BUNDLE_MODULES.j()
            local Util = __DARKLUA_BUNDLE_MODULES.k()
            local Builder = __DARKLUA_BUNDLE_MODULES.h()
            local TESTING_HEADER = 
[[type Instance = number
type Player = number
type CFrame = number
type Vector3 = number
type Color3 = number
type Sound = number
type buffer = number
]]
            local VERSION_HEADER = `// File generated by Blink v{'0.18.6' or '0.0.0'} (https://github.com/1Axen/Blink)\n// This file is not meant to be edited\n`
            local Generators = {}
            local Primitives = Prefabs.Primitives

            local function GetPrefix(Indent)
                return Indent == 0 and 'declare ' or ''
            end
            local function IsValidIdentifier(Identifier)
                return Identifier:match('%a%w*') == Identifier
            end
            local function FormatKey(Key)
                if IsValidIdentifier(Key) then
                    return Key
                end

                return `["{Key}"]`
            end
            local function GetTypescriptType(State, Declaration)
                local Type = ''
                local Values = ''

                if Declaration.Type == 'Primitive' then
                    local Tokens = (Declaration).Tokens
                    local Primitive = Primitives[Tokens.Primitive.Value]

                    if type(Primitive.Type) == 'function' then
                        Type = Primitive.Type(Declaration)
                    else
                        Type = Primitive.Type
                    end
                    if Type == 'any' then
                        Type = 'unknown'
                    end
                elseif Declaration.Type == 'Set' then
                    local Value = (Declaration).Value
                    local Entries = {}

                    for _, Flag in Value.Values do
                        table.insert(Entries, `{FormatKey(Flag)}: boolean,`)
                    end

                    Type = `\{{table.concat(Entries)}}`
                elseif Declaration.Type == 'Enum' then
                    local Value = (Declaration).Value

                    Type = Util.GenerateEnumLiterals(Value.Values)
                elseif Declaration.Type == 'TagEnum' then
                    local Value = (Declaration).Value
                    local Literals = {}

                    for Index, Variant in Value.Values do
                        local TagField = `{Value.Tag}: "{Variant.Name}"`
                        local ValueType = GetTypescriptType(State, Variant)

                        table.insert(Literals, `\{ {TagField},{string.sub(ValueType, 2)}`)
                    end

                    Type = table.concat(Literals, ' | ')
                elseif Declaration.Type == 'Map' then
                    local MapValue = (Declaration).Value
                    local Key = GetTypescriptType(State, MapValue.Values[1])
                    local Value = GetTypescriptType(State, MapValue.Values[2])

                    Type = `Map<{Key}, {Value}>`
                elseif Declaration.Type == 'Struct' then
                    local Value = Declaration.Value
                    local Fields = {}

                    for _, Field in Value.Values do
                        local Name = Field.Name
                        local FieldType = GetTypescriptType(State, Field)
                        local Optional = Field.Type == 'Optional' and '?' or ''

                        table.insert(Fields, `{FormatKey(Name)}{Optional}: {FieldType}`)
                    end

                    Type = `\{ {table.concat(Fields, ', ')} }`
                elseif Declaration.Type == 'Generic' then
                    Type = `{Declaration.Value.Generic}`
                elseif Declaration.Type == 'Tuple' then
                    local Value = (Declaration).Value
                    local TupleValues = Value.Values
                    local Types = {}
                    local Variables = {}
                    local VariableTypes = {}

                    for Index, TupleValue in TupleValues do
                        local Variable = `Value{Index}`
                        local ValueType = GetTypescriptType(State, TupleValue)

                        table.insert(Types, ValueType)
                        table.insert(Variables, Variable)
                        table.insert(VariableTypes, `{Variable}: {ValueType}`)
                    end

                    Type = `{table.concat(Types, ', ')}`
                    Values = table.concat(VariableTypes, ', ')
                elseif Declaration.Type == 'Array' then
                    local Value = Declaration.Value

                    Type = `{GetTypescriptType(State, Value.Of)}[]`
                elseif Declaration.Type == 'Optional' then
                    local Value = Declaration.Value

                    Type = `{GetTypescriptType(State, Value.Of)} | undefined`
                end

                local Value = Declaration.Value

                if Value.Parameters then
                    local Parameters = {}

                    for Index, Parameter in Value.Parameters do
                        local ParameterType = GetTypescriptType(State, Parameter)

                        table.insert(Parameters, ParameterType)
                    end

                    Type = `{Type}<{table.concat(Parameters, ',')}>`
                end
                if Declaration.Type ~= 'Tuple' then
                    Values = `Value: {Type}`
                else
                    Type = `LuaTuple<[{Type}]>`
                end

                return Type, Values
            end

            function Generators.Type(State, Type)
                local Name = Type.Name
                local Value = Type.Value
                local Indent = State.Indent
                local StringBuilder = State.Builder
                local TypescriptType = GetTypescriptType(State, Type)
                local Generics = ''

                if Value.Generics then
                    local Types = {}

                    for _, Generic in Value.Generics.List do
                        table.insert(Types, Generic)
                    end

                    Generics = `<{table.concat(Types, ',')}>`
                end

                StringBuilder.Push(`type {Name}{Generics} = {TypescriptType}`, 0, Indent)
            end
            function Generators.Export(State, Type)
                local Name = Type.Name
                local Indent = State.Indent
                local Casing = State.Casing
                local StringBuilder = State.Builder
                local Types, Values = GetTypescriptType(State, Type)

                StringBuilder.Push(`{GetPrefix(Indent)}const {Name}: \{`, 0, Indent)
                StringBuilder.Push(`{Casing.Read}: (Buffer: buffer) => {Types}`, 0, Indent + 1)
                StringBuilder.Push(`{Casing.Write}: ({Values}) => buffer`, 0, Indent + 1)
                StringBuilder.Push(`}`, 0, Indent)
            end
            function Generators.Function(State, Function)
                local Name = Function.Name
                local Value = Function.Value
                local Indent = State.Indent
                local Casing = State.Casing
                local StringBuilder = State.Builder
                local _, Values = 'void', 'Value: void'

                if Value.Data then
                    _, Values = GetTypescriptType(State, Value.Data)
                end

                local ReturnTypes = 'void'

                if Value.Return then
                    ReturnTypes = GetTypescriptType(State, Value.Return)
                end

                StringBuilder.Push(`export {GetPrefix(Indent)}const {Name}: \{`, 0, Indent)

                if State.Context == 'Server' then
                    StringBuilder.Push(`{Casing.On}: (Listener: (Player: Player, {Values}) => {ReturnTypes}) => void`, 0, Indent + 1)
                else
                    if Value.Yield == 'Promise' then
                        ReturnTypes = `Promise<{ReturnTypes}>`
                    end

                    StringBuilder.Push(`{Casing.Invoke}: ({Values}) => {ReturnTypes}`, 0, Indent + 1)
                end

                StringBuilder.Push(`}`, 0, Indent)
            end
            function Generators.Event(State, Event)
                local Name = Event.Name
                local Value = Event.Value
                local Indent = State.Indent
                local Casing = State.Casing
                local StringBuilder = State.Builder
                local IsPolling = Value.Call == 'Polling' or State.Options.UsePolling
                local _, Values = '', 'Value: void'

                if Value.Data then
                    _, Values = GetTypescriptType(State, Value.Data)
                end

                local ListenerValues = Values

                if Value.From == 'Client' then
                    ListenerValues = `Player: Player, {Values}`
                end
                if IsPolling then
                    ListenerValues = `Index: number, {ListenerValues}`
                    ListenerValues = `LuaTuple<[{ListenerValues}]>`
                end

                StringBuilder.Push(`export {GetPrefix(Indent)}const {Name}: \{`, 0, Indent)

                if Value.From == State.Context then
                    if Value.From == 'Server' then
                        StringBuilder.Push(`{Casing.Fire}: (Player: Player, {Values}) => void`, 0, Indent + 1)
                        StringBuilder.Push(`{Casing.FireAll}: ({Values}) => void`, 0, Indent + 1)
                        StringBuilder.Push(`{Casing.FireExcept}: (Except: Player, {Values}) => void`, 0, Indent + 1)
                        StringBuilder.Push(`{Casing.FireList}: (List: Player[], {Values}) => void`, 0, Indent + 1)
                    else
                        StringBuilder.Push(`{Casing.Fire}: ({Values}) => void`, 0, Indent + 1)
                    end
                elseif IsPolling then
                    StringBuilder.Push(`{Casing.Iter}: () => IterableFunction<{ListenerValues}>`, 0, Indent + 1)
                else
                    StringBuilder.Push(`{Casing.On}: (Listener: ({ListenerValues}) => void) => (() => void)`, 0, Indent + 1)
                end

                StringBuilder.Push(`}`, 0, Indent)
            end
            function Generators.Scope(State, Scope)
                local Name = Scope.Name
                local Value = Scope.Value
                local Parent = State.Scope
                local Indent = State.Indent
                local StringBuilder = State.Builder

                State.Indent += 1

                State.Scope = Value.Scope

                StringBuilder.Push(`export {GetPrefix(Indent)}namespace {Name} \{`, 0, Indent)
                Generators.Tree(State, Value.Values)
                StringBuilder.Push(`}`, 0, Indent)

                State.Indent -= 1

                State.Scope = Parent
            end
            function Generators.Tree(State, Tree)
                for Index, Declaration in Tree do
                    if Declaration.Type == 'Scope' then
                        Generators.Scope(State, Declaration)
                    elseif Declaration.Type == 'Event' then
                        Generators.Event(State, Declaration)
                    elseif Declaration.Type == 'Function' then
                        Generators.Function(State, Declaration)
                    else
                        if Declaration.Value.Export then
                            Generators.Export(State, Declaration)
                        end

                        Generators.Type(State, Declaration)
                    end
                end
            end

            return function(FileContext, AbstractSyntaxTree)
                local Options = AbstractSyntaxTree.Value.Options
                local Casing = Settings.GetCasing(Options.Casing or 'Pascal')
                local StringBuilder = Builder.new()

                StringBuilder.Push(VERSION_HEADER)
                StringBuilder.Push(`export declare const {Casing.StepReplication}: () => void`)

                if '0.18.6' == nil then
                    StringBuilder.Push(TESTING_HEADER)
                end

                local State = {
                    Scope = nil,
                    Indent = 0,
                    Casing = Casing,
                    Context = FileContext,
                    Options = Options,
                    Builder = StringBuilder,
                }

                Generators.Tree(State, AbstractSyntaxTree.Value.Declarations)

                return table.concat(StringBuilder.DumpLines())
            end
        end

        function __DARKLUA_BUNDLE_MODULES.l()
            local v = __DARKLUA_BUNDLE_MODULES.cache.l

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.l = v
            end

            return v.c
        end
    end
    do
        local function __modImpl()
            return 
[[local Invocations = 0

local SendSize = 64
local SendOffset = 0
local SendCursor = 0
local SendBuffer = buffer.create(64)
local SendInstances = {}

local RecieveCursor = 0
local RecieveBuffer = buffer.create(64)

local RecieveInstances = {}
local RecieveInstanceCursor = 0

local Null = newproxy()

type Entry = {
    value: any,
    next: Entry?
}

type Queue = {
    head: Entry?,
    tail: Entry?
}

type BufferSave = {
    Size: number, 
    Cursor: number, 
    Buffer: buffer, 
    Instances: {Instance}
}

local function Read(Bytes: number)
    local Offset = RecieveCursor
    RecieveCursor += Bytes
    return Offset
end

local function Save(): BufferSave
    return {
        Size = SendSize,
        Cursor = SendCursor,
        Buffer = SendBuffer,
        Instances = SendInstances
    }
end

local function Load(Save: BufferSave?)
    if Save then
        SendSize = Save.Size
        SendCursor = Save.Cursor
        SendOffset = Save.Cursor
        SendBuffer = Save.Buffer
        SendInstances = Save.Instances
        return
    end

    SendSize = 64
    SendCursor = 0
    SendOffset = 0
    SendBuffer = buffer.create(64)
    SendInstances = {}
end

local function Invoke()
    if Invocations == 255 then
        Invocations = 0
    end

    local Invocation = Invocations
    Invocations += 1
    return Invocation
end

local function Allocate(Bytes: number)
    local InUse = (SendCursor + Bytes)
    if InUse > SendSize then
        --> Avoid resizing the buffer for every write
        while InUse > SendSize do
            SendSize *= 1.5
        end

        local Buffer = buffer.create(SendSize)
        buffer.copy(Buffer, 0, SendBuffer, 0, SendCursor)
        SendBuffer = Buffer
    end

    SendOffset = SendCursor
    SendCursor += Bytes
    
    return SendOffset
end

local function CreateQueue(): Queue
    return {
        head = nil,
        tail = nil
    }
end

local function Pop(queue: Queue): any
    local head = queue.head
    if head == nil then
        return
    end

    queue.head = head.next
    return head.value
end

local function Push(queue: Queue, value: any)
    local entry: Entry = {
        value = value,
        next = nil
    }

    if queue.tail ~= nil then
        queue.tail.next = entry
    end

    queue.tail = entry

    if queue.head == nil then
        queue.head = entry
    end
end

local Calls = table.create(256)

local Events: any = {
    Reliable = table.create(256),
    Unreliable = table.create(256)
}

local Queue: any = {
    Reliable = table.create(256),
    Unreliable = table.create(256)
}

]]
        end

        function __DARKLUA_BUNDLE_MODULES.m()
            local v = __DARKLUA_BUNDLE_MODULES.cache.m

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.m = v
            end

            return v.c
        end
    end
    do
        local function __modImpl()
            return 
[[local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- SPLIT --
if not RunService:IsClient() then
    error("Client network module can only be required from the client.")
end

local Reliable: RemoteEvent = ReplicatedStorage:WaitForChild(BASE_EVENT_NAME .. "_RELIABLE_REMOTE") :: RemoteEvent
local Unreliable: UnreliableRemoteEvent = ReplicatedStorage:WaitForChild(BASE_EVENT_NAME .. "_UNRELIABLE_REMOTE") :: UnreliableRemoteEvent

local function StepReplication()
    if SendCursor <= 0 then
        return
    end

    local Buffer = buffer.create(SendCursor)
    buffer.copy(Buffer, 0, SendBuffer, 0, SendCursor)
    Reliable:FireServer(Buffer, SendInstances)

    SendSize = 64
    SendCursor = 0
    SendOffset = 0
    SendBuffer = buffer.create(64)
    table.clear(SendInstances)
end
]]
        end

        function __DARKLUA_BUNDLE_MODULES.n()
            local v = __DARKLUA_BUNDLE_MODULES.cache.n

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.n = v
            end

            return v.c
        end
    end
    do
        local function __modImpl()
            return 
[[local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- SPLIT --
if not RunService:IsServer() then
    error("Server network module can only be required from the server.")
end

local Reliable: RemoteEvent = ReplicatedStorage:FindFirstChild(BASE_EVENT_NAME .. "_RELIABLE_REMOTE") :: RemoteEvent
if not Reliable then
    local RemoteEvent = Instance.new("RemoteEvent")
    RemoteEvent.Name = BASE_EVENT_NAME .. "_RELIABLE_REMOTE"
    RemoteEvent.Parent = ReplicatedStorage
    Reliable = RemoteEvent
end

local Unreliable: UnreliableRemoteEvent = ReplicatedStorage:FindFirstChild(BASE_EVENT_NAME .. "_UNRELIABLE_REMOTE") :: UnreliableRemoteEvent
if not Unreliable then
    local UnreliableRemoteEvent = Instance.new("UnreliableRemoteEvent")
    UnreliableRemoteEvent.Name = BASE_EVENT_NAME .. "_UNRELIABLE_REMOTE"
    UnreliableRemoteEvent.Parent = ReplicatedStorage
    Unreliable = UnreliableRemoteEvent
end

local PlayersMap: {[Player]: BufferSave} = {}

Players.PlayerRemoving:Connect(function(Player)
    PlayersMap[Player] = nil
end)

local function StepReplication()
    for Player, Send in PlayersMap do
        if Send.Cursor <= 0 then
            continue
        end

        local Buffer = buffer.create(Send.Cursor)
        buffer.copy(Buffer, 0, Send.Buffer, 0, Send.Cursor)
        Reliable:FireClient(Player, Buffer, Send.Instances)

        Send.Size = 64
        Send.Cursor = 0
        Send.Buffer = buffer.create(64)
        table.clear(Send.Instances)
    end
end
]]
        end

        function __DARKLUA_BUNDLE_MODULES.o()
            local v = __DARKLUA_BUNDLE_MODULES.cache.o

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.o = v
            end

            return v.c
        end
    end
    do
        local function __modImpl()
            local Parser = __DARKLUA_BUNDLE_MODULES.g()
            local Settings = __DARKLUA_BUNDLE_MODULES.b()
            local Builder = __DARKLUA_BUNDLE_MODULES.h()
            local Table = __DARKLUA_BUNDLE_MODULES.e()
            local Blocks = __DARKLUA_BUNDLE_MODULES.i()
            local GenerateTypescript = __DARKLUA_BUNDLE_MODULES.l()
            local Prefabs = __DARKLUA_BUNDLE_MODULES.j()
            local Util = __DARKLUA_BUNDLE_MODULES.k()
            local Sources = {
                Base = __DARKLUA_BUNDLE_MODULES.m(),
                Shared = {
                    '',
                    '',
                },
                Client = string.split(__DARKLUA_BUNDLE_MODULES.n(), '-- SPLIT --'),
                Server = string.split(__DARKLUA_BUNDLE_MODULES.o(), '-- SPLIT --'),
            }
            local EVENTS_TYPE = 'BLINK_EVENTS_SYMBOL'
            local DIRECTIVES = {
                '--!strict\n',
                '--!native\n',
                '--!optimize 2\n',
                '--!nolint LocalShadow\n',
                '--#selene: allow(shadowing)\n',
            }
            local VERSION_HEADER = {
                `-- File generated by Blink v{'0.18.6' or '0.0.0'} (https://github.com/1Axen/Blink)\n-- This file is not meant to be edited\n\n`,
            }
            local EVENT_BODY = {
                'RecieveCursor = 0\n',
                'RecieveBuffer = Buffer\n',
                'RecieveInstances = Instances\n',
                'RecieveInstanceCursor = 0\n',
                'local Size = buffer.len(RecieveBuffer)\n',
            }
            local SYNC_VALIDATION_BODY = {
                `local SerdesEvent = "?"\n`,
                'local SerdesThread: thread?\n',
            }
            local EVENT_SYNC_VALIDATION = {
                `if SerdesThread and coroutine.status(SerdesThread) == "suspended" then\n`,
                '\twarn(`[Blink]: Yielded in a Sync call. Event "{SerdesEvent}" uses a Sync call, consider using an Async call instead.`)\n',
                '\tcoroutine.close(SerdesThread)\n',
                'end\n',
                'SerdesThread = coroutine.running()\n',
            }
            local RELIABLE_BODY = {
                Header = 
[[local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances]],
                Body = {
                    'Load(PlayersMap[Player])\n',
                    'local Position = Allocate(Size)\n',
                    'buffer.copy(SendBuffer, Position, Buffer, 0, Size)\n',
                    
[[table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
]],
                    'PlayersMap[Player] = Save()\n',
                },
            }
            local UNRELIABLE_BODY = {
                'local Buffer = buffer.create(SendCursor)\n',
                'buffer.copy(Buffer, 0, SendBuffer, 0, SendCursor)\n',
            }
            local IGNORED_TYPES_IN_SHARED = {
                Event = true,
                Function = true,
            }
            local Scope
            local Context
            local Casing
            local Noop
            local Events
            local UserTypes
            local LuauTypes
            local Reliables
            local Unreliables
            local Return
            local Options
            local Generators = {}
            local Declarations = {}
            local Channels = {
                Reliable = {
                    Count = 0,
                    Listening = false,
                },
                Unreliable = {
                    Count = 0,
                    Listening = false,
                },
            }
            local Types = Prefabs.Types
            local Primitives = Prefabs.Primitives
            local Structures = Prefabs.Structures

            local function IsValidIdentifier(Identifier)
                return Identifier:match('%a%w*') == Identifier
            end
            local function FormatKey(Key)
                if not IsValidIdentifier(Key) then
                    return `["{Key}"]`
                end

                return Key
            end
            local function FormatIndex(Index)
                if not IsValidIdentifier(Index) then
                    return `["{Index}"]`
                end

                return `.{Index}`
            end
            local function BitIndexToHex(Index)
                return `0x{string.format('%x', 2 ^ Index)}`
            end

            function Declarations.Primitive(Declaration, Read, Write, Variable)
                local Tokens = Declaration.Tokens
                local Primitive = Tokens.Primitive.Value
                local Generator = Primitives[Primitive]

                Generator.Generate(Declaration, Variable, Read, Write, Options.WriteValidations)
            end
            function Declarations.Set(Declaration, Read, Write, Variable)
                local Value = Declaration.Value
                local Flags = Value.Values

                do
                    Read:Line(`{Read:Declare(Variable)} = \{}`)

                    local Remaining = #Flags
                    local FlagIndex = 1

                    while Remaining > 0 do
                        local Partition = math.min(Remaining, 32)

                        Prefabs.GetTypeToUseByBits(Partition).Read('SET_BITS', Read)

                        for Index = 1, Partition do
                            local Flag = Flags[FlagIndex]

                            Read:EmptyDeclare(Flag)
                            Read:Line(`{Variable}{FormatIndex(Flag)} = bit32.btest(SET_BITS, {BitIndexToHex(Index - 1)});`)

                            FlagIndex += 1
                        end

                        Remaining -= Partition
                    end
                end
                do
                    local Remaining = #Flags
                    local FlagIndex = 1

                    while Remaining > 0 do
                        local Partition = math.min(Remaining, 32)

                        Write:Line(`{Write:Declare('SET_BITS')} = 0`)

                        for Index = 1, Partition do
                            local Flag = Flags[FlagIndex]

                            Write:Line(`if {Variable}{FormatIndex(Flag)} == true then SET_BITS += {BitIndexToHex(Index - 1)} end`)

                            FlagIndex += 1
                        end

                        Prefabs.GetTypeToUseByBits(Partition).Write('SET_BITS', Write)

                        Remaining -= Partition
                    end
                end
            end
            function Declarations.Enum(Declaration, Read, Write, Variable)
                local Value = Declaration.Value
                local Enums = Value.Values
                local Literal = Util.GenerateEnumLiterals(Enums)

                Literal = string.gsub(Literal, '|', 'or')

                Read:Line(`{Read:Declare(Variable)} = true :: any`)
                Types.u8.Read(`Index`, Read)

                Read = Read:Compare('Index', '0', 'Equals')

                for Index, EnumItem in Enums do
                    if Index > 1 then
                        Read = Read:Branch('Conditional', 'Index', `{Index - 1}`, 'Equals')
                    end

                    Read:Line(`{Variable} = "{EnumItem}"`)
                end

                Read:Branch('Default'):Line(`error(\`Unexpected enum: \{Index}\`)`):End()

                local Allocation = Write:Allocate(1)

                for Index, EnumItem in Enums do
                    if Index == 1 then
                        Write = Write:Compare(Variable, `"{EnumItem}"`, 'Equals')
                    else
                        Write = Write:Branch('Conditional', Variable, `"{EnumItem}"`, 'Equals')
                    end

                    Write:Line(`buffer.writeu8(SendBuffer, {Allocation}, {Index - 1})`)
                end

                Write:Branch('Default'):Line(`error(\`Unexpected enum: \{{Variable}}, expected one of {Literal}.\`)`):End()
            end
            function Declarations.Map(Declaration, Read, Write, Variable)
                local MapValue = Declaration.Value
                local Key = MapValue.Values[1]
                local Value = MapValue.Values[2]
                local KeyVariable = `Key_{Read.Indent}`
                local ElementVariable = `Element_{Write.Indent}`
                local ElementsVariable = `Elements_{Write.Indent}`
                local ElementsAllocation = Write:Allocate(2)

                Read:Line(`{Read:Declare(Variable)} = \{}`)
                Write:Line(`local {ElementsVariable} = 0`)
                Types.u16.Read(ElementsVariable, Read)

                local ReadLoop = Read:Loop('_ = 1', ElementsVariable)
                local WriteLoop = Write:Iterator(KeyVariable, ElementVariable, Variable)

                ReadLoop:DisableOperationOptimisations()
                WriteLoop:DisableOperationOptimisations()
                WriteLoop:Line(`{ElementsVariable} += 1`)
                Generators.UserType(Key, ReadLoop, WriteLoop, KeyVariable)
                Generators.UserType(Value, ReadLoop, WriteLoop, ElementVariable)
                ReadLoop:Line(`{Variable}[{KeyVariable}] = {ElementVariable}`)
                WriteLoop:End()
                ReadLoop:End()
                Write:Line(`buffer.writeu16(SendBuffer, {ElementsAllocation}, {ElementsVariable})`)
            end
            function Declarations.Struct(Declaration, Read, Write, Variable)
                local Value = Declaration.Value

                Read:Line(`{Read:Declare(Variable)} = \{} :: any`)

                for _, Field in Value.Values do
                    local Name = Field.Name
                    local FieldVariable = `{Variable}{FormatIndex(Name)}`

                    Generators.UserType(Field, Read, Write, FieldVariable)
                end
            end
            function Declarations.Tuple(Declaration, Read, Write)
                for Index, Value in Declaration.Value.Values do
                    local Variable = `Value{Index}`

                    Generators.UserType(Value, Read, Write, Variable)
                end
            end
            function Declarations.TagEnum(Declaration, Read, Write, Variable)
                local Value = Declaration.Value
                local Values = Value.Values
                local Tag = Value.Tag
                local Header = `"{Values[1].Name}"`
                local TagIndex = `{Variable}{FormatIndex(Tag)}`

                Types.u8.Read(`Tag`, Read)
                Read:Line(`{Read:Declare(Variable)} = true :: any`)

                local Allocation = Write:Allocate(1)

                Read = Read:Compare('Tag', '0', 'Equals')
                Write = Write:Compare(TagIndex, Header, 'Equals')

                for Index, Variant in Values do
                    local Name = `"{Variant.Name}"`

                    if Index > 1 then
                        Read = Read:Branch('Conditional', 'Tag', tostring(Index - 1), 'Equals')
                        Write = Write:Branch('Conditional', TagIndex, Name, 'Equals')
                    end

                    Write:_lineFront(`buffer.writeu8(SendBuffer, {Allocation}, {Index - 1})`)
                    Write:Advance(1)
                    Generators.UserType(Variant, Read, Write, Variable)
                    Read:Line(`{TagIndex} = {Name}`)
                end

                Read:Branch('Default'):Line(`error(\`Unexpected variant: \{Tag}\`)`):End()
                Write:Branch('Default'):Line(`error(\`Unexpected variant: \{{TagIndex}}\`)`):End()
            end
            function Declarations.Event(Declaration)
                local Value = Declaration.Value
                local Identifier = `EVENT_{Declaration.Name}`
                local Reliability = Value.Type
                local IsReliable = (Reliability == 'Reliable')
                local IsUnreliable = (Reliability == 'Unreliable')
                local IsPolling = (Value.Call == 'Polling' or Options.UsePolling)
                local IsSameContext = Value.From == Context
                local Block = IsUnreliable and Unreliables or Reliables
                local Channel = IsUnreliable and Channels.Unreliable or Channels.Reliable
                local Index = Channel.Count
                local Queue = `Queue.{Reliability}[{Index}]`
                local Connection = `Events.{Reliability}[{Index}]`
                local Types, Values, Arguments, _ = 'nil', 'Value: nil', 'Value', nil
                local Read, Write = Generators.Event(Value.Data, Index, Identifier)

                if Value.Data then
                    Types, Values, _, Arguments = Generators.LuauType((Value.Data), true)
                end
                if IsSameContext then
                    UserTypes.PushLines(Write, 1, 0)
                else
                    UserTypes.PushLines(Read, 1, 0)
                end

                local Body = Builder.new()
                local Indent = Util.GetScopeIndent(Scope)
                local WriteEvent = `{Util.GetPath(Identifier, true, Scope)}({Arguments})`

                Body.Push(`{Declaration.Name} = \{`, 0, Indent)
                Noop.Push(`{Declaration.Name} = \{`, 0, Indent)

                if Value.From ~= Context and IsPolling ~= true then
                    local IsSync = (Value.Call == 'SingleSync' or Value.Call == 'ManySync')
                    local IsSingle = (Value.Call == 'SingleSync' or Value.Call == 'SingleAsync')

                    if not IsSingle then
                        Events.Push(`{Connection} = \{}`)
                    end

                    Events.Push(`{Queue} = table.create(256)`)

                    Block = (Channel.Listening == false) and Block:Compare('Index', Index, 'Equals') or Block:Branch('Conditional', 'Index', Index, 'Equals')

                    if IsUnreliable then
                        Unreliables = Block
                    else
                        Reliables = Block
                    end

                    Channel.Listening = true

                    local Listener
                    local ContextArguments = `Listener: ({Context == 'Server' and 'Player: Player, ' or ''}{Values}) -> ()`
                    local ListenerArguments = `{Context == 'Server' and 'Player, ' or ''}{Arguments}`
                    local CallListener = Blocks.Block()

                    do
                        if IsSync and Options.SyncValidation then
                            CallListener = CallListener:Line(`SerdesEvent = "{Declaration.Name}"`)
                        end

                        local PathExpr = IsSingle and Connection or 'Listener'
                        local CallExpr = IsSync and `{PathExpr}({ListenerArguments})` or `task.spawn({PathExpr}, {ListenerArguments})`

                        CallListener = CallListener:Line(CallExpr)
                    end

                    Block:Line(`local {Values} = {Util.GetPath(Identifier, false, Scope)}()`)

                    local Disconnect = Blocks.Function('', '', '()')

                    if IsSingle then
                        Disconnect = Disconnect:Compare(Connection, 'Listener', 'Equals'):Line(`{Connection} = nil`):End()
                    else
                        Disconnect = Disconnect:Line(`local Index = table.find({Connection}, Listener)`)
                        Disconnect = Disconnect:Compare('Index', 'nil', 'Not'):Line(`table.remove({Connection}, Index)`):End()
                    end

                    Disconnect = Disconnect:End():Wrap('return ', '')

                    if IsReliable then
                        local ListenerBound

                        if IsSingle then
                            ListenerBound = Block:Compare(Connection, 'nil', 'Not'):Lines(CallListener.Content, Block.Indent)
                        else
                            ListenerBound = Block:Compare(`#{Connection}`, '0', 'Greater'):Iterator('_', 'Listener', Connection):Lines(CallListener.Content, Block.Indent + 1):End()
                        end

                        ListenerBound:Branch('Default'):Compare(`#{Queue}`, '256', 'Greater'):Line(`warn("[Blink]: Event queue of \\"{Declaration.Name}\\" exceeded 256, did you forget to implement a listener?")`):End():Line(`table.insert({Queue}, \{{ListenerArguments}} :: \{any})`):End()

                        Listener = Blocks.Function(Casing.On, ContextArguments, `() -> ()`, true):Line(IsSingle and `{Connection} = Listener` or `table.insert({Connection}, Listener)`):Iterator('Index', 'Arguments', Queue):Line(IsSync and `Listener(table.unpack(Arguments))` or `task.spawn(Listener, table.unpack(Arguments))`):End():Line(`{Queue} = \{}`):Lines(Disconnect.Content, 1):End()
                    else
                        if IsSingle then
                            Block:Compare(Connection, 'nil', 'Not'):Lines(CallListener.Content, Block.Indent):End()
                        else
                            Block:Iterator('_', 'Listener', Connection):Lines(CallListener.Content, Block.Indent):End()
                        end

                        Listener = Blocks.Function(Casing.On, ContextArguments, `() -> ()`, true):Line(IsSingle and `{Connection} = Listener` or `table.insert({Connection}, Listener)`):Lines(Disconnect.Content, 1):End()
                    end

                    Noop.Push(`{Casing.On} = NOOP`, 0, Indent + 1)
                    Body.PushLines(Listener.Content, 0, Indent + 1)
                elseif Value.From ~= Context and IsPolling then
                    Events.Push(`{Queue} = CreateQueue()`)

                    Block = (Channel.Listening == false) and Block:Compare('Index', Index, 'Equals') or Block:Branch('Conditional', 'Index', Index, 'Equals')

                    if IsUnreliable then
                        Unreliables = Block
                    else
                        Reliables = Block
                    end

                    Channel.Listening = true

                    Block:Line(`Push({Queue}, table.pack({Context == 'Server' and 'Player, ' or ''}{Util.GetPath(Identifier, false, Scope)}()))`)

                    local IterTypes = `number, {Context == 'Server' and 'Player, ' or ''}{Types}`
                    local Next = Blocks.Function('', '', `({IterTypes})`):Line('index += 1'):Line('local arguments = Pop(queue)'):Compare('arguments', 'nil', 'Not'):Return('index, unpack(arguments, 1, arguments.n)'):End():Return(''):End():Wrap('return ', '')
                    local Deprecated = Blocks.Function(Casing.Next, '', `() -> ({IterTypes})`, true):Line(`local index = 0`):Line(`local queue = {Queue}`):Lines(Next.Content, 1):End()
                    local Iter = Blocks.Function(Casing.Iter, '', `() -> ({IterTypes})`, true):Line(`local index = 0`):Line(`local queue = {Queue}`):Lines(Next.Content, 1):End():Wrap('', ',')

                    Noop.Push(`{Casing.Iter} = NOOP,`, 0, Indent + 1)
                    Noop.Push(`{Casing.Next} = NOOP`, 0, Indent + 1)
                    Body.PushLines(Iter.Content, 0, Indent + 1)
                    Body.Push('--- @deprecated v0.14.1 -- Use `Iter` instead.', 0, Indent + 1)
                    Body.PushLines(Deprecated.Content, 0, Indent + 1)
                elseif Context == 'Client' then
                    local Fire = Blocks.Function(Casing.Fire, Values, '()', true)

                    if IsReliable then
                        Fire:Line(WriteEvent)
                    else
                        Fire:Line(`local Previous = Save()`)
                        Fire:Line(`Load()`)
                        Fire:Line(WriteEvent)
                        Fire:Line('local Buffer = buffer.create(SendCursor)')
                        Fire:Line('buffer.copy(Buffer, 0, SendBuffer, 0, SendCursor)')
                        Fire:Line('Unreliable:FireServer(Buffer, SendInstances)')
                        Fire:Line('Load(Previous)')
                    end

                    Fire:End()
                    Noop.Push(`{Casing.Fire} = NOOP`, 0, Indent + 1)
                    Body.PushLines(Fire.Content, 0, Indent + 1)
                else
                    local Fire = Blocks.Function(Casing.Fire, `Player: Player, {Values}`, '()', true)

                    if IsReliable then
                        Fire:Line('Load(PlayersMap[Player])')
                        Fire:Line(WriteEvent)
                        Fire:Line('PlayersMap[Player] = Save()')
                    else
                        Fire:Line('Load()')
                        Fire:Line(WriteEvent)
                        Fire:Lines(UNRELIABLE_BODY, 1)
                        Fire:Line('Unreliable:FireClient(Player, Buffer, SendInstances)')
                    end

                    Fire:End()

                    local FireAll = Blocks.Function(Casing.FireAll, Values, '()', true)

                    if IsReliable then
                        FireAll:Line('Load()')
                        FireAll:Line(WriteEvent)
                        FireAll:Line(RELIABLE_BODY.Header)
                        FireAll:Iterator('_', 'Player', 'Players:GetPlayers()'):Lines(RELIABLE_BODY.Body, 2):End()
                    else
                        FireAll:Line('Load()')
                        FireAll:Line(WriteEvent)
                        FireAll:Lines(UNRELIABLE_BODY, 1)
                        FireAll:Line('Unreliable:FireAllClients(Buffer, SendInstances)')
                    end

                    FireAll:End()

                    local FireList = Blocks.Function(Casing.FireList, `List: \{Player}, {Values}`, '()', true)

                    if IsReliable then
                        FireList:Line('Load()')
                        FireList:Line(WriteEvent)
                        FireList:Line(RELIABLE_BODY.Header)
                        FireList:Iterator('_', 'Player', 'List'):Lines(RELIABLE_BODY.Body, 2):End()
                    else
                        FireList:Line('Load()')
                        FireList:Line(WriteEvent)
                        FireList:Lines(UNRELIABLE_BODY, 1)
                        FireList:Iterator('_', 'Player', 'List'):Line('Unreliable:FireClient(Player, Buffer, SendInstances)'):End()
                    end

                    FireList:End()

                    local FireExcept = Blocks.Function(Casing.FireExcept, `Except: Player, {Values}`, '()', true)

                    if IsReliable then
                        FireExcept:Line('Load()')
                        FireExcept:Line(WriteEvent)
                        FireExcept:Line(RELIABLE_BODY.Header)
                        FireExcept:Iterator('_', 'Player', 'Players:GetPlayers()'):Compare('Player', 'Except', 'Equals'):Line('continue'):End():Lines(RELIABLE_BODY.Body, 2):End()
                    else
                        FireExcept:Line('Load()')
                        FireExcept:Line(WriteEvent)
                        FireExcept:Lines(UNRELIABLE_BODY, 1)
                        FireExcept:Iterator('_', 'Player', 'Players:GetPlayers()'):Compare('Player', 'Except', 'Equals'):Line('continue'):End():Line('Unreliable:FireClient(Player, Buffer, SendInstances)'):End()
                    end

                    FireExcept:End()
                    Noop.PushLines({
                        `{Casing.Fire} = NOOP,\n`,
                        `{Casing.FireAll} = NOOP,\n`,
                        `{Casing.FireList} = NOOP,\n`,
                        `{Casing.FireExcept} = NOOP\n`,
                    }, 0, Indent + 1)
                    Body.PushLines(Fire:Wrap('', ',').Content, 0, Indent + 1)
                    Body.PushLines(FireAll:Wrap('', ',').Content, 0, Indent + 1)
                    Body.PushLines(FireList:Wrap('', ',').Content, 0, Indent + 1)
                    Body.PushLines(FireExcept:Wrap('', ',').Content, 0, Indent + 1)
                end

                Channel.Count += 1

                Body.Push(`},`, 0, Indent)
                Noop.Push(`},`, 0, Indent)
                Return.PushLines(Body.DumpLines(), 0)
            end
            function Declarations.Function(Declaration)
                local Name = Declaration.Name
                local Value = Declaration.Value
                local DataIdentifier = `FUNCTION_DATA_{Name}`
                local ReturnIdentifier = `FUNCTION_RETURN_{Name}`
                local Yield = Value.Yield
                local IsFuture = (Yield == 'Future')
                local IsPromise = (Yield == 'Promise')

                if IsFuture and not Options.FutureLibrary then
                    error(`Cannot use yield type: "Future", without providing a path to the future library.`)
                end
                if IsPromise and not Options.PromiseLibrary then
                    error(`Cannot use yield type: "Promise", without providing a path to the promise library.`)
                end

                local Block = Reliables
                local Channel = Channels.Reliable
                local Index = Channel.Count
                local Queue = `Queue.Reliable[{Index}]`
                local Connection = `Events.Reliable[{Index}]`
                local DataTypes, DataValues, _, DataArguments = 'nil', 'Value: nil', nil, 'Value'
                local ReturnTypes, ReturnValues, _, ReturnArguments = 'nil', 'ReturnValue: nil', nil, 'ReturnValue'

                if Value.Data then
                    DataTypes, DataValues, _, DataArguments = Generators.LuauType((Value.Data), true)
                end
                if Value.Return then
                    ReturnTypes, ReturnValues, _, ReturnArguments = Generators.LuauType((Value.Return), true, 'Return')
                end

                do
                    local DataRead, DataWrite = Generators.Event((Value.Data), Index, DataIdentifier, 'Data')
                    local ReturnRead, ReturnWrite = Generators.Event((Value.Return), Index, ReturnIdentifier, 'Return')

                    if Context == 'Client' then
                        UserTypes.PushLines(DataWrite, 1, 0)
                        UserTypes.PushLines(ReturnRead, 1, 0)
                    elseif Context == 'Server' then
                        UserTypes.PushLines(DataRead, 1, 0)
                        UserTypes.PushLines(ReturnWrite, 1, 0)
                    end
                end

                local Body = Builder.new()
                local Indent = Util.GetScopeIndent(Scope)

                Noop.Push(`{Name} = \{`, 0, Indent)
                Body.Push(`{Name} = \{`, 0, Indent)
                Events.Push(`{Queue} = table.create(256)`)

                Block = (Channel.Listening == false) and Block:Compare('Index', Index, 'Equals') or Block:Branch('Conditional', 'Index', Index, 'Equals')
                Reliables = Block

                if Context == 'Server' then
                    Types.u8.Read('InvocationIdentifier', Block)
                    Block:Line(`local {DataValues} = {Util.GetPath(DataIdentifier, false, Scope)}()`):Compare(Connection, 'nil', 'Not'):Line(`task.spawn({Connection}, Player, {DataArguments}, InvocationIdentifier)`):Branch('Default'):Compare(`#{Queue}`, '256', 'Greater'):Line(`warn("[Blink]: Event queue of \\"{Name}\\" exceeded 256, did you forget to implement a listener?")`):End():Line(`table.insert({Queue}, \{Player, {DataArguments}, InvocationIdentifier} :: \{any})`):End()

                    local FlushQueue = Blocks.Function('', '', '()'):Line(`local EventQueue = {Queue} or \{}`):Line(`{Queue} = nil`):Iterator('Index', 'Arguments', 'EventQueue'):Line(`{Connection}(table.unpack(Arguments))`):End():End():Wrap('task.spawn(', ')')
                    local Serialize = Blocks.Function('', ''):Line(`{ReturnArguments} = Listener(Player, {DataArguments})`):End():Wrap('local Success, Error = pcall(', ')')
                    local TrueListener = Blocks.Function(Connection, `Player: Player, {DataValues}, InvocationIdentifier: number`, '()', true):Line(`local {ReturnValues};`):Lines(Serialize.Content, 1):Line('Load(PlayersMap[Player])'):Compare('Success', 'true', 'Not'):Line('local Position = Allocate(3)'):Line(`buffer.writeu8(SendBuffer, Position, {Index})`):Line(`buffer.writeu8(SendBuffer, Position + 1, InvocationIdentifier)`):Line(`buffer.writeu8(SendBuffer, Position + 2, 0)`):Line(`warn(\`"{Name}" encountered an error, \{Error}\`)`):Branch('Default'):Line(`{Util.GetPath(ReturnIdentifier, true, Scope)}({ReturnArguments}, InvocationIdentifier)`):End():Line('PlayersMap[Player] = Save()'):End()
                    local Listener = Blocks.Function(Casing.On, `Listener: (Player, {DataTypes}) -> ({ReturnTypes})`, '()', true):Lines(TrueListener.Content, 1):Lines(FlushQueue.Content, 1):End()

                    Noop.Push(`{Casing.On} = NOOP`, 0, Indent + 1)
                    Body.PushLines(Listener.Content, 0, 2)
                else
                    local Deserialize = Blocks.Function('', ''):Return(`{Util.GetPath(ReturnIdentifier, false, Scope)}()`):End():Wrap(`local Success, {ReturnArguments} = pcall(`, ')')

                    Types.u8.Read('InvocationIdentifier', Block)
                    Block:Lines(Deserialize.Content, Block.Indent + 1)
                    Block:Compare('Calls[InvocationIdentifier]', 'nil', 'Not'):Line(`task.spawn(Calls[InvocationIdentifier], Success, {ReturnArguments})`):Line('Calls[InvocationIdentifier] = nil'):End()

                    local Exhaust = Blocks.Block():Compare('Calls[InvocationIdentifier]', 'nil', 'Not'):Line('Invocations -= 1'):Line(
[[error("More than 256 calls are awaiting a response, this packet has been dropped.")]]):End().Content
                    local Error = `"There was an exception while processing \\"{Name}\\"."`
                    local Contents = Blocks.Block():Line('local InvocationIdentifier = Invoke()'):Lines(Exhaust):Line(`{Util.GetPath(DataIdentifier, true, Scope)}({DataArguments}, InvocationIdentifier)`):Line('Calls[InvocationIdentifier] = coroutine.running()'):Line(`local Success, {ReturnValues} = coroutine.yield()`):Compare('Success', 'true', 'Not'):Line(`error({Error})`):End():Return(ReturnArguments).Content
                    local Invoke

                    if IsFuture then
                        local Wrapper = Blocks.Function('', ''):Lines(Contents):End():Wrap('return Future.Try(', ')')

                        Invoke = Blocks.Function(Casing.Invoke, DataValues, `Future.Future<boolean, {ReturnTypes}>`, true)

                        Invoke:Lines(Wrapper.Content, 1)
                    elseif IsPromise then
                        local OnCancel = Blocks.Function('', ''):Line('Calls[InvocationIdentifier] = nil'):End():Wrap('OnCancel(', ')')
                        local Promise = Blocks.Function('', 'Resolve, Reject, OnCancel'):Line('local InvocationIdentifier = Invoke()'):Lines(Exhaust):Line(`{Util.GetPath(DataIdentifier, true, Scope)}({DataArguments}, InvocationIdentifier)`):Line('Calls[InvocationIdentifier] = coroutine.running()'):Lines(OnCancel.Content, 1):Line(`local Success, {ReturnValues} = coroutine.yield()`):Compare('Success', 'true', 'Not'):Line(`Reject({Error})`):Return(''):End():Line(`Resolve({ReturnArguments})`):End():Wrap(`return Promise.new(`, ')')

                        Invoke = Blocks.Function(Casing.Invoke, DataValues, nil, true)

                        Invoke:Lines(Promise.Content, 1)
                    else
                        Invoke = Blocks.Function(Casing.Invoke, DataValues, `({ReturnTypes})`, true)

                        Invoke:Lines(Contents, 0)
                    end

                    Invoke:End()
                    Noop.Push(`{Casing.Invoke} = NOOP`, 0, Indent + 1)
                    Body.PushLines(Invoke.Content, 0, Indent + 1)
                end

                Channel.Count += 1

                Channel.Listening = true

                Noop.Push(`},`, 0, Indent)
                Body.Push(`},`, 0, Indent)
                Return.PushLines(Body.DumpLines(), 0)
            end
            function Declarations.Array(Declaration, Read, Write, Variable)
                local Value = Declaration.Value
                local Of = Value.Of
                local Range = (Value.Range)

                Read:Comment('START ARRAY')
                Write:Comment('START ARRAY')

                local Lower = Range.Min
                local Upper = Range.Max
                local Iterator = `Item_{Read.Indent}`
                local IsVariableSize = (Lower ~= Upper)

                if IsVariableSize then
                    local LengthType = Prefabs.GetTypeToUse(Upper)

                    LengthType.Read('Length', Read)

                    local Assert = Prefabs.Asserts.number('Length', Lower, Upper)

                    Read:Line(Assert.Lower)
                    Read:Line(Assert.Upper)
                    LengthType.Write(`#{Variable}`, Write)
                else
                    Read:Line(`local Length = {Upper}`)
                end

                Read:Line(`{Read:Declare(Variable)} = table.create(Length)`)

                Read = Read:Loop('Index = 1', 'Length')
                Write = Write:Loop('Index = 1', IsVariableSize and `#{Variable}` or Upper)

                Write:Line(`local {Iterator} = {Variable}[Index]`)
                Generators.UserType(Of, Read, Write, Iterator)
                Read:Line(`table.insert({Variable}, {Iterator})`)

                Read = Read:End()
                Write = Write:End()

                Read:Comment('END ARRAY')
                Write:Comment('END ARRAY')
            end
            function Declarations.Optional(Declaration, Read, Write, Variable)
                Read:Declare(Variable, true)

                local Of = Declaration.Value.Of
                local IsInstance = if Of.Type == 'Primitive'then Of.Tokens.Primitive.Value == 'Instance'else false

                if IsInstance then
                    Read:Line('RecieveInstanceCursor += 1')

                    Read = Read:Compare('typeof(RecieveInstances[RecieveInstanceCursor])', '"Instance"', 'Equals')

                    Read:Line('RecieveInstanceCursor -= 1')
                else
                    Types.u8.Write(`{Variable} ~= nil and 1 or 0`, Write)

                    Read = Read:Compare(`buffer.readu8(RecieveBuffer, {Read:Read(1)})`, '1', 'Equals')
                    Write = Write:Compare(Variable, 'nil', 'Not')
                end

                Generators.UserType(Declaration.Value.Of, Read, Write, Variable)
                Read:End()

                if not IsInstance then
                    Write:End()
                end
            end
            function Generators.UserType(Declaration, Read, Write, Variable)
                local Name = Declaration.Name
                local Variable = Variable or 'Value'

                if not true then
                    Read:Comment(`{Variable}: {Name}`)
                    Write:Comment(`{Variable}: {Name}`)
                end
                if Declaration.Type == 'Primitive' then
                    local Kind = (Declaration).Tokens.Primitive.Value

                    if Kind == 'Instance' then
                        Read:Line('RecieveInstanceCursor += 1')
                    end

                    Declarations.Primitive(Declaration, Read, Write, Variable)
                elseif Declaration.Type == 'Set' then
                    Declarations.Set(Declaration, Read, Write, Variable)
                elseif Declaration.Type == 'Map' then
                    Declarations.Map(Declaration, Read, Write, Variable)
                elseif Declaration.Type == 'Enum' then
                    Declarations.Enum(Declaration, Read, Write, Variable)
                elseif Declaration.Type == 'Struct' then
                    Declarations.Struct(Declaration, Read, Write, Variable)
                elseif Declaration.Type == 'Tuple' then
                    Declarations.Tuple(Declaration, Read, Write)
                elseif Declaration.Type == 'TagEnum' then
                    Declarations.TagEnum(Declaration, Read, Write, Variable)
                elseif Declaration.Type == 'Array' then
                    Declarations.Array(Declaration, Read, Write, Variable)
                elseif Declaration.Type == 'Optional' then
                    Declarations.Optional(Declaration, Read, Write, Variable)
                end
            end
            function Generators.LuauType(Declaration, UseTypeAsValue, Prefix)
                Prefix = Prefix or ''

                local Type = 'nil'
                local Values = 'Value: nil'
                local Export = Util.GetExportName(Declaration.Name, Scope)
                local Returns = `{Prefix}Value`

                if Declaration.Type == 'Primitive' then
                    local Tokens = (Declaration).Tokens
                    local Primitive = Primitives[Tokens.Primitive.Value]

                    if type(Primitive.Type) == 'function' then
                        Type = Primitive.Type(Declaration)
                    else
                        Type = Primitive.Type
                    end
                elseif Declaration.Type == 'Set' then
                    local Value = (Declaration).Value
                    local Entries = {}

                    for _, Flag in Value.Values do
                        table.insert(Entries, `{FormatKey(Flag)}: boolean,`)
                    end

                    Type = `\{{table.concat(Entries)}}`
                elseif Declaration.Type == 'Enum' then
                    local Value = (Declaration).Value

                    Type = `({Util.GenerateEnumLiterals(Value.Values)})`
                elseif Declaration.Type == 'TagEnum' then
                    local Value = (Declaration).Value
                    local Literals = {}

                    for Index, Variant in Value.Values do
                        local TagField = `{FormatKey(Value.Tag)}: "{Variant.Name}"`
                        local ValueType = Generators.LuauType(Variant)

                        table.insert(Literals, `\{ {TagField},{string.sub(ValueType, 2)}`)
                    end

                    Type = table.concat(Literals, ' | ')
                elseif Declaration.Type == 'Map' then
                    local MapValue = (Declaration).Value
                    local Key = Generators.LuauType(MapValue.Values[1])
                    local Value = Generators.LuauType(MapValue.Values[2])

                    Type = `\{[{Key}]: {Value}}`
                elseif Declaration.Type == 'Struct' then
                    local Value = Declaration.Value
                    local Fields = {}

                    for _, Field in Value.Values do
                        local Name = Field.Name
                        local FieldType = Generators.LuauType(Field)

                        table.insert(Fields, `{FormatKey(Name)}: {FieldType}`)
                    end

                    Type = `\{ {table.concat(Fields, ', ')} }`
                elseif Declaration.Type == 'Generic' then
                    Type = `{Declaration.Value.Generic}`
                elseif Declaration.Type == 'Tuple' then
                    local Value = (Declaration).Value
                    local Types = {
                        'nil',
                    }
                    local Variables = {
                        'Value',
                    }
                    local AnnotatedVariables = {
                        'Value: nil',
                    }

                    for Index, TupleValue in Value.Values do
                        local Variable = `{Prefix}Value{Index}`
                        local ValueType = Generators.LuauType(TupleValue)

                        Types[Index] = ValueType
                        Variables[Index] = Variable
                        AnnotatedVariables[Index] = `{Variable}: {ValueType}`
                    end

                    Type = table.concat(Types, ', ')
                    Values = table.concat(AnnotatedVariables, ', ')
                    Returns = table.concat(Variables, ', ')
                elseif Declaration.Type == 'Array' then
                    local Value = Declaration.Value

                    Type = `\{ {Generators.LuauType(Value.Of)} }`
                elseif Declaration.Type == 'Optional' then
                    local Value = Declaration.Value

                    Type = `{Generators.LuauType(Value.Of)}?`
                end

                local Value = Declaration.Value

                if Value.Parameters then
                    local Parameters = {}

                    for Index, Parameter in Value.Parameters do
                        local ParameterType = Generators.LuauType(Parameter)

                        table.insert(Parameters, ParameterType)
                    end

                    Type = `{Type}<{table.concat(Parameters, ',')}>`
                end
                if Declaration.Type ~= 'Tuple' then
                    Values = `{Prefix}Value: {UseTypeAsValue and Type or Export}`
                end

                return Type, Values, Export, Returns
            end
            function Generators.Type(Declaration)
                local Value = Declaration.Value
                local Type, _, Export = Generators.LuauType(Declaration)
                local Generics = ''

                if Value.Generics then
                    local Types = {}

                    for _, Generic in Value.Generics.List do
                        table.insert(Types, Generic)
                    end

                    Generics = `<{table.concat(Types, ',')}>`
                end

                LuauTypes.PushMultiline(`export type {Export}{Generics} = {Type}`, 1, 0)
            end
            function Generators.Export(Declaration)
                local Name = Declaration.Name
                local _, Values, Export, Returns = Generators.LuauType(Declaration)
                local Read = Blocks.Function(Casing.Read, 'Buffer: buffer', `({Export})`, true)
                local Write = Blocks.Function(Casing.Write, `{Values}`, `(buffer)`, true)
                local Body = Builder.new()
                local Indent = Util.GetScopeIndent(Scope)

                Body.Push(`{Name} = \{`, 0, Indent)
                Read:Comment('Buffer overwrite')
                Write:Comment('Buffer overwrite')
                Read:Lines({
                    'local PreviousCursor = RecieveCursor\n',
                    'local PreviousBuffer = RecieveBuffer\n',
                    'local PreviousInstanceCursor = RecieveInstanceCursor\n',
                    'RecieveCursor = 0\n',
                    'RecieveBuffer = Buffer\n',
                }, 1)
                Write:Lines({
                    'local Previous = Save()\n',
                    'Load()\n',
                }, 1)
                Read:Advance(#Read.Content - 1)
                Write:Advance(#Write.Content - 1)
                Read:Comment('Buffer read')
                Write:Comment('Buffer write')
                Generators.UserType(Declaration, Read, Write)
                Read:Comment('Buffer restore')
                Write:Comment('Buffer restore')
                Read:Lines({
                    'RecieveCursor = PreviousCursor\n',
                    'RecieveBuffer = PreviousBuffer\n',
                    'RecieveInstanceCursor = PreviousInstanceCursor\n',
                }, 1)
                Write:Line('local Result = buffer.create(SendCursor)')
                Write:Line('buffer.copy(Result, 0, SendBuffer, 0, SendCursor)')
                Write:Line(`Load(Previous)`)
                Read:Return(Returns)
                Write:Return('Result')
                Read:End():Wrap('', ',')
                Write:End()
                Body.PushLines(Read.Content, 0, Indent + 1)
                Body.PushLines(Write.Content, 0, Indent + 1)
                Body.Push(`},`, 0, Indent)

                local BodyLines = Body.DumpLines()

                Noop.PushLines(table.clone(BodyLines), 0, 0)
                Return.PushLines(BodyLines, 0, 0)
            end
            function Generators.Event(Data, Index, Identifier, Function)
                local Type, Values, _, Returns = 'nil', 'Value: nil', nil, 'nil'

                if Data then
                    Type, Values, _, Returns = Generators.LuauType(Data, true)
                end

                local Arguments = `{Values}{Function and ', InvocationIdentifier: number' or ''}`
                local Read = Blocks.Function(Util.GetPath(Identifier, false, Scope), '', `({Type})`, false, true)
                local Write = Blocks.Function(Util.GetPath(Identifier, true, Scope), Arguments, '()', false, true)

                if not true then
                    Write:Comment(`{Identifier} ({Index})`)
                end

                Types.u8.Write(Index, Write)

                if Function then
                    Types.u8.Write('InvocationIdentifier', Write)

                    if Function == 'Return' then
                        Types.u8.Write('1', Write)
                        Types.u8.Read('Success', Read)
                        Read:Compare('Success', '1', 'Not'):Line('error("Server encountered an error.")'):End()
                    end
                end
                if Data then
                    Generators.UserType(Data, Read, Write)
                end

                return Read:Return(Returns):End().Content, Write:End().Content
            end
            function Generators.Scope(Declaration)
                local Name = Declaration.Name
                local Value = Declaration.Value
                local Parent = Scope
                local NewScope = Value.Scope
                local Path = Util.GetScopePrefix(NewScope, true, Scope)
                local Indent = (#string.split(Path, '.') - 1)

                Path = string.sub(Path, 1, #Path - 1)
                Scope = NewScope

                Noop.Push(`{Name} = \{`, 0, Indent)
                Return.Push(`{Name} = \{`, 0, Indent)
                Generators.AbstractSyntaxTree(Value.Values)
                Noop.Push(`},`, 0, Indent)
                Return.Push(`},`, 0, Indent)

                Scope = Parent
            end
            function Generators.AbstractSyntaxTree(Tree)
                for Index, Declaration in Tree do
                    if Context == 'Shared' and IGNORED_TYPES_IN_SHARED[Declaration.Type] then
                        continue
                    end
                    if Declaration.Type == 'Scope' then
                        Generators.Scope(Declaration)
                    elseif Declaration.Type == 'Event' then
                        Declarations.Event(Declaration)
                    elseif Declaration.Type == 'Function' then
                        Declarations.Function(Declaration)
                    else
                        if Declaration.Value.Export then
                            Generators.Export(Declaration)
                        end

                        Generators.Type(Declaration)
                    end
                end
            end

            local Generator = {}

            function Generator.Reset()
                Noop = Builder.new()
                Events = Builder.new()
                UserTypes = Builder.new()
                LuauTypes = Builder.new()
                Return = Builder.new()
                Channels.Reliable.Count = 0
                Channels.Unreliable.Count = 0
                Channels.Reliable.Listening = false
                Channels.Unreliable.Listening = false
            end
            function Generator.Generate(FileContext, AbstractSyntaxTree)
                local Imports = Builder.new()

                Generator.Reset()

                Context = FileContext
                Options = AbstractSyntaxTree.Value.Options
                Casing = Settings.GetCasing(((Options.Casing)) or 'Pascal')

                Noop.Push(`if not RunService:IsRunning() then`)
                Noop.Push(`local NOOP = function() end`, 0, 1)
                Noop.Push(`local Returns = table.freeze(\{`, 0, 1)

                local Signal = Context == 'Client' and 'OnClientEvent' or 'OnServerEvent'
                local Arguments = (Context == 'Server' and 'Player: Player, ' or '') .. 'Buffer: buffer, Instances: {Instance}'

                Reliables = Blocks.Connection(`Reliable.{Signal}`, Arguments)
                Unreliables = Blocks.Connection(`Unreliable.{Signal}`, Arguments)

                Reliables:Lines(EVENT_BODY, 1)
                Unreliables:Lines(EVENT_BODY, 1)

                if Options.SyncValidation then
                    Reliables:Lines(EVENT_SYNC_VALIDATION, 1)
                    Unreliables:Lines(EVENT_SYNC_VALIDATION, 1)
                end

                Reliables = Reliables:While('RecieveCursor < Size')
                Unreliables = Unreliables:While('RecieveCursor < Size')

                Types.u8.Read('Index', Reliables)
                Types.u8.Read('Index', Unreliables)

                if Options.FutureLibrary then
                    Imports.Push(`local Future = require({Options.FutureLibrary})`)
                end
                if Options.PromiseLibrary then
                    Imports.Push(`local Promise = require({Options.PromiseLibrary})`)
                end

                local Replication = Builder.new()

                Return.Push(`{Casing.StepReplication} = StepReplication,`, 1, 1)

                if not Options.ManualReplication then
                    Replication.Push('RunService.Heartbeat:Connect(StepReplication)')
                end

                Generators.AbstractSyntaxTree(AbstractSyntaxTree.Value.Declarations)

                local Source = Sources[Context]

                if Channels.Reliable.Listening then
                    Reliables = Reliables:End()
                end
                if Channels.Unreliable.Listening then
                    Unreliables = Unreliables:End()
                end

                Reliables = Reliables:End():End()
                Unreliables = Unreliables:End():End()

                Noop.Push(`})`, 0, 1)
                Noop.Push(`return Returns :: {EVENTS_TYPE}`, 0, 1)
                Noop.Push(`end`, 0, 0)
                Return.PushFront(`\nlocal Returns = table.freeze(\{`)
                Return.Push(`})`)

                local ScopeValidationBody = {}

                if Context ~= 'Shared' then
                    local RemoteScope = Options.RemoteScope or 'BLINK'

                    ScopeValidationBody = {
                        '_G._BLINK = _G._BLINK or {}\n',
                        `if _G._BLINK["{RemoteScope}"] then\n`,
                        `\terror("[Blink]: An instance of blink is already running with the remote scope \\"{RemoteScope}\\". Change the remote scope of either instance to avoid conflicts.")\n`,
                        'end\n',
                        `_G._BLINK["{RemoteScope}"] = true\n`,
                    }
                end

                local MergedOutput = Table.Merge(DIRECTIVES, VERSION_HEADER, ScopeValidationBody, string.split(Source[1], '\r'), Imports.DumpLines(), {
                    `local BASE_EVENT_NAME = "{Options.RemoteScope and Options.RemoteScope .. '_' or ''}BLINK"\n`,
                }, string.split(Sources.Base, '\r'), (if Options.SyncValidation then SYNC_VALIDATION_BODY else{}), Events.DumpLines(), LuauTypes.DumpLines(), UserTypes.DumpLines(), Noop.DumpLines(), string.split(Source[2], '\r'), Replication.DumpLines(), Reliables.Content, Unreliables.Content, Return.DumpLines(), {
                    `type {EVENTS_TYPE} = typeof(Returns)\n`,
                    `return Returns :: {EVENTS_TYPE}`,
                })

                return table.concat(MergedOutput)
            end
            function Generator.GenerateShared(AbstractSyntaxTree)
                Generator.Reset()

                Context = 'Shared'
                Options = AbstractSyntaxTree.Value.Options
                Casing = Settings.GetCasing(((Options.Casing)) or 'Pascal')

                Generators.AbstractSyntaxTree(AbstractSyntaxTree.Value.Declarations)

                local Source = Sources[Context]
                local MergedOutput = Table.Merge(DIRECTIVES, VERSION_HEADER, string.split(Source[1], '\r'), string.split(Sources.Base, '\r'), LuauTypes.DumpLines(), {
                    '\n',
                }, UserTypes.DumpLines(), string.split(Source[2], '\r'), {
                    '\n',
                }, {
                    `\nreturn \{\n`,
                }, Return.DumpLines(), {
                    '\n}',
                })

                return table.concat(MergedOutput)
            end
            function Generator.GenerateTypescript(
                FileContext,
                AbstractSyntaxTree
            )
                return GenerateTypescript(FileContext, AbstractSyntaxTree)
            end

            return Generator
        end

        function __DARKLUA_BUNDLE_MODULES.p()
            local v = __DARKLUA_BUNDLE_MODULES.cache.p

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.p = v
            end

            return v.c
        end
    end
    do
        local function __modImpl()
            local fs = require('@lune/fs')
            local stdio = require('@lune/stdio')
            local Error = __DARKLUA_BUNDLE_MODULES.a()
            local Generator = __DARKLUA_BUNDLE_MODULES.p()
            local GetDefinitionFilePath = __DARKLUA_BUNDLE_MODULES.f()
            local Parser = __DARKLUA_BUNDLE_MODULES.g()
            local PathParser = __DARKLUA_BUNDLE_MODULES.d()
            local Utility = {}

            local function Message(Color, Options, ...)
                if Options.Silent then
                    return
                end

                stdio.write(stdio.color(Color))
                print(...)
                stdio.write(stdio.color('reset'))
            end
            local function FormatTime(Time)
                if Time < 1E-6 then
                    return `{Time * 1E9} ns`
                elseif Time < 0.001 then
                    return `{Time * 1E6} \206\188s`
                elseif Time < 1 then
                    return `{Time * 1000} ms`
                else
                    return `{Time} seconds`
                end
            end
            local function CreateDirectoryIfNotFound(Path, Options)
                local Directory = PathParser.Directory(Path) or './'

                if fs.isDir(Directory) then
                    return
                end

                local Result = Options.YesToEverything or stdio.prompt('confirm', `Directory {Directory} doesn't exist, create directory?`)

                if Result then
                    fs.writeDir(Directory)

                    return
                end

                error('User refused prompt to create directory')
            end

            function Utility.Compile(Path, Options)
                local FilePath = GetDefinitionFilePath(Path)

                Error.SetCompact(Options.Compact)
                Message('cyan', Options, `Reading source from {FilePath}...`)

                local Source = fs.readFile(FilePath)

                Message('blue', Options, 'Parsing source into AST...')

                local FileDirectory = PathParser.Directory(FilePath) or './'
                local SourceParser = Parser.new(FileDirectory, PathParser.NameWithExtension(FilePath))
                local ParseStart = os.clock()
                local AbstractSyntaxTree = SourceParser:Parse(Source)
                local ParseTime = (os.clock() - ParseStart)

                if Options.OutputAbstractSyntaxTree then
                    print(AbstractSyntaxTree.Value.Options)
                    print(AbstractSyntaxTree.Value.Declarations)

                    return
                end

                local FileOptions = AbstractSyntaxTree.Value.Options
                local ClientOutputPath = FileOptions.ClientOutput
                local ServerOutputPath = FileOptions.ServerOutput

                assert(ClientOutputPath, 'A client output path must be defined.')
                assert(ServerOutputPath, 'A server output path must be defined.')

                local ClientTypescriptPath
                local ServerTypescriptPath

                do
                    local Directory, Filename = PathParser.Components(ClientOutputPath)
                    local TypescriptFilename = if Filename == 'init'then'index'else Filename

                    ClientOutputPath = `{Directory}/{Filename}.luau`
                    ClientTypescriptPath = if PathParser.PathType(ClientOutputPath) == 'absolute'then`{Directory}/{TypescriptFilename}.d.ts`else`{FileDirectory}{Directory}/{TypescriptFilename}.d.ts`
                end
                do
                    local Directory, Filename = PathParser.Components(ServerOutputPath)
                    local TypescriptFilename = if Filename == 'init'then'index'else Filename

                    ServerOutputPath = `{Directory}/{Filename}.luau`
                    ServerTypescriptPath = if PathParser.PathType(ServerOutputPath) == 'absolute'then`{Directory}/{TypescriptFilename}.d.ts`else`{FileDirectory}{Directory}/{TypescriptFilename}.d.ts`
                end

                local TypesOutput
                local ClientOutput
                local ServerOutput

                if PathParser.PathType(ClientOutputPath) == 'absolute' then
                    ClientOutput = ClientOutputPath
                else
                    ClientOutput = `{FileDirectory}{ClientOutputPath}`
                end
                if PathParser.PathType(ServerOutputPath) == 'absolute' then
                    ServerOutput = ServerOutputPath
                else
                    ServerOutput = `{FileDirectory}{ServerOutputPath}`
                end

                CreateDirectoryIfNotFound(ClientOutput, Options)
                CreateDirectoryIfNotFound(ServerOutput, Options)
                Message('blue', Options, 'Generating output files...')

                local FilesStart = os.clock()
                local ServerGenerateStart = os.clock()
                local ServerSource = Generator.Generate('Server', AbstractSyntaxTree)
                local ServerGenerateTime = (os.clock() - ServerGenerateStart)
                local ClientGenerateStart = os.clock()
                local ClientSource = Generator.Generate('Client', AbstractSyntaxTree)
                local ClientGenerateTime = (os.clock() - ClientGenerateStart)
                local TypesSource

                if FileOptions.TypesOutput then
                    TypesOutput = if PathParser.PathType(Path) == 'absolute'then FileOptions.TypesOutput else`{FileDirectory}{FileOptions.TypesOutput}`
                    TypesSource = Generator.GenerateShared(AbstractSyntaxTree)
                end

                local ClientTypescriptSource
                local ServerTypescriptSource

                if FileOptions.Typescript then
                    ClientTypescriptSource = Generator.GenerateTypescript('Client', AbstractSyntaxTree)
                    ServerTypescriptSource = Generator.GenerateTypescript('Server', AbstractSyntaxTree)
                end

                local FilesTime = (os.clock() - FilesStart)

                fs.writeFile(ServerOutput, ServerSource)
                fs.writeFile(ClientOutput, ClientSource)

                if TypesSource and TypesOutput then
                    CreateDirectoryIfNotFound(TypesOutput, Options)
                    fs.writeFile(TypesOutput, TypesSource)
                end
                if ClientTypescriptSource and ServerTypescriptSource then
                    fs.writeFile(ClientTypescriptPath, ClientTypescriptSource)
                    fs.writeFile(ServerTypescriptPath, ServerTypescriptSource)
                end

                Message('green', Options, 'Network files generated!')

                if Options.Debug and not Options.Silent then
                    print(`[DEBUG]: Parsed source in {FormatTime(ParseTime)}.`)
                    print(`[DEBUG]: Generated server luau in {FormatTime(ServerGenerateTime)}.`)
                    print(`[DEBUG]: Generated client luau in {FormatTime(ClientGenerateTime)}.`)
                    print(`[DEBUG]: Generated files in {FormatTime(FilesTime)}.`)
                    print(`[DEBUG]: Completed everything in {FormatTime(ParseTime + FilesTime)}.`)
                end
            end

            return Utility
        end

        function __DARKLUA_BUNDLE_MODULES.q()
            local v = __DARKLUA_BUNDLE_MODULES.cache.q

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.q = v
            end

            return v.c
        end
    end
    do
        local function __modImpl()
            local dateTime = require('@lune/datetime')
            local fs = require('@lune/fs')
            local stdio = require('@lune/stdio')
            local task = require('@lune/task')
            local Compile = __DARKLUA_BUNDLE_MODULES.q()
            local GetDefinitionFilePath = __DARKLUA_BUNDLE_MODULES.f()
            local PathParser = __DARKLUA_BUNDLE_MODULES.d()
            local IMPORT_PATTERN = `import "([%w%/%.-_]+)"`
            local WATCH_OPTIONS = {
                Debug = false,
                Silent = true,
                Compact = false,
                YesToEverything = true,
                OutputAbstractSyntaxTree = false,
            }
            local Utility = {}

            local function Color(Color, Text)
                return `{stdio.color(Color)}{Text}{stdio.color('reset')}`
            end
            local function BuildImportsArray(Entry, PreviousArray)
                local Array = PreviousArray or {}

                table.insert(Array, Entry)

                local Source = fs.readFile(Entry)
                local Directory = PathParser.Directory(Entry)
                local Iterator = string.gmatch(Source, IMPORT_PATTERN)

                while true do
                    local Path = Iterator()

                    if not Path then
                        break
                    end

                    Path = `{Directory}{Path}`
                    Path = GetDefinitionFilePath(Path)

                    if not fs.isFile(Path) then
                        error(`No file to import at "{Path}"`)
                    end
                    if table.find(Array, Path) then
                        continue
                    end

                    BuildImportsArray(Path, Array)
                end

                return Array
            end

            function Utility.Watch(Path)
                local FilePath = GetDefinitionFilePath(Path)
                local Imports

                _G.WATCH_THREAD = true

                local function Traverse()
                    local OldImports = Imports and #Imports or 0

                    Imports = BuildImportsArray(FilePath)

                    if OldImports ~= #Imports then
                        print(`Blink is watching for changes:\n\tEntry: {Color('yellow', FilePath)}\n\tImports: {Color('yellow', tostring(#Imports - 1))}`)
                    end

                    return true
                end
                local function Recompile()
                    Traverse()
                    Compile.Compile(Path, WATCH_OPTIONS)
                end

                local InitialSuccess, Why = pcall(Traverse)

                if not InitialSuccess then
                    warn(`There was an error while trying to start the watcher thread:\n{Why}`)

                    return
                end

                local Timestamps = {}

                while true do
                    local FileChanged = false

                    for _, File in Imports do
                        local Metadata = fs.metadata(File)

                        if not Metadata.exists then
                            continue
                        end

                        local ModifiedAt = Metadata.modifiedAt and Metadata.modifiedAt.unixTimestampMillis or 0
                        local LastModifiedA = Timestamps[File]

                        Timestamps[File] = ModifiedAt

                        if ModifiedAt ~= LastModifiedA then
                            FileChanged = true
                        end
                    end

                    if FileChanged then
                        pcall(Recompile)
                    end

                    task.wait(1)
                end
            end

            return Utility
        end

        function __DARKLUA_BUNDLE_MODULES.r()
            local v = __DARKLUA_BUNDLE_MODULES.cache.r

            if not v then
                v = {
                    c = __modImpl(),
                }
                __DARKLUA_BUNDLE_MODULES.cache.r = v
            end

            return v.c
        end
    end
end

local process = require('@lune/process')
local stdio = require('@lune/stdio')
local Compile = __DARKLUA_BUNDLE_MODULES.q()
local Watch = __DARKLUA_BUNDLE_MODULES.r()
local ARGUMENTS = {
    Help = {
        Aliases = {
            '-h',
            '--help',
        },
        Description = 'Print help information',
    },
    Version = {
        Aliases = {
            '-v',
            '--version',
        },
        Description = 'Print version information',
    },
    Watch = {
        Aliases = {
            '-w',
            '--watch',
        },
        Description = 
[[Watch [CONFIG] for changes, automatically recompile upon one occuring]],
    },
    Silent = {
        Aliases = {
            '-q',
            '--quiet',
        },
        Description = 'Silence program output',
    },
    Compact = {
        Aliases = {
            '-c',
            '--compact',
        },
        Description = 
[[Compacts error output, the full message is still printed out after a compacted version.]],
    },
    YesToAll = {
        Aliases = {
            '-y',
            '--yes',
        },
        Description = 'Accept all prompts',
    },
    OutputAst = {
        Hidden = true,
        Aliases = {
            '--ast',
        },
        Description = 'Output the AST of [CONFIG]',
    },
    Statistics = {
        Hidden = true,
        Aliases = {
            '-S',
            '--stats',
        },
        Description = 'Output compilation time statistics',
    },
}

local function Style(Text, Style)
    return `{stdio.style(Style)}{Text}{stdio.style('reset')}`
end
local function Color(Text, Color)
    return `{stdio.color(Color)}{Text}{stdio.color('reset')}`
end
local function PrintHelpMessage()
    print(Color(Style('USAGE:', 'bold'), 'yellow'))
    print('\tblink.exe [CONFIG] [OPTIONS]')
    print(Color(Style('OPTIONS:', 'bold'), 'yellow'))

    local Sorted = {}

    for _, Argument in ARGUMENTS do
        if not Argument.Hidden then
            table.insert(Sorted, Argument)
        end
    end

    table.sort(Sorted, function(a, b)
        return a.Aliases[1] < b.Aliases[1]
    end)

    for _, Argument in Sorted do
        print(`\t{stdio.color('green')}{table.concat(Argument.Aliases, ', ')}{stdio.color('reset')}\t{Argument.Description}`)
    end
end

print(`{Color('Blink', 'green')} {'0.18.6' or 'DEBUG'}`)

local RawArguments = process.args

if #RawArguments < 1 then
    PrintHelpMessage()

    return
end

local Path = RawArguments[1]
local Arguments = {}

for Key, Argument in ARGUMENTS do
    local IsSupplied = false

    for _, Alias in Argument.Aliases do
        if table.find(RawArguments, Alias) ~= nil then
            IsSupplied = true

            break
        end
    end

    Arguments[Key] = IsSupplied
end

if Arguments.Help then
    PrintHelpMessage()

    return
end
if Arguments.Version then
    return
end
if not Arguments.Watch then
    local CompileOptions = {
        Debug = (true == nil) or Arguments.Statistics,
        Silent = Arguments.Silent,
        Compact = Arguments.Compact,
        YesToEverything = Arguments.YesToAll,
        OutputAbstractSyntaxTree = Arguments.OutputAst,
    }

    Compile.Compile(Path, CompileOptions)
else
    Watch.Watch(Path)
end
