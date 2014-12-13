class Replace
  def simple(string)
    replace(string) do
      s /cc/, 'dd'
      s /aa/, 'bb'
    end
  end

  def image(string)
    replace(string) do
      s /Insert\s(18333fig\d+)\.png\s*\n.*?\d{1,2}-\d{1,2}\. (.*)/, '![\2](\1-tn.png)'
    end
  end

  def title(string)
    replace(string) do
      s /\A^---\r?\n(.*?)^---\r?\n/m do |match|
        doc = YAML::load($1)
        "# #{doc['title']}\n\n" if doc['title']
      end
    end
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