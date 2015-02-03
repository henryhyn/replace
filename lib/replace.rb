require 'yaml'
require 'pandoc-ruby'

class Replace
  attr_reader :string, :scan

  def initialize(string)
    @string = string
  end

  def help
    method_comments = {}
    replace(@string) do
      s /((.*#.*\r?\n)*)\s*def\s+(\w+)/ do
        method_comments[$3.to_sym] = $1
      end
    end
    method_comments
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

  # 扫描注释列表生成替换字典
  def scan_note
    del_head_blank
    note = {}
    @string.scan(/^[(（]\d+[）)]\s*(.*?)[:：]\s*(.*?)\\?\r?\n/) do |key, value|
      key_stem = key.gsub(/[(（](.*?)[）)]/, '')
      note[key_stem] = "#{key}: #{value}"
    end
    note
  end

  # 批量逐个替换第一个匹配项
  def batch_replace(regexps = {})
    regexps.each do |key, value|
      replace(@string) do
        sub! Regexp.new("\\G(.*?)#{key}", Regexp::MULTILINE), '\1'"#{key} ^[#{value}] "
      end
    end
    self
  end

  def simple
    replace(@string) do
      s /cc/, 'dd'
      s /aa/, 'bb'
    end
    self
  end

  # 处理 Shell 命令 tree 的输出 (通过验证, 危险等级: 0)
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
      s /\s*\\footnote\{(.*?)\}\s*/, '\footnote{\1}'
      s /\\footnote\{(.*?)[:：]\s*(.*?)\}/, '〔{\kaishu \1: \2}〕'
    end
    theorem
  end

  # 标准化 Markdown 文件, 处理 HTML 文件的转换结果 (未通过验证, 危险等级: 4)
  # code.punct2.blank
  def standard
    blank.del_line_break.punct2.code.add_line_break.format_markdown
  end

  # 处理 pdftotext 的转换结果 (未通过验证, 危险等级: 4)
  # paragraph.blank.del_line_break.chapter.list.punct2.add_line_break
  def pdftotext
    replace(@string) do
      # 删除页码行
      s /^[[:blank:]]*[０-９]+[[:blank:]]*\r?\n/, ''
    end
    paragraph.blank.del_line_break.chapter.list.punct2.add_line_break
  end

  # 中文标点转为英文标点 (通过验证, 危险等级: 3, 可能需要用中文标点)
  # 保留部分中文符号: 、《》〈〉【】〖〗〔〕
  # ascii2: ？！，；：（）
  def punct2
    replace(@string) do
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
      # 句末符号 .!?;:
      # 标点符号 `$()''""
      # 句中符号 ,、
      s /。/, '.'
      s /[“”]/, '"'
      s /[‘’]/, "'"
      s /──/, '---'
      s /—/, '--'
    end
    ascii2
  end

  # 台湾标点转大陆标点 (通过验证, 危险等级: 0)
  # ascii2
  def taiwan
    replace(@string) do
      s /「/, '‘'
      s /」/, '’'
      s /『/, '“'
      s /』/, '”'
    end
    ascii2
  end

  # 双字节 ASCII 字符转为单字节字符 (通过验证, 危险等级: 0)
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
  def ascii2
    replace(@string) do
      s /([\u{FF01}-\u{FF5E}])/ do
        bytes = $1.bytes
        bytes[1] -= 0xBC
        bytes[2] -= 0x60
        bytes[2] += 64*bytes[1]
        bytes[2..2].pack("c*")
      end
    end
    self
  end

  # 删除一些没必要的分行
  def del_line_break
    replace(@string) do
      # "无\n法\n处\n理\n这\n种\n情\n况"
      s /(\p{Han})\r?\n(\p{Han})/, '\1\2'
      s /(\p{Han})\r?\n([[:punct:]])/, '\1\2'
      s /…{3,}(\r?\n)+/, ''
    end
    self
  end

  # 增加一些必要的分行
  def add_line_break
    replace(@string) do
      s /(\p{Han})[[:blank:]]*([:,])[[:blank:]]*(\p{Han})/, '\1\2 \3'
      s /(\p{Han})[[:blank:]]*([。.!?;])[[:blank:]]*(\p{Han})/, '\1\2'"\n"'\3'
      s /(\p{Han})[[:blank:]]*(\p{Ps})/, '\1 \2'
      s /(\p{Pe})[[:blank:]]*(\p{Han})/, '\1 \2'
    end
    self
  end

  # 删除汉字之间的空格 (通过验证, 危险等级: 3)
  # 添加汉字与数字、英文之间的空格
  # del_head_blank.del_blank_line
  def blank
    replace(@string) do
      # 删除汉字之间的空格, "无 法 处 理 这 种 情 况"
      s /(\p{Han})[[:blank:]]+(\p{Han})/, '\1\2'
      # 添加汉字与数字、英文之间的空格
      s /(\p{Han})(\w)/, '\1 \2'
      s /(\w)(\p{Han})/, '\1 \2'
    end
    del_head_blank.del_blank_line
  end

  # 删除行首的空白 (通过验证, 危险等级: 3, 可能是 Markdown 缩进)
  # 将看上去像空白的行转化为真真的空白行
  def del_head_blank
    replace(@string) do
      s /^[[:blank:]]+/, ''
    end
    self
  end

  # 删除行尾的空白 (通过验证, 危险等级: 0)
  # 将看上去像空白的行转化为真真的空白行
  def del_tail_blank
    replace(@string) do
      s /[[:blank:]]+\r?\n/, "\n"
    end
    self
  end

  # 删除多余的空行 (通过验证, 危险等级: 0)
  # del_tail_blank
  def del_blank_line
    replace(@string) do
      s /(^[[:blank:]]*\r?\n){2,}/, "\n"
    end
    del_tail_blank
  end

  # 处理插图路径 (通过验证, 危险等级: 0)
  def image
    replace(@string) do
      s /Insert\s(18333fig\d+)\.png\s*\n.*?\d{1,2}-\d{1,2}\. (.*)/, '![\2](\1-tn.png)'
      s /!\[(.*?)\]\(.*\/(.*?)\)/, '![\1](\2)'
    end
    self
  end

  # 删除页眉页脚
  def head_foot
    replace(@string) do
      s /\A(^[^\r\n]*\r?\n){11}\s*/m, ''
      s /^\[«.*?\z/m, ''
      # s /(^.*?\r?\n){4}\z/, ''
    end
    self
  end

  # 行内代码两边各留一个空格 (未通过验证, 危险等级: 4)
  # jekyll_code
  def code
    replace(@string) do
      # 行内代码两边各留一个空格
      s /([[:alnum:]])`([^`]+?)`([[:alnum:]])/, '\1 `\2` \3'
    end
    jekyll_code
  end

  # Jekyll 代码格式转为 Fenced 代码格式 (通过验证, 危险等级: 0)
  def jekyll_code
    replace(@string) do
      s /\s*\{%\s*highlight\s+(\w+)\s*%\}\s*/, "\n\n"'```{.\1}'"\n"
      s /\s*\{%\s*endhighlight\s*%\}\s*/, "\n"'```'"\n\n"
    end
    self
  end

  # 定理环境, LaTeX 命令 (未通过验证, 危险等级: 2)
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

  # 转换 YAML 标题信息 (通过验证, 危险等级: 0)
  def title
    replace(@string) do
      s /\A^-{3,}\r?\n(.*?)^-{3,}\r?\n/m do
        doc = YAML::load($1)
        "# #{doc['title']}\n\n" if doc['title']
      end
    end
    self
  end

  # 删除加粗斜体样式 (通过验证, 危险等级: 3, 可能是 Markdown 加粗斜体)
  def del_italics_and_bold
    replace(@string) do
      s /([\W_]|^)(\*\*|__)(?=\S)([^\r]*?\S[\*_]*)\2([\W_]|$)/, '\1\3\4'
      s /([\W_]|^)(\*|_)(?=\S)([^\r\*_]*?\S)\2([\W_]|$)/, '\1\3\4'
    end
    self
  end

  def foreign_literature
    replace(@string) do
      s /\s*\n/, "\n\n"
      s /\${4,}\s*/, '#### '
      s /[　\u{001A}]/, ''
      s /# [０-９]+．\s*/, '## '
      s /#### 第[^\r\n]+[卷部]\s*(.*)\s*\n/, "PART: "'\1'"\n\n"
      s /#### 第[^\r\n]+[章]\s*(.*)\s*\n/, "# "'\1'"\n\n"
    end
    del_head_blank
  end

  def ancient_literature
    replace(@string) do
      s /_古诗文网/, ''
      s /作者：.*\r?\n/, ''
    end
    del_head_blank
  end

  # 判定段落的起始 (通过验证, 危险等级: 0)
  def paragraph
    replace(@string) do
      s /^[[:blank:]]{2,}/, "\n"
    end
    self
  end

  # 判定章节标题 (通过验证, 危险等级: 0)
  def chapter
    replace(@string) do
      s /^第[一二三四五六七八九十]+[卷部篇]/, 'PART: '
      s /^第[一二三四五六七八九十]+[章]/, '# '
      s /^第[一二三四五六七八九十]+[节]/, '## '
      s /^[一二三四五六七八九十]+、/, '### '
      s /^\([一二三四五六七八九十]+\)/, '#### '
    end
    self
  end

  def list
    replace(@string) do
      s /^(\d.)\s*/, '\1'"\t"
      s /^[●]\s*/, "-\t"
    end
    self
  end

  def format_markdown
    markdown2html.html2markdown
  end

  def markdown2html
    converter = PandocRuby.new(@string, from: :markdown, to: :html)
    @string = converter.convert('chapters', 'indented-code-classes' => 'sourceCode')
    self
  end

  def html2markdown
    converter = PandocRuby.new(@string, from: :html, to: :markdown)
    @string = converter.convert('chapters', 'atx-headers', 'normalize', 'columns' => 100)
    self
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