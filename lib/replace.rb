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
        doc_options = YAML::load($1)
        '#' + doc_options['title'] if doc_options['title']
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