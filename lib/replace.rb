class Replace
  attr_reader :string

  def initialize(string)
    @string = string
  end

  def simple
    replace(@string) do
      s /cc/, 'dd'
      s /aa/, 'bb'
    end
    self
  end

  def standard
    punctuation.linebreak
  end

  def punctuation
    replace(@string) do
      s /，/, ', '
      s /：/, ': '
      s /；/, '; '
      s /。/, '. '
      s /（/, ' ('
      s /）/, ') '
      s /“/, ' "'
      s /”/, '" '
    end
    self
  end

  def linebreak
    replace(@string) do
      s /\.\s*/, ".\n"
    end
    self
  end

  def image
    replace(@string) do
      s /Insert\s(18333fig\d+)\.png\s*\n.*?\d{1,2}-\d{1,2}\. (.*)/, '![\2](\1-tn.png)'
    end
    self
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