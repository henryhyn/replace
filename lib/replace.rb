class Replace
  def simple(string)
    replace(string) do
      s /cc/, 'dd'
      s /aa/, 'bb'
    end
  end

  def title(string)
    replace(string) do
      s /^---\r?\n(.*?)^---\r?\n/m do |match|
        doc = YAML::load($1)
        "# #{doc['title']}\n" if doc['title']
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