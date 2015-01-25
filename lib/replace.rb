class Replace
  attr_reader :string, :scan

  def initialize(string)
    @string = string
  end

  def scan_test
    @scan = @string.scan(/\w+/)
  end

  def scan_url
    @scan = @string.scan(/href=['"](.*?)['"]/)
  end

  def scan_image
    @scan = @string.scan(/!\[.*?\]\(([^\s]+?)(?:\s+.*?)?\)/)
  end

  def simple
    replace(@string) do
      s /cc/, 'dd'
      s /aa/, 'bb'
    end
    self
  end

  def tree
    replace(@string) do
      s /[│├]/, '|'
      s /[└]/, '\\'
      s /[─]/, '-'
    end
    self
  end

  def rename
    replace(@string) do
      s /!\[\]\(image(\d+).jpg\)/ do
        i = $1.to_i - 1
        "![](image%03d.jpg)" % i
      end
    end
    self
  end

  def pre_pandoc_for_latex
    title
  end

  def post_pandoc_for_latex
    replace(@string) do
      s /\{verbatim\}/, '{Verbatim}'
      s /\\begin\{center\}\\rule\{3in\}\{0.4pt\}\\end\{center\}/, '\newpage'
    end
    theorem
  end

  def standard
    code.punctuation.blank
  end

  def pdftotext
    replace(@string) do
      # 删除页码行
      s /^[[:blank:]]*[０-９]+[[:blank:]]*\r?\n/, ''
    end
    self
  end

  # 中文标点转为英文标点
  # 句末符号 .!?;:
  # 标点符号 `$()''""
  # 句中符号 ,、
  def punctuation
    replace(@string) do
      # ！＂＃＄％＆＇（）＊＋，－．／
      # ０１２３４５６７８９：；＜＝＞？
      # ＠ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯ
      # ＰＱＲＳＴＵＶＷＸＹＺ［＼］＾＿
      # ｀ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏ
      # ｐｑｒｓｔｕｖｗｘｙｚ｛｜｝～
      # !"#$%&'()*+,-./
      # 0123456789:;<=>?
      # @ABCDEFGHIJKLMNO
      # PQRSTUVWXYZ[\]^_
      # `abcdefghijklmno
      # pqrstuvwxyz{|}~
      # ‐‑‒–—―‖‗‘’‚‛“”„‟
      # †‡•‣․‥…‧
      # ‰‱′″‴‵‶‷‸‹›※‼‽‾‿
      # ⁀⁁⁂⁃
      # ⁅⁆⁇⁈⁉⁊⁋⁌⁍⁎⁏
      # ⁐⁑
      # ⁓⁔⁕⁖⁗⁘⁙⁚⁛⁜⁝⁞
      # ⁽⁾
      # 、。〃
      # 〈〉《》「」『』
      # 【】
      # 〔〕〖〗〘〙〚〛〜〝〞〟
      # 〰
      # 〽
      # \p{S}: $+<=>^`|~⁄⁒
      # \p{Sm}: +<=>|~⁄⁒
      # \p{Sc}: $
      # \p{Sk}: ^`
      # \p{Pi}: ‘‛“‟
      # \p{Pf}: ’”
      s /([\u{FF01}-\u{FF5E}])/ do
        bytes = $1.bytes
        bytes[1] -= 0xBC
        bytes[2] -= 0x60
        bytes[2] += 64*bytes[1]
        bytes[2..2].pack("c*")
      end
      s /。/, '.'
      s /“/, '"'
      s /”/, '"'
      s /’/, "'"
      s /(\p{Han})[[:blank:]]*([:,])[[:blank:]]*(\p{Han})/, '\1\2 \3'
      s /(\p{Han})[[:blank:]]*([.!?;])[[:blank:]]*(\p{Han})/, '\1\2'"\n"'\3'
      s /(\p{Han})[[:blank:]]*(\p{Ps})/, '\1 \2'
      s /(\p{Pe})[[:blank:]]*(\p{Han})/, '\1 \2'
    end
    self
  end

  def linebreak
    replace(@string) do
      s /(\p{Han})\r?\n/, '\1'
      s /\r?\n^([[:punct:]])/, '\1'
      s /\\\r?\n/, "\n"
    end
    self
  end

  def blank
    replace(@string) do
      # 删除汉字之间的空格
      s /(\p{Han})[[:blank:]]+(\p{Han})/, '\1\2'
      # 添加汉字与数字、英文之间的空格
      s /(\p{Han})(\w)/, '\1 \2'
      s /(\w)(\p{Han})/, '\1 \2'
    end
    del_head_blank.del_foot_blank.del_blank_line
  end

  # 删除行首的空白
  def del_head_blank
    replace(@string) do
      s /^[[:blank:]]+/, ''
    end
    self
  end

  # 删除行尾的空白
  def del_foot_blank
    replace(@string) do
      s /[[:blank:]]+\r?\n/, "\n"
    end
    self
  end

  # 删除多余的空行
  def del_blank_line
    replace(@string) do
      s /(^\r?\n){2,}/, "\n"
    end
    self
  end

  def image
    replace(@string) do
      s /Insert\s(18333fig\d+)\.png\s*\n.*?\d{1,2}-\d{1,2}\. (.*)/, '![\2](\1-tn.png)'
      s /!\[(.*?)\]\(.*\/(.*?)\)/, '![\1](\2)'
    end
    self
  end

  def head_foot
    replace(@string) do
      s /\A(^[^\r\n]*\r?\n){11}\s*/m, ''
      s /^\[«.*?\z/m, ''
      # s /(^.*?\r?\n){4}\z/, ''
    end
    self
  end

  def code
    replace(@string) do
      s /\{% highlight\s*(\w+)\s*%\}\s*/, '```{.\1}'"\n"
      s /\s*\{% endhighlight %\}/, "\n```\n"
      # 行内代码两边各留一个空格
      s /([[:alnum:]])`([^`]+?)`([[:alnum:]])/, '\1 `\2` \3'
    end
    self
  end

  def theorem
    replace(@string) do
      s /^(ASSUMPTION|DEFINITION|CONCLUSION|ALGORITHM|EXPERIMENT|EXAMPLE|REMARK|NNOTE|THEOREM|AXIOM|LEMMA|PROPERTY|COROLLARY|PROPOSITION|CLAIM|PROBLEM|QUESTION|CONJECTURE|PROOF|SOLUTION|ANSWER|ANALYSIS)[.:](.*?)(\n(?=\n)|\Z)/mi do
        css_class = $1.downcase
        "\\begin{#{css_class}}\n#{$2.strip}\n\\end{#{css_class}}\n"
      end
    end
    replace(@string) do
      s /^(PART)[.:](.*?)(\n(?=\n)|\Z)/mi do
        "\\#{$1.downcase}{#{$2.strip}}\n"
      end
    end
    self
  end

  def title
    replace(@string) do
      s /\A^-{3,}\r?\n(.*?)^-{3,}\r?\n/m do
        doc = YAML::load($1)
        "# #{doc['title']}\n\n" if doc['title']
      end
    end
    self
  end

  def del_italics_and_bold
    replace(@string) do
      s /([\W_]|^)(\*\*|__)(?=\S)([^\r]*?\S[\*_]*)\2([\W_]|$)/, '\1\3\4'
      s /([\W_]|^)(\*|_)(?=\S)([^\r\*_]*?\S)\2([\W_]|$)/, '\1\3\4'
    end
    self
  end

  def foreign_literature
    replace(@string) do
      s /^[　\s]+/, ''
      s /\s*\n/, "\n\n"
      s /\${4,}\s*/, '#### '
      s /[　\u{001A}]/, ''
      s /# [０-９]+．\s*/, '## '
      s /#### 第[^\r\n]+[卷部]\s*(.*)\s*\n/, "PART: "'\1'"\n\n"
      s /#### 第[^\r\n]+[章]\s*(.*)\s*\n/, "# "'\1'"\n\n"
    end
    self
  end

  def ancient_literature
    replace(@string) do
      s /_古诗文网/, ''
      s /作者：.*\r?\n/, ''
    end
    del_head_blank
  end

  private

  def replace(string, &block)
    string.instance_eval do
      alias :s :gsub!
      instance_eval(&block)
    end
    string
  end
end