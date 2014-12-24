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

  def simple
    replace(@string) do
      s /cc/, 'dd'
      s /aa/, 'bb'
    end
    self
  end

  def standard
    punctuation.blank
  end

  # 中文标点转为英文标点
  # 句末符号 .!?;:
  # 标点符号 `$()''""
  # 句中符号 ,、
  def punctuation
    replace(@string) do
      s /。/, ".\n"
      s /．/, ".\n"
      s /！/, "!\n"
      s /？/, "?\n"
      s /；/, ";\n"
      s /：/, ': '
      s /，/, ', '
      s /（/, ' ('
      s /）/, ') '
      s /“/, '"'
      s /”/, '"'
      s /’/, "'"
    end
    self
  end

  def linebreak
    replace(@string) do
      s /\.\s*/, ".\n"
    end
    self
  end

  def blank
    replace(@string) do
      # 将看上去像空白行的行变成真正的空白行
      s /^\s+\r?\n/m, "\n"
      # 删除行尾空格
      s /[[:blank:]]+\r?\n/, "\n"
      # 删除汉字之间的空格
      s /(\p{Lo})[[:blank:]]+(\p{Lo})/, '\1\2'
      # 添加汉字与数字、英文之间的空格
      s /(\p{Lo})(\w)/, '\1 \2'
      s /(\w)(\p{Lo})/, '\1 \2'
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
    end
  end

  def code
    replace(@string) do
      s /\{% highlight\s*(\w+)\s*%\}\s*/, '```{.\1}' + "\n"
      s /\s*\{% endhighlight %\}/m, "\n```\n"
    end
  end

  def theorem
    replace(@string) do
      s /^([A-Z]+)[.:](.*?)(\n(?=\n)|\Z)/m do
        css_class = $1.downcase
        "\\begin{#{css_class}}\n#{$2.strip}\n\\end{#{css_class}}\n"
      end
    end
  end

  def title
    replace(@string) do
      s /\A^---\r?\n(.*?)^---\r?\n/m do |match|
        doc = YAML::load($1)
        "# #{doc['title']}\n\n" if doc['title']
      end
    end
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