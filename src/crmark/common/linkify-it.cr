module LinkifyRe
    SRC_ANY = "[\0-\uD7FF\uE000-\uFFFF]"
    SRC_CC  = "[\0-\u001F\u007F-\u009F]" # Control
    SRC_Z   = "[ \u00A0\u1680\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]" # Space
    SRC_P = "[!\"#%&'()*,\\-\\./:;?@\\[\\\\\\]_{}]" # Punctuation
    # regular expression is too large \xA1\xA7\xAB\xB6\xB7\xBB\xBF\u037E\u0387\u055A-\u055F\u0589\u058A\u05BE\u05C0\u05C3\u05C6\u05F3\u05F4\u0609\u060A\u060C\u060D\u061B\u061E\u061F\u066A-\u066D\u06D4\u0700-\u070D\u07F7-\u07F9\u0830-\u083E\u085E\u0964\u0965\u0970\u0AF0\u0DF4\u0E4F\u0E5A\u0E5B\u0F04-\u0F12\u0F14\u0F3A-\u0F3D\u0F85\u0FD0-\u0FD4\u0FD9\u0FDA\u104A-\u104F\u10FB\u1360-\u1368\u1400\u166D\u166E\u169B\u169C\u16EB-\u16ED\u1735\u1736\u17D4-\u17D6\u17D8-\u17DA\u1800-\u180A\u1944\u1945\u1A1E\u1A1F\u1AA0-\u1AA6\u1AA8-\u1AAD\u1B5A-\u1B60\u1BFC-\u1BFF\u1C3B-\u1C3F\u1C7E\u1C7F\u1CC0-\u1CC7\u1CD3\u2010-\u2027\u2030-\u2043\u2045-\u2051\u2053-\u205E\u207D\u207E\u208D\u208E\u2308-\u230B\u2329\u232A\u2768-\u2775\u27C5\u27C6\u27E6-\u27EF\u2983-\u2998\u29D8-\u29DB\u29FC\u29FD\u2CF9-\u2CFC\u2CFE\u2CFF\u2D70\u2E00-\u2E2E\u2E30-\u2E42\u3001-\u3003\u3008-\u3011\u3014-\u301F\u3030\u303D\u30A0\u30FB\uA4FE\uA4FF\uA60D-\uA60F\uA673\uA67E\uA6F2-\uA6F7\uA874-\uA877\uA8CE\uA8CF\uA8F8-\uA8FA\uA92E\uA92F\uA95F\uA9C1-\uA9CD\uA9DE\uA9DF\uAA5C-\uAA5F\uAADE\uAADF\uAAF0\uAAF1\uABEB\uFD3E\uFD3F\uFE10-\uFE19\uFE30-\uFE52\uFE54-\uFE61\uFE63\uFE68\uFE6A\uFE6B\uFF01-\uFF03\uFF05-\uFF0A\uFF0C-\uFF0F\uFF1A\uFF1B\uFF1F\uFF20\uFF3B-\uFF3D\uFF3F\uFF5B\uFF5D\uFF5F-\uFF65]|\uD800[\uDD00-\uDD02\uDF9F\uDFD0]|\uD801\uDD6F|\uD802[\uDC57\uDD1F\uDD3F\uDE50-\uDE58\uDE7F\uDEF0-\uDEF6\uDF39-\uDF3F\uDF99-\uDF9C]|\uD804[\uDC47-\uDC4D\uDCBB\uDCBC\uDCBE-\uDCC1\uDD40-\uDD43\uDD74\uDD75\uDDC5-\uDDC8\uDDCD\uDE38-\uDE3D]|\uD805[\uDCC6\uDDC1-\uDDC9\uDE41-\uDE43]|\uD809[\uDC70-\uDC74]|\uD81A[\uDE6E\uDE6F\uDEF5\uDF37-\uDF3B\uDF44]|\uD82F\uDC9F

    # \p{\Z\P\Cc} (white spaces + control + punctuation)
    SRC_Z_P_CC = [ SRC_Z, SRC_P, SRC_CC ].join('|')

    # \p{\Z\Cc} (white spaces + control)
    SRC_Z_CC = [ SRC_Z, SRC_CC ].join('|')

    # All possible word characters (everything without punctuation, spaces & controls)
    # Defined via punctuation & spaces to save space
    # Should be something like \p{\L\N\S\M} (\w but without `_`)
    SRC_PSEUDO_LETTER       = "(?:(?!" + SRC_Z_P_CC + ")" + SRC_ANY + ")"
    # The same as above but without [0-9]
    SRC_PSEUDO_LETTER_NON_D = "(?:(?![0-9]|" + SRC_Z_P_CC + ")" + SRC_ANY + ")"

    #------------------------------------------------------------------------------

    SRC_IP4   = "(?:(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"

    SRC_AUTH  = "(?:(?:(?!" + SRC_Z_CC + ").)+@)?"

    #SRC_PORT  = "(?::(?:6(?:[0-4]\\d{3}|5(?:[0-4]\\d{2}|5(?:[0-2]\\d|3[0-5])))|[1-5]?\\d{1,4}))?"
    SRC_PORT  = "(?::\d+)?"

    SRC_HOST_TERMINATOR = "(?=$|" + SRC_Z_P_CC + ")(?!-|_|:\\d|\\.-|\\.(?!$|" + SRC_Z_P_CC + "))"

    SRC_PATH = 
      "(?:" +
        "[/?#]" +
          "(?:" +
            "(?!" + SRC_Z_CC + "|[()\\[\\]{}.,\"'?!\\-]).|" +
            "\\[(?:(?!" + SRC_Z_CC + "|\\]).)*\\]|" +
            "\\((?:(?!" + SRC_Z_CC + "|[)]).)*\\)|" +
            "\\{(?:(?!" + SRC_Z_CC + "|[}]).)*\\}|" +
           %{\\"(?:(?!} + SRC_Z_CC +%{|["]).)+\\"|} +
            "\\'(?:(?!" + SRC_Z_CC + "|[']).)+\\'|" +
            "\\'(?=" + SRC_PSEUDO_LETTER + ").|" +  # allow `I'm_king` if no pair found
            "\\.{2,3}[a-zA-Z0-9%/]|" + # github has ... in commit range links. Restrict to
                                       # - english
                                       # - percent-encoded
                                       # - parts of file path
                                       # until more examples found.
            "\\.(?!" + SRC_Z_CC + "|[.]).|" +
            "\\-(?!--(?:[^-]|$))(?:-*)|" +  # `---` => long dash, terminate
            "\\,(?!" + SRC_Z_CC + ").|" +      # allow `,,,` in paths
            "\\!(?!" + SRC_Z_CC + "|[!]).|" +
            "\\?(?!" + SRC_Z_CC + "|[?])." +
          ")+" +
        "|\\/" +
      ")?"

    SRC_EMAIL_NAME  = %{[\\-;:&=\\+\\$,\\"\\.a-zA-Z0-9_]+}
    SRC_XN          = "xn--[a-z0-9\\-]{1,59}"

    # More to read about domain names
    # http://serverfault.com/questions/638260/

    SRC_DOMAIN_ROOT = 
      # Can't have digits and dashes
      "(?:" +
        SRC_XN +
        "|" +
        SRC_PSEUDO_LETTER_NON_D + "{1,63}" +
      ")"

    SRC_DOMAIN = 
      "(?:" +
        SRC_XN +
        "|" +
        "(?:" + SRC_PSEUDO_LETTER + ")" +
        "|" +
        # don't allow `--` in domain names, because:
        # - that can conflict with markdown &mdash; / &ndash;
        # - nobody use those anyway
        "(?:" + SRC_PSEUDO_LETTER + "(?:-(?!-)|" + SRC_PSEUDO_LETTER + "){0,61}" + SRC_PSEUDO_LETTER + ")" +
      ")"

    SRC_HOST = 
      "(?:" +
        SRC_IP4 +
      "|" +
        "(?:(?:(?:" + SRC_DOMAIN + ")\\.)*" + SRC_DOMAIN_ROOT + ")" +
      ")"

    TPL_HOST_FUZZY = 
      "(?:" +
        SRC_IP4 +
      "|" +
        "(?:(?:(?:" + SRC_DOMAIN + ")\\.)+(?:%TLDS%))" +
      ")"

    TPL_HOST_NO_IP_FUZZY =
      "(?:(?:(?:" + SRC_DOMAIN + ")\\.)+(?:%TLDS%))"

    SRC_HOST_STRICT            = SRC_HOST + SRC_HOST_TERMINATOR
    TPL_HOST_FUZZY_STRICT      = TPL_HOST_FUZZY + SRC_HOST_TERMINATOR
    SRC_HOST_PORT_STRICT       = SRC_HOST + SRC_PORT + SRC_HOST_TERMINATOR
    TPL_HOST_PORT_FUZZY_STRICT = TPL_HOST_FUZZY + SRC_PORT + SRC_HOST_TERMINATOR
    TPL_HOST_PORT_NO_IP_FUZZY_STRICT = TPL_HOST_NO_IP_FUZZY + SRC_PORT + SRC_HOST_TERMINATOR
      
    #------------------------------------------------------------------------------
    # Main rules

    # Rude test fuzzy links by host, for quick deny
    TPL_HOST_FUZZY_TEST = "localhost|\\.\\d{1,3}\\.|(?:\\.(?:%TLDS%)(?:" + SRC_Z_P_CC + "|$))"
    TPL_EMAIL_FUZZY     = "(^|>|" + SRC_Z_CC + ")(" + SRC_EMAIL_NAME + "@" + TPL_HOST_FUZZY_STRICT + ")"
    TPL_LINK_FUZZY =
        # Fuzzy link can't be prepended with .:/\- and non punctuation.
        # but can start with > (markdown blockquote)
        "(^|(?![.:/\\-_@])(?:[$+<=>^`|]|" + SRC_Z_P_CC + "))" +
        "((?![$+<=>^`|])" + TPL_HOST_PORT_FUZZY_STRICT + SRC_PATH + ")"

    TPL_LINK_NO_IP_FUZZY =
        # Fuzzy link can't be prepended with .:/\- and non punctuation.
        # but can start with > (markdown blockquote)
        "(^|(?![.:/\\-_@])(?:[$+<=>^`|]|" + SRC_Z_P_CC + "))" +
        "((?![$+<=>^`|])" + TPL_HOST_PORT_NO_IP_FUZZY_STRICT + SRC_PATH + ")"
end

module LinkifyIt
  HTTP_VALIDATOR = ->(text : String, pos : Int32) {
    tail = text[pos..-1]
    if RE_HTTP =~ tail
      tail.match(RE_HTTP).not_nil![0].not_nil!.size
    else
      0
    end
  }

  EMAIL_VALIDATOR = ->(text : String, pos : Int32) {
    tail = text[pos..-1]
    if RE_MAILTO =~ tail
      tail.match(RE_MAILTO).not_nil![0].not_nil!.size
    else
      0
    end
  }

  SLASH_SLASH_VALIDATOR = ->(text : String, pos : Int32) {
    tail = text[pos..-1]
    if RE_NO_HTTP =~ tail
      if pos >= 3 && text[pos - 3] == ':'
        0
      else
        tail.match(RE_NO_HTTP).not_nil![0].not_nil!.size
      end
    else
      0
    end
  }

  SCHEMAS_VALIDATORS = {
    "http:"   => HTTP_VALIDATOR,
    "https:"  => HTTP_VALIDATOR,
    "ftp:"    => HTTP_VALIDATOR,
    "mailto:" => EMAIL_VALIDATOR,
    "//"      => SLASH_SLASH_VALIDATOR,
  }
  SCHEMAS_LIST = SCHEMAS_VALIDATORS.keys.join('|')

  TLDS_2CH_SRC_RE = "a[cdefgilmnoqrstuwxz]|b[abdefghijmnorstvwyz]|c[acdfghiklmnoruvwxyz]|d[ejkmoz]|e[cegrstu]|f[ijkmor]|g[abdefghilmnpqrstuwy]|h[kmnrtu]|i[delmnoqrst]|j[emop]|k[eghimnprwyz]|l[abcikrstuvy]|m[acdeghklmnopqrstuvwxyz]|n[acefgilopruz]|om|p[aefghklmnrstwy]|qa|r[eosuw]|s[abcdeghijklmnortuvxyz]|t[cdfghjklmnortvwz]|u[agksyz]|v[aceginu]|w[fs]|y[et]|z[amw]"
  TLDS_DEFAULT = "biz|com|edu|gov|net|org|pro|web|xxx|aero|asia|coop|info|museum|name|shop|рф"
  SRC_TLDS = [TLDS_2CH_SRC_RE, TLDS_DEFAULT, LinkifyRe::SRC_XN].join('|')

  EMAIL_FUZZY      = Regex.new(LinkifyRe::TPL_EMAIL_FUZZY.gsub("%TLDS%", SRC_TLDS))
  LINK_FUZZY       = Regex.new(LinkifyRe::TPL_LINK_FUZZY.gsub("%TLDS%", SRC_TLDS))
  LINK_NO_IP_FUZZY = Regex.new(LinkifyRe::TPL_LINK_NO_IP_FUZZY.gsub("%TLDS%", SRC_TLDS))
  HOST_FUZZY_TEST  = Regex.new(LinkifyRe::TPL_HOST_FUZZY_TEST.gsub("%TLDS%", SRC_TLDS))

  SCHEMA_TEST   = Regex.new("(^|(?!_)(?:>|" + LinkifyRe::SRC_Z_P_CC + "))(" + SCHEMAS_LIST + ")", Regex::Options::IGNORE_CASE)
  SCHEMA_SEARCH = Regex.new("(^|(?!_)(?:>|" + LinkifyRe::SRC_Z_P_CC + "))(" + SCHEMAS_LIST + ")", Regex::Options::IGNORE_CASE)
  PRETEST       = Regex.new( "(" + SCHEMA_TEST.source + ")|" + "(" + HOST_FUZZY_TEST.source + ")|" + "@", Regex::Options::IGNORE_CASE)

  RE_HTTP = Regex.new("^\/\/" + LinkifyRe::SRC_AUTH + LinkifyRe::SRC_HOST_PORT_STRICT + LinkifyRe::SRC_PATH, Regex::Options::IGNORE_CASE)
  RE_MAILTO = Regex.new("^" + LinkifyRe::SRC_EMAIL_NAME + "@" + LinkifyRe::SRC_HOST_STRICT, Regex::Options::IGNORE_CASE)
  RE_NO_HTTP = Regex.new("^" + LinkifyRe::SRC_AUTH + LinkifyRe::SRC_HOST_PORT_STRICT + LinkifyRe::SRC_PATH, Regex::Options::IGNORE_CASE)


  def self.pretest(text)
    !(String.new(text) =~ PRETEST).nil?
  end

  def self.test(text : String, offset = 0)
    if md = SCHEMA_SEARCH.match(text, offset)
      lastIndex = md.end(0).not_nil!
      len = testSchemaAt(text, md[2], lastIndex)
      if len > 0
        start = md.begin(0).not_nil! + md[1].size
        finish = md.begin(0).not_nil! + md[0].size + len
        url = text[start...finish]
        return Match.new(md[2], start, finish, url, url, url)
      end
    end

    if HOST_FUZZY_TEST.match(text, offset)
      if md = LINK_FUZZY.match(text, offset)
        start = md.begin(0).not_nil! + md[1].size
        finish = md.begin(0).not_nil! + md[0].size
        urlText = text[start...finish]
        return Match.new("", start, finish, urlText, "http://" + urlText, urlText)
      end
    end

    if at_pos = text.index('@')
      if md = EMAIL_FUZZY.match(text, offset)
        start = md.begin(0).not_nil! + md[1].size
        finish = md.begin(0).not_nil! + md[0].size
        urlText = text[start...finish]
        return Match.new("mailto:", start, finish, urlText, "mailto:" + urlText, urlText)
      end
    end
  end

  class Match
    property :schema, :index, :lastIndex, :raw, :url, :text

    def initialize(
        @schema : String = "",
        @index : Int32 = 0,
        @lastIndex : Int32 = -1,
        @raw = "",
        @url = "",
        @text = "",
      )
    end

    def self.normalize(match : Match)
      return if @bypass_normalizer
      
      # Do minimal possible changes by default. Need to collect feedback prior
      # to move forward https://github.com/markdown-it/linkify-it/issues/1

      match.url = "http://#{match.url}" if match.schema.empty?

      if (match.schema == "mailto:" && !(/^mailto\:/i =~ match.url))
        match.url = "mailto:" + match.url
      end
    end
  end

  def self.match(_text) : Array(Match)
    text = String.new(_text)
    result = [] of Match

    lastIndex = 0
    while match = test(text, lastIndex)
      result << match
      lastIndex = match.lastIndex
    end

    result
  end

  def self.testSchemaAt(text, schema, pos : Int32)
    if SCHEMAS_VALIDATORS[schema]
      SCHEMAS_VALIDATORS[schema].call(text, pos)
    else
      0
    end
  end
end