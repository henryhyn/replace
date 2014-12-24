class Replace
  attr_reader :source

  def initialize(source)
    @source = source
  end

  def simple
    replace(@source) do
      s /cc/, 'dd'
      s /aa/, 'bb'
    end
    self
  end

  def image
    replace(@source) do
      s /Insert\s(18333fig\d+)\.png\s*\n.*?\d{1,2}-\d{1,2}\. (.*)/, '![\2](\1-tn.png)'
    end
    self
  end

  def title
    replace(@source) do
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